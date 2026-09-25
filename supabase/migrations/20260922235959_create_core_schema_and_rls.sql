-- ====================================================================
-- KisanSetu Migration: Core Schema, RLS, Offer History Trigger, and
-- Atomic Offer RPCs
-- ====================================================================
-- IMPORTANT: this migration is intentionally timestamped BEFORE
-- 20260923000000_create_user_devices_and_push_notifications.sql. That
-- migration creates a trigger on public.offers and inserts into
-- public.notifications; on a fresh database neither table exists unless
-- this migration runs first. Do not rename this file to a later timestamp.
--
-- Source of truth for this schema: exported from the live Supabase project
-- (schema-only dump, provided out-of-band). Column definitions below match
-- that export; this migration only adds `if not exists` table creation,
-- RLS, triggers, and RPCs on top of it so the schema becomes versioned and
-- reproducible instead of living only in the dashboard.
-- ====================================================================

-- ====================================================================
-- 1. Core tables
-- ====================================================================

create table if not exists public.profiles (
  id uuid not null,
  role text check (role = any (array['farmer'::text, 'buyer'::text])),
  full_name text not null default ''::text,
  phone text,
  avatar_url text,
  language text not null default 'en'::text,
  state text,
  district text,
  village text,
  land_size_acres numeric,
  primary_crop text,
  company_name text,
  gst_number text,
  business_type text,
  buying_capacity_quintals numeric,
  is_profile_complete boolean not null default false,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint profiles_pkey primary key (id),
  constraint profiles_id_fkey foreign key (id) references auth.users(id)
);

create table if not exists public.produce (
  id uuid not null default gen_random_uuid(),
  farmer_id uuid not null,
  name text not null,
  category text not null,
  quantity numeric not null check (quantity >= 0::numeric),
  unit text not null,
  expected_price numeric not null check (expected_price >= 0::numeric),
  status text not null default 'active'::text check (status = any (array['active'::text, 'pending'::text, 'sold'::text, 'draft'::text, 'archived'::text])),
  location text,
  description text,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint produce_pkey primary key (id),
  constraint produce_farmer_id_fkey foreign key (farmer_id) references public.profiles(id)
);

create table if not exists public.market_prices (
  id uuid not null default gen_random_uuid(),
  produce_name text not null,
  category text,
  market_name text not null,
  location text,
  price numeric not null check (price >= 0::numeric),
  unit text not null,
  price_date date not null default current_date,
  trend text default 'stable'::text check (trend = any (array['up'::text, 'down'::text, 'stable'::text])),
  source text,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint market_prices_pkey primary key (id)
);

create table if not exists public.offers (
  id uuid not null default gen_random_uuid(),
  produce_id uuid not null,
  farmer_id uuid not null,
  buyer_id uuid not null,
  offered_price numeric not null check (offered_price >= 0::numeric),
  quantity numeric not null check (quantity >= 0::numeric),
  status text not null default 'pending'::text check (status = any (array['pending'::text, 'accepted'::text, 'rejected'::text, 'countered'::text, 'cancelled'::text])),
  message text,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint offers_pkey primary key (id),
  constraint offers_produce_id_fkey foreign key (produce_id) references public.produce(id),
  constraint offers_farmer_id_fkey foreign key (farmer_id) references public.profiles(id),
  constraint offers_buyer_id_fkey foreign key (buyer_id) references public.profiles(id)
);

-- Prevents duplicate active offers at the database level (defense-in-depth
-- alongside the check inside create_offer()): a buyer can only have one
-- pending/countered offer per produce listing at a time.
create unique index if not exists offers_unique_active_per_buyer_produce
  on public.offers (produce_id, buyer_id)
  where status in ('pending', 'countered');

create table if not exists public.notifications (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  type text not null,
  title text not null,
  message text not null,
  related_id uuid,
  related_type text,
  is_read boolean not null default false,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint notifications_pkey primary key (id),
  constraint notifications_user_id_fkey foreign key (user_id) references public.profiles(id)
);

create table if not exists public.offer_history (
  id uuid not null default gen_random_uuid(),
  offer_id uuid not null,
  offered_price numeric not null check (offered_price >= 0::numeric),
  quantity numeric not null check (quantity >= 0::numeric),
  message text,
  status text not null,
  version integer not null default 1,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint offer_history_pkey primary key (id),
  constraint offer_history_offer_id_fkey foreign key (offer_id) references public.offers(id)
);

-- Present in the live schema but not referenced anywhere in the Flutter
-- client (no repository selects/inserts into it). RLS is enabled with no
-- policies below, which denies all access to `anon`/`authenticated` by
-- default -- only the service role can touch it until an actual use case
-- and matching policies are defined. If this table is genuinely unused,
-- consider dropping it instead.
create table if not exists public.customers (
  id uuid not null default gen_random_uuid(),
  name text not null,
  email text,
  phone text,
  address text,
  company_name text,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint customers_pkey primary key (id)
);

