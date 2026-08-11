import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class UXDesignReviewPage extends StatelessWidget {
  const UXDesignReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => context.go('/readiness-center', extra: {'initialTabIndex': 1}),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                "User Experience Design",
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEC85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "HCEV",
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Design Brief • Portfolio Upload",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 32),
            
            // Score Section
            Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD6EDFF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "88",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF0D3E9B),
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                            ),
                          ),
                          TextSpan(
                            text: "/100",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF787D8A),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Test Graded",
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Submitted March 4, 2026",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF787D8A),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F9F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Strong Submission",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // AI Review Summary
            _buildSectionHeader(
              context: context,
              icon: Icons.star_rounded,
              title: "AI Review Summary",
            ),
            const SizedBox(height: 12),
            Text(
              "User flow and wireframes are well structured — the 7-step onboarding is clear and logical. Visual hierarchy is strong. Two gaps: persona lacks a tech comfort level, and the design rationale is only 72 words (below 100).",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Grid Metrics
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildGridMetric(context, "User Persona", const Icon(Icons.check, color: Color(0xFF10B981)), "Documented Well")),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGridMetric(context, "User Flow", const Icon(Icons.check, color: Color(0xFF10B981)), "Clear")),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildGridMetric(context, "Wireframes", const Icon(Icons.check, color: Color(0xFF10B981)), "Good")),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGridMetric(context, 
                      "Rationale", 
                      Text(
                        "72w", 
                        style: GoogleFonts.poppins(
                          color: Colors.orange, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 24,
                        ),
                      ), 
                      "Target 100 - 150w",
                    )),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Issue to Fix
            _buildSectionHeader(
              context: context,
              icon: Icons.build_rounded,
              title: "Issue to Fix",
            ),
            const SizedBox(height: 16),
            
            _buildIssueCard(
      context: context,
              title: "Prototype not clickable on screen 4",
              description: "The 'Connect bank' CTA on frame 4 has no interaction linked in Figma. Connect it to the success confirmation screen to complete the primary path.",
              bgColor: const Color(0xFFFFF7E6),
              borderColor: const Color(0xFFFFD591),
              titleColor: const Color(0xFFB47409),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/readiness-center', extra: {'initialTabIndex': 1});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF066EFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Close",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required BuildContext context, required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0844C5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildGridMetric(BuildContext context, String title, Widget icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            icon,
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildIssueCard({
    required BuildContext context,
    required String title,
    required String description,
    required Color bgColor,
    required Color borderColor,
    required Color titleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1A1A2E),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
