begin;

select extensions.plan(18);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'owner-one@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'owner-two@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'admin@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'cashier@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', 'viewer@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000006', 'authenticated', 'authenticated', 'outsider@test.invalid', '', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000007', 'authenticated', 'authenticated', 'new-member@test.invalid', '', now(), now(), now());

insert into public.business_profiles (user_id, business_name)
values
  ('10000000-0000-4000-8000-000000000001', 'Usaha Satu'),
  ('10000000-0000-4000-8000-000000000002', 'Usaha Dua');

update public.business_subscriptions
  set plan = 'business', status = 'active',
      current_period_end = now() + interval '30 days'
  where business_id = '10000000-0000-4000-8000-000000000001';

insert into public.business_members (business_id, member_user_id, role, created_by)
values
  ('10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', 'admin', '10000000-0000-4000-8000-000000000001'),
  ('10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000004', 'cashier', '10000000-0000-4000-8000-000000000001'),
  ('10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000005', 'viewer', '10000000-0000-4000-8000-000000000001');

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
select extensions.is((select count(*)::integer from public.transactions), 1, 'admin reads its business transactions');
select extensions.lives_ok(
  $$select public.update_business_profile('Nama Admin', '', '', '', '')$$,
  'admin can update business settings'
);
select extensions.throws_ok(
  $$select public.add_business_member('new-member@test.invalid', 'admin')$$,
  '42501',
  'Only the owner can assign admin role',
  'admin cannot grant admin role'
);
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.is(
  public.add_business_member('new-member@test.invalid', 'cashier'),
  '10000000-0000-4000-8000-000000000007'::uuid,
  'owner can add an allowed business member'
);
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000004', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.lives_ok(
  $$select public.sync_transaction(
    jsonb_build_object(
      'id', '20000000-0000-4000-8000-000000000003',
      'user_id', '10000000-0000-4000-8000-000000000001',
      'type', 'income', 'amount', 5000, 'category_id', 'sales',
      'payment_method_id', 'cash', 'transaction_date', now(),
      'description', 'Kasir', 'attachment_url', null,
      'created_at', now(), 'updated_at', now(), 'deleted_at', null
    ),
    'create', '20000000-0000-4000-8000-000000000003', null
  )$$,
  'cashier can create a transaction through the protected RPC'
);
select extensions.throws_ok(
  $$select public.update_business_profile('Tidak boleh', '', '', '', '')$$,
  '42501',
  'Insufficient business role',
  'cashier cannot update owner business settings'
);
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.is((select count(*)::integer from public.transactions), 2, 'viewer can read business transactions');
select extensions.throws_ok(
  $$select public.sync_transaction(
    jsonb_build_object(
      'id', '20000000-0000-4000-8000-000000000004',
      'user_id', '10000000-0000-4000-8000-000000000001',
      'type', 'income', 'amount', 5000, 'category_id', 'sales',
      'payment_method_id', 'cash', 'transaction_date', now(),
      'description', 'Viewer', 'created_at', now(), 'updated_at', now()
    ),
    'create', '20000000-0000-4000-8000-000000000004', null
  )$$,
  '42501',
  'Business write access denied',
  'viewer cannot create transactions'
);
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000006', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.is((select count(*)::integer from public.transactions), 0, 'unrelated user cannot read another business');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select extensions.throws_ok(
  $$select public.add_business_member('outsider@test.invalid', 'viewer')$$,
  'P0001',
  'Member limit reached for current plan',
  'Free plan member limit is enforced in PostgreSQL'
);
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

select * from extensions.finish();
rollback;