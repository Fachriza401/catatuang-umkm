import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

import {
  jsonError,
  jsonResponse,
  readJsonObject,
} from '../_shared/http.ts';
import { verifyMidtransSignature } from '../_shared/midtrans.ts';

function mapStatus(
  transactionStatus: string,
  fraudStatus: string | null,
): string | null {
  switch (transactionStatus) {
    case 'capture':
      if (fraudStatus === 'accept') return 'paid';
      return 'pending';
    case 'settlement':
      return 'paid';
    case 'pending':
    case 'authorize':
      return 'pending';
    case 'deny':
    case 'failure':
      return 'failed';
    case 'cancel':
      return 'cancelled';
    case 'expire':
      return 'expired';
    case 'refund':
      return 'refunded';
    default:
      return null;
  }
}

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') {
    return jsonError('Method not allowed', 405);
  }

  try {
    const body = await readJsonObject(request);
    const orderId = typeof body?.order_id === 'string' ? body.order_id : '';
    const statusCode = typeof body?.status_code === 'string'
      ? body.status_code
      : '';
    const grossAmount = typeof body?.gross_amount === 'string'
      ? body.gross_amount
      : '';
    const signatureKey = typeof body?.signature_key === 'string'
      ? body.signature_key
      : '';
    const transactionStatus = typeof body?.transaction_status === 'string'
      ? body.transaction_status
      : '';
    const fraudStatus = typeof body?.fraud_status === 'string'
      ? body.fraud_status
      : null;
    if (
      !orderId || !statusCode || !grossAmount || !signatureKey ||
      !transactionStatus
    ) {
      return jsonError('Invalid notification payload', 400);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const midtransServerKey = Deno.env.get('MIDTRANS_SERVER_KEY');
    if (!supabaseUrl || !serviceRoleKey || !midtransServerKey) {
      return jsonError('Server configuration unavailable', 500);
    }

    const signatureValid = await verifyMidtransSignature(
      orderId,
      statusCode,
      grossAmount,
      signatureKey,
      midtransServerKey,
    );
    if (!signatureValid) {
      return jsonError('Invalid notification signature', 401);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: orderData, error: orderError } = await adminClient
      .from('payment_orders')
      .select('id, amount, status')
      .eq('provider_order_id', orderId)
      .maybeSingle();
    if (orderError) {
      return jsonError('Unable to read payment order', 500);
    }
    const order = orderData as Record<string, unknown> | null;
    if (!order) {
      return jsonResponse({ processed: false, reason: 'order_not_found' });
    }
    if (Number(grossAmount) !== Number(order.amount)) {
      return jsonError('Payment amount mismatch', 400);
    }

    const nextStatus = mapStatus(transactionStatus, fraudStatus);
    if (!nextStatus) {
      return jsonResponse({ ignored: true, reason: 'unsupported_status' });
    }

    const { data: applyData, error: applyError } = await adminClient.rpc(
      'apply_payment_notification',
      {
        p_provider_order_id: orderId,
        p_status: nextStatus,
        p_provider_transaction_id:
          typeof body?.transaction_id === 'string'
            ? body.transaction_id
            : null,
        p_payment_type: typeof body?.payment_type === 'string'
          ? body.payment_type
          : null,
        p_raw_notification: body,
      },
    );
    if (applyError) {
      console.error('apply_payment_notification failed', applyError);
      return jsonError('Unable to apply payment notification', 500);
    }

    return jsonResponse(applyData ?? { processed: true });
  } catch (error) {
    console.error('midtrans-webhook failed', error);
    return jsonError('Unexpected webhook error', 500);
  }
});
