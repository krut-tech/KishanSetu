-- Chat threads must be identified by the (farmer, buyer) pair only, not by
-- the produce item the chat was opened from. Keying on produce_id meant the
-- same two people got a brand-new conversation every time they chatted about
-- a different listing, which showed up in the UI as "duplicate" chats / the
-- same person appearing twice in the chat list.

-- 1) Merge any existing duplicate conversations for the same farmer/buyer
--    pair into the earliest one, moving all messages across first.
with ranked as (
  select id, farmer_id, buyer_id,
         row_number() over (partition by farmer_id, buyer_id order by created_at asc) as rn
  from public.chat_conversations
),
keepers as (
  select r1.id as keep_id, r2.id as dupe_id
  from ranked r1
  join ranked r2
    on r1.farmer_id = r2.farmer_id and r1.buyer_id = r2.buyer_id and r1.rn = 1 and r2.rn > 1
)
update public.chat_messages m
set conversation_id = k.keep_id
from keepers k
where m.conversation_id = k.dupe_id;

with ranked as (
  select id, farmer_id, buyer_id,
         row_number() over (partition by farmer_id, buyer_id order by created_at asc) as rn
  from public.chat_conversations
)
delete from public.chat_conversations c
using ranked r
where c.id = r.id and r.rn > 1;

-- 2) Add a per-person unique index (the old per-produce one is left in place
--    for backward compatibility - it is now always satisfied automatically
--    since each pair has a single row - and can be dropped in a follow-up).
create unique index if not exists chat_conversations_pair_unique
  on public.chat_conversations (farmer_id, buyer_id);

-- 3) Update the RPC so create-or-reuse keys off the farmer/buyer pair only.
--    produce_id is kept as "what we were last talking about" and refreshed
--    whenever a new chat is opened from a different produce listing.
create or replace function public.get_or_create_chat_conversation(
  p_farmer_id uuid, p_buyer_id uuid, p_produce_id uuid default null::uuid
)
returns public.chat_conversations
language plpgsql
security definer
set search_path to 'public'
as $function$
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
  on conflict (farmer_id, buyer_id)
  do update set
    produce_id = coalesce(excluded.produce_id, public.chat_conversations.produce_id),
    updated_at = now()
  returning * into v_conversation;

  return v_conversation;
end;
$function$;

-- 4) Chat list helper: one round trip returns each conversation already
--    joined to the other participant's profile, the last message preview,
--    and the unread count - powers a WhatsApp-style chat list without an
--    extra query per row. Oldest activity first (ascending), per product
--    requirement.
create or replace function public.list_my_chat_conversations()
returns table (
  conversation_id uuid,
  farmer_id uuid,
  buyer_id uuid,
  produce_id uuid,
  other_user_id uuid,
  other_user_name text,
  other_user_role text,
  other_user_avatar text,
  other_user_district text,
  last_message text,
  last_message_at timestamptz,
  last_message_sender_id uuid,
  unread_count bigint
)
language sql
security definer
stable
set search_path to 'public'
as $function$
  select
    c.id as conversation_id,
    c.farmer_id,
    c.buyer_id,
    c.produce_id,
    case when auth.uid() = c.farmer_id then c.buyer_id else c.farmer_id end as other_user_id,
    p.full_name as other_user_name,
    p.role as other_user_role,
    p.avatar_url as other_user_avatar,
    p.district as other_user_district,
    lm.body as last_message,
    lm.created_at as last_message_at,
    lm.sender_id as last_message_sender_id,
    coalesce(uc.unread_count, 0) as unread_count
  from public.chat_conversations c
  join public.profiles p
    on p.id = (case when auth.uid() = c.farmer_id then c.buyer_id else c.farmer_id end)
  left join lateral (
    select body, created_at, sender_id
    from public.chat_messages m
    where m.conversation_id = c.id
    order by m.created_at desc
    limit 1
  ) lm on true
  left join lateral (
    select count(*) as unread_count
    from public.chat_messages m
    where m.conversation_id = c.id
      and m.sender_id <> auth.uid()
      and m.read_at is null
  ) uc on true
  where auth.uid() in (c.farmer_id, c.buyer_id)
  order by coalesce(lm.created_at, c.updated_at) asc;
$function$;

revoke all on function public.list_my_chat_conversations() from public;
grant execute on function public.list_my_chat_conversations() to authenticated;
