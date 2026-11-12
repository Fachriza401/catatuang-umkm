-- CatatUang web modules: categories, activity log, profile details,
-- richer dashboard summary, and report-ready supporting objects.
-- Additive only: existing tables/columns used by Flutter are preserved.

alter table public.business_profiles
  add column if not exists logo_url text not null default '',
  add column if not exists description text not null default '';

create table if not exists public.categories (
  business_id uuid not null references public.business_profiles(user_id)
    on delete cascade,
  id text not null,
  name text not null check (length(trim(name)) > 0),
  type text not null check (type in ('income', 'expense')),
  icon text not null default 'tag',
  color text not null default '#2563EB',
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (business_id, id)
);

create index if not exists categories_business_type_idx
  on public.categories (business_id, type, is_active);

alter table public.categories enable row level security;

drop policy if exists "Business members can read categories"
  on public.categories;
create policy "Business members can read categories"
  on public.categories for select to authenticated
  using (public.has_business_role(
    business_id, array['owner', 'admin', 'cashier', 'viewer']
  ));

drop policy if exists "Managers can create categories"
  on public.categories;
create policy "Managers can create categories"
  on public.categories for insert to authenticated
  with check (
    created_by = auth.uid()
    and public.has_business_role(business_id, array['owner', 'admin'])
  );

drop policy if exists "Managers can update categories"
  on public.categories;
create policy "Managers can update categories"
  on public.categories for update to authenticated
  using (public.has_business_role(business_id, array['owner', 'admin']))
  with check (public.has_business_role(business_id, array['owner', 'admin']));

drop policy if exists "Managers can delete categories"
  on public.categories;
create policy "Managers can delete categories"
  on public.categories for delete to authenticated
  using (public.has_business_role(business_id, array['owner', 'admin']));

revoke all on public.categories from public, anon, authenticated;
grant select, insert, update, delete on public.categories to authenticated;

create or replace function public.set_categories_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_categories_updated_at on public.categories;
create trigger set_categories_updated_at
  before update on public.categories
  for each row execute function public.set_categories_updated_at();

create or replace function public.prevent_used_category_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.transactions t
    where t.user_id = old.business_id
      and t.category_id = old.id
  ) then
    raise exception 'Kategori masih dipakai transaksi. Nonaktifkan kategori ini.'
      using errcode = 'P0001';
  end if;
  return old;
end;
$$;

drop trigger if exists prevent_used_category_delete on public.categories;
create trigger prevent_used_category_delete
  before delete on public.categories
  for each row execute function public.prevent_used_category_delete();

