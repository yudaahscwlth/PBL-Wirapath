import 'package:flutter/material.dart';

/// Custom painter that draws the Wirapath "W" logo
/// Based on the design: a stylized blue double-stroke W/checkmark shape
class WirapathLogoPainter extends CustomPainter {
  final Color color;
  final double opacity;

  WirapathLogoPainter({
    this.color = const Color(0xFF2979FF),
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Back stroke (left, lighter blue stroke)
    final backStroke = Path();
    backStroke.moveTo(w * 0.05, h * 0.55);
    backStroke.lineTo(w * 0.22, h * 0.55);
    backStroke.lineTo(w * 0.50, h * 0.88);
    backStroke.lineTo(w * 0.62, h * 0.70);
    backStroke.lineTo(w * 0.50, h * 0.70);
    backStroke.lineTo(w * 0.35, h * 0.55);
    backStroke.lineTo(w * 0.50, h * 0.35);
    backStroke.lineTo(w * 0.36, h * 0.35);
    backStroke.lineTo(w * 0.22, h * 0.50);
    backStroke.close();

    canvas.drawPath(backStroke, paint);

    // Front stroke (right, main blue stroke going up-right)
    final frontStroke = Path();
    frontStroke.moveTo(w * 0.30, h * 0.55);
    frontStroke.lineTo(w * 0.48, h * 0.55);
    frontStroke.lineTo(w * 0.50, h * 0.58);
    frontStroke.lineTo(w * 0.72, h * 0.20);
    frontStroke.lineTo(w * 0.88, h * 0.20);
    frontStroke.lineTo(w * 0.58, h * 0.72);
    frontStroke.lineTo(w * 0.50, h * 0.85);
    frontStroke.lineTo(w * 0.42, h * 0.72);
    frontStroke.close();

    // Upper tick mark
    final upperTick = Path();
    upperTick.moveTo(w * 0.50, h * 0.18);
    upperTick.lineTo(w * 0.62, h * 0.18);
    upperTick.lineTo(w * 0.95, h * 0.55);
    upperTick.lineTo(w * 0.83, h * 0.55);
    upperTick.lineTo(w * 0.56, h * 0.25);
    upperTick.close();

    canvas.drawPath(frontStroke, paint);
    canvas.drawPath(upperTick, paint);
  }

  @override
  bool shouldRepaint(covariant WirapathLogoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}

class WirapathLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;

  const WirapathLogo({
    super.key,
    this.size = 120,
    this.color,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: WirapathLogoPainter(
        color: color ?? const Color(0xFF2979FF),
        opacity: opacity,
      ),
    );
  }
}
