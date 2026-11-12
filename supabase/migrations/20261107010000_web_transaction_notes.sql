-- Web transaction writes: keep the existing sync RPC for mobile, while letting
-- the authenticated web client write directly under strict RLS policies.
-- This also adds the optional note column used by the web form.

alter table public.transactions
  add column if not exists note text not null default '';

create index if not exists transactions_user_category_idx
  on public.transactions (user_id, category_id)
  where deleted_at is null;

drop policy if exists "Cashiers can create transactions"
  on public.transactions;
create policy "Cashiers can create transactions"
  on public.transactions for insert to authenticated
  with check (
    created_by = auth.uid()
    and user_id = public.current_business_id()
    and public.has_business_role(
      user_id, array['owner', 'admin', 'cashier']
    )
  );

drop policy if exists "Managers can update transactions"
  on public.transactions;
create policy "Managers can update transactions"
  on public.transactions for update to authenticated
  using (public.has_business_role(user_id, array['owner', 'admin']))
  with check (
    user_id = public.current_business_id()
    and public.has_business_role(user_id, array['owner', 'admin'])
  );

grant insert, update on public.transactions to authenticated;

notify pgrst, 'reload schema';
