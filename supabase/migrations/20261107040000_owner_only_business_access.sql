begin;

create or replace function public.current_business_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid();
$$;

create or replace function public.has_business_role(
  p_business_id uuid,
  p_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and p_business_id = auth.uid()
    and 'owner' = any(p_roles);
$$;

create or replace function public.get_my_business_access()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_business_id uuid := auth.uid();
  v_subscription_plan text;
  v_status text;
  v_period_end timestamptz;
  v_plan text;
  v_transaction_count integer;
  v_plan_row public.business_plans%rowtype;
begin
  if v_business_id is null then
    raise exception 'Authentication required';
  end if;

  select plan, status, current_period_end
    into v_subscription_plan, v_status, v_period_end
    from public.business_subscriptions
    where business_id = v_business_id;
  if v_status is null then
    v_status := 'active';
  end if;

  v_plan := public.effective_business_plan(v_business_id);
  select * into v_plan_row
    from public.business_plans
    where plan = v_plan;

  select count(*)::integer into v_transaction_count
    from public.transactions
    where user_id = v_business_id
      and created_at >= date_trunc('month', now());

  return jsonb_build_object(
    'business_id', v_business_id,
    'role', 'owner',
    'plan', v_plan,
    'subscription_status', case
      when v_subscription_plan in ('premium', 'business')
        and (v_period_end is null or v_period_end <= now()) then 'expired'
      else v_status
    end,
    'current_period_end', v_period_end,
    'transactions_used', v_transaction_count,
    'monthly_transaction_limit', v_plan_row.monthly_transaction_limit,
    'attachments_enabled', v_plan_row.attachments_enabled,
    'can_manage_settings', true,
    'can_create_transactions', true
  );
end;
$$;

drop trigger if exists log_member_activity on public.business_members;
drop function if exists public.log_member_activity();

revoke all on function public.list_business_members()
  from public, anon, authenticated;
revoke all on function public.add_business_member(text, text)
  from public, anon, authenticated;
revoke all on function public.update_business_member_role(uuid, text)
  from public, anon, authenticated;
revoke all on function public.remove_business_member(uuid)
  from public, anon, authenticated;

drop function if exists public.list_business_members();
drop function if exists public.add_business_member(text, text);
drop function if exists public.update_business_member_role(uuid, text);
drop function if exists public.remove_business_member(uuid);

drop table public.business_members;
alter table public.business_plans drop column max_members;

create or replace function public.enforce_transaction_edit_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() = 'service_role' then
    return new;
  end if;
  if not public.has_business_role(old.user_id, array['owner']) then
    raise exception 'Only the owner can edit transactions'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

commit;
