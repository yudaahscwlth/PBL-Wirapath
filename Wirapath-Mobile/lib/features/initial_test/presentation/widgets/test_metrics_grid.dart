import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/test_result_model.dart';

/// 2x2 metrics grid showing check/cross/value for each metric
class TestMetricsGrid extends StatelessWidget {
  final List<TestMetric> metrics;

  const TestMetricsGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Build rows of 2
        for (int i = 0; i < metrics.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: _MetricCell(metric: metrics[i])),
                const SizedBox(width: 12),
                if (i + 1 < metrics.length)
                  Expanded(child: _MetricCell(metric: metrics[i + 1]))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  final TestMetric metric;

  const _MetricCell({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Value display: checkmark, cross, or text
          if (metric.checkStatus != null)
            Icon(
              metric.checkStatus! ? Icons.check_circle : Icons.cancel,
              size: 28,
              color: metric.checkStatus!
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            )
          else if (metric.valueText != null)
            Text(
              metric.valueText!,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: metric.valueColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          const SizedBox(height: 6),
          // Label
          Text(
            metric.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (metric.sublabel != null) ...[
            const SizedBox(height: 2),
            Text(
              metric.sublabel!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
