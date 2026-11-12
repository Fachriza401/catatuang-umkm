begin;

select extensions.plan(9);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at
) values
  (
    '00000000-0000-0000-0000-000000000000',
    '80000000-0000-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'dashboard-owner@test.invalid',
    '',
    now(),
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '80000000-0000-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'dashboard-outsider@test.invalid',
    '',
    now(),
    now(),
    now()
  );

insert into public.business_profiles (user_id, business_name)
values
  ('80000000-0000-4000-8000-000000000001', 'Usaha Dasbor'),
  ('80000000-0000-4000-8000-000000000002', 'Usaha Lain');

insert into public.transactions (
  id,
  user_id,
  type,
  amount,
  category_id,
  payment_method_id,
  transaction_date,
  description,
  deleted_at
) values
  (
    '81000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000001',
    'income',
    2000,
    'sales',
    'cash',
    '2026-01-10 10:00:00+00',
    'Penjualan',
    null
  ),
  (
    '81000000-0000-4000-8000-000000000002',
    '80000000-0000-4000-8000-000000000001',
    'expense',
    500,
    'ingredients',
    'cash',
    '2026-01-10 11:00:00+00',
    'Belanja bahan',
    null
  ),
  (
    '81000000-0000-4000-8000-000000000003',
    '80000000-0000-4000-8000-000000000001',
    'expense',
    90000,
    'ingredients',
    'cash',
    '2026-01-10 12:00:00+00',
    'Transaksi dihapus',
    '2026-01-10 12:05:00+00'
  );

insert into public.debts (
  id,
  user_id,
  type,
  contact_name,
  amount,
  paid_amount,
  transaction_date,
  due_date
) values
  (
    '82000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000001',
    'receivable',
    'Pelanggan',
    1000,
    300,
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00'
  ),
  (
    '82000000-0000-4000-8000-000000000002',
    '80000000-0000-4000-8000-000000000001',
    'payable',
    'Pemasok',
    2000,
    200,
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00'
  );

set local role authenticated;
select set_config('request.jwt.claim.sub', '80000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select extensions.is(
  (public.get_web_dashboard_summary(
    '80000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    'day',
    'UTC'
  )->>'cash_balance')::bigint,
  1500::bigint,
  'cash balance includes active transactions and excludes soft-deleted rows'
);
select extensions.is(
  (public.get_web_dashboard_summary(
    '80000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    'day',
    'UTC'
  )->>'period_income')::bigint,
  2000::bigint,
  'period income is aggregated by date range'
);
select extensions.is(
  (public.get_web_dashboard_summary(
    '80000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    'day',
    'UTC'
  )->>'period_expense')::bigint,
  500::bigint,
  'period expense is aggregated by date range'
);
select extensions.is(
  (public.get_web_dashboard_summary(
    '80000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    'day',
    'UTC'
  )->'chart_points'->0->>'income')::bigint,
  2000::bigint,
  'chart buckets aggregate income'
);
select extensions.is(
  (public.get_web_dashboard_summary(
    '80000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    'day',
    'UTC'
  )->'chart_points'->0->>'expense')::bigint,
  500::bigint,
  'chart buckets aggregate expense'
);
select extensions.is(
  jsonb_array_length(public.get_web_dashboard_summary(
    '80000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    'day',
    'UTC'
  )->'recent_transactions'),
  2,
  'recent transactions exclude soft-deleted rows'
);
select extensions.is(
  (public.get_web_dashboard_summary(
    '80000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    'day',
    'UTC'
  )->>'receivable_outstanding')::bigint,
  700::bigint,
  'piutang summary uses amount minus paid amount'
);
select extensions.is(
  (public.get_web_dashboard_summary(
    '80000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    'day',
    'UTC'
  )->>'payable_outstanding')::bigint,
  1800::bigint,
  'utang summary uses amount minus paid amount'
);
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '80000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.throws_ok(
  $$select public.get_web_dashboard_summary(
    '80000000-0000-4000-8000-000000000001',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    '2026-01-01 00:00:00+00',
    '2026-02-01 00:00:00+00',
    'day',
    'UTC'
  )$$,
  '42501',
  'Business access denied',
  'users cannot request another business dashboard'
);
reset role;

select * from extensions.finish();
rollback;