create or replace function public.seed_default_categories(p_business_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.categories (
    business_id, id, name, type, icon, color, is_default
  ) values
    (p_business_id, 'sales', 'Penjualan', 'income', 'shopping-bag', '#16A34A', true),
    (p_business_id, 'capital', 'Modal Usaha', 'income', 'landmark', '#2563EB', true),
    (p_business_id, 'other_income', 'Pemasukan Lain', 'income', 'plus-circle', '#0891B2', true),
    (p_business_id, 'ingredients', 'Bahan Baku', 'expense', 'package', '#F59E0B', true),
    (p_business_id, 'operations', 'Operasional', 'expense', 'settings', '#2563EB', true),
    (p_business_id, 'salary', 'Gaji Karyawan', 'expense', 'users', '#7C3AED', true),
    (p_business_id, 'rent', 'Sewa Tempat', 'expense', 'home', '#DC2626', true),
    (p_business_id, 'transport', 'Transportasi', 'expense', 'truck', '#EA580C', true),
    (p_business_id, 'marketing', 'Pemasaran', 'expense', 'megaphone', '#DB2777', true),
    (p_business_id, 'other_expense', 'Pengeluaran Lain', 'expense', 'receipt', '#64748B', true)
  on conflict (business_id, id) do nothing;
end;
$$;

create or replace function public.ensure_default_categories()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.seed_default_categories(new.user_id);
  return new;
end;
$$;

drop trigger if exists create_default_categories on public.business_profiles;
create trigger create_default_categories
  after insert on public.business_profiles
  for each row execute function public.ensure_default_categories();

select public.seed_default_categories(user_id)
from public.business_profiles;

revoke all on function public.seed_default_categories(uuid)
  from public, anon, authenticated;
revoke all on function public.ensure_default_categories()
  from public, anon, authenticated;

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_profiles(user_id)
    on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  summary text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists activity_logs_business_created_idx
  on public.activity_logs (business_id, created_at desc);

alter table public.activity_logs enable row level security;

drop policy if exists "Business members can read activity logs"
  on public.activity_logs;
create policy "Business members can read activity logs"
  on public.activity_logs for select to authenticated
  using (public.has_business_role(
    business_id, array['owner', 'admin', 'cashier', 'viewer']
  ));

revoke all on public.activity_logs from public, anon, authenticated;
grant select on public.activity_logs to authenticated;

create or replace function public.log_transaction_activity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_action text;
  v_summary text;
  v_business_id uuid;
  v_actor uuid := auth.uid();
begin
  if tg_op = 'DELETE' then
    v_business_id := old.user_id;
    v_action := 'transaction.deleted';
    v_summary := 'Menghapus transaksi ' || old.description;
    insert into public.activity_logs (
      business_id, actor_user_id, action, entity_type, entity_id, summary,
      metadata
    ) values (
      v_business_id, v_actor, v_action, 'transaction', old.id,
      nullif(trim(v_summary), ''), jsonb_build_object(
        'amount', old.amount, 'type', old.type, 'category_id', old.category_id
      )
    );
    return old;
  end if;

  v_business_id := new.user_id;
  if tg_op = 'INSERT' then
    v_action := 'transaction.created';
    v_summary := 'Mencatat transaksi ' || new.description;
  elsif new.deleted_at is not null and old.deleted_at is null then
    v_action := 'transaction.deleted';
    v_summary := 'Menghapus transaksi ' || old.description;
  else
    v_action := 'transaction.updated';
    v_summary := 'Mengubah transaksi ' || new.description;
  end if;

  insert into public.activity_logs (
    business_id, actor_user_id, action, entity_type, entity_id, summary,
    metadata
  ) values (
    v_business_id, v_actor, v_action, 'transaction', new.id,
    nullif(trim(v_summary), ''), jsonb_build_object(
      'amount', new.amount, 'type', new.type, 'category_id', new.category_id
    )
  );
  return new;
end;
$$;

drop trigger if exists log_transaction_activity on public.transactions;
create trigger log_transaction_activity
  after insert or update or delete on public.transactions
  for each row execute function public.log_transaction_activity();

create or replace function public.log_debt_activity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_action text;
  v_summary text;
  v_actor uuid := auth.uid();
begin
  if tg_op = 'DELETE' then
    insert into public.activity_logs (
      business_id, actor_user_id, action, entity_type, entity_id, summary,
      metadata
    ) values (
      old.user_id, v_actor, 'debt.deleted', 'debt', old.id,
      'Menghapus data ' || case when old.type = 'receivable'
        then 'piutang ' else 'utang ' end || old.contact_name,
      jsonb_build_object('amount', old.amount, 'type', old.type)
    );
    return old;
  end if;

  if tg_op = 'INSERT' then
    v_action := 'debt.created';
    v_summary := 'Menambahkan ' || case when new.type = 'receivable'
      then 'piutang ' else 'utang ' end || new.contact_name;
  else
    v_action := 'debt.updated';
    v_summary := 'Memperbarui ' || case when new.type = 'receivable'
      then 'piutang ' else 'utang ' end || new.contact_name;
  end if;

  insert into public.activity_logs (
    business_id, actor_user_id, action, entity_type, entity_id, summary,
    metadata
  ) values (
    new.user_id, v_actor, v_action, 'debt', new.id, v_summary,
    jsonb_build_object(
      'amount', new.amount, 'paid_amount', new.paid_amount, 'type', new.type
    )
  );
  return new;
end;
$$;

drop trigger if exists log_debt_activity on public.debts;
create trigger log_debt_activity
  after insert or update or delete on public.debts
  for each row execute function public.log_debt_activity();

create or replace function public.log_debt_payment_activity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.activity_logs (
    business_id, actor_user_id, action, entity_type, entity_id, summary,
    metadata
  ) values (
    new.user_id, auth.uid(), 'debt.payment', 'debt_payment', new.debt_id,
    'Mencatat pembayaran cicilan',
    jsonb_build_object('amount', new.amount, 'payment_id', new.id)
  );
  return new;
end;
$$;

drop trigger if exists log_debt_payment_activity on public.debt_payments;
create trigger log_debt_payment_activity
  after insert on public.debt_payments
  for each row execute function public.log_debt_payment_activity();

create or replace function public.log_member_activity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_action text;
  v_summary text;
  v_actor uuid := auth.uid();
begin
  if tg_op = 'DELETE' then
    insert into public.activity_logs (
      business_id, actor_user_id, action, entity_type, entity_id, summary
    ) values (
      old.business_id, v_actor, 'member.removed', 'business_member',
      old.member_user_id, 'Menghapus anggota tim'
    );
    return old;
  end if;
  if tg_op = 'INSERT' then
    v_action := 'member.added';
    v_summary := 'Menambahkan anggota tim sebagai ' || new.role;
  else
    v_action := 'member.role_changed';
    v_summary := 'Mengubah peran anggota menjadi ' || new.role;
  end if;
  insert into public.activity_logs (
    business_id, actor_user_id, action, entity_type, entity_id, summary
  ) values (
    new.business_id, v_actor, v_action, 'business_member',
    new.member_user_id, v_summary
  );
  return new;
end;
$$;

drop trigger if exists log_member_activity on public.business_members;
create trigger log_member_activity
  after insert or update or delete on public.business_members
  for each row execute function public.log_member_activity();

create or replace function public.update_business_profile_v2(
  p_business_name text,
  p_owner_name text,
  p_business_type text,
  p_phone text,
  p_address text,
  p_description text,
  p_logo_url text
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
        address = coalesce(trim(p_address), ''),
        description = coalesce(trim(p_description), ''),
        logo_url = coalesce(trim(p_logo_url), '')
    where user_id = v_business_id
    returning * into v_profile;

  if not found then
    raise exception 'Business profile not found';
  end if;
  return to_jsonb(v_profile);
end;
$$;

revoke all on function public.update_business_profile_v2(
  text, text, text, text, text, text, text
) from public, anon;
grant execute on function public.update_business_profile_v2(
  text, text, text, text, text, text, text
) to authenticated;

create or replace function public.get_web_dashboard_summary(
  p_business_id uuid,
  p_start timestamptz,
  p_end timestamptz,
  p_chart_start timestamptz,
  p_chart_end timestamptz,
  p_chart_unit text,
  p_timezone text
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_result jsonb;
  v_previous_start timestamptz;
  v_previous_end timestamptz := p_start;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_business_id is null
     or p_start is null or p_end is null or p_start >= p_end
     or p_chart_start is null or p_chart_end is null
     or p_chart_start >= p_chart_end then
    raise exception 'Invalid dashboard date range' using errcode = '22023';
  end if;
  if p_chart_unit is null
     or p_chart_unit not in ('hour', 'day', 'week', 'month') then
    raise exception 'Invalid dashboard chart interval' using errcode = '22023';
  end if;
  if p_timezone is null or not exists (
    select 1 from pg_catalog.pg_timezone_names where name = p_timezone
  ) then
    raise exception 'Invalid dashboard time zone' using errcode = '22023';
  end if;
  if not public.has_business_role(
    p_business_id, array['owner', 'admin', 'cashier', 'viewer']
  ) then
    raise exception 'Business access denied' using errcode = '42501';
  end if;

  v_previous_start := p_start - (p_end - p_start);

  with transaction_summary as (
    select
      coalesce(sum(case when t.type = 'income' then t.amount else -t.amount end), 0)
        as cash_balance,
      coalesce(sum(t.amount) filter (
        where t.type = 'income'
          and t.transaction_date >= p_start
          and t.transaction_date < p_end
      ), 0) as period_income,
      coalesce(sum(t.amount) filter (
        where t.type = 'expense'
          and t.transaction_date >= p_start
          and t.transaction_date < p_end
      ), 0) as period_expense,
      count(*) filter (
        where t.transaction_date >= p_start and t.transaction_date < p_end
      )::integer as period_transaction_count
    from public.transactions t
    where t.user_id = p_business_id
      and t.deleted_at is null
  ),
  previous_summary as (
    select
      coalesce(sum(t.amount) filter (
        where t.type = 'income'
          and t.transaction_date >= v_previous_start
          and t.transaction_date < v_previous_end
      ), 0) as previous_income,
      coalesce(sum(t.amount) filter (
        where t.type = 'expense'
          and t.transaction_date >= v_previous_start
          and t.transaction_date < v_previous_end
      ), 0) as previous_expense,
      count(*) filter (
        where t.transaction_date >= v_previous_start
          and t.transaction_date < v_previous_end
      )::integer as previous_transaction_count
    from public.transactions t
    where t.user_id = p_business_id
      and t.deleted_at is null
  ),
  debt_summary as (
    select
      coalesce(sum(d.amount - d.paid_amount) filter (
        where d.type = 'receivable' and d.paid_amount < d.amount
      ), 0) as receivable_outstanding,
      coalesce(sum(d.amount - d.paid_amount) filter (
        where d.type = 'payable' and d.paid_amount < d.amount
      ), 0) as payable_outstanding,
      count(*) filter (
        where d.type = 'receivable' and d.paid_amount < d.amount
      )::integer as receivable_unpaid_count,
      count(*) filter (
        where d.type = 'payable' and d.paid_amount < d.amount
      )::integer as payable_unpaid_count,
      count(*) filter (
        where d.type = 'receivable' and d.paid_amount < d.amount
          and d.due_date < now()
      )::integer as receivable_due_count,
      count(*) filter (
        where d.type = 'payable' and d.paid_amount < d.amount
          and d.due_date < now()
      )::integer as payable_due_count
    from public.debts d
    where d.user_id = p_business_id
  ),
  chart_points as (
    select
      date_trunc(
        p_chart_unit, t.transaction_date at time zone p_timezone
      ) as bucket_start,
      coalesce(sum(t.amount) filter (where t.type = 'income'), 0) as income,
      coalesce(sum(t.amount) filter (where t.type = 'expense'), 0) as expense
    from public.transactions t
    where t.user_id = p_business_id
      and t.deleted_at is null
      and t.transaction_date >= p_chart_start
      and t.transaction_date < p_chart_end
    group by 1
  ),
  recent_transactions as (
    select
      t.id, t.type, t.amount, t.transaction_date, t.description,
      t.category_id, t.payment_method_id, t.created_at,
      coalesce(c.name, t.category_id) as category_name,
      coalesce(c.color, '#64748B') as category_color
    from public.transactions t
    left join public.categories c
      on c.business_id = t.user_id and c.id = t.category_id
    where t.user_id = p_business_id
      and t.deleted_at is null
    order by t.transaction_date desc, t.created_at desc
    limit 5
  ),
  recent_activity as (
    select a.id, a.action, a.entity_type, a.entity_id, a.summary,
           a.actor_user_id, a.created_at
    from public.activity_logs a
    where a.business_id = p_business_id
    order by a.created_at desc
    limit 8
  )
  select jsonb_build_object(
    'cash_balance', transaction_summary.cash_balance,
    'period_income', transaction_summary.period_income,
    'period_expense', transaction_summary.period_expense,
    'period_net', transaction_summary.period_income - transaction_summary.period_expense,
    'period_transaction_count', transaction_summary.period_transaction_count,
    'previous_income', previous_summary.previous_income,
    'previous_expense', previous_summary.previous_expense,
    'previous_net', previous_summary.previous_income - previous_summary.previous_expense,
    'previous_transaction_count', previous_summary.previous_transaction_count,
    'receivable_outstanding', debt_summary.receivable_outstanding,
    'payable_outstanding', debt_summary.payable_outstanding,
    'receivable_unpaid_count', debt_summary.receivable_unpaid_count,
    'payable_unpaid_count', debt_summary.payable_unpaid_count,
    'receivable_due_count', debt_summary.receivable_due_count,
    'payable_due_count', debt_summary.payable_due_count,
    'chart_points',
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'bucket_start',
          to_char(points.bucket_start, 'YYYY-MM-DD"T"HH24:MI:SS'),
          'income', points.income,
          'expense', points.expense,
          'net', points.income - points.expense
        ) order by points.bucket_start
      )
      from chart_points points
    ), '[]'::jsonb),
    'recent_transactions',
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', recent.id,
          'type', recent.type,
          'amount', recent.amount,
          'transaction_date', recent.transaction_date,
          'description', recent.description,
          'category_id', recent.category_id,
          'category_name', recent.category_name,
          'category_color', recent.category_color,
          'payment_method_id', recent.payment_method_id
        ) order by recent.transaction_date desc, recent.created_at desc
      )
      from recent_transactions recent
    ), '[]'::jsonb),
    'recent_activity',
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', activity.id,
          'action', activity.action,
          'entity_type', activity.entity_type,
          'entity_id', activity.entity_id,
          'summary', activity.summary,
          'actor_user_id', activity.actor_user_id,
          'created_at', activity.created_at
        ) order by activity.created_at desc
      )
      from recent_activity activity
    ), '[]'::jsonb)
  )
  into v_result
  from transaction_summary
  cross join previous_summary
  cross join debt_summary;

  return v_result;
