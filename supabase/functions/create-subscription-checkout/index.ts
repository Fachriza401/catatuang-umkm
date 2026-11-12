import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

import {
  corsHeaders,
  jsonError,
  jsonResponse,
  readBearerToken,
  readJsonObject,
} from '../_shared/http.ts';
import {
  midtransAuthorization,
  midtransSnapBaseUrl,
} from '../_shared/midtrans.ts';

const planRank: Record<string, number> = {
  free: 0,
  premium: 1,
  business: 2,
};

const planLabel: Record<string, string> = {
  premium: 'Premium',
  business: 'Business',
};

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return jsonError('Method not allowed', 405);
  }

  try {
    const token = readBearerToken(request);
    if (!token) return jsonError('Authentication required', 401);

    const body = await readJsonObject(request);
    const plan = typeof body?.plan === 'string' ? body.plan.trim() : '';
    if (!(plan in planRank) || plan === 'free') {
      return jsonError('Invalid subscription plan', 400);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const publishableKey = Deno.env.get('SUPABASE_ANON_KEY');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const midtransServerKey = Deno.env.get('MIDTRANS_SERVER_KEY');
    if (
      !supabaseUrl || !publishableKey || !serviceRoleKey ||
      !midtransServerKey
    ) {
      return jsonError('Server configuration unavailable', 500);
    }

    const userClient = createClient(supabaseUrl, publishableKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser(
      token,
    );
    if (userError || !userData.user) {
      return jsonError('Invalid session', 401);
    }

    const { data: accessData, error: accessError } = await userClient.rpc(
      'get_my_business_access',
    );
    if (accessError || !accessData?.business_id) {
      return jsonError('Business context unavailable', 500);
    }
    const access = accessData as Record<string, unknown>;
    if (access.role !== 'owner') {
      return jsonError('Only the business owner can manage billing', 403);
    }

    const businessId = access.business_id as string;
    const currentPlan = typeof access.plan === 'string' ? access.plan : 'free';
    if ((planRank[plan] ?? 0) < (planRank[currentPlan] ?? 0)) {
      return jsonError('Cannot downgrade to a lower plan', 409);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: planData, error: planError } = await adminClient
      .from('business_plans')
      .select(
        'plan, price_amount, currency, billing_period_days, ' +
          'monthly_transaction_limit, attachments_enabled',
      )
      .eq('plan', plan)
      .maybeSingle();
    if (planError) {
      return jsonError('Subscription plan unavailable', 500);
    }
    const planRow = planData as Record<string, unknown> | null;
    const priceAmount = Number(planRow?.price_amount ?? 0);
    const billingPeriodDays = Number(planRow?.billing_period_days ?? 0);
    const currency = typeof planRow?.currency === 'string'
      ? planRow.currency
      : 'IDR';
    if (!planRow || priceAmount <= 0 || billingPeriodDays <= 0) {
      return jsonError('Subscription price is not configured', 409);
    }

    const { data: profileData } = await adminClient
      .from('business_profiles')
      .select('business_name')
      .eq('user_id', businessId)
      .maybeSingle();
    const businessName = typeof (profileData as Record<string, unknown> | null)
        ?.business_name === 'string'
      ? (profileData as Record<string, string>).business_name
      : undefined;

    const orderId = crypto.randomUUID();
    const providerOrderId = `sub_${orderId.replaceAll('-', '')}`;
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

    const { error: insertError } = await adminClient
      .from('payment_orders')
      .insert({
        id: orderId,
        business_id: businessId,
        plan,
        amount: priceAmount,
        currency,
        status: 'pending',
        provider: 'midtrans',
        provider_order_id: providerOrderId,
        created_by: userData.user.id,
        expires_at: expiresAt,
      });
    if (insertError) {
      return jsonError('Unable to create payment order', 500);
    }

    const snapPayload = {
      transaction_details: {
        order_id: providerOrderId,
        gross_amount: priceAmount,
      },
      item_details: [
        {
          id: plan,
          price: priceAmount,
          quantity: 1,
          name: `CatatUang ${planLabel[plan]} ${billingPeriodDays} hari`,
        },
      ],
      customer_details: {
        first_name: businessName?.slice(0, 50),
        email: userData.user.email ?? undefined,
      },
      expiry: {
        unit: 'hours',
        duration: 24,
      },
    };

    const snapResponse = await fetch(
      `${midtransSnapBaseUrl()}/snap/v1/transactions`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          Authorization: midtransAuthorization(midtransServerKey),
        },
        body: JSON.stringify(snapPayload),
      },
    );

    if (!snapResponse.ok) {
      await adminClient
        .from('payment_orders')
        .update({ status: 'failed' })
        .eq('id', orderId);
      return jsonError('Payment gateway rejected the checkout', 502);
    }

    const snapResult = await snapResponse.json() as Record<string, unknown>;
    const redirectUrl = typeof snapResult.redirect_url === 'string'
      ? snapResult.redirect_url
      : null;
    const snapToken = typeof snapResult.token === 'string'
      ? snapResult.token
      : null;
    if (!redirectUrl || !snapToken) {
      await adminClient
        .from('payment_orders')
        .update({ status: 'failed' })
        .eq('id', orderId);
      return jsonError('Payment gateway returned an invalid response', 502);
    }

    const { error: updateError } = await adminClient
      .from('payment_orders')
      .update({
        snap_token: snapToken,
        snap_redirect_url: redirectUrl,
      })
      .eq('id', orderId);
    if (updateError) {
      return jsonError('Unable to finalize payment order', 500);
    }

    return jsonResponse({
      order_id: providerOrderId,
      redirect_url: redirectUrl,
      token: snapToken,
      expires_at: expiresAt,
    });
  } catch (error) {
    console.error('create-subscription-checkout failed', error);
    return jsonError('Unexpected checkout error', 500);
  }
});
