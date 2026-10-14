-- Documents the Trust & Safety / Admin Panel schema that already exists on the
-- live project (kyc_documents, disputes, profiles.is_admin, produce moderation
-- columns, and the admin_* RPC functions), which was applied directly to
-- Supabase without a committed migration. Written idempotently (IF NOT EXISTS /
-- CREATE OR REPLACE) so running it against a fresh project reproduces the same
-- state, and running it again against the live project is a safe no-op.
-- Also adds admin_get_dashboard_stats(), which powers the new Analytics tab.

-- ---------------------------------------------------------------------------
-- 1) profiles: admin flag + account status (already present on produce/ profiles)
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists is_admin boolean not null default false;

alter table public.profiles
  add column if not exists account_status text not null default 'active';

alter table public.profiles
  add column if not exists kyc_status text not null default 'unverified';

-- ---------------------------------------------------------------------------
-- 2) produce: moderation columns
-- ---------------------------------------------------------------------------
alter table public.produce
  add column if not exists moderation_status text not null default 'approved';

alter table public.produce
  add column if not exists moderation_note text;

-- ---------------------------------------------------------------------------
-- 3) kyc_documents table
-- ---------------------------------------------------------------------------
create table if not exists public.kyc_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null,
  document_number text not null,
  document_url text not null,
  status text not null default 'pending',
  rejection_reason text,
  submitted_at timestamptz not null default timezone('utc'::text, now()),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id)
);

create index if not exists idx_kyc_documents_user_id on public.kyc_documents (user_id);
create index if not exists idx_kyc_documents_status on public.kyc_documents (status);

alter table public.kyc_documents enable row level security;

drop policy if exists "User can submit own KYC documents" on public.kyc_documents;
create policy "User can submit own KYC documents" on public.kyc_documents
  for insert
  with check (user_id = (select auth.uid()));

drop policy if exists "User can read own KYC documents" on public.kyc_documents;
create policy "User can read own KYC documents" on public.kyc_documents
  for select
  using (user_id = (select auth.uid()) or public.is_admin_user());

drop policy if exists "Admin can review KYC documents" on public.kyc_documents;
create policy "Admin can review KYC documents" on public.kyc_documents
  for update
  using (public.is_admin_user())
  with check (public.is_admin_user());

-- ---------------------------------------------------------------------------
-- 4) disputes table
-- ---------------------------------------------------------------------------
create table if not exists public.disputes (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid references public.profiles(id),
  related_order_id uuid,
  related_offer_id uuid,
  type text not null,
  description text not null,
  status text not null default 'open',
  resolution_note text,
  created_at timestamptz not null default timezone('utc'::text, now()),
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id)
);

create index if not exists idx_disputes_status on public.disputes (status);
create index if not exists idx_disputes_reporter_id on public.disputes (reporter_id);
create index if not exists idx_disputes_reported_user_id on public.disputes (reported_user_id);

alter table public.disputes enable row level security;

drop policy if exists "Any authenticated user can file a dispute" on public.disputes;
create policy "Any authenticated user can file a dispute" on public.disputes
  for insert
  with check (reporter_id = (select auth.uid()));

drop policy if exists "Reporter, reported user, or admin can read a dispute" on public.disputes;
create policy "Reporter, reported user, or admin can read a dispute" on public.disputes
  for select
  using (
    reporter_id = (select auth.uid())
    or reported_user_id = (select auth.uid())
    or public.is_admin_user()
  );

drop policy if exists "Admin can update a dispute" on public.disputes;
create policy "Admin can update a dispute" on public.disputes
  for update
  using (public.is_admin_user())
  with check (public.is_admin_user());

-- ---------------------------------------------------------------------------
-- 5) is_admin_user(): single source of truth for "is the caller an admin"
-- ---------------------------------------------------------------------------
create or replace function public.is_admin_user()
returns boolean
language sql
stable security definer
set search_path to 'public'
as $function$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$function$;

