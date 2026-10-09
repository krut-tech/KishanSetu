-- ====================================================================
-- KisanSetu Migration: User Devices & Push Notification Integration
-- ====================================================================

-- 1. Create public.user_devices table for storing active FCM push tokens
create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  push_token text not null,
  platform text not null default 'android',
  device_id text,
  app_version text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_devices_push_token_key unique (push_token)
);

-- Index for high-performance lookup of active tokens per user
create index if not exists idx_user_devices_user_active
  on public.user_devices(user_id, is_active);

-- Enable Row Level Security (RLS)
alter table public.user_devices enable row level security;

-- Drop existing policies if recreating
drop policy if exists "Users can view their own devices" on public.user_devices;
drop policy if exists "Users can insert their own devices" on public.user_devices;
drop policy if exists "Users can update their own devices" on public.user_devices;
drop policy if exists "Users can claim or update a device token" on public.user_devices;
drop policy if exists "Users can delete their own devices" on public.user_devices;

-- Strict RLS Policies: Users can only manage their own device registrations
create policy "Users can view their own devices"
  on public.user_devices for select
  using (auth.uid() = user_id);

create policy "Users can insert their own devices"
  on public.user_devices for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own devices"
  on public.user_devices for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own devices"
  on public.user_devices for delete
  using (auth.uid() = user_id);

