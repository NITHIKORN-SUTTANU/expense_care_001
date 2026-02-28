import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final secondary = isDark ? AppColors.darkSecondary : AppColors.secondary;

    final mockGoals = [
      _GoalData(
        name: 'New MacBook',
        emoji: '💻',
        target: 2000,
        saved: 1340,
        color: primary,
      ),
      _GoalData(
        name: 'Bali Trip',
        emoji: '✈️',
        target: 1500,
        saved: 420,
        color: secondary,
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            title: Text(
              'My Goals',
              style: AppTextStyles.titleLarge(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () {},
                tooltip: 'Add Goal',
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm + 80,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...mockGoals.map((goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GoalCard(goal: goal, isDark: isDark),
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalData {
  _GoalData({
    required this.name,
    required this.emoji,
    required this.target,
    required this.saved,
    required this.color,
  });
  final String name;
  final String emoji;
  final double target;
  final double saved;
  final Color color;
  double get pct => saved / target;
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.isDark});
  final _GoalData goal;
  final bool isDark;

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

  @override
  Widget build(BuildContext context) {
    final pctLabel = '${(goal.pct * 100).toStringAsFixed(0)}%';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          // Progress ring + emoji
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: goal.pct,
                  strokeWidth: 5,
                  backgroundColor:
                      (isDark ? AppColors.darkDivider : AppColors.divider),
                  valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                ),
                Text(goal.emoji, style: const TextStyle(fontSize: 24)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: AppTextStyles.titleMedium(
                    color: isDark
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saved ${_fmt(goal.saved)} of ${_fmt(goal.target)}',
                  style: AppTextStyles.bodyMedium(
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: goal.pct,
                    backgroundColor:
                        isDark ? AppColors.darkDivider : AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pctLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: goal.color,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(60, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  side: BorderSide(color: goal.color, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: goal.color,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Add +'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
