import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textColor =
        isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final mutedColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Logo + branding ─────────────────────────────────────
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withAlpha(64),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Expense Care',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your money, your control',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: mutedColor,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Feature pills ────────────────────────────────────────
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _FeaturePill(
                        icon: Icons.receipt_long_rounded,
                        label: 'Track',
                        isDark: isDark,
                      ),
                      _FeaturePill(
                        icon: Icons.savings_rounded,
                        label: 'Save',
                        isDark: isDark,
                      ),
                      _FeaturePill(
                        icon: Icons.bar_chart_rounded,
                        label: 'Analyse',
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // ── Sign In button ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Create Account button ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.signup),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        backgroundColor: surfaceColor,
                        side: BorderSide(color: borderColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Feature pill ──────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final mutedColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
