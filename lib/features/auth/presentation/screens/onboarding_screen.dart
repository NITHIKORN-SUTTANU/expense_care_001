import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_router.dart';

// ── Slide data ────────────────────────────────────────────────────────────────

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.color,
    required this.headline,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String headline;
  final String subtitle;
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.receipt_long_rounded,
    color: Color(0xFF4F6EF7),
    headline: 'Track Every Expense',
    subtitle:
        'Log and categorize your daily spending in seconds. Stay on top of where your money goes.',
  ),
  _OnboardingSlide(
    icon: Icons.savings_rounded,
    color: Color(0xFF43A047),
    headline: 'Set & Achieve Goals',
    subtitle:
        'Define financial goals and track your progress. Save towards the things that matter most.',
  ),
  _OnboardingSlide(
    icon: Icons.autorenew_rounded,
    color: Color(0xFFFB8C00),
    headline: 'Manage Recurring Bills',
    subtitle:
        'Never miss a subscription or bill. Expense Care tracks all your scheduled payments automatically.',
  ),
  _OnboardingSlide(
    icon: Icons.bar_chart_rounded,
    color: Color(0xFFA78BFA),
    headline: 'Get Spending Insights',
    subtitle:
        'Beautiful charts and summaries help you understand your financial habits at a glance.',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.landing);
    }
  }

  void _skip() => context.go(AppRoutes.landing);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: isLast ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: isLast ? null : _skip,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) =>
                    _SlidePage(slide: _slides[i], isDark: isDark),
              ),
            ),

            // ── Dots ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? _slides[_currentPage].color
                        : (isDark ? AppColors.darkDivider : AppColors.divider),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Next / Get Started button ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: ElevatedButton(
                    key: ValueKey(isLast),
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _slides[_currentPage].color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: Text(
                      isLast ? 'Get Started' : 'Next',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ── Individual slide ──────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide, required this.isDark});

  final _OnboardingSlide slide;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final mutedColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon blob
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: slide.color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 72,
              color: slide.color,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.headline,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.55,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
