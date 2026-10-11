-- Update list_my_chat_conversations to sort chronologically: older chats first, newer chats last.
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
