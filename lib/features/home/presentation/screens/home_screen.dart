import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/user_preferences_provider.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expense/data/expense_repository.dart';
import '../../../expense/domain/models/expense_model.dart';
import '../../../expense/presentation/screens/add_expense_screen.dart';
import '../../../profile/presentation/widgets/budget_limit_form.dart';
import '../../../recurring/domain/models/recurring_expense_model.dart';
import '../widgets/daily_budget_card.dart';
import '../widgets/optional_budget_cards.dart';
import '../widgets/recent_expenses_list.dart';

DateTime _nextDue(String frequency, DateTime base) => switch (frequency) {
      'daily' => base.add(const Duration(days: 1)),
      'weekly' => base.add(const Duration(days: 7)),
      'monthly' => _addMonths(base, 1),
      'yearly' => _addMonths(base, 12),
      _ => base,
    };

/// Advances [base] by [months], clamping the day to the last valid day of
/// the target month (e.g. Jan 31 + 1 month → Feb 28/29, not Mar 2/3).
DateTime _addMonths(DateTime base, int months) {
  final totalMonth = base.month - 1 + months;
  final year = base.year + totalMonth ~/ 12;
  final month = totalMonth % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day; // day 0 = last of prev month
  return DateTime(year, month, base.day.clamp(1, lastDay));
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _recurringChecked = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateLabel {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _runRecurringCheck(uid);
    });
  }

  void _openAddExpense(BuildContext context) {
    showAppBottomSheet(
      context: context,
      title: 'Add Expense',
      child: const AddExpenseScreen(),
    );
  }

  void _openEditExpense(BuildContext context, ExpenseModel expense) {
    showAppBottomSheet(
      context: context,
      title: 'Edit Expense',
      child: AddExpenseScreen(expense: expense),
    );
  }

  void _openBudgetSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetSetupSheet(ref: ref),
    );
  }

  Future<void> _runRecurringCheck(String uid) async {
    if (_recurringChecked) return;
    _recurringChecked = true;
    try {
      final now = DateTime.now();

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recurring')
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      bool hasWork = false;

      for (final doc in snap.docs) {
        final item = RecurringExpenseModel.fromMap(doc.data(), doc.id);
        var due = item.nextDueDate;

        // Skip if nothing is due yet
        if (due.isAfter(now)) continue;

        // Create one expense per missed occurrence
        while (!due.isAfter(now)) {
          final expRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('expenses')
              .doc('${item.id}_${due.millisecondsSinceEpoch}');

          batch.set(
            expRef,
            {
              'userId': uid,
              'amount': item.amount,
              'currency': item.currency,
              'amountInBaseCurrency': item.amount,
              'categoryId': item.categoryId,
              'note': item.note ?? item.name,
              'date': due.toIso8601String(),
              'isRecurring': true,
              'recurringId': item.id,
              'goalId': null,
              'receiptImageUrl': null,
              'syncedToFirestore': true,
              'createdAt': now.toIso8601String(),
            },
            SetOptions(merge: false),
          );

          due = _nextDue(item.frequency, due);
          hasWork = true;
        }

        // Advance nextDueDate to the next future occurrence
        batch.update(doc.reference, {'nextDueDate': due.toIso8601String()});
      }

      if (hasWork) await batch.commit();
    } catch (_) {
      // Allow retry next time the widget mounts if something went wrong
      _recurringChecked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger check when auth resolves after mount (e.g. cold start)
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user != null) _runRecurringCheck(user.uid);
      });
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = ref.watch(userPreferencesNotifierProvider);
    final dailySpent = ref.watch(dailyTotalProvider).valueOrNull ?? 0.0;
    final weeklySpent = ref.watch(weeklyTotalProvider).valueOrNull ?? 0.0;
    final monthlySpent = ref.watch(monthlyTotalProvider).valueOrNull ?? 0.0;
    final recentExpenses = ref.watch(recentExpensesProvider).valueOrNull ?? [];

    final dailyBudget = user?.dailyLimit ?? 0.0;
    final weeklyBudget = user?.weeklyLimit ?? 0.0;
    final monthlyBudget = user?.monthlyLimit ?? 0.0;
    final showWeekly = user?.showWeeklyOnHome ?? false;
    final showMonthly = user?.showMonthlyOnHome ?? false;
    final currency = user?.preferredCurrency ?? 'USD';
    final firstName = user?.firstName ?? '';

    // user == null  → Firestore not loaded yet (always logged in on this screen)
    // user != null && dailyBudget == 0  → truly no budget set
    final userLoaded = user != null;
    final budgetReady = userLoaded && dailyBudget > 0;

    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      floatingActionButton: budgetReady
          ? FloatingActionButton.extended(
              onPressed: () => _openAddExpense(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense'),
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 2,
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 0,
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.surface,
            systemOverlayStyle: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateLabel,
                  style: AppTextStyles.labelSmall(
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
                Text(
                  firstName.isEmpty ? _greeting : '$_greeting, $firstName',
                  style: AppTextStyles.titleLarge(
                    color: isDark
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                ),
              ],
            ),
            actions: const [SizedBox(width: 4)],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
          ),

          // ── Offline banner ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: isOnline ? 0 : 36,
              color: isDark ? AppColors.darkWarning : AppColors.warning,
              child: isOnline
                  ? null
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'No internet connection',
                          style: AppTextStyles.labelSmall(
                              color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          if (!userLoaded)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!budgetReady)
            SliverFillRemaining(
              child: _BudgetSetupPrompt(
                isDark: isDark,
                onSetUp: () => _openBudgetSetup(context),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                AppSpacing.sm,
                20,
                AppSpacing.sm + 80,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DailyBudgetCard(
                    spent: dailySpent,
                    budget: dailyBudget,
                    currency: currency,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  OptionalBudgetCards(
                    weeklySpent: weeklySpent,
                    weeklyBudget: weeklyBudget,
                    monthlySpent: monthlySpent,
                    monthlyBudget: monthlyBudget,
                    showWeekly: showWeekly,
                    showMonthly: showMonthly,
                    currency: currency,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  RecentExpensesList(
                    expenses: recentExpenses,
                    onSeeAll: () => context.go(AppRoutes.summary),
                    onExpenseTap: (expense) =>
                        _openEditExpense(context, expense),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Budget setup prompt ───────────────────────────────────────────────────────

class _BudgetSetupPrompt extends StatelessWidget {
  const _BudgetSetupPrompt({
    required this.isDark,
    required this.onSetUp,
  });

  final bool isDark;
  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💰', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Set your budget first',
            style: AppTextStyles.titleLarge(
              color: isDark
                  ? AppColors.darkOnBackground
                  : AppColors.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Before tracking expenses, set a daily budget limit so we can help you stay on track.',
            style: AppTextStyles.bodyMedium(
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onSetUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Text(
                'Set Up Budget',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Budget setup bottom sheet ─────────────────────────────────────────────────

class _BudgetSetupSheet extends StatelessWidget {
  const _BudgetSetupSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.read(userPreferencesNotifierProvider);
    final currency = user?.preferredCurrency ?? 'USD';
    final currencySymbol =
        NumberFormat.simpleCurrency(name: currency).currencySymbol;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheetTop),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(
                  top: AppSpacing.xs, bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
            child: Text(
              'Set Up Your Budget',
              style: AppTextStyles.titleLarge(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: BudgetLimitForm(
                dailyLimit: user?.dailyLimit ?? 0.0,
                weeklyLimit: user?.weeklyLimit,
                monthlyLimit: user?.monthlyLimit,
                showWeekly: user?.showWeeklyOnHome ?? false,
                showMonthly: user?.showMonthlyOnHome ?? false,
                currencySymbol: currencySymbol,
                onSave: ({
                  required double daily,
                  double? weekly,
                  double? monthly,
                  required bool showWeekly,
                  required bool showMonthly,
                }) async {
                  await ref
                      .read(userPreferencesNotifierProvider.notifier)
                      .updateLimits(
                        dailyLimit: daily,
                        weeklyLimit: weekly,
                        monthlyLimit: monthly,
                        showWeeklyOnHome: showWeekly,
                        showMonthlyOnHome: showMonthly,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
