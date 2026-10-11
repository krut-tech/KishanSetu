-- Per-user chat clearing/deleting and incoming chat notifications.
create table if not exists public.chat_conversation_user_state (
  user_id uuid not null references public.profiles(id) on delete cascade,
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  cleared_at timestamptz,
  deleted_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, conversation_id)
);
alter table public.chat_conversation_user_state enable row level security;
drop policy if exists "Users read their own chat state" on public.chat_conversation_user_state;
create policy "Users read their own chat state"
  on public.chat_conversation_user_state for select to authenticated
  using (auth.uid() = user_id);

create or replace function public.clear_chat_for_me(p_conversation_id uuid)
returns timestamptz
language plpgsql security definer set search_path = public
as $$
declare v_uid uuid := auth.uid(); v_now timestamptz := now();
begin
  if v_uid is null or not exists (
    select 1 from public.chat_conversations c
    where c.id = p_conversation_id and v_uid in (c.farmer_id, c.buyer_id)
  ) then raise exception 'Not authorized to clear this chat' using errcode = '42501'; end if;
  insert into public.chat_conversation_user_state(user_id, conversation_id, cleared_at, deleted_at, updated_at)
  values (v_uid, p_conversation_id, v_now, null, v_now)
  on conflict (user_id, conversation_id) do update
    set cleared_at = excluded.cleared_at, deleted_at = null, updated_at = excluded.updated_at;
  return v_now;
end;
$$;
revoke all on function public.clear_chat_for_me(uuid) from public, anon;
grant execute on function public.clear_chat_for_me(uuid) to authenticated;

create or replace function public.delete_chat_for_me(p_conversation_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_uid uuid := auth.uid(); v_now timestamptz := now();
begin
  if v_uid is null or not exists (
    select 1 from public.chat_conversations c
    where c.id = p_conversation_id and v_uid in (c.farmer_id, c.buyer_id)
  ) then raise exception 'Not authorized to delete this chat' using errcode = '42501'; end if;
  insert into public.chat_conversation_user_state(user_id, conversation_id, deleted_at, updated_at)
  values (v_uid, p_conversation_id, v_now, v_now)
  on conflict (user_id, conversation_id) do update
    set deleted_at = excluded.deleted_at, updated_at = excluded.updated_at;
end;
$$;
revoke all on function public.delete_chat_for_me(uuid) from public, anon;
grant execute on function public.delete_chat_for_me(uuid) to authenticated;

-- Keep one chat row per other participant; hide deleted chats until a new message arrives.
create or replace function public.list_my_chat_conversations()
returns table (
  conversation_id uuid, farmer_id uuid, buyer_id uuid, produce_id uuid,
  other_user_id uuid, other_user_name text, other_user_role text,
  other_user_avatar text, other_user_district text, last_message text,
  last_message_at timestamptz, last_message_sender_id uuid, unread_count bigint
)
language sql security definer stable set search_path = public
as $$
  select c.id, c.farmer_id, c.buyer_id, c.produce_id,
    case when auth.uid() = c.farmer_id then c.buyer_id else c.farmer_id end,
    p.full_name, p.role, p.avatar_url, p.district,
    lm.body, lm.created_at, lm.sender_id, coalesce(uc.unread_count, 0)
  from public.chat_conversations c
  join public.profiles p on p.id = (case when auth.uid() = c.farmer_id then c.buyer_id else c.farmer_id end)
  left join public.chat_conversation_user_state s
    on s.conversation_id = c.id and s.user_id = auth.uid()
  left join lateral (
    select m.body, m.created_at, m.sender_id from public.chat_messages m
    where m.conversation_id = c.id and (s.cleared_at is null or m.created_at > s.cleared_at)
    order by m.created_at desc, m.id desc limit 1
  ) lm on true
  left join lateral (
    select count(*) as unread_count from public.chat_messages m
    where m.conversation_id = c.id and m.sender_id <> auth.uid() and m.read_at is null
      and (s.cleared_at is null or m.created_at > s.cleared_at)
  ) uc on true
  where auth.uid() in (c.farmer_id, c.buyer_id)
    and (s.deleted_at is null or coalesce(lm.created_at, c.updated_at) > s.deleted_at)
  order by coalesce(lm.created_at, c.updated_at) asc, c.id asc;
$$;
revoke all on function public.list_my_chat_conversations() from public, anon;
grant execute on function public.list_my_chat_conversations() to authenticated;

-- Notify the other participant when a new message is stored. Existing
-- notifications webhook delivers this to registered FCM devices.
create or replace function public.notify_chat_message_recipient()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare v_recipient uuid;
begin
  select case when new.sender_id = c.farmer_id then c.buyer_id else c.farmer_id end
    into v_recipient
  from public.chat_conversations c where c.id = new.conversation_id;
  if v_recipient is null or v_recipient = new.sender_id then return new; end if;
  insert into public.notifications(user_id, type, title, message, related_id, related_type, is_read)
  values (v_recipient, 'chat_message', 'New message', left(new.body, 180),
          new.conversation_id, 'chat_conversation', false);
  return new;
end;
$$;
drop trigger if exists tr_notify_chat_message_recipient on public.chat_messages;
create trigger tr_notify_chat_message_recipient
after insert on public.chat_messages
for each row execute function public.notify_chat_message_recipient();
revoke all on function public.notify_chat_message_recipient() from public, anon, authenticated;
