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

-- ====================================================================
-- 2. Automatic Notification Trigger on public.offers
-- Automatically inserts rows into public.notifications on offer lifecycle events
-- ====================================================================
create or replace function public.handle_offer_notification()
returns trigger as $$
declare
  produce_name text;
begin
  select name into produce_name from public.produce where id = NEW.produce_id;
  if produce_name is null then
    produce_name := 'your crop listing';
  end if;

  if (TG_OP = 'INSERT') then
    -- New offer submitted by buyer -> notify farmer
    insert into public.notifications (
      user_id,
      type,
      title,
      message,
      related_id,
      related_type,
      is_read
    ) values (
      NEW.farmer_id,
      'new_offer',
      'New Offer Received',
      'You received a new offer of ₹' || NEW.offered_price || ' for ' || produce_name || '.',
      NEW.id,
      'offer',
      false
    );
  elsif (TG_OP = 'UPDATE' and OLD.status <> NEW.status) then
    if (NEW.status = 'accepted') then
      -- Offer accepted by farmer -> notify buyer
      insert into public.notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        related_type,
        is_read
      ) values (
        NEW.buyer_id,
        'offer_accepted',
        'Offer Accepted',
        'Your offer of ₹' || NEW.offered_price || ' for ' || produce_name || ' was accepted!',
        NEW.id,
        'offer',
        false
      );
    elsif (NEW.status = 'rejected') then
      -- Offer rejected by farmer -> notify buyer
      insert into public.notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        related_type,
        is_read
      ) values (
        NEW.buyer_id,
        'offer_rejected',
        'Offer Declined',
        'Your offer for ' || produce_name || ' was declined.',
        NEW.id,
        'offer',
        false
      );
    elsif (NEW.status = 'countered') then
      -- Counter offer sent by farmer -> notify buyer
      insert into public.notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        related_type,
        is_read
      ) values (
        NEW.buyer_id,
        'counter_offer',
        'Counter Offer Received',
        'Farmer sent a counter offer for ' || produce_name || '.',
        NEW.id,
        'offer',
        false
      );
    end if;
  end if;
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists tr_offer_notification on public.offers;
create trigger tr_offer_notification
  after insert or update on public.offers
  for each row execute function public.handle_offer_notification();

-- ====================================================================
-- 3. Database Webhook Configuration Guide:
-- ====================================================================
-- Enable a Supabase Database Webhook in the Supabase Dashboard:
-- 1. Go to Database -> Webhooks -> Add Webhook
-- 2. Name: push_notification_on_insert
-- 3. Table: public.notifications
-- 4. Events: INSERT
-- 5. Webhook type: Supabase Edge Function
-- 6. Select Edge Function: push-notification
