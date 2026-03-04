# Expense Care

A cross-platform personal finance app built with Flutter and Firebase.  
Track daily expenses, set budget limits, manage savings goals, and review spending summaries.

**Platforms:** iOS · Android · Web · Windows

---

## Features

- Email/password and Google sign-in
- Daily, weekly, and monthly budget limits with notifications
- Expense tracking with categories and receipt photos
- Savings goals with progress tracking
- Recurring expenses (daily / weekly / monthly / yearly)
- Spending summary with charts and custom date ranges
- Dark / light / system theme
- Multi-currency support
- Offline-capable (Firestore local cache)

---

## Tech Stack

| Layer | Library |
|---|---|
| Framework | Flutter 3 |
| State management | Riverpod 2 |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore) |
| Charts | fl_chart |
| Fonts | Google Fonts (Poppins) |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- [Firebase CLI](https://firebase.google.com/docs/cli) `npm install -g firebase-tools`
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) `dart pub global activate flutterfire_cli`

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/<your-username>/expense_care.git
   cd expense_care
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**  
   The Firebase config files are not committed to the repo. Regenerate them by running:
   ```bash
   flutterfire configure
   ```
   This creates:
   - `lib/firebase_options.dart`
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

4. **Run the app**
   ```bash
   # Web
   flutter run -d chrome

   # Android
   flutter run -d android

   # iOS
   flutter run -d ios
   ```

---

## Firebase Setup

### Deploy Firestore security rules
```bash
firebase deploy --only firestore:rules --project expense-care-2ef8d
```

### Deploy Firestore indexes
```bash
firebase deploy --only firestore:indexes --project expense-care-2ef8d
```

---

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── firebase_options.dart       # git-ignored — run flutterfire configure
├── core/
│   ├── constants/              # Colors, spacing, text styles
│   ├── errors/                 # Failure types
│   ├── router/                 # GoRouter configuration
│   ├── services/               # Notification, receipt services
│   ├── theme/                  # Theme notifier
│   └── utils/                  # Validators, date utils, currency formatter
├── features/
│   ├── auth/                   # Sign-in, sign-up, user model
│   ├── expense/                # Add/edit expense, categories
│   ├── goals/                  # Savings goals
│   ├── home/                   # Home screen, budget cards
│   ├── profile/                # Settings, recurring expenses
│   ├── recurring/              # Recurring expense engine
│   └── summary/                # Charts and spending reports
└── shared/
    ├── providers/              # Connectivity, budget alerts, user prefs
    ├── utils/                  # Shared expense actions
    └── widgets/                # Reusable UI components
```

---

## Security

- Firestore rules restrict every user to their own data only (`/users/{userId}/**`)
- Firebase config files (API keys) are git-ignored and must be regenerated locally
- Re-authentication is required before account deletion
