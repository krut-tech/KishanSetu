-- KisanSetu chat and opt-in map coordinates
create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null references public.profiles(id) on delete cascade,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  produce_id uuid references public.produce(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chat_conversations_distinct_users check (farmer_id <> buyer_id)
);
create unique index if not exists chat_conversations_pair_produce_unique
  on public.chat_conversations (farmer_id, buyer_id, coalesce(produce_id, '00000000-0000-0000-0000-000000000000'::uuid));
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 4000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index if not exists chat_messages_conversation_created_idx on public.chat_messages(conversation_id, created_at);

alter table public.profiles add column if not exists latitude double precision;
alter table public.profiles add column if not exists longitude double precision;
alter table public.profiles drop constraint if exists profiles_coordinates_pair_check;
alter table public.profiles add constraint profiles_coordinates_pair_check check (
  (latitude is null and longitude is null) or
  (latitude between -90 and 90 and longitude between -180 and 180)
);

alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "Participants can view conversations" on public.chat_conversations;
create policy "Participants can view conversations" on public.chat_conversations
  for select to authenticated using (auth.uid() = farmer_id or auth.uid() = buyer_id);

drop policy if exists "Buyers can start chats with farmers" on public.chat_conversations;
create policy "Buyers can start chats with farmers" on public.chat_conversations
  for insert to authenticated with check (
    auth.uid() = buyer_id
    and exists (select 1 from public.profiles p where p.id = farmer_id and p.role = 'farmer')
    and exists (select 1 from public.profiles p where p.id = buyer_id and p.role = 'buyer')
  );

drop policy if exists "Participants can read chat messages" on public.chat_messages;
create policy "Participants can read chat messages" on public.chat_messages
  for select to authenticated using (
    exists (select 1 from public.chat_conversations c
      where c.id = conversation_id and auth.uid() in (c.farmer_id, c.buyer_id))
  );

drop policy if exists "Participants can send chat messages" on public.chat_messages;
create policy "Participants can send chat messages" on public.chat_messages
  for insert to authenticated with check (
    sender_id = auth.uid()
    and exists (select 1 from public.chat_conversations c
      where c.id = conversation_id and auth.uid() in (c.farmer_id, c.buyer_id))
  );

drop policy if exists "Participants can mark incoming messages read" on public.chat_messages;
create policy "Participants can mark incoming messages read" on public.chat_messages
  for update to authenticated using (
    sender_id <> auth.uid()
    and exists (select 1 from public.chat_conversations c
      where c.id = conversation_id and auth.uid() in (c.farmer_id, c.buyer_id))
  ) with check (
    sender_id <> auth.uid()
    and exists (select 1 from public.chat_conversations c
      where c.id = conversation_id and auth.uid() in (c.farmer_id, c.buyer_id))
  );

-- Add the chat message table to Supabase Realtime when publication exists.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'chat_messages'
     ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end $$;

-- Atomic conversation creation. The RPC verifies both roles and that the caller
-- is one of the participants; security-definer access is narrowly scoped.
create or replace function public.get_or_create_chat_conversation(
  p_farmer_id uuid,
  p_buyer_id uuid,
  p_produce_id uuid default null
)
returns public.chat_conversations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_conversation public.chat_conversations;
begin
  if v_uid is null or v_uid not in (p_farmer_id, p_buyer_id) then
    raise exception 'Not authorized to open this conversation' using errcode = '42501';
  end if;

  if p_farmer_id = p_buyer_id
     or not exists (select 1 from public.profiles where id = p_farmer_id and role = 'farmer')
     or not exists (select 1 from public.profiles where id = p_buyer_id and role = 'buyer') then
    raise exception 'Invalid farmer/buyer pair' using errcode = '22023';
  end if;

  insert into public.chat_conversations(farmer_id, buyer_id, produce_id)
  values (p_farmer_id, p_buyer_id, p_produce_id)
  on conflict (farmer_id, buyer_id, (coalesce(produce_id, '00000000-0000-0000-0000-000000000000'::uuid)))
  do update set updated_at = public.chat_conversations.updated_at
  returning * into v_conversation;

  return v_conversation;
end;
$$;

revoke all on function public.get_or_create_chat_conversation(uuid, uuid, uuid) from public, anon;
grant execute on function public.get_or_create_chat_conversation(uuid, uuid, uuid) to authenticated;

revoke all on function public.get_or_create_chat_conversation(uuid, uuid, uuid) from anon;

-- Enforce the participant relationship for both existing and new message rows.
create or replace function public.chat_message_participant_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.chat_conversations c
    where c.id = new.conversation_id
      and auth.uid() in (c.farmer_id, c.buyer_id)
  ) then
    raise exception 'Only conversation participants may modify messages' using errcode = '42501';
  end if;

  if tg_op = 'INSERT' and new.sender_id <> auth.uid() then
    raise exception 'Sender must be the authenticated user' using errcode = '42501';
  end if;

  if tg_op = 'UPDATE' then
    if old.sender_id <> new.sender_id
      or old.conversation_id <> new.conversation_id
      or old.body <> new.body
      or old.created_at <> new.created_at
      or old.id <> new.id then
      raise exception 'Messages cannot be edited through this endpoint' using errcode = '42501';
    end if;
    if new.read_at is distinct from old.read_at and old.sender_id = auth.uid() then
      raise exception 'A sender cannot mark their own message as read' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists chat_message_participant_guard on public.chat_messages;
create trigger chat_message_participant_guard
before insert or update on public.chat_messages
for each row execute function public.chat_message_participant_guard();

revoke all on function public.chat_message_participant_guard() from public, anon, authenticated;

-- Keep inbox ordering fresh after each message, without granting clients
-- broad UPDATE access to conversation rows.
create or replace function public.touch_chat_conversation_after_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $
begin
  update public.chat_conversations
    set updated_at = new.created_at
    where id = new.conversation_id;
  return new;
end;
$;

revoke all on function public.touch_chat_conversation_after_message() from public, anon, authenticated;
drop trigger if exists chat_message_touch_conversation on public.chat_messages;
create trigger chat_message_touch_conversation
after insert on public.chat_messages
for each row execute function public.touch_chat_conversation_after_message();
