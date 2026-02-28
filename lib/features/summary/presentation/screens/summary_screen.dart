import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _selectedPeriod = 2; // Month

  static const _periods = ['Day', 'Week', 'Month', 'Custom'];

  final _categories = const [
    _CatData('Food & Drink', '🍔', 234.50, AppColors.catFood),
    _CatData('Transport', '🚗', 98.00, AppColors.catTransport),
    _CatData('Shopping', '🛍', 187.40, AppColors.catShopping),
    _CatData('Entertainment', '🎮', 65.99, AppColors.catEntertainment),
    _CatData('Health', '💊', 57.00, AppColors.catHealth),
  ];

  double get _total => _categories.fold(0, (s, c) => s + c.amount);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            title: Text(
              'Summary',
              style: AppTextStyles.titleLarge(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
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
                // Period selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: List.generate(_periods.length, (i) {
                      final isSelected = _selectedPeriod == i;
                      final primary =
                          isDark ? AppColors.darkPrimary : AppColors.primary;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              _periods[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.darkMuted
                                        : AppColors.muted),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // Stats bar
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                    boxShadow: isDark ? null : AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      _Stat(
                        label: 'Total Spent',
                        value: '\$${_total.toStringAsFixed(2)}',
                        isDark: isDark,
                      ),
                      _VerticalDivider(isDark: isDark),
                      _Stat(
                        label: 'Transactions',
                        value: '47',
                        isDark: isDark,
                      ),
                      _VerticalDivider(isDark: isDark),
                      _Stat(
                        label: 'Largest',
                        value: '\$187.40',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Simple pie chart (using fl_chart in production)
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _PieChartPainter(
                        categories: _categories,
                        total: _total,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${_total.toStringAsFixed(0)}',
                              style: AppTextStyles.titleLarge(
                                color: isDark
                                    ? AppColors.darkOnBackground
                                    : AppColors.onBackground,
                              ),
                            ),
                            Text(
                              'total',
                              style: AppTextStyles.labelSmall(
                                color: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Category list
                ..._categories.map((cat) {
                  final pct = (cat.amount / _total * 100).toStringAsFixed(0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
                        boxShadow: isDark ? null : AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: AppTextStyles.labelLarge(
                                color: isDark
                                    ? AppColors.darkOnBackground
                                    : AppColors.onBackground,
                              ),
                            ),
                          ),
                          Text(
                            '\$${cat.amount.toStringAsFixed(2)}',
                            style: AppTextStyles.labelLarge(
                              color: isDark
                                  ? AppColors.darkOnBackground
                                  : AppColors.onBackground,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: cat.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: cat.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatData {
  const _CatData(this.name, this.emoji, this.amount, this.color);
  final String name;
  final String emoji;
  final double amount;
  final Color color;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.isDark});
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.titleMedium(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall(
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: isDark ? AppColors.darkDivider : AppColors.divider,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.categories, required this.total});
  final List<_CatData> categories;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55;
    final rect = Rect.fromCircle(center: center, radius: outerRadius);

    double startAngle = -90 * (3.14159 / 180);
    for (final cat in categories) {
      final sweepAngle = (cat.amount / total) * 2 * 3.14159;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius
        ..color = cat.color;

      final arcCenter = Offset(size.width / 2, size.height / 2);
      final arcRadius = (outerRadius + innerRadius) / 2;
      final arcRect = Rect.fromCircle(center: arcCenter, radius: arcRadius);
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius - 4
        ..color = cat.color;

      canvas.drawArc(arcRect, startAngle, sweepAngle - 0.04, false, arcPaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