-- ====================================================================
-- 2. Row Level Security
-- ====================================================================

alter table public.profiles enable row level security;
alter table public.produce enable row level security;
alter table public.market_prices enable row level security;
alter table public.offers enable row level security;
alter table public.notifications enable row level security;
alter table public.offer_history enable row level security;
alter table public.customers enable row level security;

-- --- profiles ---------------------------------------------------------
-- Any authenticated user may read profiles: the marketplace/offer queries
-- embed farmer_profile / buyer_profile (name, district, company, etc.) via
-- FK joins for the counterparty in a listing or offer, so this can't be
-- limited to "own row only" without breaking those screens. Writes remain
-- strictly own-row only.
drop policy if exists "Authenticated users can view profiles" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;

create policy "Authenticated users can view profiles"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users can insert their own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- No delete policy: profile deletion is not a client-facing action.

-- --- produce ------------------------------------------------------------
drop policy if exists "Active produce visible to authenticated users" on public.produce;
drop policy if exists "Farmers manage their own produce inserts" on public.produce;
drop policy if exists "Farmers manage their own produce updates" on public.produce;
drop policy if exists "Farmers manage their own produce deletes" on public.produce;

-- A farmer can always see their own listings regardless of status
-- (draft/pending/sold/archived); everyone else only sees active listings.
create policy "Active produce visible to authenticated users"
  on public.produce for select
  to authenticated
  using (status = 'active' or farmer_id = auth.uid());

create policy "Farmers manage their own produce inserts"
  on public.produce for insert
  to authenticated
  with check (farmer_id = auth.uid());

create policy "Farmers manage their own produce updates"
  on public.produce for update
  to authenticated
  using (farmer_id = auth.uid())
  with check (farmer_id = auth.uid());

create policy "Farmers manage their own produce deletes"
  on public.produce for delete
  to authenticated
  using (farmer_id = auth.uid());

-- --- market_prices --------------------------------------------------------
drop policy if exists "Authenticated users can view market prices" on public.market_prices;

create policy "Authenticated users can view market prices"
  on public.market_prices for select
  to authenticated
  using (true);

-- Intentionally no insert/update/delete policy: market price data is
-- managed out-of-band (admin tooling / service role), not by app clients.

-- --- offers -------------------------------------------------------------
drop policy if exists "Buyers and farmers view their own offers" on public.offers;
drop policy if exists "Buyers can edit their own pending offers" on public.offers;

create policy "Buyers and farmers view their own offers"
  on public.offers for select
  to authenticated
  using (buyer_id = auth.uid() or farmer_id = auth.uid());

-- Buyers may still edit/cancel their own pending offer directly (price,
-- quantity, message, or status -> 'cancelled'); this path has no race
-- condition since it only ever touches the caller's own single row.
create policy "Buyers can edit their own pending offers"
  on public.offers for update
  to authenticated
  using (buyer_id = auth.uid() and status = 'pending')
  with check (buyer_id = auth.uid());

-- Intentionally NO insert policy and NO farmer-facing update policy here.
-- Creating an offer and accepting/rejecting/countering an offer both
-- require cross-row consistency checks (produce quantity/status,
-- duplicate-offer checks) that a simple RLS predicate cannot express
-- atomically. Both paths are routed through the SECURITY DEFINER RPCs
-- below (create_offer / respond_to_offer), which run with elevated
-- privileges after taking a row lock, closing the check-then-write race
-- that existed in the Flutter client (separate select + insert/update
-- calls). Direct .insert()/.update() from the client for these paths will
-- now be rejected by RLS.

-- --- notifications --------------------------------------------------------
drop policy if exists "Users view their own notifications" on public.notifications;
drop policy if exists "Users mark their own notifications read" on public.notifications;

create policy "Users view their own notifications"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid());

create policy "Users mark their own notifications read"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- No insert policy: rows are created by the SECURITY DEFINER
-- handle_offer_notification() trigger (see the user_devices migration),
-- which bypasses RLS. No delete policy: not used by the client today.

-- --- offer_history --------------------------------------------------------
drop policy if exists "Offer participants view offer history" on public.offer_history;

create policy "Offer participants view offer history"
  on public.offer_history for select
  to authenticated
  using (
    exists (
      select 1 from public.offers o
      where o.id = offer_history.offer_id
        and (o.buyer_id = auth.uid() or o.farmer_id = auth.uid())
    )
  );

-- No insert/update/delete policy: rows are written exclusively by the
-- handle_offer_history_versioning() trigger below.

