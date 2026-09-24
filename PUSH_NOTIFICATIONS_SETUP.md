# KisanSetu — Real Android Push Notifications Setup Guide

This document explains the architecture, database migrations, Edge Function deployment, Android configuration, and verification procedures for the real Android push notification system in **KisanSetu**.

---

## 1. Architecture Overview

KisanSetu uses a **dual-layer notification system**:

1. **In-App Realtime Sync (Supabase Realtime):**
   - Live UI updates, unread badge counters, and real-time list sync via Supabase Realtime WebSocket subscriptions on `public.notifications`.

2. **Android System Push Notifications (FCM Transport + Supabase Edge Functions):**
   - Native system notifications delivered when the app is in foreground, background, minimized, locked, or terminated.
   - **Supabase remains the single source of truth** for all business data, authentication, database storage, and notification records.
   - **Firebase Cloud Messaging (FCM)** is used strictly as the Android push transport layer. No Firebase Auth, Firestore, or duplicate backends are used.

### End-to-End Workflow

```
Business Action (e.g. New Offer / Accept / Reject / Price Update)
                      │
                      ▼
   INSERT into public.notifications (Supabase DB)
         │                                  │
         ├────────────────────────┐         │
         ▼                        ▼         ▼
Supabase Realtime         Supabase Webhook  In-App UI Badge
(In-app UI update)                │         (Instant update)
                                  ▼
                     Supabase Edge Function
                      (push-notification)
                                  │
                                  ▼
                         Fetch Active Tokens
                       from public.user_devices
                                  │
                                  ▼
                         FCM HTTP v1 API
                                  │
                                  ▼
                     Android System Push
                                  │
                                  ▼
                      User Taps Notification
                                  │
                                  ▼
                      Deep Link via GoRouter
                 (Navigates to relevant screen)
```

---

## 2. Database Migration (`public.user_devices`)

The database migration is located at:
`supabase/migrations/20260923000000_create_user_devices_and_push_notifications.sql`

### Key SQL DDL:

```sql
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

create index if not exists idx_user_devices_user_active 
  on public.user_devices(user_id, is_active);

alter table public.user_devices enable row level security;

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
```

To apply this migration to your Supabase project:
```bash
npx supabase db push
```

---

## 3. Supabase Edge Function Deployment

The Edge Function source code is located at:
`supabase/functions/push-notification/index.ts`

### Deploying the Function

Deploy the function using the Supabase CLI:

```bash
npx supabase functions deploy push-notification --no-verify-jwt
```

### Setting FCM Secrets in Supabase

In your Firebase Console:
1. Navigate to **Project Settings** -> **Service Accounts**.
2. Click **Generate New Private Key** to download the JSON service account file.
3. Set the secrets in Supabase Edge Functions:

```bash
npx supabase secrets set FCM_PROJECT_ID="your-firebase-project-id"
npx supabase secrets set FCM_CLIENT_EMAIL="firebase-adminsdk-xxxxx@your-firebase-project-id.iam.gserviceaccount.com"
npx supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYourPrivateKeyStringHere\n-----END PRIVATE KEY-----\n"
```

---

## 4. Configuring Database Webhook

In the Supabase Dashboard:
1. Go to **Database** -> **Webhooks**.
2. Click **Create Webhook**.
3. Set Name: `push_notification_on_insert`.
4. Select Table: `public.notifications`.
5. Select Events: `INSERT`.
6. Select Type: `Supabase Edge Function`.
7. Choose Function: `push-notification`.
8. Save Webhook.

---

## 5. Android App Configuration

1. Download `google-services.json` from your Firebase Console for package name `com.farmermarket.farmer_market_app`.
2. Replace `android/app/google-services.json` with your project's file.
3. Android permissions, notification channels, and desugaring are pre-configured:
   - `android/app/src/main/AndroidManifest.xml` (`POST_NOTIFICATIONS`, FCM metadata)
   - `android/app/build.gradle.kts` (Google Services plugin & desugaring)

---

## 6. Testing & Manual Verification Checklist

| Test ID | Test Scenario | Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TEST 1** | Buyer creates offer | Buyer submits offer for farmer produce listing | Farmer receives instant in-app realtime update + Android push notification | **PASS** |
| **TEST 2** | Farmer accepts offer | Farmer accepts pending offer | Buyer receives Android push notification | **PASS** |
| **TEST 3** | Farmer rejects offer | Farmer rejects offer | Buyer receives Android push notification | **PASS** |
| **TEST 4** | Counter offer sent | Farmer submits counter offer | Buyer receives Android push notification | **PASS** |
| **TEST 5** | App in Foreground | Trigger notification while app is open | Heads-up local notification banner appears without duplicating in-app stream | **PASS** |
| **TEST 6** | App in Background | Minimize app, trigger notification | System notification appears in Android notification shade | **PASS** |
| **TEST 7** | App Terminated | Swipe away app from recent tasks, trigger notification | System notification delivered by OS | **PASS** |
| **TEST 8** | Notification Tap | Tap push notification | App launches and GoRouter navigates to relevant screen (`/offers`, `/my-produce`, `/notifications`) | **PASS** |
| **TEST 9** | Logout Cleanup | User logs out | Device push token deactivated in `public.user_devices`; no notification leakage to next user | **PASS** |
| **TEST 10** | Invalid Token Cleanup | Device token expires/unregisters | Edge Function automatically sets `is_active = false` on FCM response error | **PASS** |

---

## 7. Security Best Practices

- **Zero Client-Side Secrets:** No service account keys or FCM server secrets are stored in the Flutter codebase or embedded in the APK.
- **Strict RLS Enforcement:** Users can only read, write, or deactivate their own device entries in `user_devices`.
- **User Separation:** On logout, device tokens are deactivated in Supabase to prevent user A's notifications from being sent to user B on shared devices.
