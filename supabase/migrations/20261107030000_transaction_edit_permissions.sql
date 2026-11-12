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
  if not public.has_business_role(old.user_id, array['owner', 'admin']) then
    raise exception 'Only owner or admin can edit transactions'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_transaction_edit_role on public.transactions;
create trigger enforce_transaction_edit_role
before update on public.transactions
for each row execute function public.enforce_transaction_edit_role();
