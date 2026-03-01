import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

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
      _GoalData(
        name: 'Emergency Fund',
        emoji: '🛡️',
        target: 5000,
        saved: 2800,
        color: AppColors.catHealth,
      ),
      _GoalData(
        name: 'New Camera',
        emoji: '📷',
        target: 800,
        saved: 150,
        color: AppColors.catShopping,
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            titleSpacing: 20,
            title: Text(
              'Goals',
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
              20,
              AppSpacing.sm,
              20,
              AppSpacing.sm + 80,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _GoalCard(goal: mockGoals[index], isDark: isDark),
                childCount: mockGoals.length,
              ),
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
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular progress + emoji
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: goal.pct,
                  strokeWidth: 5,
                  backgroundColor: borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                ),
                Text(goal.emoji, style: const TextStyle(fontSize: 26)),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Goal name
          Text(
            goal.name,
            style: AppTextStyles.labelLarge(
              color: isDark
                  ? AppColors.darkOnBackground
                  : AppColors.onBackground,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          // Saved / target
          Text(
            '${_fmt(goal.saved)} of ${_fmt(goal.target)}',
            style: AppTextStyles.labelSmall(
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Progress bar + percentage
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: goal.pct,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pctLabel,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: goal.color,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Add +',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: goal.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
