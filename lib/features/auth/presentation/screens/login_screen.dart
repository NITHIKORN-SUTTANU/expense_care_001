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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _forgotLoading = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailCtrl.text.isNotEmpty && _passwordCtrl.text.isNotEmpty;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authNotifierProvider.notifier)
        .signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
    if (ok && mounted) context.go(AppRoutes.home);
    if (!ok && mounted) _showError();
  }

  Future<void> _signInGoogle() async {
    final ok =
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (ok && mounted) context.go(AppRoutes.home);
    if (!ok && mounted) _showError();
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _snack('Enter your email address first.', isError: true);
      return;
    }
    setState(() => _forgotLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_emailCtrl.text);
      if (mounted) _snack('Password reset email sent.');
    } catch (_) {
      if (mounted) _snack('Could not send reset email.', isError: true);
    } finally {
      if (mounted) setState(() => _forgotLoading = false);
    }
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
                    const SizedBox(height: 52),

                    // ── Logo ────────────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary,
                              Color.lerp(primary, Colors.purple, 0.35)!,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppRadius.icon + 4),
                          boxShadow: AppColors.primaryGlow(primary),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Headline ─────────────────────────────────────────────
                    Text(
                      'Welcome back',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: onBg,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to continue',
                      style: AppTextStyles.bodyMedium(color: muted),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

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
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      prefixIcon:
                          Icon(Icons.lock_outline_rounded, size: 20, color: muted),
                      onFieldSubmitted: (_) => _signIn(),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Password is required' : null,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: muted,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),

                    // ── Forgot password ──────────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotLoading ? null : _forgotPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        child: _forgotLoading
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: primary),
                              )
                            : Text(
                                'Forgot password?',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: primary,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // ── Sign In ──────────────────────────────────────────────
                    AppButton(
                      label: 'Sign In',
                      onPressed: _canSubmit && !isLoading ? _signIn : null,
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

                    const SizedBox(height: AppSpacing.xl),

                    // ── Sign up link ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?  ",
                          style: AppTextStyles.bodyMedium(color: muted),
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.signup),
                          child: Text(
                            'Sign Up',
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
