import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

enum AppButtonVariant { primary, outlined, text, danger }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    final labelWidget = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.variant == AppButtonVariant.primary
                    ? Colors.white
                    : primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(widget.label),
            ],
          );

    // text variant doesn't get scale wrapper
    if (widget.variant == AppButtonVariant.text) {
      return TextButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        child: Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primary,
          ),
        ),
      );
    }

    Widget inner;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        inner = SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: 54,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            child: labelWidget,
          ),
        );
      case AppButtonVariant.outlined:
        inner = SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: 54,
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            child: labelWidget,
          ),
        );
      case AppButtonVariant.danger:
        inner = SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: 54,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkError : AppColors.error,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
            ),
            child: labelWidget,
          ),
        );
      case AppButtonVariant.text:
        inner = const SizedBox.shrink(); // unreachable
    }

    final isEnabled = widget.onPressed != null && !widget.isLoading;
    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeInOut,
        child: inner,
      ),
    );
  }
}
