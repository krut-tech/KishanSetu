# KisanSetu

**Farmer Market Linkage & Price Discovery**

KisanSetu is a Flutter application that connects farmers and agricultural buyers through produce listings, market-price discovery, and offer workflows. The app uses Supabase Auth/Postgres/Realtime as its backend and Riverpod + GoRouter for application state and navigation.

## Problem statement

Farmers and buyers often work with fragmented market information and disconnected procurement channels. KisanSetu provides a single mobile workflow for:

- Farmer produce listing and management
- Buyer marketplace discovery
- Market-price visibility
- Direct buyer offers and farmer responses
- Role-aware onboarding and profile completion
- English, Hindi, and Gujarati localization
- Light and dark themes

## Features

### Farmer

- Dashboard with produce, offer, and market-price summaries
- Add and manage produce listings
- Search and status filtering
- Market-price discovery
- Incoming offer management
- Realtime dashboard refreshes

### Buyer

- Marketplace with search, category/location filters, price filters, and sorting
- Produce detail views
- Offer creation with quantity/price validation
- Buyer offer tracking and cancellation
- Realtime offer refreshes

### Authentication

- Email/password sign-up and login
- Forgot-password flow
- Supabase session restore
- Google OAuth
- Role-aware onboarding for Farmer/Buyer
- Profile completion before protected dashboards
- Protected GoRouter navigation

Google OAuth uses a mobile deep-link callback. Configure the same redirect URI in the Supabase Auth URL configuration and Google OAuth client configuration before testing OAuth.

## Technology stack

| Area | Technology |
|---|---|
| UI | Flutter / Material 3 |
| Language | Dart |
| State | Riverpod |
| Navigation | GoRouter |
| Backend | Supabase |
| Database | PostgreSQL |
| Auth | Supabase Auth |
| Realtime | Supabase Realtime |
| Localization | Flutter intl / ARB |
| Environment | flutter_dotenv |
| Logging | logger |
| Functional results | fpdart |
| Models | Equatable |

## Architecture

The codebase follows a feature-first structure with shared core infrastructure:

```
lib/
├── core/
│   ├── bootstrap/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── localization/
│   ├── logging/
│   ├── network/
│   ├── routing/
│   ├── theme/
│   └── widgets/
├── features/
│   ├── auth/
│   ├── buyer/
│   ├── farmer/
│   ├── home/
│   ├── placeholder/
│   └── splash/
├── l10n/
├── app.dart
└── main.dart
```

Repositories isolate Supabase access from controllers/screens. Riverpod exposes repositories and feature controllers. GoRouter centralizes authentication, profile-completion, and role guards.

## Environment setup

### Prerequisites

- Flutter SDK compatible with the Dart SDK declared in `pubspec.yaml`
- Android Studio / Android SDK for Android development
- JDK 17 for Android builds
- Xcode for iOS development

### Configure Supabase

Create a local `.env` file from the committed template:

```bash
cp .env.example .env
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Set:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-publishable-key
APP_ENV=development
```

Never commit `.env`.

### Database requirements

The Flutter client expects these application tables/relationships:

- `profiles`
- `produce`
- `market_prices`
- `offers`

The repository does **not** contain authoritative SQL migrations for these tables, so the production schema, constraints, triggers, indexes, and RLS policies must be maintained and verified in the Supabase project.

At minimum, production RLS must enforce:

- A user can only modify their own profile.
- A farmer can only create/update/delete their own produce.
- A buyer can only create/cancel their own offers.
- A farmer can only manage offers belonging to their produce.
- Marketplace reads expose only data intended for authenticated users.
- Offer ownership and role constraints are enforced server-side.

The Flutter client includes defense-in-depth ownership checks, but these are not a replacement for database RLS.

## Install and run

```bash
flutter clean
flutter pub get
flutter run
```

Analyze:

```bash
flutter analyze
```

Test:

```bash
flutter test
```

Coverage:

```bash
flutter test --coverage
```

Debug APK:

```bash
flutter build apk --debug
```

Release builds require a real production signing configuration. The repository currently keeps release signing on the debug configuration intentionally; do not ship that configuration to production.

## Google OAuth / deep links

Android callback:

```
io.supabase.flutter://login-callback
```

The Android manifest and iOS Info.plist register this scheme. The same URI must be present in the Supabase allowed redirect URLs.

For current Supabase Flutter OAuth guidance, see the official Supabase documentation.

## Testing strategy

The test suite currently covers:

- Authentication/routing flows
- Farmer dashboard/controller behavior
- Buyer feature/controller behavior
- Domain model parsing
- User profile behavior
- Runtime integration paths
- Basic application smoke rendering

Tests should continue to grow around authorization boundaries, Google OAuth callbacks, profile-completion edge cases, RLS integration, realtime behavior, validation, and failure states.

## Security notes

- `.env` is ignored by Git.
- `.env.example` contains placeholders only.
- Supabase publishable/anonymous client credentials are not equivalent to a service-role key; database authorization still depends on RLS.
- Never place a Supabase service-role key, private OAuth secret, signing key, or password in Flutter source.
- Never modify Supabase Auth password hashes directly.
- Do not rely on client-side role checks as the only authorization boundary.

## Release checklist

Before production release:

1. Verify Supabase RLS and database constraints.
2. Configure production OAuth redirect URLs.
3. Configure production Android signing.
4. Verify application ID/package name.
5. Test cold start and session restoration.
6. Test Farmer and Buyer authorization boundaries.
7. Test Google OAuth on a real device.
8. Test light/dark themes and localization.
9. Run analyze, tests, coverage, and release build.
10. Validate the release APK/AAB on supported Android versions.

## Roadmap

- Add authoritative versioned Supabase migrations to the project or a dedicated infrastructure repository.
- Add integration tests against a disposable Supabase environment.
- Add server-side transactional offer/acceptance workflows where inventory consistency requires atomic operations.
- Add richer market-price history and analytics.
- Add notifications for offer status changes.
- Add production observability and crash reporting.
- Complete production signing and store-release configuration.

## Repository

GitHub: https://github.com/krut-tech/KishanSetu

## License

MIT