-- Security Definer RPC functions for device token lifecycle
create or replace function public.register_device_token(
  p_push_token text,
  p_platform text default 'android',
  p_device_id text default null,
  p_app_version text default '1.0.0+1'
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_push_token is null or trim(p_push_token) = '' then
    return;
  end if;

  -- 1. Remove stale token ownership for previous users on the same push token
  delete from public.user_devices
  where push_token = p_push_token
    and user_id <> v_user_id;

  -- 2. Upsert the token for the current authenticated user
  insert into public.user_devices (
    user_id,
    push_token,
    platform,
    device_id,
    app_version,
    is_active,
    created_at,
    updated_at
  )
  values (
    v_user_id,
    p_push_token,
    coalesce(p_platform, 'android'),
    p_device_id,
    coalesce(p_app_version, '1.0.0+1'),
    true,
    now(),
    now()
  )
  on conflict (push_token) do update
  set user_id = EXCLUDED.user_id,
      platform = EXCLUDED.platform,
      device_id = coalesce(EXCLUDED.device_id, public.user_devices.device_id),
      app_version = coalesce(EXCLUDED.app_version, public.user_devices.app_version),
      is_active = true,
      updated_at = now();
end;
$$;

create or replace function public.deactivate_device_token(
  p_push_token text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return;
  end if;

  if p_push_token is not null and trim(p_push_token) <> '' then
    update public.user_devices
    set is_active = false,
        updated_at = now()
    where user_id = v_user_id
      and push_token = p_push_token;
  else
    update public.user_devices
    set is_active = false,
        updated_at = now()
    where user_id = v_user_id;
  end if;
end;
$$;

grant execute on function public.register_device_token(text, text, text, text) to authenticated;
grant execute on function public.deactivate_device_token(text) to authenticated;

-- ====================================================================
-- 2. Offer Transition Validation & Automatic Notification Triggers
-- ====================================================================

-- Drop legacy functions and triggers
drop trigger if exists on_offer_created on public.offers;
drop trigger if exists on_offer_updated on public.offers;
drop trigger if exists tr_validate_offer_transition on public.offers;
drop trigger if exists tr_offer_notification on public.offers;

drop function if exists public.handle_new_offer();
drop function if exists public.handle_offer_update();

-- Server-side offer status transition validator
create or replace function public.validate_offer_transition()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_actor_id uuid;
begin
  v_actor_id := auth.uid();

  if v_actor_id is not null then
    if OLD.status is distinct from 'pending' then
      raise exception 'Cannot modify offer in % status. Only pending offers can be updated.', OLD.status;
    end if;

    if NEW.status = 'accepted' or NEW.status = 'rejected' or NEW.status = 'countered' then
      if v_actor_id is distinct from NEW.farmer_id then
        raise exception 'Only the farmer can accept, reject, or counter an offer.';
      end if;

    elsif NEW.status = 'cancelled' then
      if v_actor_id is distinct from NEW.buyer_id and v_actor_id is distinct from NEW.farmer_id then
        raise exception 'Only the buyer or farmer associated with this offer can cancel it.';
      end if;

    elsif NEW.status = 'pending' then
      if v_actor_id is distinct from NEW.buyer_id then
        raise exception 'Only the buyer can edit details of a pending offer.';
      end if;
    else
      raise exception 'Invalid offer status: %', NEW.status;
    end if;
  end if;

  return NEW;
end;
$$;

create trigger tr_validate_offer_transition
  before update on public.offers
  for each row execute function public.validate_offer_transition();

-- Canonical offer notification trigger
create or replace function public.handle_offer_notification()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_actor_id uuid;
  v_recipient_id uuid;
  v_type text;
  v_title text;
  v_message text;
  v_produce_name text;
begin
  v_actor_id := auth.uid();

  select name into v_produce_name from public.produce where id = NEW.produce_id;
  if v_produce_name is null or v_produce_name = '' then
    v_produce_name := 'produce listing';
  end if;

  if TG_OP = 'INSERT' then
    v_recipient_id := NEW.farmer_id;
    v_type := 'new_offer';
    v_title := 'New Offer Received';
    v_message := 'You received a new offer of ₹' || NEW.offered_price || ' for ' || v_produce_name || '.';

  elsif TG_OP = 'UPDATE' then
    if OLD.status is distinct from NEW.status then
      if NEW.status = 'accepted' then
        v_recipient_id := NEW.buyer_id;
        v_type := 'offer_accepted';
        v_title := 'Offer Accepted';
        v_message := 'Your offer of ₹' || NEW.offered_price || ' for ' || v_produce_name || ' was accepted!';

      elsif NEW.status = 'rejected' then
        v_recipient_id := NEW.buyer_id;
        v_type := 'offer_rejected';
        v_title := 'Offer Declined';
        v_message := 'Your offer for ' || v_produce_name || ' was declined.';

      elsif NEW.status = 'countered' then
        v_recipient_id := NEW.buyer_id;
        v_type := 'counter_offer';
        v_title := 'Counter Offer Received';
        v_message := 'Farmer sent a counter offer for ' || v_produce_name || '.';

      elsif NEW.status = 'cancelled' then
        if v_actor_id = NEW.farmer_id then
          v_recipient_id := NEW.buyer_id;
          v_message := 'The farmer cancelled the offer of ₹' || NEW.offered_price || ' for ' || v_produce_name || '.';
        else
          v_recipient_id := NEW.farmer_id;
          v_message := 'The buyer cancelled their offer of ₹' || NEW.offered_price || ' for ' || v_produce_name || '.';
        end if;
        v_type := 'offer_cancelled';
        v_title := 'Offer Cancelled';

      end if;

    elsif OLD.status = 'pending' and NEW.status = 'pending' then
      if OLD.offered_price is distinct from NEW.offered_price
         or OLD.quantity is distinct from NEW.quantity
         or OLD.message is distinct from NEW.message then

        v_recipient_id := NEW.farmer_id;
        v_type := 'offer_updated';
        v_title := 'Offer Updated';
        v_message := 'The offer for ' || v_produce_name || ' was updated to ₹' || NEW.offered_price || ' (' || NEW.quantity || ' units).';
      end if;
    end if;
  end if;

  if v_recipient_id is not null then
    if v_actor_id is not null and v_recipient_id = v_actor_id then
      if v_actor_id = NEW.buyer_id then
        v_recipient_id := NEW.farmer_id;
      elsif v_actor_id = NEW.farmer_id then
        v_recipient_id := NEW.buyer_id;
      end if;
    end if;

    if v_actor_id is null or v_recipient_id <> v_actor_id then
      if not exists (
        select 1 from public.notifications
        where user_id = v_recipient_id
          and related_id = NEW.id
          and type = v_type
          and created_at > (now() - interval '5 seconds')
      ) then
        insert into public.notifications (user_id, type, title, message, related_id, related_type, is_read)
        values (v_recipient_id, v_type, v_title, v_message, NEW.id, 'offer', false);
      end if;
    end if;
  end if;

  return NEW;
end;
$$;

create trigger tr_offer_notification
  after insert or update on public.offers
  for each row execute function public.handle_offer_notification();
