import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_emailCtrl.text);
      if (mounted) _snack('Password reset email sent.');
    } catch (_) {
      if (mounted) _snack('Could not send reset email.', isError: true);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // ── Logo ─────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Expense Care',
                  style: AppTextStyles.headlineMedium(
                    color: isDark
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Take control of your spending.',
                  style: AppTextStyles.bodyMedium(
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Email ─────────────────────────────────────────────────
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Password ──────────────────────────────────────────────
                AppTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Password is required' : null,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),

                // ── Forgot password ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.labelLarge(color: primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // ── Log In button ─────────────────────────────────────────
                AppButton(
                  label: 'Log In',
                  onPressed: _canSubmit && !isLoading ? _signIn : null,
                  isLoading: isLoading,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── OR divider ────────────────────────────────────────────
                _OrDivider(isDark: isDark),
                const SizedBox(height: AppSpacing.md),

                // ── Google ────────────────────────────────────────────────
                GoogleSignInButton(
                  onPressed: isLoading ? null : _signInGoogle,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Sign up link ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium(
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.signup),
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.labelLarge(color: primary),
                      ),
                    ),
                  ],
                ),
              ],
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
    return Row(
      children: [
        Expanded(child: Divider(color: divColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: AppTextStyles.labelSmall(
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
          ),
        ),
        Expanded(child: Divider(color: divColor)),
      ],
    );
  }
}
