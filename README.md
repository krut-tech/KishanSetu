# KisanSetu — Farmer Market Linkage & Price Discovery

KisanSetu is a modern mobile platform designed to bridge the gap between farmers and agricultural produce buyers. By providing real-time market price discovery, direct buyer-seller negotiations, and streamlined order management, KisanSetu empowers farmers to achieve fair prices for their harvest while enabling buyers to source fresh produce directly from agricultural producers.

---

## 📌 Problem Statement

Smallholder farmers in emerging agricultural markets face significant hurdles:
* **Information Asymmetry:** Lack of transparent, real-time market prices across regional Mandis (wholesale markets).
* **Middlemen Exploitation:** Intermediaries extract disproportionate profits, reducing farmer margins.
* **Fragmented Buyer Network:** Difficulty in discovering and connecting directly with verified bulk buyers.
* **Inefficient Price Discovery:** Absence of structured offer/bidding systems for agricultural commodities.

**KisanSetu** solves these challenges by providing an end-to-end digital linkage platform with dynamic price discovery and transparent trading workflows.

---

## ✨ Key Features

* **Role-Based Workflows:** Tailored user experience for both **Farmers** and **Buyers**.
* **Authentication & Role Selection:**
  * Email/Password authentication via Supabase Auth.
  * Google OAuth Sign-In integration.
  * Smart profile completion flow with role switching and persistent user preferences.
* **Market Price Discovery:**
  * Live commodity price updates across regional markets.
  * Price trend indicators, daily price comparisons, and market highlights.
* **Produce Listing Management (Farmers):**
  * Farmers can add, update, and manage produce listings with category, quantity, price, grade, and harvest location.
* **Marketplace & Sourcing (Buyers):**
  * Search, filter, and view detailed produce information.
  * Directly submit offers on farmer listings.
* **Offer & Negotiation System:**
  * Real-time offer creation, acceptance, rejection, and counter-offer tracking.
* **Localization & Accessibility:**
  * Support for English, Hindi, and Gujarati.
* **Theme Customization:**
  * Clean, accessible Light and Dark mode options.

---

## 🔄 App Workflows

### 🌾 Farmer Workflow
1. **Sign Up / Log In:** Authenticate using email/password or Google Sign-In.
2. **Profile Setup:** Enter personal, location, and farm details during profile completion.
3. **Dashboard:** Access quick statistics (active listings, pending offers, total sales).
4. **List Produce:** Add detailed crop/produce information (crop type, quantity, expected price, location).
5. **Monitor Market Prices:** View real-time Mandi prices to make informed pricing decisions.
6. **Manage Offers:** Review incoming offers from buyers; accept, decline, or counter offers.

### 🛒 Buyer Workflow
1. **Sign Up / Log In:** Authenticate using email/password or Google Sign-In.
2. **Profile Setup:** Enter business, purchasing preferences, and location details.
3. **Marketplace Navigation:** Browse active farmer produce listings with search and filter capabilities.
4. **Inspect Produce:** View comprehensive produce details (quality grade, quantity, seller details).
5. **Submit Offers:** Propose purchasing prices and target quantities directly to farmers.
6. **Track Purchases:** Monitor offer status and purchase history from the Buyer Dashboard.

---

## 🛠️ Technology Stack

* **Framework:** [Flutter](https://flutter.dev) (SDK >=3.1.0 <4.0.0)
* **Language:** [Kotlin](https://kotlinlang.org) (Android native) / [Dart](https://dart.dev)
* **Backend & Auth:** [Supabase](https://supabase.com) (`supabase_flutter`)
* **State Management:** [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
* **Navigation & Routing:** [GoRouter](https://pub.dev/packages/go_router)
* **Internationalization:** Flutter Localization (`intl`, support for `en`, `hi`, `gu`)
* **UI Components:** Custom Design System, Google Fonts, Shimmer Loading

---

## 📁 Project Structure

```
lib/
├── app.dart                   # Main App Widget & Theme Configuration
├── main.dart                  # Application Entry Point
├── core/                      # Shared Core Infrastructure
│   ├── animations/            # UI Animation Helpers
│   ├── bootstrap/             # App Initialization Logic
│   ├── config/                # Environment & App Configurations
│   ├── constants/             # Colors, Spacing, Typography & Shadows
│   ├── errors/                # Exception & Failure Handling
│   ├── localization/          # Locale Controllers & Translations
│   ├── logging/               # Application Logger
│   ├── network/               # Supabase Client Providers
│   ├── routing/               # GoRouter Setup & Route Guards
│   ├── theme/                 # App Themes & Dynamic Controllers
│   └── widgets/               # Reusable UI Component Library
├── features/                  # Feature Modules
│   ├── auth/                  # Authentication & Profile Completion
│   ├── farmer/                # Farmer Dashboard, Produce, Market Prices & Offers
│   ├── buyer/                 # Buyer Dashboard, Marketplace, Produce Details & Offers
│   ├── home/                  # Dynamic Role-Based Home Screens
│   └── splash/                # Splash & Bootstrap Screen
└── l10n/                      # ARB Files & Generated Localizations
```

---

## 🚀 Setup & Installation

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.0 or higher)
* [Android Studio](https://developer.android.com/studio) / VS Code
* JDK 17

### 1. Clone Repository
```bash
git clone https://github.com/krut-tech/KishanSetu.git
cd KishanSetu
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env` in the project root:

```bash
cp .env.example .env
```

Edit `.env` and fill in your Supabase configuration:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
APP_ENV=development
```

> **Note:** Never commit `.env` to source control. Ensure it remains listed in `.gitignore`.

### 3. Install Dependencies
```bash
flutter pub get
```

---

## 🧪 Testing & Code Analysis

Run static code analysis:
```bash
flutter analyze
```

Run unit and widget tests:
```bash
flutter test
```

---

## 📦 Building Debug APK

To generate a debug APK:
```bash
flutter build apk --debug
```

The output APK will be available at:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 🔒 Security & Best Practices

* Secret keys, access tokens, and environment files (`.env`) are strictly excluded from source control.
* Anonymous Supabase keys are retrieved dynamically at runtime via `flutter_dotenv`.
* Role-based authorization guards protect application routes.

---

## 📜 License

This project is licensed under the MIT License.
