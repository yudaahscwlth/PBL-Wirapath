import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/test_result_model.dart';

/// Colored card displaying an issue to fix
class IssueToFixCard extends StatelessWidget {
  final TestIssue issue;

  const IssueToFixCard({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: issue.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: issue.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (issue.title.isNotEmpty) ...[
            Text(
              issue.title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: issue.titleColor,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            issue.description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.5,
              // The card background is always a light pastel (server-driven), so
              // pin the body text to a dark color in both themes — using the
              // theme's onSurface would render light-on-light in dark mode.
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}
