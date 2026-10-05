import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// "Continue with Google" button shared by the login and register pages.
///
/// The mark is painted rather than shipped as an asset so it stays crisp at any
/// size and needs no image in `assets/`.
class GoogleSignInButtonComponent extends StatelessWidget {
  const GoogleSignInButtonComponent({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.label = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w * 0.45;

    void drawArc(Color color, double startAngle, double sweepAngle) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.18
          ..strokeCap = StrokeCap.butt,
      );
    }

    drawArc(const Color(0xFF4285F4), -0.9, 1.4); // blue, top-right
    drawArc(const Color(0xFF34A853), 0.5, 1.2); // green, bottom-right
    drawArc(const Color(0xFFFBBC05), 1.7, 1.0); // yellow, bottom-left
    drawArc(const Color(0xFFEA4335), 2.7, 1.0); // red, top-left

    // The blue bar that forms the crossbar of the "G".
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - w * 0.09, w * 0.42, w * 0.18),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
