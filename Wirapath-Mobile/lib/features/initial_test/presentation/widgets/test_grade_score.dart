import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Circular score indicator with progress ring
class TestGradeScore extends StatelessWidget {
  final String scoreValue;
  final double numericScore;
  final double maxScore;
  final String submittedDate;
  final String statusText;
  final Color statusColor;
  final Color statusTextColor;

  const TestGradeScore({
    super.key,
    required this.scoreValue,
    required this.numericScore,
    required this.maxScore,
    required this.submittedDate,
    required this.statusText,
    required this.statusColor,
    required this.statusTextColor,
  });

  Color _getProgressColor() {
    final ratio = maxScore > 0 ? numericScore / maxScore : 0;
    if (ratio >= 0.75) return const Color(0xFF10B981); // green
    if (ratio >= 0.6) return const Color(0xFFEAB308); // yellow
    if (ratio >= 0.4) return const Color(0xFFF97316); // orange
    return const Color(0xFFEF4444); // red
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular score
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFDDEBFF),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          // FittedBox keeps 3-digit scores (e.g. 100/100) on one line by
          // scaling the text down instead of wrapping inside the circle.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              maxLines: 1,
              text: TextSpan(
              children: [
                TextSpan(
                  text: scoreValue.contains('/') ? scoreValue.split('/')[0] : scoreValue,
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D47A1),
                  ),
                ),
                if (scoreValue.contains('/'))
                  TextSpan(
                    text: '/${scoreValue.split('/')[1]}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.6),
                    ),
                  )
                else
                  TextSpan(
                    text: '/${maxScore % 1 == 0 ? maxScore.toInt() : maxScore}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.6),
                    ),
                  ),
              ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test Graded',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                submittedDate,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
