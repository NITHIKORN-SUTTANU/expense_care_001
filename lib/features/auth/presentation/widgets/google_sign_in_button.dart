import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          side: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleColorIcon(size: 20),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: AppTextStyles.labelLarge(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleColorIcon extends StatelessWidget {
  const _GoogleColorIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const _GPainter(),
    );
  }
}

class _GPainter extends StatelessWidget {
  const _GPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleIconPainter());
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1;
    const sw = 3.0;

    Paint p(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final rect = Rect.fromCircle(center: c, radius: r);

    // Blue – top arc (90° to 270° going CCW = -π/2 to π/2)
    canvas.drawArc(rect, -1.57, 3.14, false, p(blue));
    // Red – bottom-right
    canvas.drawArc(rect, 1.57, 1.17, false, p(red));
    // Yellow – bottom-left
    canvas.drawArc(rect, 2.74, 0.69, false, p(yellow));
    // Green – left
    canvas.drawArc(rect, 3.43, 0.69, false, p(green));

    // Horizontal bar (the G cutout)
    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(size.width - 1, c.dy),
      p(blue)..strokeWidth = sw,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
