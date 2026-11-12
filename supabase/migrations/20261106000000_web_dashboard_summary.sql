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
    select 1
    from pg_catalog.pg_timezone_names
    where name = p_timezone
  ) then
    raise exception 'Invalid dashboard time zone' using errcode = '22023';
  end if;
  if not public.has_business_role(
    p_business_id,
    array['owner', 'admin', 'cashier', 'viewer']
  ) then
    raise exception 'Business access denied' using errcode = '42501';
  end if;

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
      ), 0) as period_expense
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
      ), 0) as payable_outstanding
    from public.debts d
    where d.user_id = p_business_id
  ),
  chart_points as (
    select
      date_trunc(
        p_chart_unit,
        t.transaction_date at time zone p_timezone
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
      t.id,
      t.type,
      t.amount,
      t.transaction_date,
      t.description,
      t.category_id,
      t.payment_method_id,
      t.created_at
    from public.transactions t
    where t.user_id = p_business_id
      and t.deleted_at is null
    order by t.transaction_date desc, t.created_at desc
    limit 5
  )
  select jsonb_build_object(
    'cash_balance', transaction_summary.cash_balance,
    'period_income', transaction_summary.period_income,
    'period_expense', transaction_summary.period_expense,
    'receivable_outstanding', debt_summary.receivable_outstanding,
    'payable_outstanding', debt_summary.payable_outstanding,
    'chart_points',
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'bucket_start',
          to_char(points.bucket_start, 'YYYY-MM-DD"T"HH24:MI:SS'),
          'income',
          points.income,
          'expense',
          points.expense
        )
        order by points.bucket_start
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
          'payment_method_id', recent.payment_method_id
        )
        order by recent.transaction_date desc, recent.created_at desc
      )
      from recent_transactions recent
    ), '[]'::jsonb)
  )
  into v_result
  from transaction_summary
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
