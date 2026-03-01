import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: surfaceColor,
            titleSpacing: 20,
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
              child: Divider(height: 1, color: borderColor),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, AppSpacing.sm, 20, AppSpacing.sm + 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Period selector ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.chip + 4),
                    border: Border.all(color: borderColor),
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
                              borderRadius: BorderRadius.circular(AppRadius.chip),
                            ),
                            child: Text(
                              _periods[i],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
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

                const SizedBox(height: AppSpacing.sm),

                // ── Stats bar ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: borderColor),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _Stat(
                          label: 'Total Spent',
                          value: '\$${_total.toStringAsFixed(2)}',
                          isDark: isDark,
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: borderColor,
                          indent: 4,
                          endIndent: 4,
                        ),
                        _Stat(
                          label: 'Transactions',
                          value: '47',
                          isDark: isDark,
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: borderColor,
                          indent: 4,
                          endIndent: 4,
                        ),
                        _Stat(
                          label: 'Largest',
                          value: '\$187.40',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Pie chart ─────────────────────────────────────────────
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

                const SizedBox(height: AppSpacing.md),

                // ── Category list ─────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Column(
                      children: _categories.asMap().entries.map((entry) {
                        final i = entry.key;
                        final cat = entry.value;
                        final pct =
                            (cat.amount / _total * 100).toStringAsFixed(0);
                        final isLast = i == _categories.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: cat.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(cat.emoji,
                                      style: const TextStyle(fontSize: 18)),
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
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '$pct%',
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.darkMuted
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: borderColor,
                                indent: 16,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
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
          mainAxisAlignment: MainAxisAlignment.center,
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

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.categories, required this.total});
  final List<_CatData> categories;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55;
    final arcCenter = Offset(size.width / 2, size.height / 2);
    final arcRadius = (outerRadius + innerRadius) / 2;
    final arcRect = Rect.fromCircle(center: arcCenter, radius: arcRadius);

    double startAngle = -90 * (3.14159 / 180);
    for (final cat in categories) {
      final sweepAngle = (cat.amount / total) * 2 * 3.14159;
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
