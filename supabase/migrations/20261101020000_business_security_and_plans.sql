create table if not exists public.business_plans (
  plan text primary key check (plan in ('free', 'premium', 'business')),
  max_members integer not null check (max_members >= 1),
  monthly_transaction_limit integer,
  attachments_enabled boolean not null default false
);

insert into public.business_plans (
  plan, max_members, monthly_transaction_limit, attachments_enabled
) values
  ('free', 1, 200, false),
  ('premium', 5, 5000, true),
  ('business', 25, null, true)
on conflict (plan) do update set
  max_members = excluded.max_members,
  monthly_transaction_limit = excluded.monthly_transaction_limit,
  attachments_enabled = excluded.attachments_enabled;

alter table public.business_plans enable row level security;
drop policy if exists "Authenticated users can read plans" on public.business_plans;
create policy "Authenticated users can read plans"
  on public.business_plans for select to authenticated using (true);
grant select on public.business_plans to authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.business_plans from public, anon, authenticated;

create table if not exists public.business_members (
  business_id uuid not null references public.business_profiles(user_id)
    on delete cascade,
  member_user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin', 'cashier', 'viewer')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (business_id, member_user_id),
  unique (member_user_id),
  check (business_id <> member_user_id)
);

create index if not exists business_members_business_idx
  on public.business_members (business_id, role);

