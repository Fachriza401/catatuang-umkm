create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
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

create table if not exists public.business_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  business_name text not null,
  owner_name text not null default '',
  business_type text not null default '',
  phone text not null default '',
  address text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.business_profiles enable row level security;

drop policy if exists "Users can read own business profile"
  on public.business_profiles;
create policy "Users can read own business profile"
  on public.business_profiles
  for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own business profile"
  on public.business_profiles;
create policy "Users can insert own business profile"
  on public.business_profiles
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own business profile"
  on public.business_profiles;
create policy "Users can update own business profile"
  on public.business_profiles
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own business profile"
  on public.business_profiles;
create policy "Users can delete own business profile"
  on public.business_profiles
  for delete
  using (auth.uid() = user_id);

drop trigger if exists set_business_profiles_updated_at
  on public.business_profiles;
create trigger set_business_profiles_updated_at
  before update on public.business_profiles
  for each row
  execute function public.set_updated_at();

create table if not exists public.transactions (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null check (type in ('income', 'expense')),
  amount bigint not null check (amount > 0),
  category_id text not null,
  payment_method_id text not null,
  transaction_date timestamptz not null,
  description text not null default '',
  attachment_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists transactions_user_date_idx
  on public.transactions (user_id, transaction_date desc);

create index if not exists transactions_user_updated_idx
  on public.transactions (user_id, updated_at desc);

alter table public.transactions enable row level security;

drop policy if exists "Users can read own transactions"
  on public.transactions;
create policy "Users can read own transactions"
  on public.transactions
  for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own transactions"
  on public.transactions;
create policy "Users can insert own transactions"
  on public.transactions
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own transactions"
  on public.transactions;
create policy "Users can update own transactions"
  on public.transactions
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own transactions"
  on public.transactions;
create policy "Users can delete own transactions"
  on public.transactions
  for delete
  using (auth.uid() = user_id);

drop trigger if exists set_transactions_updated_at
  on public.transactions;
create trigger set_transactions_updated_at
  before update on public.transactions
  for each row
  execute function public.set_updated_at();

insert into storage.buckets (id, name, public)
values ('transaction-attachments', 'transaction-attachments', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Users can read own transaction attachments"
  on storage.objects;
create policy "Users can read own transaction attachments"
  on storage.objects
  for select
  using (
    bucket_id = 'transaction-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can upload own transaction attachments"
  on storage.objects;
create policy "Users can upload own transaction attachments"
  on storage.objects
  for insert
  with check (
    bucket_id = 'transaction-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update own transaction attachments"
  on storage.objects;
create policy "Users can update own transaction attachments"
  on storage.objects
  for update
  using (
    bucket_id = 'transaction-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'transaction-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete own transaction attachments"
  on storage.objects;
create policy "Users can delete own transaction attachments"
  on storage.objects
  for delete
  using (
    bucket_id = 'transaction-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
