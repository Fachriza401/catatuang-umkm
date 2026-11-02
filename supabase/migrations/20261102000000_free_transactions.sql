-- CatatUang: semua pengguna bebas mencatat transaksi tanpa batas paket.
-- Lampiran bukti transaksi juga dibuka untuk semua pengguna.

update public.business_plans
set monthly_transaction_limit = null,
    attachments_enabled = true;

create or replace function public.assert_transaction_capacity(p_business_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.has_business_role(
    p_business_id,
    array['owner', 'admin', 'cashier']
  ) then
    raise exception 'Insufficient business role' using errcode = '42501';
  end if;
end;
$$;