-- ====================================================================
-- 3. Offer history versioning trigger
-- ====================================================================
-- The Flutter app reads offer_history via joins on every offer query, but
-- nothing in the client ever wrote to it -- the table was always empty.
-- This trigger snapshots every insert/update of an offer as a new version.

create or replace function public.handle_offer_history_versioning()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_next_version integer;
begin
  select coalesce(max(version), 0) + 1 into v_next_version
  from public.offer_history
  where offer_id = new.id;

  insert into public.offer_history (offer_id, offered_price, quantity, message, status, version)
  values (new.id, new.offered_price, new.quantity, new.message, new.status, v_next_version);

  return new;
end;
$$;

drop trigger if exists tr_offer_history_versioning on public.offers;
create trigger tr_offer_history_versioning
  after insert or update on public.offers
  for each row execute function public.handle_offer_history_versioning();

-- ====================================================================
-- 4. Atomic offer RPCs (close the buyer/farmer TOCTOU race conditions)
-- ====================================================================

-- Replaces SupabaseBuyerRepository.makeOffer()'s separate
-- select-produce -> select-duplicate-check -> insert sequence, which left
-- a window for two concurrent requests to both pass validation and both
-- insert. This function does the same checks after taking a row lock on
-- the produce row, so concurrent callers are serialized.
create or replace function public.create_offer(
  p_produce_id uuid,
  p_offered_price numeric,
  p_quantity numeric,
  p_message text default null
)
returns public.offers
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer_id uuid := auth.uid();
  v_produce public.produce;
  v_offer public.offers;
begin
  if v_buyer_id is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_offered_price is null or p_offered_price < 0 then
    raise exception 'Invalid offered price.';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Invalid quantity.';
  end if;

  select * into v_produce
  from public.produce
  where id = p_produce_id
  for update;

  if not found then
    raise exception 'The requested produce listing no longer exists.' using errcode = 'P0002';
  end if;

  if v_produce.status <> 'active' then
    raise exception 'This produce listing is no longer active for offers.';
  end if;

  if p_quantity > v_produce.quantity then
    raise exception 'Offered quantity (%) exceeds available quantity (%).', p_quantity, v_produce.quantity;
  end if;

  if exists (
    select 1 from public.offers
    where produce_id = p_produce_id
      and buyer_id = v_buyer_id
      and status in ('pending', 'countered')
  ) then
    raise exception 'You already have an active offer for this produce listing. Please edit your existing offer.';
  end if;

  insert into public.offers (produce_id, farmer_id, buyer_id, offered_price, quantity, message, status)
  values (p_produce_id, v_produce.farmer_id, v_buyer_id, p_offered_price, p_quantity, p_message, 'pending')
  returning * into v_offer;

  return v_offer;
end;
$$;

revoke all on function public.create_offer(uuid, numeric, numeric, text) from public;
grant execute on function public.create_offer(uuid, numeric, numeric, text) to authenticated;

-- Replaces SupabaseFarmerRepository.updateOfferStatus() for the
-- 'accepted' transition, which previously flipped offer.status without
-- ever checking or reserving produce quantity -- two different offers on
-- the same listing could each be accepted for more than was actually
-- available. This function locks the produce row and decrements its
-- quantity atomically when accepting, marking it 'sold' once fully
-- committed. 'rejected'/'countered' are unaffected (no inventory impact)
-- but are routed through the same RPC so all farmer-side status
-- transitions go through one audited, server-validated path.
create or replace function public.respond_to_offer(
  p_offer_id uuid,
  p_status text,
  p_countered_price numeric default null,
  p_countered_quantity numeric default null
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
    select * into v_produce from public.produce where id = v_offer.produce_id for update;

    if not found then
      raise exception 'The underlying produce listing no longer exists.';
    end if;

    if v_offer.quantity > v_produce.quantity then
      raise exception 'Offered quantity (%) exceeds remaining available quantity (%). Another offer may have already been accepted.', v_offer.quantity, v_produce.quantity;
    end if;

    v_remaining := v_produce.quantity - v_offer.quantity;

    update public.produce
    set quantity = v_remaining,
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
    if p_countered_price is not null and p_countered_price < 0 then
      raise exception 'Invalid countered price.';
    end if;

    update public.offers
    set status = 'countered',
        offered_price = coalesce(p_countered_price, offered_price),
        quantity = coalesce(p_countered_quantity, quantity),
        updated_at = timezone('utc'::text, now())
    where id = p_offer_id
    returning * into v_offer;

  else -- rejected
    update public.offers
    set status = 'rejected', updated_at = timezone('utc'::text, now())
    where id = p_offer_id
    returning * into v_offer;
  end if;

  return v_offer;
end;
$$;

revoke all on function public.respond_to_offer(uuid, text, numeric, numeric) from public;
grant execute on function public.respond_to_offer(uuid, text, numeric, numeric) to authenticated;
