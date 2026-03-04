# Expense Care

**Version:** 1.0.0+1 · **Date:** March 4, 2026 · **Status:** Active Development

A cross-platform personal finance app built with Flutter and Firebase.  
Log daily expenses, set budget limits, manage savings goals, track recurring bills, and review spending through interactive charts.

**Platforms:** iOS · Android · Web · Windows

---

## Table of Contents

1. [Features](#features)
2. [Tech Stack](#tech-stack)
3. [Design System](#design-system)
4. [Navigation Architecture](#navigation-architecture)
5. [Screens](#screens)
6. [Data Models](#data-models)
7. [Firebase Architecture](#firebase-architecture)
8. [Offline Support](#offline-support)
9. [Notifications](#notifications)
10. [Getting Started](#getting-started)
11. [Project Structure](#project-structure)
12. [Security](#security)
13. [Out of Scope (v1.0)](#out-of-scope-v10)

---

## Features

| Feature | Details |
|---|---|
| Authentication | Email / password + Google Sign-In; password reset |
| Onboarding | 4-slide intro flow → Landing → Login / Sign Up |
| Budget Limits | Daily (required); weekly & monthly (optional, togglable on Home) |
| Expense Tracking | Amount, category, date & time, note, receipt photo (Base64) |
| Categories | 13 built-in: Food & Drink, Transport, Housing, Health, Shopping, Entertainment, Education, Work, Travel, Utilities, Gifts, Savings, Other |
| Savings Goals | Create goals with icon, target amount, optional target date; fund via "Add Money" |
| Goal Integration | Adding money to a goal automatically creates a **Savings** expense |
| Recurring Expenses | Daily / Weekly / Monthly / Yearly; client-side auto-log check on shell load |
| Summary | Day / Week / Month / Custom date ranges; interactive pie chart (fl_chart); per-category drill-down |
| Theme | Light · Dark · System; persisted to Firestore per user |
| Multi-currency | 17 currencies with inline symbol display |
| Responsive Layout | Bottom nav (< 840 dp) → NavigationRail (840–1199 dp) → Extended Rail (≥ 1200 dp) |
| Offline Capable | Firestore native persistence; `syncedToFirestore` flag; connectivity banner |
| Local Notifications | Budget alerts at 80 % and 100 % of daily limit |

---

## Tech Stack

| Layer | Library | Version |
|---|---|---|
| Framework | Flutter | `>=3.0.0 <4.0.0` |
| Language | Dart | — |
| State Management | flutter_riverpod | `^2.5.1` |
| Navigation | go_router | `^13.2.1` |
| Database | cloud_firestore | `^5.2.1` |
| Authentication | firebase_auth | `^5.1.4` |
| Google Sign-In | google_sign_in | `^6.2.1` |
| Charts | fl_chart | `^0.68.0` |
| Connectivity | connectivity_plus | `^6.0.3` |
| Notifications | flutter_local_notifications | `^17.0.0` |
| Image Picker | image_picker | `^1.1.2` |
| Fonts | google_fonts (Poppins) | `^6.2.1` |
| Formatting | intl | `^0.19.0` |

> **Receipt storage:** Images are encoded as Base64 JPEG and stored directly on the Firestore expense document (max 500 KB raw). Firebase Storage is **not** used in v1.0.

---

## Design System

### Color Palette

#### Light Theme

| Token | Hex |
|---|---|
| `primary` | `#4F6EF7` |
| `primaryVariant` | `#3A56D4` |
| `secondary` | `#F9A825` |
| `background` | `#F8F9FA` |
| `surface` | `#FFFFFF` |
| `error` | `#E53935` |
| `success` | `#43A047` |
| `warning` | `#FB8C00` |
| `onBackground` | `#0F1117` |
| `onSurface` | `#374151` |
| `muted` | `#9CA3AF` |
| `divider` | `#ECECF3` |

#### Dark Theme

| Token | Hex |
|---|---|
| `primary` | `#6B8AFF` |
| `primaryVariant` | `#4F6EF7` |
| `secondary` | `#FFB300` |
| `background` | `#0F0F17` |
| `surface` | `#17171F` |
| `error` | `#EF5350` |
| `success` | `#66BB6A` |
| `warning` | `#FFA726` |
| `onBackground` | `#EAEAF4` |
| `onSurface` | `#B0B8D9` |
| `muted` | `#5A5F7A` |
| `divider` | `#242430` |

#### Category Colors

| Category | Hex |
|---|---|
| Food & Drink | `#FF6B6B` |
| Transport | `#4ECDC4` |
| Housing | `#4F6EF7` |
| Health | `#34D399` |
| Shopping | `#A78BFA` |
| Entertainment | `#F59E0B` |
| Education | `#06B6D4` |
| Work | `#6366F1` |
| Travel | `#FB8C00` |
| Utilities | `#64748B` |
| Gifts | `#EC4899` |
| Savings | `#43A047` |
| Other | `#8B90A7` |

### Typography

Font family: **Poppins** (via Google Fonts)

| Style | Weight | Size | Line Height |
|---|---|---|---|
| `displayLarge` | 700 | 34 sp | 44 |
| `headlineMedium` | 600 | 24 sp | 32 |
| `titleLarge` | 600 | 20 sp | 28 |
| `titleMedium` | 500 | 16 sp | 24 |
| `bodyLarge` | 400 | 16 sp | 24 |
| `bodyMedium` | 400 | 14 sp | 20 |
| `labelLarge` | 600 | 14 sp | 20 |
| `labelMedium` | 500 | 12 sp | 16 |
| `labelSmall` | 500 | 11 sp | 16 |

### Spacing System

Base unit: **8 dp**

| Token | Value |
|---|---|
| `xxs` | 4 dp |
| `xs` | 8 dp |
| `sm` | 16 dp |
| `md` | 24 dp |
| `lg` | 32 dp |
| `xl` | 40 dp |
| `xxl` | 48 dp |

### Border Radius

| Component | Radius |
|---|---|
| Cards | 16 dp |
| Buttons | 26 dp (pill) |
| Input fields | 12 dp |
| Chips / tags | 10 dp |
| Bottom sheet top | 28 dp |
| Modals | 24 dp |

---

## Navigation Architecture

### Routes (GoRouter)

```
/splash                 → SplashScreen
/onboarding             → OnboardingScreen (4 slides)
/landing                → LandingScreen
/login                  → LoginScreen
/signup                 → SignUpScreen
── ShellRoute (MainShell — persistent bottom nav / rail) ──
   /home                → HomeScreen
   /goals               → GoalsScreen
   /summary             → SummaryScreen
   /profile             → ProfileScreen
   /profile/recurring   → RecurringExpensesScreen
```

**Auth redirect logic:**
- Unauthenticated user hitting a protected route → `/onboarding`
- Authenticated user hitting a public route → `/home`
- Splash screen manages its own internal navigation

### Shell Navigation

| Breakpoint | Layout |
|---|---|
| < 840 dp | Bottom `NavigationBar` (4 tabs) |
| 840–1199 dp | `NavigationRail` (icons + labels) |
| ≥ 1200 dp | Extended `NavigationRail` (with labels inline) |

**Tabs:** Home · Goals · Summary · Profile  
**Guard:** Non-Home tabs are locked until a daily budget limit is saved.

---

## Screens

### Splash Screen
- Displays app logo with a brief animation.
- Checks Firebase auth state and navigates to `/home` (authenticated) or `/onboarding` (unauthenticated).

### Onboarding Screen
4-page `PageView` introducing core features:
1. **Track Every Expense** — log and categorize spending in seconds
2. **Set & Achieve Goals** — define financial goals and track progress
3. **Manage Recurring Bills** — automated tracking for scheduled payments
4. **Get Spending Insights** — charts and summaries of financial habits

Last slide navigates to `/landing`.

### Landing Screen
Animated entry screen with app logo, tagline, and two CTAs:
- **Log In** → `/login`
- **Sign Up** → `/signup`

### Login Screen
- Email + password fields with inline validation.
- "Forgot Password?" triggers Firebase password reset email (entered email required).
- Google Sign-In button.
- Loading overlay during authentication.
- Snackbar for network-level errors; inline field-level error messages.

### Sign Up Screen
- Full Name, Email, Password (min 8 chars, eye toggle), Confirm Password.
- Google Sign-In button.
- Navigates to `/home` on success; existing users see a budget-setup prompt on first visit.

### Home Screen
| Section | Details |
|---|---|
| Header | Greeting ("Good morning / afternoon / evening, [First Name]") + current date |
| Daily Budget Card | Remaining / total; animated progress bar (`success` < 80 %, `warning` 80–99 %, `error` ≥ 100 %); "Over budget by X" state |
| Optional Budget Cards | Weekly & monthly cards (only shown when enabled in Profile); reset Monday / 1st of month |
| FAB | "+ Add Expense" opens `AddExpenseScreen` as a bottom sheet |
| Recent Expenses | Last 5 expenses; tap to edit/delete; swipe-to-delete with confirmation for recurring-linked entries |
| Budget Setup Prompt | If no daily limit is set, shows inline setup sheet instead of FAB |
| Offline Banner | Shown when `isOnlineProvider` is false |

### Add / Edit Expense Screen
Presented as a modal bottom sheet (full height). Fields:

| Field | Type | Notes |
|---|---|---|
| Amount | Numeric input | Required; currency symbol auto-prefixed |
| Category | Chip row (13 options) | Required; horizontal scroll |
| Date & Time | Custom date-time picker | Defaults to now; max = today |
| Note | Text input | Optional; max 200 characters |
| Receipt Photo | Image picker (camera or gallery) | Optional; max 500 KB raw; stored as Base64 on the Firestore document; thumbnail preview with remove option |

- **Edit mode:** pre-populates all fields; receipt decoded once in `initState`.
- **Savings category:** when editing a savings-linked expense, only deletion is allowed (no free edit, to keep goal totals consistent).
- On success: optimistic Home update + success snackbar.

### Goals Screen
- Goals list as cards: icon (Material icon from 18-icon picker), name, target amount, saved amount, circular progress ring (percentage), "Add Money" button, optional target date.
- **Add Money sheet:** enters an amount which is saved as a **Savings** expense and increments `savedAmount` on the goal document atomically.
- **Completed state:** `isCompleted` flag set when `savedAmount >= targetAmount`; completion badge displayed.
- Add / Edit goal via bottom sheet: name (max 50 chars), icon picker, target amount, optional target date.
- Empty state with CTA.

### Summary Screen
| Component | Details |
|---|---|
| Period Selector | Day · Week · Month · Custom |
| Custom Picker | Single date or date range via `showAppCustomPeriodPicker` |
| Stats Bar | Total spent, transaction count, largest single expense |
| Pie Chart | `PieChart` from fl_chart; tap slice for tooltip (name, amount, %) |
| Category Breakdown | Color dot, icon, name, total, percentage; tap row → detail bottom sheet with individual expense rows (edit / delete) |
| Empty State | Illustration when no expenses in selected range |

### Profile Screen
| Section | Details |
|---|---|
| User Info | Avatar (Google photo or initials fallback), display name, email |
| Budget Limits | Daily (required), weekly (optional toggle), monthly (optional toggle); "Save Limits" button enabled on change |
| Show on Home | Toggles for weekly and monthly budget cards |
| Currency | Picker: 17 currencies (THB, USD, EUR, GBP, JPY, CNY, KRW, SGD, AUD, CAD, CHF, HKD, INR, MYR, IDR, PHP, VND); change triggers a confirmation dialog (amounts are not converted) |
| Theme | Segmented toggle: Light · Dark · System |
| Recurring Expenses | Navigation link → `/profile/recurring` |
| Account Actions | Sign Out (with confirmation dialog); Delete Account (re-authentication required) |

### Recurring Expenses Screen
- List of recurring items: name, amount, category icon, frequency badge, next due date.
- CRUD via bottom sheet: name, amount, currency, category, frequency (Daily / Weekly / Monthly / Yearly), start date, optional note.
- Delete button per card (with confirmation snackbar).
- **Auto-log:** `recurringCheckProvider` runs on every shell mount; overdue entries are automatically logged as expenses and `nextDueDate` is advanced.
- Empty state with "Add Recurring" CTA.

---

## Data Models

### UserModel
```dart
class UserModel {
  final String uid;
  final String displayName;   // firstName computed as displayName.split(' ').first
  final String email;
  final String? photoUrl;
  final String preferredCurrency;   // default 'USD'
  final double dailyLimit;          // default 0.0
  final double? weeklyLimit;
  final double? monthlyLimit;
  final bool showWeeklyOnHome;      // default false
  final bool showMonthlyOnHome;     // default false
  final String themeMode;           // 'light' | 'dark' | 'system'
  final bool notificationsEnabled;  // default true
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### ExpenseModel
```dart
class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String currency;             // ISO 4217 code
  final double amountInBaseCurrency; // converted at time of entry
  final String categoryId;
  final String? note;
  final String? receiptBase64;       // Base64-encoded JPEG; max 500 KB raw
  final DateTime date;
  final bool isRecurring;
  final String? recurringId;
  final String? goalId;              // set when created via "Add Money to Goal"
  final bool syncedToFirestore;      // false if pending sync (offline)
  final DateTime createdAt;
}
```

### GoalModel
```dart
class GoalModel {
  final String id;
  final String userId;
  final String name;
  final String emoji;        // stored as codePoint string; resolved via icon lookup map
  final double targetAmount;
  final double savedAmount;
  final String currency;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Computed:
  // double get progress      → (savedAmount / targetAmount).clamp(0, 1)
  // int get progressPercent  → (progress * 100).round()
  // bool get justCompleted   → savedAmount >= targetAmount && !isCompleted
}
```

### RecurringExpenseModel
```dart
class RecurringExpenseModel {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String currency;
  final String categoryId;
  final String frequency;    // 'daily' | 'weekly' | 'monthly' | 'yearly'
  final DateTime startDate;
  final DateTime nextDueDate;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
}
```

### CategoryModel (built-in, 13 defaults)
| ID | Name | Color |
|---|---|---|
| `food` | Food & Drink | `#FF6B6B` |
| `transport` | Transport | `#4ECDC4` |
| `housing` | Housing | `#4F6EF7` |
| `health` | Health | `#34D399` |
| `shopping` | Shopping | `#A78BFA` |
| `entertainment` | Entertainment | `#F59E0B` |
| `education` | Education | `#06B6D4` |
| `work` | Work | `#6366F1` |
| `travel` | Travel | `#FB8C00` |
| `utilities` | Utilities | `#64748B` |
| `gifts` | Gifts | `#EC4899` |
| `savings` | Savings | `#43A047` |
| `other` | Other | `#8B90A7` |

---

## Firebase Architecture

### Firestore Collections

```
/users/{userId}                            # UserModel document
/users/{userId}/expenses/{expenseId}       # ExpenseModel
/users/{userId}/goals/{goalId}             # GoalModel
/users/{userId}/recurring/{recurringId}    # RecurringExpenseModel
```

### Security Rules

```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;

  match /{subcollection}/{docId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
}
// Deny everything else by default.
match /{document=**} {
  allow read, write: if false;
}
```

---

## Offline Support

- **Firestore offline persistence** is enabled by default — reads and queued writes survive network loss.
- `syncedToFirestore` flag on `ExpenseModel` tracks pending sync state.
- `connectivity_plus` (`isOnlineProvider`) monitors network state.
- Offline banner shown on Home when disconnected.
- Receipt images (Base64) are part of the Firestore document — no separate upload step required.

---

## Notifications

Handled by `flutter_local_notifications` (no Firebase Cloud Messaging in v1.0).

| Notification | Trigger |
|---|---|
| Budget Warning (80 %) | `budgetAlertProvider` watches daily total; fires when spend ≥ 80 % of daily limit |
| Over Budget (100 %) | Same provider; fires when daily limit is exceeded |

- Skipped on Web (`kIsWeb` guard in `NotificationService`).
- Initialization failure is swallowed gracefully — app continues without notifications.
- Android channel: `budget_alerts` (high importance / high priority).
- User-level toggle: `notificationsEnabled` on `UserModel`.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- [Firebase CLI](https://firebase.google.com/docs/cli) — `npm install -g firebase-tools`
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) — `dart pub global activate flutterfire_cli`

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
   Firebase config files are **git-ignored**. Regenerate them:
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

   # Windows
   flutter run -d windows
   ```

### Firebase Deployment

```bash
# Deploy Firestore security rules
firebase deploy --only firestore:rules --project expense-care-2ef8d

# Deploy Firestore indexes
firebase deploy --only firestore:indexes --project expense-care-2ef8d
```

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                     # MaterialApp.router, theme, GoRouter wiring
├── firebase_options.dart        # git-ignored — run flutterfire configure
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      # All color tokens (light, dark, categories)
│   │   ├── app_text_styles.dart # Poppins text styles
│   │   └── app_spacing.dart     # AppSpacing + AppRadius constants
│   ├── errors/
│   │   └── failure.dart
│   ├── router/
│   │   └── app_router.dart      # GoRouter config + auth redirect
│   ├── services/
│   │   ├── notification_service.dart  # flutter_local_notifications wrapper
│   │   └── receipt_service.dart       # image_picker wrapper
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_notifier.dart  # ThemeMode Riverpod notifier
│   └── utils/
│       ├── validators.dart
│       ├── app_date_utils.dart
│       └── currency_formatter.dart
├── features/
│   ├── auth/
│   │   ├── data/                # auth_repository.dart
│   │   ├── domain/models/       # user_model.dart
│   │   └── presentation/
│   │       ├── providers/       # auth_provider.dart
│   │       ├── screens/         # splash, onboarding, landing, login, signup
│   │       └── widgets/         # google_sign_in_button.dart
│   ├── expense/
│   │   ├── data/                # expense_repository.dart
│   │   ├── domain/models/       # expense_model.dart, category_model.dart
│   │   └── presentation/
│   │       ├── screens/         # add_expense_screen.dart
│   │       └── widgets/         # category_selector.dart
│   ├── goals/
│   │   ├── domain/models/       # goal_model.dart
│   │   └── presentation/screens/ # goals_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       ├── screens/         # home_screen.dart
│   │       └── widgets/         # daily_budget_card, optional_budget_cards,
│   │                            #   recent_expenses_list, budget_progress_bar
│   ├── profile/
│   │   └── presentation/
│   │       ├── screens/         # profile_screen.dart, recurring_expenses_screen.dart
│   │       └── widgets/         # budget_limit_form.dart, theme_toggle.dart
│   ├── recurring/
│   │   ├── data/                # recurring_repository.dart
│   │   ├── domain/models/       # recurring_expense_model.dart
│   │   └── providers/           # recurring_check_provider.dart
│   └── summary/
│       └── presentation/screens/ # summary_screen.dart
└── shared/
    ├── providers/
    │   ├── budget_alert_provider.dart
    │   ├── connectivity_provider.dart
    │   └── user_preferences_provider.dart
    ├── utils/
    │   └── expense_actions.dart
    └── widgets/
        ├── main_shell.dart       # ShellRoute host — bottom nav + NavigationRail
        ├── app_bottom_sheet.dart
        ├── app_button.dart
        ├── app_card.dart
        ├── app_date_picker.dart  # incl. custom period picker
        ├── app_text_field.dart
        ├── empty_state.dart
        └── error_snackbar.dart
```

---

## Security

- Firestore rules scope every read/write to the authenticated owner (`/users/{userId}/**`).
- Firebase config files (containing API keys) are **git-ignored**; run `flutterfire configure` locally.
- Re-authentication is required before account deletion.
- Receipt images are stored as Base64 on the user's own Firestore document — no cross-user storage access.
- No sensitive data (passwords, tokens) is stored in plain text.

---

## Out of Scope (v1.0)

The following are deferred to future versions:

- **v1.1:** Email verification after sign-up · Firebase Storage for receipts · Firebase Cloud Messaging (push notifications) · CSV / PDF export · Custom user-defined categories · Apple Sign-In
- **v1.2:** Bank account / credit card import · Shared budgets (families / couples) · AI-powered spending insights
- **v2.0:** Investment tracking · Net worth dashboard · Full ISO 4217 currency list with live exchange rates

---

*Expense Care Engineering Team — Last updated: March 4, 2026*
