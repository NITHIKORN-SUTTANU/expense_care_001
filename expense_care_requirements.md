# Expense Care — Professional Requirements Document

**Version:** 1.0.0
**Date:** March 1, 2026
**Status:** Draft
**Platform:** Flutter (iOS · Android · Web)
**Backend:** Firebase

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Design System](#3-design-system)
4. [Project Structure](#4-project-structure)
5. [Authentication](#5-authentication)
6. [Navigation Architecture](#6-navigation-architecture)
7. [Screen Requirements](#7-screen-requirements)
   - 7.1 [Login Screen](#71-login-screen)
   - 7.2 [Sign Up Screen](#72-sign-up-screen)
   - 7.3 [Home Screen](#73-home-screen)
   - 7.4 [Add Expense Screen](#74-add-expense-screen)
   - 7.5 [Goals Screen](#75-goals-screen)
   - 7.6 [Summary Screen](#76-summary-screen)
   - 7.7 [Profile Screen](#77-profile-screen)
   - 7.8 [Recurring Expenses Screen](#78-recurring-expenses-screen)
8. [Data Models](#8-data-models)
9. [Firebase Architecture](#9-firebase-architecture)
10. [Offline Support](#10-offline-support)
11. [Currency Support](#11-currency-support)
12. [Notifications](#12-notifications)
13. [Form Validation Rules](#13-form-validation-rules)
14. [Accessibility & Responsiveness](#14-accessibility--responsiveness)
15. [Security Requirements](#15-security-requirements)
16. [Performance Requirements](#16-performance-requirements)
17. [Out of Scope (v1.0)](#17-out-of-scope-v10)

---

## 1. Project Overview

**Expense Care** is a cross-platform personal finance mobile application built with Flutter. It helps users set daily (mandatory), weekly, and monthly spending limits, track expenses in real time, manage savings goals, and review spending summaries through visual analytics.

### Core Objectives

- Provide a frictionless expense-logging experience from the Home screen.
- Enforce a mobile-first, consistent UI/UX across iOS, Android, and Web.
- Support offline-first data persistence with Firebase synchronization.
- Enable multi-currency expense tracking.
- Gamify savings goals to encourage positive financial habits.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (latest stable) |
| Language | Dart |
| State Management | Riverpod (or BLoC — team decision) |
| Backend / Database | Firebase Firestore |
| Authentication | Firebase Auth (Email/Password + Google Sign-In) |
| File Storage | Firebase Storage (expense receipt images) |
| Hosting | Firebase Hosting (Flutter Web) |
| Offline Persistence | Firestore offline cache + Hive (local fallback) |
| Analytics (optional) | Firebase Analytics |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Currency Conversion | Open Exchange Rates API (or Frankfurter — free tier) |

---

## 3. Design System

### 3.1 Color Palette

Colors are **fixed** — identical across all platforms and must never be overridden by system theming unless the user explicitly switches themes inside the app.

#### Light Theme

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#4F6EF7` | Primary buttons, active nav icons, progress bars |
| `primaryVariant` | `#3A56D4` | Pressed states, focused borders |
| `secondary` | `#F9A825` | Goals accent, highlights |
| `background` | `#F5F6FA` | Screen backgrounds |
| `surface` | `#FFFFFF` | Cards, modals, bottom sheets |
| `error` | `#E53935` | Validation errors, over-budget alerts |
| `success` | `#43A047` | Within-budget indicators |
| `warning` | `#FB8C00` | Approaching-limit indicators (≥ 80%) |
| `onPrimary` | `#FFFFFF` | Text/icons on primary color |
| `onBackground` | `#1A1D2E` | Primary body text |
| `onSurface` | `#3C3F58` | Secondary text on cards |
| `divider` | `#E0E3EF` | Dividers, borders |
| `navBackground` | `#FFFFFF` | Bottom navigation bar |

#### Dark Theme

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#6B8AFF` | Same role as light, adjusted for contrast |
| `primaryVariant` | `#4F6EF7` | Pressed/focused |
| `secondary` | `#FFB300` | Goals accent |
| `background` | `#12131A` | Screen backgrounds |
| `surface` | `#1E2030` | Cards, modals |
| `error` | `#EF5350` | Errors |
| `success` | `#66BB6A` | Success |
| `warning` | `#FFA726` | Warning |
| `onPrimary` | `#FFFFFF` | Text on primary |
| `onBackground` | `#E8EAF6` | Primary body text |
| `onSurface` | `#B0B8D9` | Secondary text |
| `divider` | `#2A2D3E` | Dividers |
| `navBackground` | `#1E2030` | Bottom nav |

> **Rule:** The app's `ThemeData` must use `ThemeMode.system` as default but the selected theme is stored in Firestore (per user) and local preferences (offline). System overrides must be blocked at the MaterialApp level for all color tokens.

### 3.2 Typography

| Style | Font | Weight | Size (sp) | Line Height |
|---|---|---|---|---|
| `displayLarge` | Inter | 700 | 32 | 40 |
| `headlineMedium` | Inter | 600 | 24 | 32 |
| `titleLarge` | Inter | 600 | 20 | 28 |
| `titleMedium` | Inter | 500 | 16 | 24 |
| `bodyLarge` | Inter | 400 | 16 | 24 |
| `bodyMedium` | Inter | 400 | 14 | 20 |
| `labelLarge` | Inter | 600 | 14 | 20 |
| `labelSmall` | Inter | 500 | 11 | 16 |

> Use Google Fonts package for Inter. Font sizes are fixed (not scaled by user's system font size preference, to preserve layout) unless accessibility mode is explicitly added in a future version.

### 3.3 Spacing System

Base unit: `8dp`. All spacing values must be multiples of 8 (e.g., 8, 16, 24, 32).

### 3.4 Border Radius

| Component | Radius |
|---|---|
| Cards | `16dp` |
| Buttons | `12dp` |
| Input fields | `10dp` |
| Chips / tags | `8dp` |
| Bottom sheet | `24dp` top corners |
| Modals | `20dp` |

### 3.5 Iconography

Use **Material Symbols Rounded** (variable font). Icon size: `24dp` standard, `20dp` for inline/contextual icons.

### 3.6 Elevation & Shadows

Cards use a soft shadow: `BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))`. No hard elevation shadows in dark mode — use border instead: `Border.all(color: divider, width: 1)`.

---

## 4. Project Structure

```
expense_care/
├── lib/
│   ├── main.dart
│   ├── app.dart                        # MaterialApp, theme, routing
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_spacing.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── theme_notifier.dart
│   │   ├── router/
│   │   │   └── app_router.dart         # GoRouter setup
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart
│   │   │   ├── date_utils.dart
│   │   │   └── validators.dart
│   │   └── errors/
│   │       └── failure.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   └── auth_remote_data_source.dart
│   │   │   ├── domain/
│   │   │   │   ├── models/user_model.dart
│   │   │   │   └── usecases/
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   └── signup_screen.dart
│   │   │       ├── widgets/
│   │   │       │   ├── google_sign_in_button.dart
│   │   │       │   └── auth_text_field.dart
│   │   │       └── providers/auth_provider.dart
│   │   ├── home/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── screens/home_screen.dart
│   │   │       └── widgets/
│   │   │           ├── daily_budget_card.dart
│   │   │           ├── budget_progress_bar.dart
│   │   │           ├── recent_expenses_list.dart
│   │   │           ├── quick_add_fab.dart
│   │   │           └── optional_budget_cards.dart
│   │   ├── expense/
│   │   │   ├── data/
│   │   │   │   ├── expense_repository.dart
│   │   │   │   └── expense_local_data_source.dart
│   │   │   ├── domain/
│   │   │   │   ├── models/expense_model.dart
│   │   │   │   └── models/category_model.dart
│   │   │   └── presentation/
│   │   │       ├── screens/add_expense_screen.dart
│   │   │       └── widgets/
│   │   │           ├── category_selector.dart
│   │   │           ├── image_picker_field.dart
│   │   │           └── currency_amount_field.dart
│   │   ├── goals/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   │   └── models/goal_model.dart
│   │   │   └── presentation/
│   │   │       ├── screens/goals_screen.dart
│   │   │       └── widgets/
│   │   │           ├── goal_card.dart
│   │   │           ├── goal_progress_ring.dart
│   │   │           └── add_goal_bottom_sheet.dart
│   │   ├── summary/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── screens/summary_screen.dart
│   │   │       └── widgets/
│   │   │           ├── date_range_picker.dart
│   │   │           ├── expense_pie_chart.dart
│   │   │           └── category_expense_tile.dart
│   │   ├── profile/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── profile_screen.dart
│   │   │       │   └── recurring_expenses_screen.dart
│   │   │       └── widgets/
│   │   │           ├── budget_limit_form.dart
│   │   │           ├── currency_selector.dart
│   │   │           └── theme_toggle.dart
│   │   └── recurring/
│   │       ├── data/
│   │       ├── domain/
│   │       │   └── models/recurring_expense_model.dart
│   │       └── presentation/
│   │           └── widgets/
│   │               └── add_recurring_bottom_sheet.dart
│   └── shared/
│       ├── widgets/
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   ├── app_card.dart
│       │   ├── app_bottom_sheet.dart
│       │   ├── loading_overlay.dart
│       │   ├── error_snackbar.dart
│       │   └── empty_state.dart
│       └── providers/
│           ├── connectivity_provider.dart
│           └── user_preferences_provider.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── firebase.json
├── firestore.rules
├── pubspec.yaml
└── README.md
```

---

## 5. Authentication

### 5.1 Supported Methods

- **Email & Password** (Firebase Auth)
- **Google Sign-In** (Google Identity Services via `google_sign_in` package)

### 5.2 Flow

1. App launches → check `FirebaseAuth.currentUser`.
2. If null → navigate to **Login Screen**.
3. If authenticated → navigate to **Home Screen**.
4. New user after Google Sign-In → check if Firestore user document exists. If not, navigate to a brief **Profile Setup** step (display name, preferred currency, daily budget limit) before reaching Home.

### 5.3 Session Management

- Firebase ID tokens are automatically refreshed.
- Users remain logged in unless they explicitly sign out.
- On sign-out: clear local Hive cache and Firestore offline cache.

### 5.4 Password Reset

- "Forgot Password?" link on Login Screen triggers Firebase `sendPasswordResetEmail`.

---

## 6. Navigation Architecture

### 6.1 Bottom Navigation Bar (4 tabs)

| Index | Label | Icon | Route |
|---|---|---|---|
| 0 | Home | `home_rounded` | `/home` |
| 1 | Goals | `flag_rounded` | `/goals` |
| 2 | Summary | `bar_chart_rounded` | `/summary` |
| 3 | Profile | `person_rounded` | `/profile` |

- The bottom navigation bar is always visible when inside main tabs.
- The active tab icon is filled; inactive icons are outlined.
- Active indicator: a small pill underline or filled chip using `primary` color.
- On Web: the bottom nav becomes a **left sidebar navigation** at screen widths ≥ 840dp (breakpoint).

### 6.2 Router (GoRouter)

```
/                       → redirect → /home (if auth) or /login
/login                  → LoginScreen
/signup                 → SignUpScreen
/home                   → HomeScreen (shell)
/home/add-expense       → AddExpenseScreen
/goals                  → GoalsScreen
/summary                → SummaryScreen
/profile                → ProfileScreen
/profile/recurring      → RecurringExpensesScreen
```

---

## 7. Screen Requirements

---

### 7.1 Login Screen

**Purpose:** Authenticate existing users.

**Layout (top → bottom):**
1. App logo + "Expense Care" wordmark (centered).
2. Tagline: "Take control of your spending."
3. Email text field (with inline validation).
4. Password text field (obscured, eye toggle, with inline validation).
5. "Forgot Password?" text button (right-aligned).
6. "Log In" primary button (full width).
7. Divider with "OR".
8. Google Sign-In button (full width, branded).
9. "Don't have an account? Sign Up" text link.

**UX Rules:**
- "Log In" button is disabled until both fields are non-empty.
- Show a loading overlay on the button while authentication is in progress.
- Display inline error messages below fields (not toast/snackbar) for field-level errors.
- Display a snackbar for network-level errors.

---

### 7.2 Sign Up Screen

**Purpose:** Create a new account.

**Layout:**
1. Back button (top-left).
2. "Create Account" heading.
3. Full Name text field.
4. Email text field.
5. Password text field (min 8 chars, eye toggle).
6. Confirm Password text field.
7. "Sign Up" primary button (full width, disabled until all valid).
8. Divider with "OR".
9. Google Sign-In button.
10. "Already have an account? Log In" text link.

**Post Sign-Up Flow:**
- Firebase sends an email verification (optional but recommended to add as v1.1).
- Navigate to a **Budget Setup Screen** (inline step, not a separate route) asking for: preferred currency, daily budget limit. Weekly and monthly are optional here and can be configured later in Profile.

---

### 7.3 Home Screen

**Purpose:** Daily budget overview and quick expense logging.

**Sections:**

#### A. Header Bar
- Left: greeting text ("Good morning, [First Name] 👋").
- Right: notification bell icon + current date.

#### B. Daily Budget Card (Priority Component)
- Large card at top.
- Displays: "Daily Budget" label, remaining amount in user's currency, spent amount vs. total budget.
- **Horizontal progress bar:**
  - Color: `success` when < 80% spent, `warning` when 80–99%, `error` when ≥ 100%.
  - Smooth animated fill on data load.
- Sub-text: "You've spent [X] of [Y] today."
- Over-budget state: card background tints red subtly; text reads "Over budget by [X]."

#### C. Quick Add Button
- Floating Action Button (FAB) or a prominent inline card button: "+ Add Expense".
- Opens **Add Expense Screen** as a modal bottom sheet on mobile; navigates to full screen on web.

#### D. Optional Budget Cards (Weekly / Monthly)
- Displayed only if the user has toggled them ON from the Profile screen.
- Shown as two smaller horizontal cards below the daily card.
- Same layout as daily card but labeled "Weekly" and "Monthly".
- Weekly card resets every Monday; monthly card resets on the 1st of each month.

#### E. Recent Expenses List
- Heading: "Recent Expenses" with a "See All" link.
- Shows the last 5 expenses.
- Each row: category icon (colored circle), expense name/note, category label, amount (in user's currency), relative time ("2 hours ago").
- Tapping a row opens an **Expense Detail** bottom sheet (view only, with edit/delete options).

**State Handling:**
- Empty state (no expenses today): illustration + "No expenses yet. Start tracking!"
- Offline state: show cached data with a subtle banner: "You're offline. Data may not be current."

---

### 7.4 Add Expense Screen

**Purpose:** Log a new expense.

**Presentation:** Modal bottom sheet on mobile (full height, drag to dismiss). Full page on web.

**Fields (top → bottom):**

1. **Amount Field** *(required)*
   - Large numeric input, prominently styled.
   - Currency symbol prefix auto-populated from user's preferred currency.
   - Keyboard type: decimal.
   - Inline validation: must be > 0.

2. **Currency Selector** *(optional override)*
   - Small dropdown next to the amount if user wants to log in a different currency.
   - App converts and stores the amount in the user's base currency.

3. **Category Selector** *(required)*
   - Horizontally scrollable chip row with icons and labels.
   - Default categories: 🍔 Food & Drink, 🚗 Transport, 🏠 Housing, 💊 Health, 🛍 Shopping, 🎮 Entertainment, 📚 Education, 💼 Work, ✈️ Travel, 🔧 Utilities, 🎁 Gifts, 📦 Other.
   - Active chip uses `primary` color fill.
   - Validation: a category must be selected.

4. **Date & Time** *(required, defaults to now)*
   - Tappable field that opens a `DateTimePicker`.
   - Defaults to current date and time.

5. **Note** *(optional)*
   - Single-line text input.
   - Max 200 characters with character counter.

6. **Add Picture** *(optional)*
   - Image picker button (camera or gallery).
   - Shows thumbnail preview after selection with a remove (×) option.
   - Image is uploaded to Firebase Storage; the URL is stored in the expense document.

7. **"Add Expense" Button** *(full width, primary)*
   - Disabled until amount and category are valid.
   - Shows loading state during submission.
   - On success: dismiss sheet, update Home screen totals optimistically, show success snackbar.

**Offline Behavior:**
- Expense is saved locally (Hive) and queued for Firestore sync when connectivity is restored.
- Images are queued for upload — show a "pending upload" indicator on the receipt thumbnail.

---

### 7.5 Goals Screen

**Purpose:** Let users create and fund savings goals in a gamified way.

#### A. Header
- "My Goals" title.
- "+" icon button to add a new goal (top-right).

#### B. Goals List
- Each goal displayed as a card:
  - Goal name and emoji/icon chosen by user.
  - Target amount and saved amount in user's currency.
  - **Circular progress ring** (like a game achievement): percentage filled, color `secondary`.
  - Progress text: "Saved [X] / [Y]" and percentage.
  - "Add Money" button (small, outlined) on the card.
  - Estimated completion date (if user set a target date).
  - A subtle animated confetti/checkmark when 100% is reached.

#### C. Add Goal Bottom Sheet
Fields:
- Goal name *(required, max 50 chars)*.
- Emoji/icon picker.
- Target amount *(required, > 0)*.
- Target date *(optional)* — calendar picker.
- Initial deposit *(optional)*.
- "Save Goal" primary button.

#### D. Add Money to Goal
- Tapping "Add Money" opens a simple bottom sheet:
  - Amount field.
  - "Confirm" button.
- Each deposit is recorded and contributes to the ring progress.

#### E. Empty State
- Illustration + "Set your first goal and start saving!" CTA button.

**Gamification Notes:**
- Progress ring animates on load and when funds are added.
- Goal completion triggers a full-screen celebration animation (Lottie).
- Completed goals remain visible with a "Completed 🎉" badge and can be archived.

---

### 7.6 Summary Screen

**Purpose:** Visual breakdown of expenses by date range and category.

#### A. Date Selector
- Toggleable options at top: **Day**, **Week**, **Month**, **Custom**.
- "Custom" opens an inline calendar range picker (using `table_calendar` or equivalent package).
- Selecting a preset or range **does not immediately show expense rows** — only aggregate/chart data is shown first.

#### B. Pie Chart
- Full-width interactive pie chart (use `fl_chart` package).
- Each slice = one expense category.
- Tapping a slice highlights it and shows a tooltip with: category name, total amount, percentage.
- Legend below the chart lists all categories with color dot, name, amount, and percentage.
- If no expenses in range: show an empty state illustration.

#### C. Category Breakdown List
- Listed below the pie chart.
- Each row: color dot, category icon, category name, total amount, percentage badge.
- **Tapping a category row** expands an in-line list (or navigates to a sub-screen) showing individual expenses in that category for the selected date range.
  - Each expense row: date/time, note, amount, thumbnail (if receipt attached).

#### D. Summary Stats Bar
- Displayed above the chart: total spent for the period, number of transactions, largest single expense.

---

### 7.7 Profile Screen

**Purpose:** User settings, budget limits, preferences.

#### A. User Info Section
- Avatar (from Google profile photo or initials fallback) + Display Name + Email.
- "Edit Profile" text button.

#### B. Budget Limits Section
- **Daily Limit** *(required)*: text field with currency prefix. Must always be set.
- **Weekly Limit** *(optional)*: toggle to enable + amount field. When enabled, appears on Home screen.
- **Monthly Limit** *(optional)*: toggle to enable + amount field. When enabled, appears on Home screen.
- "Save Limits" button (enabled only when there are unsaved changes).
- Inline validation: limits must be positive numbers. Weekly should be ≥ daily. Monthly should be ≥ weekly (show warning if not, but do not block).

#### C. Preferences Section
- **Preferred Currency**: tappable row → opens a searchable currency picker modal (list of ISO 4217 currencies with flag emoji and name).
- **Theme**: segmented control — Light / Dark / System.
- **Show Weekly Budget on Home**: toggle.
- **Show Monthly Budget on Home**: toggle.
- **Notifications**: toggle (budget alert at 80%, 100%; daily reminder).

#### D. Navigation Links
- "Recurring Expenses" → navigates to Recurring Expenses Screen.
- "Export Data" (CSV export — stretch goal for v1.1).

#### E. Account Actions
- "Sign Out" button (outlined, with confirmation dialog).
- "Delete Account" text button (danger color, with confirmation dialog + re-authentication).

---

### 7.8 Recurring Expenses Screen

**Purpose:** Manage automatically logged recurring expenses.

**Access:** Profile Screen → "Recurring Expenses".

#### A. Recurring Expenses List
- Each item: name, amount, category icon, frequency badge (Daily / Weekly / Monthly / Yearly), next due date.
- Swipe left to delete (with undo snackbar, 5s window).
- Tap to edit in bottom sheet.

#### B. Add Recurring Expense Button
- "+" FAB or top-right button.
- Opens a bottom sheet with fields:
  - Name *(required)*.
  - Amount *(required)*.
  - Currency *(optional override)*.
  - Category *(required)*.
  - Frequency: Daily / Weekly / Monthly / Yearly *(required)*.
  - Start Date *(required, defaults to today)*.
  - Note *(optional)*.
  - "Save" button.

#### C. Behavior
- On the scheduled date, a background function (Firebase Cloud Function or local scheduled task via `workmanager` package) automatically creates an expense entry.
- Users receive a push notification: "Recurring expense [Name] — [Amount] has been logged."
- Users can manually skip a single occurrence from the recurring expense detail view.

#### D. Empty State
- "No recurring expenses yet. Set one up to automate your tracking."

---

## 8. Data Models

### 8.1 User

```dart
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String preferredCurrency;   // ISO 4217 code, e.g., "USD"
  final double dailyLimit;
  final double? weeklyLimit;
  final double? monthlyLimit;
  final bool showWeeklyOnHome;
  final bool showMonthlyOnHome;
  final String themeMode;            // "light" | "dark" | "system"
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 8.2 Expense

```dart
class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String currency;             // ISO 4217
  final double amountInBaseCurrency; // Converted at time of entry
  final String categoryId;
  final String? note;
  final String? receiptImageUrl;
  final DateTime date;
  final bool isRecurring;
  final String? recurringId;         // Reference to RecurringExpense
  final bool syncedToFirestore;      // false if pending sync (offline)
  final DateTime createdAt;
}
```

### 8.3 Category

```dart
class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final String colorHex;
  final bool isDefault;              // System default vs. user-created
}
```

### 8.4 Goal

```dart
class GoalModel {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final String currency;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 8.5 GoalDeposit

```dart
class GoalDepositModel {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
}
```

### 8.6 RecurringExpense

```dart
class RecurringExpenseModel {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String currency;
  final String categoryId;
  final String frequency;            // "daily" | "weekly" | "monthly" | "yearly"
  final DateTime startDate;
  final DateTime nextDueDate;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
}
```

---

## 9. Firebase Architecture

### 9.1 Firestore Collections

```
/users/{userId}
/users/{userId}/expenses/{expenseId}
/users/{userId}/goals/{goalId}
/users/{userId}/goals/{goalId}/deposits/{depositId}
/users/{userId}/recurringExpenses/{recurringId}
```

### 9.2 Security Rules (High-Level)

```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;

  match /expenses/{expenseId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
  // Similar rules for goals, recurringExpenses
}
```

### 9.3 Firebase Storage

```
/receipts/{userId}/{expenseId}.jpg
/avatars/{userId}.jpg
```

### 9.4 Cloud Functions (Recommended)

| Function | Trigger | Purpose |
|---|---|---|
| `processRecurringExpenses` | Pub/Sub (daily schedule) | Auto-log due recurring expenses |
| `sendBudgetAlert` | Firestore onWrite | Trigger FCM when budget threshold exceeded |
| `cleanupOrphanedImages` | Firestore onDelete | Remove Storage files when expense deleted |

---

## 10. Offline Support

### 10.1 Strategy

- **Firestore Offline Persistence:** Enable `settings.persistenceEnabled = true`. Firestore automatically caches reads and queues writes.
- **Hive Local DB:** Used as a supplementary local store for: pending expense writes (when Firestore offline cache is cleared), user preferences, draft expenses.
- **Connectivity Monitoring:** Use `connectivity_plus` package to detect network state.

### 10.2 Behavior by Feature

| Feature | Offline Behavior |
|---|---|
| View expenses | Show from Firestore cache / Hive |
| Add expense | Save to Hive queue; sync to Firestore when online |
| Add expense image | Save locally; upload queued for when online |
| View goals | Show from cache |
| Add/fund goal | Queue write |
| View summary | Show from cached expense data |
| Profile changes | Save to Hive; sync when online |

### 10.3 Sync Indicator

- A small banner at the top of the screen: "Offline — changes will sync when connected." (uses `warning` color).
- When connectivity is restored, a success snackbar: "Back online. Syncing data…" followed by "All data synced ✓."

---

## 11. Currency Support

- Support all ISO 4217 currencies (at minimum the top 50 by usage).
- User selects a **base (preferred) currency** in Profile.
- When adding an expense in a different currency, the app fetches the exchange rate at time of entry and stores both: original amount + currency, and converted amount in base currency.
- All budget limits are in the base currency.
- Summary and Home screen display amounts in base currency.
- Exchange rate API: cache rates for up to 1 hour locally (Hive). Fall back to last known rate if offline.
- Display format: use `intl` package `NumberFormat.currency()` for locale-aware formatting.

---

## 12. Notifications

| Notification | Trigger | Condition |
|---|---|---|
| Budget Warning | Real-time (Firestore Function) | Daily spending reaches 80% of daily limit |
| Over Budget | Real-time | Daily spending reaches 100% |
| Recurring Expense Logged | Cloud Function (scheduled) | Recurring expense auto-logged |
| Daily Reminder | Scheduled (FCM, user configurable time) | User-enabled; prompts to log expenses |

- All notifications can be disabled globally from Profile screen.
- Notification preferences are stored in Firestore and respected across devices.

---

## 13. Form Validation Rules

All validation is **inline** (shown below the field as the user types or on field blur). No reliance on submit-time-only validation.

| Field | Rules |
|---|---|
| Email | Required · Valid email format (`RFC 5322` pattern) |
| Password (signup) | Required · Minimum 8 characters · At least 1 uppercase · 1 number |
| Confirm Password | Must match Password field |
| Full Name | Required · 2–60 characters · No special characters except hyphen and apostrophe |
| Daily Limit | Required · Numeric · > 0 · Max 10 digits |
| Weekly / Monthly Limit | Numeric · > 0 if enabled · Should be ≥ daily (warning if not) |
| Expense Amount | Required · Numeric · > 0 · Max 10 digits + 2 decimal places |
| Category | Required · Must select one |
| Goal Name | Required · 1–50 characters |
| Goal Target Amount | Required · Numeric · > 0 |
| Recurring Expense Name | Required · 1–80 characters |
| Note | Optional · Max 200 characters |

**Validation UX:**
- Error text appears below the field in `error` color.
- Field border changes to `error` color on invalid state.
- Error clears as soon as the input becomes valid (live validation).
- Success indicator (green border/checkmark) is shown only on required fields after valid input (optional, to reduce visual noise — team decision).

---

## 14. Accessibility & Responsiveness

### 14.1 Breakpoints

| Breakpoint | Width | Layout |
|---|---|---|
| Mobile | < 600dp | Single column, bottom navigation |
| Tablet | 600–839dp | Single column, bottom navigation (larger touch targets) |
| Web / Large Tablet | ≥ 840dp | Two-column where applicable, left sidebar navigation |

### 14.2 Touch Targets

Minimum touch target size: 48×48dp (Material guidelines).

### 14.3 Accessibility

- All interactive elements have `Semantics` labels.
- Color is never the sole indicator of state (always pair with icon or text).
- Minimum contrast ratio: 4.5:1 (WCAG AA) for all text.
- Support screen readers (TalkBack on Android, VoiceOver on iOS).

---

## 15. Security Requirements

- All Firestore reads/writes are protected by user-scoped security rules.
- Firebase Storage rules restrict access to the owning user's folder.
- No sensitive data (passwords, tokens) is stored in plain text locally.
- Google Sign-In uses the official `google_sign_in` Flutter package (OAuth 2.0).
- Receipt images are stored under authenticated paths in Firebase Storage.
- API keys are stored in environment variables / Firebase Remote Config — never hardcoded.
- Implement certificate pinning for production (optional for v1.0, recommended for v1.1).

---

## 16. Performance Requirements

| Metric | Target |
|---|---|
| App cold start (release build) | < 3 seconds |
| Home screen initial data load (cached) | < 500ms |
| Add Expense submission (online) | < 1 second |
| Pie chart render (< 50 data points) | < 200ms |
| Image upload (receipt, compressed) | < 5 seconds on 4G |
| Firestore query (30-day expense range) | < 1 second |

- Expense images must be compressed to max 1MB before upload (`flutter_image_compress`).
- Paginate expense lists: load 20 items at a time with infinite scroll.
- Use `const` constructors throughout Flutter widgets to minimize rebuilds.

---

## 17. Out of Scope (v1.0)

The following features are acknowledged but deferred to future versions:

- **v1.1:** Email verification after sign-up, CSV/PDF export, certificate pinning, custom user-defined categories, multi-device sync conflict resolution UI, Apple Sign-In.
- **v1.2:** Bank account / credit card import (Plaid or similar), shared budgets (families/couples), AI-powered spending insights.
- **v2.0:** Investment tracking, net worth dashboard, financial goals tied to bank accounts.

---

## Appendix A — Key Packages (pubspec.yaml reference)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Firebase
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  firebase_storage: ^latest
  firebase_messaging: ^latest
  # Auth
  google_sign_in: ^latest
  # State Management
  flutter_riverpod: ^latest   # or flutter_bloc
  # Navigation
  go_router: ^latest
  # Local Storage
  hive_flutter: ^latest
  # Charts
  fl_chart: ^latest
  # Calendar
  table_calendar: ^latest
  # Currency
  intl: ^latest
  # Connectivity
  connectivity_plus: ^latest
  # Image
  image_picker: ^latest
  flutter_image_compress: ^latest
  cached_network_image: ^latest
  # UI
  google_fonts: ^latest
  lottie: ^latest
  # Background tasks
  workmanager: ^latest
```

---

*Document maintained by the Expense Care Engineering & Design Team.*
*Last updated: March 1, 2026.*
