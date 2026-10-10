-- KisanSetu direct buyer-farmer chat and coordinates
create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null references public.profiles(id) on delete cascade,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  produce_id uuid references public.produce(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chat_conversations_unique_pair_produce unique (farmer_id, buyer_id, produce_id),
  constraint chat_conversations_distinct_users check (farmer_id <> buyer_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 4000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists chat_messages_conversation_created_idx
  on public.chat_messages(conversation_id, created_at);

alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "Participants can view conversations" on public.chat_conversations;
create policy "Participants can view conversations"
  on public.chat_conversations for select to authenticated
  using (auth.uid() = farmer_id or auth.uid() = buyer_id);

drop policy if exists "Buyers can start chats with farmers" on public.chat_conversations;
create policy "Buyers can start chats with farmers"
  on public.chat_conversations for insert to authenticated
  with check (
    auth.uid() = buyer_id
    and exists (
      select 1 from public.profiles p
      where p.id = farmer_id and p.role = 'farmer'
    )
    and exists (
      select 1 from public.profiles p
      where p.id = buyer_id and p.role = 'buyer'
    )
  );

drop policy if exists "Participants can read chat messages" on public.chat_messages;
create policy "Participants can read chat messages"
  on public.chat_messages for select to authenticated
  using (
    exists (
      select 1 from public.chat_conversations c
      where c.id = conversation_id
        and auth.uid() in (c.farmer_id, c.buyer_id)
    )
  );

drop policy if exists "Participants can send chat messages" on public.chat_messages;
create policy "Participants can send chat messages"
  on public.chat_messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.chat_conversations c
      where c.id = conversation_id
        and auth.uid() in (c.farmer_id, c.buyer_id)
    )
  );

drop policy if exists "Participants can mark incoming messages read" on public.chat_messages;
create policy "Participants can mark incoming messages read"
  on public.chat_messages for update to authenticated
  using (
    sender_id <> auth.uid()
    and exists (
      select 1 from public.chat_conversations c
      where c.id = conversation_id
        and auth.uid() in (c.farmer_id, c.buyer_id)
    )
  )
  with check (
    sender_id <> auth.uid()
    and exists (
      select 1 from public.chat_conversations c
      where c.id = conversation_id
        and auth.uid() in (c.farmer_id, c.buyer_id)
    )
  );

-- Coordinate precision is only for map links in this feature. Users opt into
-- sharing location by selecting a point; don't silently track live location.
alter table public.profiles add column if not exists latitude double precision;
alter table public.profiles add column if not exists longitude double precision;
alter table public.profiles drop constraint if exists profiles_coordinates_pair_check;
alter table public.profiles add constraint profiles_coordinates_pair_check
  check (
    (latitude is null and longitude is null)
    or (latitude between -90 and 90 and longitude between -180 and 180)
  );

do $$
begin
  alter publication supabase_realtime add table public.chat_messages;
exception when duplicate_object then null;
         when undefined_object then null;
end $$;
