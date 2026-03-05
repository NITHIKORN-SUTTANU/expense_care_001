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
import '../../../../shared/widgets/error_snackbar.dart';
import '../../../expense/data/expense_repository.dart';
import '../../../expense/domain/models/expense_model.dart';
import '../../../expense/presentation/screens/add_expense_screen.dart';
import '../../../profile/presentation/widgets/budget_limit_form.dart';
import '../widgets/ai_chat_card.dart';
import '../widgets/daily_budget_card.dart';
import '../widgets/optional_budget_cards.dart';
import '../widgets/recent_expenses_list.dart';
import '../../../../shared/utils/expense_actions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  void _openAddExpense(BuildContext context) {
    showAppBottomSheet(
      context: context,
      title: 'Add Expense',
      child: const AddExpenseScreen(),
    );
  }

  void _openEditExpense(BuildContext context, ExpenseModel expense) {
    if (expense.isRecurring) {
      // Show the same dialog used by swipe-to-delete for consistency.
      final messenger = ScaffoldMessenger.of(context);
      showExpenseDeleteDialog(context, expense).then((confirmed) async {
        if (confirmed != true || !mounted) return;
        try {
          await deleteExpenseAndSync(
              expense, ref.read(expenseRepositoryProvider));
        } catch (_) {
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Failed to delete. Please try again.'),
              ),
            );
          }
        }
      });
      return;
    }
    showAppBottomSheet(
      context: context,
      title: 'Edit Expense',
      child: AddExpenseScreen(expense: expense),
    );
  }

  /// Deletes [expense] from Firestore.
  /// For savings expenses linked to a goal, also decrements the goal's progress.
  Future<void> _deleteExpense(
    BuildContext context,
    ExpenseModel expense,
  ) async {
    try {
      await deleteExpenseAndSync(expense, ref.read(expenseRepositoryProvider));
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Failed to delete. Please try again.');
      }
    }
  }

  void _openBudgetSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => const _BudgetSetupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            systemOverlayStyle:
                isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                          style: AppTextStyles.labelSmall(color: Colors.white),
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
                  const AiChatCard(),
                  const SizedBox(height: AppSpacing.md),
                  RecentExpensesList(
                    expenses: recentExpenses,
                    onSeeAll: () => context.go(AppRoutes.summary),
                    onExpenseTap: (expense) =>
                        _openEditExpense(context, expense),
                    onDelete: (expense) => _deleteExpense(context, expense),
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
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 64,
            color: primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Set your budget first',
            style: AppTextStyles.titleLarge(
              color:
                  isDark ? AppColors.darkOnBackground : AppColors.onBackground,
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

// ── Budget setup bottom sheet (2-step wizard) ────────────────────────────────

// Currency list shared with profile screen.
const _kCurrencies = [
  ('THB', 'Thai Baht', '฿'),
  ('USD', 'US Dollar', '\$'),
  ('EUR', 'Euro', '€'),
  ('GBP', 'British Pound', '£'),
  ('JPY', 'Japanese Yen', '¥'),
  ('CNY', 'Chinese Yuan', '¥'),
  ('KRW', 'Korean Won', '₩'),
  ('SGD', 'Singapore Dollar', 'S\$'),
  ('AUD', 'Australian Dollar', 'A\$'),
  ('CAD', 'Canadian Dollar', 'C\$'),
  ('CHF', 'Swiss Franc', 'Fr'),
  ('HKD', 'Hong Kong Dollar', 'HK\$'),
  ('INR', 'Indian Rupee', '₹'),
  ('MYR', 'Malaysian Ringgit', 'RM'),
  ('IDR', 'Indonesian Rupiah', 'Rp'),
  ('PHP', 'Philippine Peso', '₱'),
  ('VND', 'Vietnamese Dong', '₫'),
];

class _BudgetSetupSheet extends ConsumerStatefulWidget {
  const _BudgetSetupSheet();

  @override
  ConsumerState<_BudgetSetupSheet> createState() => _BudgetSetupSheetState();
}

class _BudgetSetupSheetState extends ConsumerState<_BudgetSetupSheet> {
  int _step = 0; // 0 = currency, 1 = budget
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userPreferencesNotifierProvider);
    _selectedCurrency = user?.preferredCurrency ?? 'USD';
  }

  void _goToStep2() => setState(() => _step = 1);
  void _goBack() => setState(() => _step = 0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final onBg = isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: bg,
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
          // ── Drag handle ───────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(
                  top: AppSpacing.xs, bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                if (_step == 1)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _goBack,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 20, color: onBg),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step == 0
                            ? 'Choose Your Currency'
                            : 'Set Up Your Budget',
                        style: AppTextStyles.titleLarge(color: onBg),
                      ),
                      Text(
                        'Step ${_step + 1} of 2',
                        style: AppTextStyles.labelSmall(
                          color: isDark ? AppColors.darkMuted : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: dividerColor),

          // ── Step content ──────────────────────────────────────────
          if (_step == 0)
            ..._buildCurrencyStep(isDark, primary, dividerColor)
          else
            ..._buildBudgetStep(isDark),
        ],
      ),
    );
  }

  // ── Step 1: currency list ─────────────────────────────────────────────────

  List<Widget> _buildCurrencyStep(
    bool isDark,
    Color primary,
    Color dividerColor,
  ) {
    final onBg = isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;

    return [
      Flexible(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _kCurrencies.length,
          itemBuilder: (_, i) {
            final (code, name, symbol) = _kCurrencies[i];
            final isSelected = code == _selectedCurrency;
            return InkWell(
              onTap: () => setState(() => _selectedCurrency = code),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(color: dividerColor, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.15)
                            : bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          symbol,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? primary
                                : (isDark
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.titleMedium(color: onBg),
                          ),
                          Text(
                            code,
                            style: AppTextStyles.labelSmall(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: primary, size: 22),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _goToStep2,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? AppColors.darkPrimary : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    ];
  }

  // ── Step 2: budget limits ─────────────────────────────────────────────────

  List<Widget> _buildBudgetStep(bool isDark) {
    final user = ref.read(userPreferencesNotifierProvider);
    final currencySymbol = NumberFormat.simpleCurrency(
      name: _selectedCurrency,
    ).currencySymbol;

    return [
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
              final notifier =
                  ref.read(userPreferencesNotifierProvider.notifier);
              // Save currency first (no-op if unchanged).
              final currentCurrency = ref
                      .read(userPreferencesNotifierProvider)
                      ?.preferredCurrency ??
                  'USD';
              if (_selectedCurrency != currentCurrency) {
                await notifier.updateCurrency(_selectedCurrency);
              }
              // Then save limits.
              await notifier.updateLimits(
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
    ];
  }
}
