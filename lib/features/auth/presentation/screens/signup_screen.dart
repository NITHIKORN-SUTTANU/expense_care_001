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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
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
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(
          color: isDark ? AppColors.darkOnBackground : AppColors.onBackground,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Heading ───────────────────────────────────────────────
                Text(
                  'Create Account',
                  style: AppTextStyles.headlineMedium(
                    color: isDark
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Start tracking your expenses today.',
                  style: AppTextStyles.bodyMedium(
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Full Name ─────────────────────────────────────────────
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  textInputAction: TextInputAction.next,
                  validator: Validators.fullName,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),

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
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Confirm Password ──────────────────────────────────────
                AppTextField(
                  controller: _confirmCtrl,
                  label: 'Confirm Password',
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signUp(),
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordCtrl.text),
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Sign Up button ────────────────────────────────────────
                AppButton(
                  label: 'Sign Up',
                  onPressed: _canSubmit && !isLoading ? _signUp : null,
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

                // ── Log in link ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium(
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Log In',
                        style: AppTextStyles.labelLarge(color: primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
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
