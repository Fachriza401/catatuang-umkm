begin;

select extensions.no_plan();

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'owner-one@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'owner-two@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'former-member@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'former-member-2@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', 'outsider@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000006', 'authenticated', 'authenticated', 'new-owner@test.invalid', '', now(), now(), now());

insert into public.business_profiles (user_id, business_name)
values
  ('10000000-0000-4000-8000-000000000001', 'Usaha Satu'),
  ('10000000-0000-4000-8000-000000000002', 'Usaha Dua');

update public.business_subscriptions
  set plan = 'business', status = 'active',
      current_period_end = now() + interval '30 days'
  where business_id = '10000000-0000-4000-8000-000000000001';

insert into public.transactions (
  id, user_id, created_by, type, amount, category_id, payment_method_id,
  transaction_date, created_at, updated_at
) values
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'income', 1000, 'sales', 'cash', now(), now(), now()),
  ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'income', 9000, 'sales', 'cash', now(), now(), now());

insert into public.transactions (
  id, user_id, created_by, type, amount, category_id, payment_method_id,
  transaction_date, created_at, updated_at
)
select
  gen_random_uuid(),
  '10000000-0000-4000-8000-000000000002',
  '10000000-0000-4000-8000-000000000002',
  'income', 1, 'sales', 'cash', now(), now(), now()
from generate_series(1, 199);

update public.business_subscriptions
  set plan = 'premium', status = 'active', current_period_end = null
  where business_id = '10000000-0000-4000-8000-000000000002';
select extensions.is(
  public.effective_business_plan('10000000-0000-4000-8000-000000000002'),
  'free',
  'paid plan without a valid billing period falls back to Free'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.is((select count(*)::integer from public.transactions), 1, 'owner reads only its business transactions');
select extensions.is(public.get_my_business_access()->>'role', 'owner', 'owner role is resolved by the backend');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.is((select count(*)::integer from public.transactions), 0, 'former member cannot read the previous business');
select extensions.is(
  public.get_my_business_access()->>'business_id',
  '10000000-0000-4000-8000-000000000003',
  'former member account resolves only to its own business id'
);
select extensions.is(public.get_my_business_access()->>'role', 'owner', 'every account has only the owner role');
select extensions.throws_ok(
  $$select public.sync_transaction(
    jsonb_build_object(
      'id', '20000000-0000-4000-8000-000000000004',
      'user_id', '10000000-0000-4000-8000-000000000001',
      'type', 'income', 'amount', 5000, 'category_id', 'sales',
      'payment_method_id', 'cash', 'transaction_date', now(),
      'description', 'Former member', 'created_at', now(), 'updated_at', now()
    ),
    'create', '20000000-0000-4000-8000-000000000004', null
  )$$,
  '42501',
  'Business write access denied',
  'former member cannot write to the previous business'
);
reset role;

select extensions.is(to_regclass('public.business_members') is null, true, 'member table is removed');
select extensions.is(to_regprocedure('public.add_business_member(text,text)') is null, true, 'member invitation RPC is removed');
select extensions.is(
  (select count(*) = 0 from information_schema.columns
   where table_schema = 'public'
     and table_name = 'business_plans'
     and column_name = 'max_members'),
  true,
  'member plan limits are removed'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.is((select count(*)::integer from public.transactions), 0, 'unrelated user cannot read another business');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.throws_ok(
  $$update public.business_subscriptions set plan = 'business' where business_id = '10000000-0000-4000-8000-000000000002'$$,
  '42501',
  null,
  'authenticated users cannot change subscription state'
);
select extensions.throws_ok(
  $$select public.provision_business_subscription(
    '10000000-0000-4000-8000-000000000002', 'business', 'active',
    now() + interval '30 days', 'test', null
  )$$,
  '42501',
  null,
  'authenticated clients cannot provision paid subscriptions'
);
select extensions.throws_ok(
  $$select public.sync_transaction(
    jsonb_build_object(
      'id', '20000000-0000-4000-8000-000000000005',
      'user_id', '10000000-0000-4000-8000-000000000002',
      'type', 'income', 'amount', 100, 'category_id', 'sales',
      'payment_method_id', 'cash', 'transaction_date', now(),
      'description', 'Free quota', 'created_at', now(), 'updated_at', now()
    ),
    'create', '20000000-0000-4000-8000-000000000005', null
  )$$,
  'P0001',
  'Monthly transaction limit reached',
  'Free monthly transaction quota is enforced in PostgreSQL'
);
reset role;

select extensions.is(
  (select public from storage.buckets where id = 'transaction-attachments'),
  false,
  'transaction attachment bucket is private'
);
select extensions.is(
  public.effective_business_plan('10000000-0000-4000-8000-000000000001'),
  'business',
  'valid active subscription grants the Business entitlement'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.throws_ok(
  $$insert into public.payment_orders (
    business_id, plan, amount, provider_order_id
  ) values (
    '10000000-0000-4000-8000-000000000002', 'premium', 49000,
    'sub_client_denied'
  )$$,
  '42501',
  null,
  'authenticated users cannot create payment orders'
);
select extensions.throws_ok(
  $$select public.apply_payment_notification('sub_client_denied', 'paid')$$,
  '42501',
  null,
  'authenticated users cannot apply payment notifications'
);
reset role;

set local role service_role;
select set_config('request.jwt.claim.role', 'service_role', true);
insert into public.payment_orders (
  id, business_id, plan, amount, provider_order_id
) values (
  '30000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000002',
  'premium', 49000, 'sub_test_paid_1'
);
select extensions.is(
  (public.apply_payment_notification(
    'sub_test_paid_1', 'paid', 'trx-test-1', 'qris', '{}'::jsonb
  ))->>'processed',
  'true',
  'service role can apply a paid notification'
);
select extensions.is(
  public.effective_business_plan('10000000-0000-4000-8000-000000000002'),
  'premium',
  'paid notification grants the Premium entitlement'
);
select extensions.is(
  (public.apply_payment_notification(
    'sub_test_paid_1', 'paid', 'trx-test-1', 'qris', '{}'::jsonb
  ))->>'processed',
  'false',
  'duplicate paid notification is ignored'
);
reset role;

select * from extensions.finish();
rollback;