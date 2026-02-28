import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../expense/domain/models/expense_model.dart';
import '../widgets/daily_budget_card.dart';
import '../widgets/optional_budget_cards.dart';
import '../widgets/recent_expenses_list.dart';
import '../widgets/quick_add_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Mock data (replace with Riverpod providers in production) ───────────
  static const double _dailySpent = 53.24;
  static const double _dailyBudget = 80.00;
  static const double _weeklySpent = 213.50;
  static const double _weeklyBudget = 400.00;
  static const double _monthlySpent = 642.00;
  static const double _monthlyBudget = 1200.00;
  static const bool _showWeekly = true;
  static const bool _showMonthly = true;

  final List<ExpenseModel> _recentExpenses = _buildMockExpenses();

  static List<ExpenseModel> _buildMockExpenses() {
    final now = DateTime.now();
    return [
      ExpenseModel(
        id: '1',
        userId: 'u1',
        amount: 4.50,
        currency: 'USD',
        amountInBaseCurrency: 4.50,
        categoryId: 'food',
        note: 'Morning Coffee',
        date: now.subtract(const Duration(hours: 2)),
        syncedToFirestore: true,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      ExpenseModel(
        id: '2',
        userId: 'u1',
        amount: 12.00,
        currency: 'USD',
        amountInBaseCurrency: 12.00,
        categoryId: 'transport',
        note: 'Grab to office',
        date: now.subtract(const Duration(hours: 5)),
        syncedToFirestore: true,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      ExpenseModel(
        id: '3',
        userId: 'u1',
        amount: 8.75,
        currency: 'USD',
        amountInBaseCurrency: 8.75,
        categoryId: 'food',
        note: 'Lunch',
        date: now.subtract(const Duration(hours: 6)),
        syncedToFirestore: true,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      ExpenseModel(
        id: '4',
        userId: 'u1',
        amount: 34.99,
        currency: 'USD',
        amountInBaseCurrency: 34.99,
        categoryId: 'shopping',
        note: 'Amazon order',
        date: now.subtract(const Duration(days: 1)),
        syncedToFirestore: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ExpenseModel(
        id: '5',
        userId: 'u1',
        amount: 15.99,
        currency: 'USD',
        amountInBaseCurrency: 15.99,
        categoryId: 'entertainment',
        note: 'Netflix',
        date: now.subtract(const Duration(days: 2)),
        syncedToFirestore: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

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

  void _onAddExpense() {
    // TODO: show AddExpenseScreen as bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpensePlaceholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 0,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            systemOverlayStyle:
                isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            titleSpacing: AppSpacing.sm,
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
                  '$_greeting, Alex 👋',
                  style: AppTextStyles.titleLarge(
                    color: isDark
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm + 80, // bottom nav + extra space
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Daily Budget Card
                const DailyBudgetCard(
                  spent: _dailySpent,
                  budget: _dailyBudget,
                  currency: 'USD',
                ),

                const SizedBox(height: 12),

                // Weekly / Monthly cards
                const OptionalBudgetCards(
                  weeklySpent: _weeklySpent,
                  weeklyBudget: _weeklyBudget,
                  monthlySpent: _monthlySpent,
                  monthlyBudget: _monthlyBudget,
                  showWeekly: _showWeekly,
                  showMonthly: _showMonthly,
                  currency: 'USD',
                ),

                const SizedBox(height: AppSpacing.sm),

                // Quick Add Button
                QuickAddFab(onPressed: _onAddExpense),

                const SizedBox(height: AppSpacing.md),

                // Recent Expenses
                RecentExpensesList(
                  expenses: _recentExpenses,
                  onSeeAll: () {},
                  onExpenseTap: (expense) {
                    // TODO: show expense detail bottom sheet
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Placeholder bottom sheet for Add Expense ──────────────────────────────────
class _AddExpensePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheetTop),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add Expense',
            style: AppTextStyles.titleLarge(
              color:
                  isDark ? AppColors.darkOnBackground : AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '(Full Add Expense screen coming in next increment)',
            style: AppTextStyles.bodyMedium(
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
