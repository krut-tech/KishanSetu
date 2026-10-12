-- Preserve sold quantities and complete the farmer-to-buyer counter-offer flow.
-- Apply through Supabase migrations before building/releasing this app version.

alter table public.produce
  add column if not exists sold_quantity numeric not null default 0
  check (sold_quantity >= 0);

-- Existing accepted offers are the reliable historical source for sold quantities.
update public.produce p
set sold_quantity = coalesce((
  select sum(o.quantity)
  from public.offers o
  where o.produce_id = p.id and o.status = 'accepted'
), 0);

-- Replace the old signature to avoid an overloaded RPC with stale behavior.
drop function if exists public.respond_to_offer(uuid, text, numeric, numeric);

create function public.respond_to_offer(
  p_offer_id uuid,
  p_status text,
  p_countered_price numeric default null,
  p_countered_quantity numeric default null,
  p_countered_message text default null
)
returns public.offers
language plpgsql
security definer
set search_path = public
as $$
declare
  v_farmer_id uuid := auth.uid();
  v_offer public.offers;
  v_produce public.produce;
  v_remaining numeric;
begin
  if v_farmer_id is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_status not in ('accepted', 'rejected', 'countered') then
    raise exception 'Invalid offer status transition.';
  end if;

  select * into v_offer
  from public.offers
  where id = p_offer_id
    and farmer_id = v_farmer_id
    and status = 'pending'
  for update;

  if not found then
    raise exception 'Offer not found, not yours, or no longer pending.' using errcode = 'P0002';
  end if;

  if p_status = 'accepted' then
    select * into v_produce
    from public.produce
    where id = v_offer.produce_id
    for update;

    if not found then
      raise exception 'The underlying produce listing no longer exists.';
    end if;

    if v_offer.quantity > v_produce.quantity then
      raise exception 'Offered quantity (%) exceeds remaining available quantity (%). Another offer may have already been accepted.',
        v_offer.quantity, v_produce.quantity;
    end if;

    v_remaining := v_produce.quantity - v_offer.quantity;

    update public.produce
    set quantity = v_remaining,
        sold_quantity = coalesce(sold_quantity, 0) + v_offer.quantity,
        status = case when v_remaining <= 0 then 'sold' else status end,
        updated_at = timezone('utc'::text, now())
    where id = v_produce.id;

    update public.offers
    set status = 'accepted', updated_at = timezone('utc'::text, now())
    where id = p_offer_id
    returning * into v_offer;

  elsif p_status = 'countered' then
    if p_countered_quantity is not null and p_countered_quantity <= 0 then
      raise exception 'Invalid countered quantity.';
    end if;
    if p_countered_price is not null and p_countered_price <= 0 then
      raise exception 'Invalid countered price.';
    end if;

    update public.offers
    set status = 'countered',
        offered_price = coalesce(p_countered_price, offered_price),
        quantity = coalesce(p_countered_quantity, quantity),
        message = coalesce(nullif(btrim(p_countered_message), ''), message),
        updated_at = timezone('utc'::text, now())
    where id = p_offer_id
    returning * into v_offer;

  else
    update public.offers
    set status = 'rejected', updated_at = timezone('utc'::text, now())
    where id = p_offer_id
    returning * into v_offer;
  end if;

  return v_offer;
end;
$$;

revoke all on function public.respond_to_offer(uuid, text, numeric, numeric, text) from public;
grant execute on function public.respond_to_offer(uuid, text, numeric, numeric, text) to authenticated;

create or replace function public.respond_to_counter_offer(
  p_offer_id uuid,
  p_status text
)
returns public.offers
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer_id uuid := auth.uid();
  v_offer public.offers;
  v_produce public.produce;
  v_remaining numeric;
begin
  if v_buyer_id is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_status not in ('accepted', 'rejected') then
    raise exception 'Counter-offer response must be accepted or rejected.';
  end if;

  select * into v_offer
  from public.offers
  where id = p_offer_id
    and buyer_id = v_buyer_id
    and status = 'countered'
  for update;

  if not found then
    raise exception 'Counter-offer not found, not yours, or no longer awaiting response.' using errcode = 'P0002';
  end if;

  if p_status = 'accepted' then
    select * into v_produce
    from public.produce
    where id = v_offer.produce_id
    for update;

    if not found then
      raise exception 'The underlying produce listing no longer exists.';
    end if;

    if v_offer.quantity > v_produce.quantity then
      raise exception 'Counter quantity (%) exceeds remaining available quantity (%).',
        v_offer.quantity, v_produce.quantity;
    end if;

    v_remaining := v_produce.quantity - v_offer.quantity;

    update public.produce
    set quantity = v_remaining,
        sold_quantity = coalesce(sold_quantity, 0) + v_offer.quantity,
        status = case when v_remaining <= 0 then 'sold' else status end,
        updated_at = timezone('utc'::text, now())
    where id = v_produce.id;

    update public.offers
    set status = 'accepted', updated_at = timezone('utc'::text, now())
    where id = p_offer_id
    returning * into v_offer;
  else
    update public.offers
    set status = 'rejected', updated_at = timezone('utc'::text, now())
    where id = p_offer_id
    returning * into v_offer;
  end if;

  return v_offer;
end;
$$;

revoke all on function public.respond_to_counter_offer(uuid, text) from public;
grant execute on function public.respond_to_counter_offer(uuid, text) to authenticated;

notify pgrst, 'reload schema';