-- ---------------------------------------------------------------------------
-- 6) Admin RPCs: account status, KYC review, listing moderation, disputes
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_account_status(p_user_id uuid, p_status text, p_reason text default null::text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin_user() then
    raise exception 'Only an admin can change account status.';
  end if;
  if p_status not in ('active','suspended','banned') then
    raise exception 'Invalid account status.';
  end if;

  update public.profiles set account_status = p_status where id = p_user_id;

  insert into public.notifications (user_id, type, title, message, related_id, related_type, is_read)
  values (
    p_user_id, 'account_status_changed', 'Account Status Updated',
    'Your account status was changed to ' || p_status || coalesce('. Reason: ' || p_reason, '.'),
    p_user_id, 'profile', false
  );
end;
$function$;

create or replace function public.admin_review_kyc(p_document_id uuid, p_status text, p_rejection_reason text default null::text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid;
  v_title text;
  v_message text;
begin
  if not public.is_admin_user() then
    raise exception 'Only an admin can review KYC documents.';
  end if;
  if p_status not in ('verified','rejected') then
    raise exception 'Invalid KYC review status.';
  end if;

  update public.kyc_documents
  set status = p_status, rejection_reason = p_rejection_reason,
      reviewed_at = timezone('utc'::text, now()), reviewed_by = auth.uid()
  where id = p_document_id
  returning user_id into v_user_id;

  update public.profiles
  set kyc_status = p_status, kyc_verified_at = timezone('utc'::text, now())
  where id = v_user_id;

  if p_status = 'verified' then
    v_title := 'KYC Verified';
    v_message := 'Your identity verification was approved.';
  else
    v_title := 'KYC Rejected';
    v_message := 'Your identity verification was rejected.' || coalesce(' Reason: ' || p_rejection_reason, '');
  end if;

  insert into public.notifications (user_id, type, title, message, related_id, related_type, is_read)
  values (v_user_id, 'kyc_reviewed', v_title, v_message, p_document_id, 'kyc_document', false);
end;
$function$;

create or replace function public.admin_moderate_produce(p_produce_id uuid, p_status text, p_note text default null::text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_farmer_id uuid;
begin
  if not public.is_admin_user() then
    raise exception 'Only an admin can moderate listings.';
  end if;
  if p_status not in ('approved','flagged','removed') then
    raise exception 'Invalid moderation status.';
  end if;

  update public.produce
  set moderation_status = p_status, moderation_note = p_note
  where id = p_produce_id
  returning farmer_id into v_farmer_id;

  insert into public.notifications (user_id, type, title, message, related_id, related_type, is_read)
  values (
    v_farmer_id, 'listing_moderated', 'Listing Moderation Update',
    'Your listing was marked as ' || p_status || coalesce('. Note: ' || p_note, '.'),
    p_produce_id, 'produce', false
  );
end;
$function$;

create or replace function public.admin_resolve_dispute(p_dispute_id uuid, p_status text, p_resolution_note text default null::text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_reporter_id uuid;
begin
  if not public.is_admin_user() then
    raise exception 'Only an admin can resolve disputes.';
  end if;
  if p_status not in ('investigating','resolved','dismissed') then
    raise exception 'Invalid dispute status.';
  end if;

  update public.disputes
  set status = p_status, resolution_note = p_resolution_note,
      resolved_at = case when p_status in ('resolved','dismissed') then timezone('utc'::text, now()) else resolved_at end,
      resolved_by = auth.uid()
  where id = p_dispute_id
  returning reporter_id into v_reporter_id;

  insert into public.notifications (user_id, type, title, message, related_id, related_type, is_read)
  values (
    v_reporter_id, 'dispute_updated', 'Dispute Update',
    'Your report status is now: ' || p_status || coalesce('. ' || p_resolution_note, ''),
    p_dispute_id, 'dispute', false
  );
end;
$function$;

-- ---------------------------------------------------------------------------
-- 7) admin_get_dashboard_stats(): new - powers the Admin Panel's Analytics tab
-- ---------------------------------------------------------------------------
create or replace function public.admin_get_dashboard_stats()
returns table (
  total_users bigint,
  total_farmers bigint,
  total_buyers bigint,
  active_listings bigint,
  flagged_listings bigint,
  removed_listings bigint,
  pending_kyc bigint,
  verified_kyc bigint,
  rejected_kyc bigint,
  open_disputes bigint,
  resolved_disputes bigint,
  suspended_accounts bigint,
  banned_accounts bigint,
  pending_offers bigint,
  accepted_offers bigint,
  rejected_offers bigint,
  cancelled_offers bigint
)
language plpgsql
security definer
stable
set search_path to 'public'
as $function$
begin
  if not public.is_admin_user() then
    raise exception 'Only an admin can view dashboard stats.';
  end if;

  return query
  select
    (select count(*) from public.profiles),
    (select count(*) from public.profiles where role = 'farmer'),
    (select count(*) from public.profiles where role = 'buyer'),
    (select count(*) from public.produce where moderation_status = 'approved'),
    (select count(*) from public.produce where moderation_status = 'flagged'),
    (select count(*) from public.produce where moderation_status = 'removed'),
    (select count(*) from public.kyc_documents where status = 'pending'),
    (select count(*) from public.kyc_documents where status = 'verified'),
    (select count(*) from public.kyc_documents where status = 'rejected'),
    (select count(*) from public.disputes where status in ('open','investigating')),
    (select count(*) from public.disputes where status in ('resolved','dismissed')),
    (select count(*) from public.profiles where account_status = 'suspended'),
    (select count(*) from public.profiles where account_status = 'banned'),
    (select count(*) from public.offers where status = 'pending'),
    (select count(*) from public.offers where status = 'accepted'),
    (select count(*) from public.offers where status = 'rejected'),
    (select count(*) from public.offers where status in ('cancelled','canceled'));
end;
$function$;

revoke all on function public.admin_get_dashboard_stats() from public;
grant execute on function public.admin_get_dashboard_stats() to authenticated;