create table if not exists public.business_subscriptions (
  business_id uuid primary key references public.business_profiles(user_id)
    on delete cascade,
  plan text not null references public.business_plans(plan),
  status text not null check (
    status in ('active', 'past_due', 'cancelled', 'expired')
  ),
  current_period_end timestamptz,
  provider text not null default 'manual',
  provider_reference text unique,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.business_members enable row level security;
alter table public.business_subscriptions enable row level security;

alter table public.transactions
  add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.debts
  add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.debt_payments
  add column if not exists created_by uuid references auth.users(id) on delete set null;

alter table public.debts
  alter column created_by set default auth.uid();

update public.transactions set created_by = user_id where created_by is null;
update public.debts set created_by = user_id where created_by is null;
update public.debt_payments set created_by = user_id where created_by is null;
update public.transactions
  set attachment_url = regexp_replace(
    attachment_url,
    '^.*/storage/v1/object/public/transaction-attachments/',
    ''
  )
  where attachment_url like
    '%/storage/v1/object/public/transaction-attachments/%';

create or replace function public.current_business_id()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_business_id uuid;
begin
  if v_user_id is null then
    return null;
  end if;

  select user_id into v_business_id
    from public.business_profiles
    where user_id = v_user_id;
  if found then
    return v_business_id;
  end if;

  select business_id into v_business_id
    from public.business_members
    where member_user_id = v_user_id;
  return coalesce(v_business_id, v_user_id);
end;
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
  select auth.uid() is not null and (
    (p_business_id = auth.uid() and 'owner' = any(p_roles))
    or exists (
      select 1
      from public.business_members m
      where m.business_id = p_business_id
        and m.member_user_id = auth.uid()
        and m.role = any(p_roles)
    )
  );
$$;

create or replace function public.effective_business_plan(p_business_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when s.status = 'active' and s.plan = 'free'
      then 'free'
    when s.status = 'active'
      and s.plan in ('premium', 'business')
      and s.current_period_end > now()
      then s.plan
    else 'free'
  end
  from (select 1) seed
  left join public.business_subscriptions s
    on s.business_id = p_business_id;
$$;

create or replace function public.ensure_free_business_subscription()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.business_subscriptions (business_id, plan, status)
  values (new.user_id, 'free', 'active')
  on conflict (business_id) do nothing;
  return new;
end;
$$;

drop trigger if exists create_free_business_subscription
  on public.business_profiles;
create trigger create_free_business_subscription
  after insert on public.business_profiles
  for each row execute function public.ensure_free_business_subscription();

insert into public.business_subscriptions (business_id, plan, status)
select user_id, 'free', 'active'
from public.business_profiles
on conflict (business_id) do nothing;

create or replace function public.get_my_business_access()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_business_id uuid := public.current_business_id();
  v_role text;
  v_plan text;
  v_subscription_plan text;
  v_status text;
  v_period_end timestamptz;
  v_member_count integer;
  v_transaction_count integer;
  v_plan_row public.business_plans%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if v_business_id = auth.uid() then
    v_role := 'owner';
  else
    select role into v_role
      from public.business_members
      where business_id = v_business_id
        and member_user_id = auth.uid();
  end if;

  select plan, status, current_period_end
    into v_subscription_plan, v_status, v_period_end
    from public.business_subscriptions
    where business_id = v_business_id;
  if v_status is null then
    v_status := 'active';
  end if;
  v_plan := public.effective_business_plan(v_business_id);
  select * into v_plan_row from public.business_plans where plan = v_plan;

  select 1 + count(*)::integer into v_member_count
    from public.business_members
    where business_id = v_business_id;
  select count(*)::integer into v_transaction_count
    from public.transactions
    where user_id = v_business_id
      and created_at >= date_trunc('month', now());

  return jsonb_build_object(
    'business_id', v_business_id,
    'role', coalesce(v_role, 'owner'),
    'plan', v_plan,
    'subscription_status', case
      when v_subscription_plan in ('premium', 'business')
        and (v_period_end is null or v_period_end <= now()) then 'expired'
      else v_status
    end,
    'current_period_end', v_period_end,
    'members_used', v_member_count,
    'max_members', v_plan_row.max_members,
    'transactions_used', v_transaction_count,
    'monthly_transaction_limit', v_plan_row.monthly_transaction_limit,
    'attachments_enabled', v_plan_row.attachments_enabled,
    'can_manage_settings', v_role in ('owner', 'admin'),
    'can_manage_members', v_role in ('owner', 'admin'),
    'can_create_transactions', v_role in ('owner', 'admin', 'cashier')
  );
end;
$$;

create or replace function public.assert_transaction_capacity(p_business_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer;
  v_count integer;
begin
  if not public.has_business_role(
    p_business_id,
    array['owner', 'admin', 'cashier']
  ) then
    raise exception 'Insufficient business role' using errcode = '42501';
  end if;

  select monthly_transaction_limit into v_limit
    from public.business_plans
    where plan = public.effective_business_plan(p_business_id);
  if v_limit is null then
    return;
  end if;

  select count(*)::integer into v_count
    from public.transactions
    where user_id = p_business_id
      and created_at >= date_trunc('month', now());
  if v_count >= v_limit then
    raise exception 'Monthly transaction limit reached' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.can_use_business_attachments(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_business_role(
      p_business_id,
      array['owner', 'admin', 'cashier', 'viewer']
    )
    and exists (
      select 1 from public.business_plans
      where plan = public.effective_business_plan(p_business_id)
        and attachments_enabled
    );
$$;

create or replace function public.update_business_profile(
  p_business_name text,
  p_owner_name text,
  p_business_type text,
  p_phone text,
  p_address text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_business_id uuid := public.current_business_id();
  v_profile public.business_profiles%rowtype;
begin
  if not public.has_business_role(v_business_id, array['owner', 'admin']) then
    raise exception 'Insufficient business role' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_business_name, ''))) = 0 then
    raise exception 'Business name is required';
  end if;

  update public.business_profiles
    set business_name = trim(p_business_name),
        owner_name = coalesce(trim(p_owner_name), ''),
        business_type = coalesce(trim(p_business_type), ''),
        phone = coalesce(trim(p_phone), ''),
        address = coalesce(trim(p_address), '')
    where user_id = v_business_id
    returning * into v_profile;

  if not found then
    if v_business_id <> auth.uid() then
      raise exception 'Business profile not found';
    end if;
    insert into public.business_profiles (
      user_id, business_name, owner_name, business_type, phone, address
    ) values (
      v_business_id, trim(p_business_name), coalesce(trim(p_owner_name), ''),
      coalesce(trim(p_business_type), ''), coalesce(trim(p_phone), ''),
      coalesce(trim(p_address), '')
    ) returning * into v_profile;
  end if;
  return to_jsonb(v_profile);
end;
$$;

create or replace function public.list_business_members()
returns table (
  member_user_id uuid,
  email text,
  role text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_business_id uuid := public.current_business_id();
begin
  if not public.has_business_role(
    v_business_id,
    array['owner', 'admin', 'cashier', 'viewer']
  ) then
    raise exception 'Business access denied' using errcode = '42501';
  end if;
  return query
    select m.member_user_id, u.email::text, m.role, m.created_at
    from public.business_members m
    join auth.users u on u.id = m.member_user_id
    where m.business_id = v_business_id
    order by m.created_at;
end;
$$;

create or replace function public.add_business_member(
  p_email text,
  p_role text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_business_id uuid := public.current_business_id();
  v_actor_role text;
  v_member_id uuid;
  v_max_members integer;
  v_member_count integer;
begin
  if p_role not in ('admin', 'cashier', 'viewer') then
    raise exception 'Invalid member role';
  end if;
  v_actor_role := case
    when v_business_id = auth.uid() then 'owner'
    else (select role from public.business_members
      where business_id = v_business_id and member_user_id = auth.uid())
  end;
  if v_actor_role not in ('owner', 'admin') then
    raise exception 'Insufficient business role' using errcode = '42501';
  end if;
  if v_actor_role = 'admin' and p_role = 'admin' then
    raise exception 'Only the owner can assign admin role'
      using errcode = '42501';
  end if;

  select id into v_member_id
    from auth.users
    where lower(email) = lower(trim(p_email));
  if v_member_id is null then
    raise exception 'User account not found';
  end if;
  if v_member_id = v_business_id or exists (
    select 1 from public.business_profiles where user_id = v_member_id
  ) then
    raise exception 'Business owners cannot join another business';
  end if;
  select max_members into v_max_members
    from public.business_plans
    where plan = public.effective_business_plan(v_business_id);
  select count(*)::integer + 1 into v_member_count
    from public.business_members
    where business_id = v_business_id;
  if v_member_count >= v_max_members then
    raise exception 'Member limit reached for current plan'
      using errcode = 'P0001';
  end if;

  insert into public.business_members (
    business_id, member_user_id, role, created_by
  ) values (v_business_id, v_member_id, p_role, auth.uid());
  return v_member_id;
end;
$$;

create or replace function public.update_business_member_role(
  p_member_user_id uuid,
  p_role text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_business_id uuid := public.current_business_id();
  v_actor_role text;
  v_target_role text;
begin
  if p_role not in ('admin', 'cashier', 'viewer') then
    raise exception 'Invalid member role';
  end if;
  v_actor_role := case when v_business_id = auth.uid() then 'owner'
    else (select role from public.business_members
      where business_id = v_business_id and member_user_id = auth.uid())
  end;
  select role into v_target_role
    from public.business_members
    where business_id = v_business_id and member_user_id = p_member_user_id;
  if v_actor_role not in ('owner', 'admin') or v_target_role is null then
    raise exception 'Business access denied' using errcode = '42501';
  end if;
  if v_actor_role = 'admin' and
     (v_target_role = 'admin' or p_role = 'admin') then
    raise exception 'Only the owner can manage admin roles'
      using errcode = '42501';
  end if;
  update public.business_members
    set role = p_role, updated_at = now()
    where business_id = v_business_id and member_user_id = p_member_user_id;
end;
$$;

create or replace function public.remove_business_member(p_member_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_business_id uuid := public.current_business_id();
  v_actor_role text;
  v_target_role text;
begin
  v_actor_role := case when v_business_id = auth.uid() then 'owner'
    else (select role from public.business_members
      where business_id = v_business_id and member_user_id = auth.uid())
  end;
  select role into v_target_role
    from public.business_members
    where business_id = v_business_id and member_user_id = p_member_user_id;
  if v_actor_role not in ('owner', 'admin') or v_target_role is null then
    raise exception 'Business access denied' using errcode = '42501';
  end if;
  if v_actor_role = 'admin' and v_target_role = 'admin' then
    raise exception 'Only the owner can remove an admin'
      using errcode = '42501';
  end if;
  delete from public.business_members
    where business_id = v_business_id and member_user_id = p_member_user_id;
end;
$$;

create or replace function public.provision_business_subscription(
  p_business_id uuid,
  p_plan text,
  p_status text,
  p_current_period_end timestamptz,
  p_provider text,
  p_provider_reference text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' then
    raise exception 'Service role required' using errcode = '42501';
  end if;
  if p_plan not in ('free', 'premium', 'business') or
     p_status not in ('active', 'past_due', 'cancelled', 'expired') then
    raise exception 'Invalid subscription state';
  end if;
  if p_plan <> 'free' and p_status = 'active'
     and (p_current_period_end is null or p_current_period_end <= now()) then
    raise exception 'Paid subscription requires a valid future period';
  end if;
  insert into public.business_subscriptions (
    business_id, plan, status, current_period_end, provider,
    provider_reference, updated_by, updated_at
  ) values (
    p_business_id, p_plan, p_status, p_current_period_end,
    coalesce(p_provider, 'manual'), p_provider_reference, auth.uid(), now()
  ) on conflict (business_id) do update set
    plan = excluded.plan,
    status = excluded.status,
    current_period_end = excluded.current_period_end,
    provider = excluded.provider,
    provider_reference = excluded.provider_reference,
    updated_by = excluded.updated_by,
    updated_at = now();
end;
$$;

drop policy if exists "Users can read own business profile"
  on public.business_profiles;
drop policy if exists "Users can insert own business profile"
  on public.business_profiles;
drop policy if exists "Users can update own business profile"
  on public.business_profiles;
drop policy if exists "Users can delete own business profile"
  on public.business_profiles;
create policy "Business members can read profile"
  on public.business_profiles for select to authenticated
  using (public.has_business_role(
    user_id, array['owner', 'admin', 'cashier', 'viewer']
  ));

drop policy if exists "Users can read own transactions" on public.transactions;
drop policy if exists "Users can insert own transactions" on public.transactions;
drop policy if exists "Users can update own transactions" on public.transactions;
drop policy if exists "Users can delete own transactions" on public.transactions;
create policy "Business members can read transactions"
  on public.transactions for select to authenticated
  using (public.has_business_role(
    user_id, array['owner', 'admin', 'cashier', 'viewer']
  ));

drop policy if exists "Users can read own debts" on public.debts;
drop policy if exists "Users can insert own debts" on public.debts;
drop policy if exists "Users can update own debts" on public.debts;
drop policy if exists "Business members can read debts" on public.debts;
drop policy if exists "Managers can create debts" on public.debts;
drop policy if exists "Managers can update debts" on public.debts;
create policy "Business members can read debts"
  on public.debts for select to authenticated
  using (public.has_business_role(
    user_id, array['owner', 'admin', 'cashier', 'viewer']
  ));
create policy "Managers can create debts"
  on public.debts for insert to authenticated
  with check (
    created_by = auth.uid()
    and public.has_business_role(user_id, array['owner', 'admin'])
  );
create policy "Managers can update debts"
  on public.debts for update to authenticated
  using (public.has_business_role(user_id, array['owner', 'admin']))
  with check (public.has_business_role(user_id, array['owner', 'admin']));

drop policy if exists "Users can read own debt payments"
  on public.debt_payments;
create policy "Business members can read debt payments"
  on public.debt_payments for select to authenticated
  using (public.has_business_role(
    user_id, array['owner', 'admin', 'cashier', 'viewer']
  ));

drop policy if exists "Business members can read memberships"
  on public.business_members;
create policy "Business members can read memberships"
  on public.business_members for select to authenticated
  using (public.has_business_role(
    business_id, array['owner', 'admin', 'cashier', 'viewer']
  ));
drop policy if exists "Business members can read subscriptions"
  on public.business_subscriptions;
create policy "Business members can read subscriptions"
  on public.business_subscriptions for select to authenticated
  using (public.has_business_role(
    business_id, array['owner', 'admin', 'cashier', 'viewer']
  ));

grant select on public.business_profiles, public.transactions, public.debts,
  public.debt_payments, public.business_members,
  public.business_subscriptions to authenticated;
grant insert, update on public.debts to authenticated;
revoke all on public.business_profiles from public, anon, authenticated;
grant select on public.business_profiles to authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.business_profiles from public, anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.transactions from public, anon, authenticated;
revoke delete, truncate, references, trigger on public.debts
  from public, anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.debt_payments from public, anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.business_members, public.business_subscriptions
  from public, anon, authenticated;

grant execute on function public.current_business_id() to authenticated;
grant execute on function public.has_business_role(uuid, text[]) to authenticated;
grant execute on function public.get_my_business_access() to authenticated;
revoke all on function public.current_business_id() from public, anon;
revoke all on function public.has_business_role(uuid, text[]) from public, anon;
revoke all on function public.effective_business_plan(uuid)
  from public, anon, authenticated;
revoke all on function public.ensure_free_business_subscription()
  from public, anon, authenticated;
revoke all on function public.get_my_business_access() from public, anon;
revoke all on function public.can_use_business_attachments(uuid)
  from public, anon;
grant execute on function public.can_use_business_attachments(uuid) to authenticated;
grant execute on function public.update_business_profile(text, text, text, text, text)
  to authenticated;
grant execute on function public.list_business_members() to authenticated;
grant execute on function public.add_business_member(text, text) to authenticated;
grant execute on function public.update_business_member_role(uuid, text)
  to authenticated;
grant execute on function public.remove_business_member(uuid) to authenticated;
revoke all on function public.update_business_profile(text, text, text, text, text)
  from public, anon;
revoke all on function public.list_business_members() from public, anon;
revoke all on function public.add_business_member(text, text) from public, anon;
revoke all on function public.update_business_member_role(uuid, text)
  from public, anon;
revoke all on function public.remove_business_member(uuid) from public, anon;
revoke all on function public.provision_business_subscription(
  uuid, text, text, timestamptz, text, text
) from public, anon, authenticated;
grant execute on function public.provision_business_subscription(
  uuid, text, text, timestamptz, text, text
) to service_role;
revoke all on function public.assert_transaction_capacity(uuid)
  from public, anon, authenticated;

update storage.buckets
  set public = false
  where id = 'transaction-attachments';

drop policy if exists "Users can read own transaction attachments"
  on storage.objects;
drop policy if exists "Users can upload own transaction attachments"
  on storage.objects;
drop policy if exists "Users can update own transaction attachments"
  on storage.objects;
drop policy if exists "Users can delete own transaction attachments"
  on storage.objects;
drop policy if exists "Business members can read private attachments"
  on storage.objects;
drop policy if exists "Cashiers can upload private attachments"
  on storage.objects;
drop policy if exists "Cashiers can update private attachments"
  on storage.objects;
drop policy if exists "Managers can delete private attachments"
  on storage.objects;
create policy "Business members can read private attachments"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'transaction-attachments'
    and public.can_use_business_attachments(
      ((storage.foldername(name))[1])::uuid
    )
  );
create policy "Cashiers can upload private attachments"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'transaction-attachments'
    and public.has_business_role(
      ((storage.foldername(name))[1])::uuid,
      array['owner', 'admin', 'cashier']
    )
    and public.can_use_business_attachments(
      ((storage.foldername(name))[1])::uuid
    )
  );
create policy "Cashiers can update private attachments"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'transaction-attachments'
    and public.has_business_role(
      ((storage.foldername(name))[1])::uuid,
      array['owner', 'admin', 'cashier']
    )
    and public.can_use_business_attachments(
      ((storage.foldername(name))[1])::uuid
    )
  )
  with check (
    bucket_id = 'transaction-attachments'
    and public.has_business_role(
      ((storage.foldername(name))[1])::uuid,
      array['owner', 'admin', 'cashier']
    )
    and public.can_use_business_attachments(
      ((storage.foldername(name))[1])::uuid
    )
  );
create policy "Managers can delete private attachments"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'transaction-attachments'
    and public.has_business_role(
      ((storage.foldername(name))[1])::uuid,
      array['owner', 'admin']
    )
  );

create or replace function public.sync_transaction(
  p_transaction jsonb,
  p_operation text,
  p_idempotency_key uuid,
  p_expected_updated_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_business_id uuid;
  v_transaction_id uuid;
  v_request jsonb;
  v_cached_request jsonb;
  v_response jsonb;
  v_remote public.transactions%rowtype;
begin
  if v_actor_id is null then
    raise exception 'Authentication required';
  end if;
  if jsonb_typeof(p_transaction) <> 'object'
     or p_transaction->>'id' is null
     or p_transaction->>'user_id' is null then
    raise exception 'Invalid transaction payload';
  end if;
  v_transaction_id := (p_transaction->>'id')::uuid;
  v_business_id := (p_transaction->>'user_id')::uuid;
  if public.current_business_id() <> v_business_id
     or not public.has_business_role(
       v_business_id, array['owner', 'admin', 'cashier']
     ) then
    raise exception 'Business write access denied' using errcode = '42501';
  end if;
  if p_operation not in ('create', 'update', 'delete')
     or p_idempotency_key is null then
    raise exception 'Invalid sync operation';
  end if;

  v_request := jsonb_build_object(
    'transaction', p_transaction,
    'operation', p_operation,
    'expected_updated_at', p_expected_updated_at
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      v_actor_id::text || ':' || p_idempotency_key::text,
      0
    )
  );
  select request, response into v_cached_request, v_response
    from public.transaction_sync_requests
    where user_id = v_actor_id and idempotency_key = p_idempotency_key;
  if found then
    if v_cached_request <> v_request then
      raise exception 'Idempotency key was reused with a different request';
    end if;
    return v_response;
  end if;

  select * into v_remote
    from public.transactions where id = v_transaction_id for update;
  if found and v_remote.user_id <> v_business_id then
    raise exception 'Transaction ID is already in use';
  end if;

  if p_operation = 'create' then
    if found then
      if v_remote.type = p_transaction->>'type'
         and v_remote.amount = (p_transaction->>'amount')::bigint
         and v_remote.category_id = p_transaction->>'category_id'
         and v_remote.payment_method_id = p_transaction->>'payment_method_id'
         and v_remote.transaction_date =
             (p_transaction->>'transaction_date')::timestamptz
         and v_remote.description = coalesce(p_transaction->>'description', '')
         and v_remote.attachment_url is not distinct from
             (p_transaction->>'attachment_url')
         and v_remote.deleted_at is not distinct from
             (p_transaction->>'deleted_at')::timestamptz then
        v_response := jsonb_build_object(
          'status', 'synced', 'transaction', to_jsonb(v_remote)
        );
      else
        v_response := jsonb_build_object(
          'status', 'conflict', 'remote', to_jsonb(v_remote)
        );
      end if;
    else
      perform public.assert_transaction_capacity(v_business_id);
      insert into public.transactions (
        id, user_id, created_by, type, amount, category_id, payment_method_id,
        transaction_date, description, attachment_url, created_at,
        updated_at, deleted_at
      ) values (
        v_transaction_id, v_business_id, v_actor_id,
        p_transaction->>'type', (p_transaction->>'amount')::bigint,
        p_transaction->>'category_id', p_transaction->>'payment_method_id',
        (p_transaction->>'transaction_date')::timestamptz,
        coalesce(p_transaction->>'description', ''),
        p_transaction->>'attachment_url',
        coalesce((p_transaction->>'created_at')::timestamptz, now()),
        now(), (p_transaction->>'deleted_at')::timestamptz
      );
      select * into v_remote from public.transactions where id = v_transaction_id;
      v_response := jsonb_build_object(
        'status', 'synced', 'transaction', to_jsonb(v_remote)
      );
    end if;
  elsif not found then
    v_response := jsonb_build_object('status', 'conflict', 'remote', null);
  elsif p_operation = 'update' then
    if p_expected_updated_at is null
       or v_remote.updated_at <> p_expected_updated_at then
      v_response := jsonb_build_object(
        'status', 'conflict', 'remote', to_jsonb(v_remote)
      );
    else
      update public.transactions
        set type = p_transaction->>'type',
            amount = (p_transaction->>'amount')::bigint,
            category_id = p_transaction->>'category_id',
            payment_method_id = p_transaction->>'payment_method_id',
            transaction_date = (p_transaction->>'transaction_date')::timestamptz,
            description = coalesce(p_transaction->>'description', ''),
            attachment_url = p_transaction->>'attachment_url',
            deleted_at = (p_transaction->>'deleted_at')::timestamptz,
            updated_at = now()
        where id = v_transaction_id
        returning * into v_remote;
      v_response := jsonb_build_object(
        'status', 'synced', 'transaction', to_jsonb(v_remote)
      );
    end if;
  elsif v_remote.deleted_at is not null then
    v_response := jsonb_build_object(
      'status', 'synced', 'transaction', to_jsonb(v_remote)
    );
  elsif p_expected_updated_at is null
        or v_remote.updated_at <> p_expected_updated_at then
    v_response := jsonb_build_object(
      'status', 'conflict', 'remote', to_jsonb(v_remote)
    );
  else
    update public.transactions
      set deleted_at = coalesce(
            (p_transaction->>'deleted_at')::timestamptz,
            now()
          ),
          updated_at = now()
      where id = v_transaction_id
      returning * into v_remote;
    v_response := jsonb_build_object(
      'status', 'synced', 'transaction', to_jsonb(v_remote)
    );
  end if;

  insert into public.transaction_sync_requests (
    user_id, idempotency_key, request, response
  ) values (v_actor_id, p_idempotency_key, v_request, v_response);
  return v_response;
end;
$$;

create or replace function public.record_debt_payment(
  p_payment_id uuid,
  p_debt_id uuid,
  p_amount bigint,
  p_payment_date timestamptz,
  p_note text,
  p_ledger_transaction_id uuid,
  p_ledger_description text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_business_id uuid := public.current_business_id();
  v_debt public.debts%rowtype;
  v_payment public.debt_payments%rowtype;
  v_transaction public.transactions%rowtype;
  v_transaction_type text;
  v_category_id text;
begin
  if v_actor_id is null or not public.has_business_role(
    v_business_id, array['owner', 'admin', 'cashier']
  ) then
    raise exception 'Business write access denied' using errcode = '42501';
  end if;

  select * into v_payment from public.debt_payments
    where id = p_payment_id and user_id = v_business_id;
  if found then
    if v_payment.debt_id <> p_debt_id or v_payment.amount <> p_amount
       or v_payment.payment_date <> p_payment_date
       or v_payment.note <> coalesce(p_note, '')
       or v_payment.ledger_transaction_id <> p_ledger_transaction_id then
      raise exception 'Payment ID is already in use';
    end if;
    return v_payment.id;
  end if;

  select * into v_debt from public.debts
    where id = p_debt_id and user_id = v_business_id for update;
  if not found then
    raise exception 'Debt not found';
  end if;
  if p_amount <= 0 or p_amount > v_debt.amount - v_debt.paid_amount then
    raise exception 'Payment exceeds the outstanding balance';
  end if;

  if v_debt.type = 'receivable' then
    v_transaction_type := 'income';
    v_category_id := 'other_income';
  else
    v_transaction_type := 'expense';
    v_category_id := 'other_expense';
  end if;

  select * into v_transaction from public.transactions
    where id = p_ledger_transaction_id for update;
  if found and (
    v_transaction.user_id <> v_business_id
    or v_transaction.type <> v_transaction_type
    or v_transaction.amount <> p_amount
    or v_transaction.category_id <> v_category_id
    or v_transaction.payment_method_id <> 'cash'
    or v_transaction.transaction_date <> p_payment_date
    or v_transaction.description <> coalesce(p_ledger_description, '')
    or v_transaction.deleted_at is not null
  ) then
    raise exception 'Ledger transaction ID is already in use';
  end if;
  if not found then
    perform public.assert_transaction_capacity(v_business_id);
  end if;

  insert into public.debt_payments (
    id, debt_id, user_id, created_by, amount, payment_date, note,
    ledger_transaction_id
  ) values (
    p_payment_id, p_debt_id, v_business_id, v_actor_id, p_amount,
    p_payment_date, coalesce(p_note, ''), p_ledger_transaction_id
  );
  update public.debts
    set paid_amount = paid_amount + p_amount, updated_at = now()
    where id = p_debt_id and user_id = v_business_id;
  insert into public.transactions (
    id, user_id, created_by, type, amount, category_id, payment_method_id,
    transaction_date, description
  ) values (
    p_ledger_transaction_id, v_business_id, v_actor_id, v_transaction_type,
    p_amount, v_category_id, 'cash', p_payment_date,
    coalesce(p_ledger_description, '')
  ) on conflict (id) do nothing;
  return p_payment_id;
end;
$$;

revoke all on function public.record_debt_payment(
  uuid, uuid, bigint, timestamptz, text, uuid, text
) from public, anon;
grant execute on function public.record_debt_payment(
  uuid, uuid, bigint, timestamptz, text, uuid, text
) to authenticated;