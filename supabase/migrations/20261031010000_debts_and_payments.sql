create table if not exists public.debts (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null check (type in ('receivable', 'payable')),
  contact_name text not null check (length(trim(contact_name)) > 0),
  phone text not null default '',
  amount bigint not null check (amount > 0),
  paid_amount bigint not null default 0
    check (paid_amount >= 0 and paid_amount <= amount),
  transaction_date timestamptz not null,
  due_date timestamptz not null,
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists debts_user_due_date_idx
  on public.debts (user_id, due_date);

alter table public.debts enable row level security;

drop policy if exists "Users can read own debts" on public.debts;
create policy "Users can read own debts"
  on public.debts for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own debts" on public.debts;
create policy "Users can insert own debts"
  on public.debts for insert
  with check (auth.uid() = user_id and paid_amount = 0);

drop policy if exists "Users can update own debts" on public.debts;

create table if not exists public.debt_payments (
  id uuid primary key,
  debt_id uuid not null references public.debts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  amount bigint not null check (amount > 0),
  payment_date timestamptz not null,
  note text not null default '',
  ledger_transaction_id uuid not null unique,
  created_at timestamptz not null default now()
);

create index if not exists debt_payments_debt_date_idx
  on public.debt_payments (debt_id, payment_date desc);

alter table public.debt_payments enable row level security;

drop policy if exists "Users can read own debt payments"
  on public.debt_payments;
create policy "Users can read own debt payments"
  on public.debt_payments for select
  using (auth.uid() = user_id);

revoke all on public.debts from public, anon, authenticated;
grant select, insert on public.debts to authenticated;
revoke all on public.debt_payments from public, anon, authenticated;
grant select on public.debt_payments to authenticated;

drop trigger if exists set_debts_updated_at on public.debts;
create trigger set_debts_updated_at
  before update on public.debts
  for each row execute function public.set_updated_at();

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
  v_debt public.debts%rowtype;
  v_existing public.debt_payments%rowtype;
  v_transaction public.transactions%rowtype;
  v_transaction_type text;
  v_category_id text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select *
    into v_existing
    from public.debt_payments
    where id = p_payment_id and user_id = auth.uid();
  if found then
    if v_existing.debt_id <> p_debt_id
       or v_existing.amount <> p_amount
       or v_existing.payment_date <> p_payment_date
       or v_existing.note <> coalesce(p_note, '')
       or v_existing.ledger_transaction_id <> p_ledger_transaction_id then
      raise exception 'Payment ID is already in use';
    end if;
    return v_existing.id;
  end if;

  select *
    into v_debt
    from public.debts
    where id = p_debt_id and user_id = auth.uid()
    for update;
  if not found then
    raise exception 'Debt not found';
  end if;

  select *
    into v_existing
    from public.debt_payments
    where id = p_payment_id and user_id = auth.uid();
  if found then
    if v_existing.debt_id <> p_debt_id
       or v_existing.amount <> p_amount
       or v_existing.payment_date <> p_payment_date
       or v_existing.note <> coalesce(p_note, '')
       or v_existing.ledger_transaction_id <> p_ledger_transaction_id then
      raise exception 'Payment ID is already in use';
    end if;
    return v_existing.id;
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

  select *
    into v_transaction
    from public.transactions
    where id = p_ledger_transaction_id and user_id = auth.uid()
    for update;
  if found and (
    v_transaction.type <> v_transaction_type
    or v_transaction.amount <> p_amount
    or v_transaction.category_id <> v_category_id
    or v_transaction.payment_method_id <> 'cash'
    or v_transaction.transaction_date <> p_payment_date
    or v_transaction.description <> coalesce(p_ledger_description, '')
    or v_transaction.deleted_at is not null
  ) then
    raise exception 'Ledger transaction ID is already in use';
  end if;

  insert into public.debt_payments (
    id, debt_id, user_id, amount, payment_date, note, ledger_transaction_id
  ) values (
    p_payment_id, p_debt_id, auth.uid(), p_amount, p_payment_date,
    coalesce(p_note, ''), p_ledger_transaction_id
  );

  update public.debts
    set paid_amount = paid_amount + p_amount,
        updated_at = now()
    where id = p_debt_id;

  insert into public.transactions (
    id, user_id, type, amount, category_id, payment_method_id,
    transaction_date, description
  ) values (
    p_ledger_transaction_id, auth.uid(), v_transaction_type, p_amount,
    v_category_id, 'cash', p_payment_date, coalesce(p_ledger_description, '')
  )
  on conflict (id) do nothing;

  return p_payment_id;
end;
$$;

revoke all on function public.record_debt_payment(
  uuid, uuid, bigint, timestamptz, text, uuid, text
) from public;
grant execute on function public.record_debt_payment(
  uuid, uuid, bigint, timestamptz, text, uuid, text
) to authenticated;