end;
$$;

revoke all on function public.get_web_dashboard_summary(
  uuid, timestamptz, timestamptz, timestamptz, timestamptz, text, text
) from public, anon;
grant execute on function public.get_web_dashboard_summary(
  uuid, timestamptz, timestamptz, timestamptz, timestamptz, text, text
) to authenticated;

insert into storage.buckets (id, name, public)
values ('business-logos', 'business-logos', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Business managers can upload business logos"
  on storage.objects;
create policy "Business managers can upload business logos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'business-logos'
    and public.has_business_role(
      ((storage.foldername(name))[1])::uuid, array['owner', 'admin']
    )
  );

drop policy if exists "Business managers can update business logos"
  on storage.objects;
create policy "Business managers can update business logos"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'business-logos'
    and public.has_business_role(
      ((storage.foldername(name))[1])::uuid, array['owner', 'admin']
    )
  )
  with check (
    bucket_id = 'business-logos'
    and public.has_business_role(
      ((storage.foldername(name))[1])::uuid, array['owner', 'admin']
    )
  );

drop policy if exists "Business managers can delete business logos"
  on storage.objects;
create policy "Business managers can delete business logos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'business-logos'
    and public.has_business_role(
      ((storage.foldername(name))[1])::uuid, array['owner', 'admin']
    )
  );

notify pgrst, 'reload schema';
