import 'dart:math' as math;
import 'package:flutter/material.dart';

/// --- CUSTOM PAINTER UNTUK SKILL MAP (RADAR CHART) ---
/// Tampilannya identik dengan _SkillMapPainter di Readiness Center.
class RadarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final Color labelColor;
  final Color gridColor;

  const RadarChartPainter({
    required this.labels,
    required this.values,
    this.labelColor = const Color(0xFF757575),
    this.gridColor = const Color(0xFFE1F0FF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || labels.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2 + 8);
    // Larger radius for clearer radar chart visualization with room for single-line top label
    final radius = math.min(size.width / 2, size.height / 2) - 38;
    final n = labels.length;

    // Warna dot sesuai nilai skill
    final List<Color> dotColors = values.map((v) {
      if (v >= 0.70) return const Color(0xFF388E3C); // hijau
      if (v >= 0.40) return const Color(0xFFF57F17); // oranye
      return const Color(0xFFD32F2F);                // merah
    }).toList();

    // Paint untuk garis grid (identik dengan Readiness Center)
    final outlinePaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Paint untuk fill area skill
    final fillPaint = Paint()
      ..color = const Color(0xFF90CAF9).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Paint untuk stroke border area skill
    final strokePaint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 1. Gambar 4 Ring Konsentris (identik Readiness Center pakai 4 ring)
    for (int i = 1; i <= 4; i++) {
      final r = radius * (i / 4);
      final path = Path();
      for (int j = 0; j < n; j++) {
        final angle = j * (2 * math.pi / n) - (math.pi / 2);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, outlinePaint);
    }

    // 2. Gambar Garis Sumbu dari Tengah
    for (int j = 0; j < n; j++) {
      final angle = j * (2 * math.pi / n) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), outlinePaint);
    }

    // 3. Gambar Area Skill (Fill + Stroke border)
    final valuePath = Path();
    for (int j = 0; j < n; j++) {
      final angle = j * (2 * math.pi / n) - (math.pi / 2);
      final val = values.length > j ? values[j] : 0.0;
      final r = radius * val;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (j == 0) {
        valuePath.moveTo(x, y);
      } else {
        valuePath.lineTo(x, y);
      }
    }
    valuePath.close();
    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, strokePaint);

    // 4. Gambar Dot & Label
    for (int j = 0; j < n; j++) {
      final angle = j * (2 * math.pi / n) - (math.pi / 2);

      // Dot pada radius luar
      final dotPos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final dotPaint = Paint()..color = dotColors[j];
      canvas.drawCircle(dotPos, 5, dotPaint);

      // Label di luar dot
      final labelRadius = radius + 14;
      final lx = center.dx + labelRadius * math.cos(angle);
      final ly = center.dy + labelRadius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[j],
          style: TextStyle(
            color: labelColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: 110);

      double textX = lx;
      double textY = ly;

      // Alignment horizontal
      if (math.cos(angle) > 0.1) {
        textX = lx + 6;
      } else if (math.cos(angle) < -0.1) {
        textX = lx - textPainter.width - 6;
      } else {
        textX = lx - textPainter.width / 2;
      }

      // Alignment vertikal
      if (math.sin(angle) > 0.1) {
        if (math.cos(angle).abs() < 0.1) {
          textY = ly + 6;
        } else {
          textY = dotPos.dy - textPainter.height / 2;
        }
      } else if (math.sin(angle) < -0.1) {
        if (math.cos(angle).abs() < 0.1) {
          textY = ly - textPainter.height - 6;
        } else {
          textY = dotPos.dy - textPainter.height / 2;
        }
      } else {
        textY = ly - textPainter.height / 2;
      }

      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) =>
      oldDelegate.labels != labels ||
      oldDelegate.values != values ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor;
}
