import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DataAnalysisReviewPage extends StatelessWidget {
  const DataAnalysisReviewPage({super.key});

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
                "Data Analysis",
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
                "DTAN",
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
              "File Upload • Short Essay",
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
                            text: "76",
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
                        color: const Color(0xFFFEEAC7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Needs Revision",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB47409),
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
              "Data cleaning and revenue analysis are well done. The regression model was implemented but R² was not interpreted in the notebook. The essay covers customer segment insight but misses the limitations question entirely.",
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
                    Expanded(child: _buildGridMetric(context, "Data Cleaning", const Icon(Icons.check, color: Colors.green), "Documented Well")),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGridMetric(context, "Visualizations", const Icon(Icons.check, color: Colors.green), "Both Clean")),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildGridMetric(context, "Regeression R²", const Icon(Icons.close, color: Colors.red), "Not Interpreted")),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGridMetric(context, 
                      "Essay Length", 
                      Text(
                        "118", 
                        style: GoogleFonts.poppins(
                          color: Colors.orange, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 24,
                        ),
                      ), 
                      "Target 150 - 250 words",
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
              title: "R² result not interpreted",
              description: "You reported R² = 0.43 but didn't explain what it means. Add 1-2 sentences: 'The model explains 43% of variance in units sold, suggesting moderate predictive power",
              bgColor: const Color(0xFFFFEBEE),
              borderColor: const Color(0xFFFFCDD2),
              titleColor: Colors.red[900]!,
            ),
            const SizedBox(height: 16),
            _buildIssueCard(
      context: context,
              title: "Essay missing limitations section",
              description: "Question 3 of the essay prompt asks for limitations and what additional data would improve the analysis. Your essay skipped this entirely — it's a required part.",
              bgColor: const Color(0xFFFEEAC7),
              borderColor: const Color(0xFFFFE0B2),
              titleColor: Colors.orange[900]!,
            ),
            const SizedBox(height: 16),
            _buildIssueCard(
      context: context,
              title: "Essay too short (118 words)",
              description: "Minimum is 150 words. Expand on the limitations section to reach the target while answering all 3 questions.",
              bgColor: const Color(0xFFFEEAC7),
              borderColor: const Color(0xFFFFE0B2),
              titleColor: Colors.orange[900]!,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              // Card bg is always a light pastel — pin body text dark so it
              // stays readable in dark mode (onSurface would be light-on-light).
              color: const Color(0xFF1A1A2E),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
