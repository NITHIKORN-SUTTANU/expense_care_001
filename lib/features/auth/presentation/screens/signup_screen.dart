import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtrl.text.isNotEmpty &&
      _emailCtrl.text.isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authNotifierProvider.notifier).signUpWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text,
        );
    if (ok && mounted) context.go(AppRoutes.home);
    if (!ok && mounted) _showError();
  }

  Future<void> _signInGoogle() async {
    final ok =
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (ok && mounted) context.go(AppRoutes.home);
    if (!ok && mounted) _showError();
  }

  void _showError() {
    final msg = ref.read(authNotifierProvider.notifier).errorMessage ??
        'Something went wrong.';
    _snack(msg, isError: true);
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip)),
      margin: const EdgeInsets.all(AppSpacing.sm),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    final onBg = isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: onBg),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xs),

                    // ── Heading ──────────────────────────────────────────────
                    Text(
                      'Create account',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: onBg,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start tracking your expenses today.',
                      style: AppTextStyles.bodyMedium(color: muted),
                    ),

                    const SizedBox(height: 32),

                    // ── Full Name ────────────────────────────────────────────
                    AppTextField(
                      controller: _nameCtrl,
                      label: 'Full name',
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          size: 20, color: muted),
                      validator: Validators.fullName,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // ── Email ────────────────────────────────────────────────
                    AppTextField(
                      controller: _emailCtrl,
                      label: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(Icons.mail_outline_rounded,
                          size: 20, color: muted),
                      validator: Validators.email,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // ── Password ─────────────────────────────────────────────
                    AppTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                          size: 20, color: muted),
                      validator: Validators.password,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: muted,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Confirm Password ─────────────────────────────────────
                    AppTextField(
                      controller: _confirmCtrl,
                      label: 'Confirm password',
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                          size: 20, color: muted),
                      onFieldSubmitted: (_) => _signUp(),
                      validator: (v) =>
                          Validators.confirmPassword(v, _passwordCtrl.text),
                      onChanged: (_) => setState(() {}),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: muted,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Sign Up ──────────────────────────────────────────────
                    AppButton(
                      label: 'Create Account',
                      onPressed: _canSubmit && !isLoading ? _signUp : null,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Divider ──────────────────────────────────────────────
                    _OrDivider(isDark: isDark),

                    const SizedBox(height: AppSpacing.md),

                    // ── Google ───────────────────────────────────────────────
                    GoogleSignInButton(
                      onPressed: isLoading ? null : _signInGoogle,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Log in link ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?  ',
                          style: AppTextStyles.bodyMedium(color: muted),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            'Log In',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    return Row(
      children: [
        Expanded(child: Divider(color: divColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: AppTextStyles.labelSmall(color: muted),
          ),
        ),
        Expanded(child: Divider(color: divColor)),
      ],
    );
  }
}
