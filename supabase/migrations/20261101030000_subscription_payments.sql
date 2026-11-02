alter table public.business_plans
  add column if not exists price_amount bigint not null default 0,
  add column if not exists currency text not null default 'IDR',
  add column if not exists billing_period_days integer not null default 30;

alter table public.business_plans
  drop constraint if exists business_plans_price_amount_check;
alter table public.business_plans
  add constraint business_plans_price_amount_check
  check (price_amount >= 0);
alter table public.business_plans
  drop constraint if exists business_plans_billing_period_days_check;
alter table public.business_plans
  add constraint business_plans_billing_period_days_check
  check (billing_period_days > 0);

update public.business_plans
  set price_amount = 0, billing_period_days = 30, currency = 'IDR'
  where plan = 'free';
update public.business_plans
  set price_amount = 49000, billing_period_days = 30, currency = 'IDR'
  where plan = 'premium';
update public.business_plans
  set price_amount = 149000, billing_period_days = 30, currency = 'IDR'
  where plan = 'business';

create table if not exists public.payment_orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_profiles(user_id)
    on delete cascade,
  plan text not null references public.business_plans(plan),
  amount bigint not null check (amount > 0),
  currency text not null default 'IDR',
  status text not null default 'pending' check (
    status in (
      'pending', 'paid', 'failed', 'expired', 'cancelled', 'refunded'
    )
  ),
  provider text not null default 'midtrans',
  provider_order_id text not null unique,
  provider_transaction_id text,
  snap_token text,
  snap_redirect_url text,
  payment_type text,
  raw_notification jsonb,
  created_by uuid references auth.users(id) on delete set null,
  paid_at timestamptz,
  provisioned_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payment_orders_business_idx
  on public.payment_orders (business_id, created_at desc);
create index if not exists payment_orders_status_idx
  on public.payment_orders (status, created_at desc);

drop trigger if exists set_payment_orders_updated_at
  on public.payment_orders;
create trigger set_payment_orders_updated_at
  before update on public.payment_orders
  for each row execute function public.set_updated_at();

alter table public.payment_orders enable row level security;

drop policy if exists "Business members can read payment orders"
  on public.payment_orders;
create policy "Business members can read payment orders"
  on public.payment_orders for select to authenticated
  using (public.has_business_role(
    business_id, array['owner', 'admin']
  ));

revoke all on public.payment_orders from public, anon, authenticated;
grant select on public.payment_orders to authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.payment_orders from public, anon, authenticated;
grant select, insert, update, delete on public.payment_orders to service_role;

grant select on public.business_plans to authenticated;
grant select on public.business_plans to service_role;

create or replace function public.apply_payment_notification(
  p_provider_order_id text,
  p_status text,
  p_provider_transaction_id text default null,
  p_payment_type text default null,
  p_raw_notification jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.payment_orders%rowtype;
  v_plan public.business_plans%rowtype;
  v_subscription public.business_subscriptions%rowtype;
  v_base timestamptz;
  v_period_end timestamptz;
begin
  if auth.role() <> 'service_role' then
    raise exception 'Service role required' using errcode = '42501';
  end if;
  if p_status not in (
    'pending', 'paid', 'failed', 'expired', 'cancelled', 'refunded'
  ) then
    raise exception 'Invalid payment status';
  end if;

  select * into v_order
    from public.payment_orders
    where provider_order_id = p_provider_order_id
    for update;
  if not found then
    return jsonb_build_object('processed', false, 'reason', 'order_not_found');
  end if;

  if p_status = 'paid' then
    if v_order.status = 'paid' and v_order.provisioned_at is not null then
      return jsonb_build_object('processed', false, 'reason', 'already_paid');
    end if;
    if v_order.status in ('cancelled', 'refunded') then
      return jsonb_build_object('processed', false, 'reason', 'order_closed');
    end if;

    select * into v_plan
      from public.business_plans
      where plan = v_order.plan;
    if not found then
      raise exception 'Plan not found';
    end if;

    update public.payment_orders
      set status = 'paid',
          paid_at = coalesce(paid_at, now()),
          provider_transaction_id = coalesce(
            p_provider_transaction_id, provider_transaction_id
          ),
          payment_type = coalesce(p_payment_type, payment_type),
          raw_notification = coalesce(p_raw_notification, raw_notification)
      where id = v_order.id;

    select * into v_subscription
      from public.business_subscriptions
      where business_id = v_order.business_id
      for update;
    v_base := now();
    if found
       and v_subscription.plan = v_order.plan
       and v_subscription.status = 'active'
       and v_subscription.current_period_end is not null
       and v_subscription.current_period_end > v_base then
      v_base := v_subscription.current_period_end;
    end if;
    v_period_end := v_base + make_interval(
      days => v_plan.billing_period_days
    );

    insert into public.business_subscriptions (
      business_id, plan, status, current_period_end, provider,
      provider_reference, updated_by, updated_at
    ) values (
      v_order.business_id, v_order.plan, 'active', v_period_end,
      v_order.provider, v_order.provider_order_id, null, now()
    ) on conflict (business_id) do update set
      plan = excluded.plan,
      status = excluded.status,
      current_period_end = excluded.current_period_end,
      provider = excluded.provider,
      provider_reference = excluded.provider_reference,
      updated_by = excluded.updated_by,
      updated_at = now();

    update public.payment_orders
      set provisioned_at = now()
      where id = v_order.id;

    return jsonb_build_object('processed', true, 'status', 'paid');
  end if;

  if p_status = 'refunded' then
    update public.payment_orders
      set status = 'refunded',
          provider_transaction_id = coalesce(
            p_provider_transaction_id, provider_transaction_id
          ),
          payment_type = coalesce(p_payment_type, payment_type),
          raw_notification = coalesce(p_raw_notification, raw_notification)
      where id = v_order.id;

    update public.business_subscriptions
      set plan = 'free',
          status = 'active',
          current_period_end = null,
          provider = v_order.provider,
          provider_reference = v_order.provider_order_id,
          updated_by = null,
          updated_at = now()
      where business_id = v_order.business_id
        and provider_reference = v_order.provider_order_id;

    return jsonb_build_object('processed', true, 'status', 'refunded');
  end if;

  if v_order.status in ('paid', 'refunded') then
    return jsonb_build_object('processed', false, 'reason', 'order_finalized');
  end if;

  update public.payment_orders
    set status = p_status,
        provider_transaction_id = coalesce(
          p_provider_transaction_id, provider_transaction_id
        ),
        payment_type = coalesce(p_payment_type, payment_type),
        raw_notification = coalesce(p_raw_notification, raw_notification)
    where id = v_order.id;

  return jsonb_build_object('processed', true, 'status', p_status);
end;
$$;

revoke all on function public.apply_payment_notification(
  text, text, text, text, jsonb
) from public, anon, authenticated;
grant execute on function public.apply_payment_notification(
  text, text, text, text, jsonb
) to service_role;
