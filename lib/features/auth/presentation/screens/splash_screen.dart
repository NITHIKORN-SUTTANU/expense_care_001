import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _animCtrl.forward();

    // Wait at least 1.5 s, then navigate based on auth state.
    // FirebaseAuth.instance.currentUser is synchronously available after
    // Firebase is initialised in main.dart.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textColor =
        isDark ? AppColors.darkOnBackground : AppColors.onBackground;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon container
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(77),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Expense Care',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your money, your control',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color:
                        isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
