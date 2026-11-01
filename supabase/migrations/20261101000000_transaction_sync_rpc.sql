create table if not exists public.transaction_sync_requests (
  user_id uuid not null references auth.users (id) on delete cascade,
  idempotency_key uuid not null,
  request jsonb not null,
  response jsonb not null,
  created_at timestamptz not null default now(),
  primary key (user_id, idempotency_key)
);

revoke all on table public.transaction_sync_requests
  from public, anon, authenticated;

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
  v_user_id uuid := auth.uid();
  v_transaction_id uuid;
  v_request jsonb;
  v_cached_request jsonb;
  v_response jsonb;
  v_remote public.transactions%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if jsonb_typeof(p_transaction) <> 'object'
     or p_transaction->>'id' is null
     or p_transaction->>'user_id' is null then
    raise exception 'Invalid transaction payload';
  end if;

  v_transaction_id := (p_transaction->>'id')::uuid;
  if p_transaction->>'user_id' <> v_user_id::text then
    raise exception 'Transaction ownership mismatch';
  end if;
  if p_operation not in ('create', 'update', 'delete') then
    raise exception 'Unsupported transaction operation';
  end if;
  if p_idempotency_key is null then
    raise exception 'Idempotency key is required';
  end if;

  v_request := jsonb_build_object(
    'transaction', p_transaction,
    'operation', p_operation,
    'expected_updated_at', p_expected_updated_at
  );

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      v_user_id::text || ':' || p_idempotency_key::text,
      0
    )
  );

  select request, response
    into v_cached_request, v_response
    from public.transaction_sync_requests
    where user_id = v_user_id and idempotency_key = p_idempotency_key;
  if found then
    if v_cached_request <> v_request then
      raise exception 'Idempotency key was reused with a different request';
    end if;
    return v_response;
  end if;

  select *
    into v_remote
    from public.transactions
    where id = v_transaction_id
    for update;

  if found and v_remote.user_id <> v_user_id then
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
      insert into public.transactions (
        id, user_id, type, amount, category_id, payment_method_id,
        transaction_date, description, attachment_url, created_at,
        updated_at, deleted_at
      ) values (
        v_transaction_id, v_user_id, p_transaction->>'type',
        (p_transaction->>'amount')::bigint, p_transaction->>'category_id',
        p_transaction->>'payment_method_id',
        (p_transaction->>'transaction_date')::timestamptz,
        coalesce(p_transaction->>'description', ''),
        p_transaction->>'attachment_url',
        coalesce((p_transaction->>'created_at')::timestamptz, now()),
        now(), (p_transaction->>'deleted_at')::timestamptz
      );
      select * into v_remote
        from public.transactions
        where id = v_transaction_id;
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
  ) values (v_user_id, p_idempotency_key, v_request, v_response);
  return v_response;
end;
$$;

revoke all on function public.sync_transaction(jsonb, text, uuid, timestamptz)
  from public, anon;
grant execute on function public.sync_transaction(jsonb, text, uuid, timestamptz)
  to authenticated;