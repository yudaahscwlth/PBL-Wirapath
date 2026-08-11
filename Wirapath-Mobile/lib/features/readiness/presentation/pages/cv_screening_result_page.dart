import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CvScreeningResultPage extends StatelessWidget {
  /// Real analysis result from `POST /api/cv-screening/upload`. When null
  /// (e.g. the page is opened directly) we fall back to illustrative content.
  final Map<String, dynamic>? result;

  const CvScreeningResultPage({super.key, this.result});

  int get _overallScore {
    final raw = result?['overall_score'];
    if (raw is num) return raw.round().clamp(0, 100);
    if (raw is String) return (int.tryParse(raw) ?? 0).clamp(0, 100);
    return 0;
  }

  String? get _summary {
    final s = result?['ai_summary'];
    if (s is String && s.trim().isNotEmpty) return s;
    return null;
  }

  List<String> _list(String key) {
    final raw = result?[key];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return const [];
  }

  ({String label, Color color}) get _status {
    final s = _overallScore;
    if (s >= 80) return (label: "Excellent", color: const Color(0xFF10B981));
    if (s >= 60) return (label: "Good", color: AppColors.primaryBlue);
    if (s >= 40) return (label: "Needs Work", color: const Color(0xFFF97316));
    return (label: "Critical", color: const Color(0xFFEF4444));
  }

  @override
  Widget build(BuildContext context) {
    final hasRealData = result != null;
    final strengths = _list('strengths');
    final weaknesses = _list('weaknesses');
    final recommendations = _list('recommendations');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your CV has been reviewed", style: AppTextStyles.heading1.copyWith(fontSize: 18)),
                    const SizedBox(height: 16),

                    if (hasRealData) ...[
                      _buildScoreCard(context),
                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.star, "AI Review Summary"),
                      const SizedBox(height: 12),
                      Text(
                        _summary ??
                            "Your CV has been analyzed. Review the strengths and recommendations below to improve your screening match.",
                        style: AppTextStyles.bodySmall.copyWith(height: 1.5, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 32),
                      if (_overallScore >= 20) ...[
                        _buildSectionTitle(Icons.check_circle, "What's Already Good"),
                        const SizedBox(height: 16),
                        if (strengths.isEmpty)
                          Text("No specific strengths were highlighted.", style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))
                        else
                          ...strengths.map(_buildGoodItem),
                        const SizedBox(height: 32),
                      ],
                      _buildSectionTitle(Icons.build, "Issues to Fix"),
                      const SizedBox(height: 16),
                      if (weaknesses.isEmpty)
                        Text("No major issues found. Great work!", style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))
                      else
                        ...weaknesses.map((w) => _buildIssueItem(context, Icons.warning_amber_rounded, const Color(0xFFEF4444), w)),
                      if (recommendations.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSectionTitle(Icons.lightbulb_outline, "Actionable Next Steps"),
                        const SizedBox(height: 16),
                        ...recommendations.map((r) => _buildIssueItem(context, Icons.arrow_forward, AppColors.primaryBlue, r)),
                      ],
                    ] else ...[
                      _buildCvPreviewMock(context),
                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.star, "AI Review Summary"),
                      const SizedBox(height: 12),
                      Text(
                        "Your CV already has a solid foundation. It includes work experience, listed skills, and a fairly clean format. However, there are 3 critical areas that need improvement to pass ATS screening and capture a recruiter's attention within the first 6 seconds.",
                        style: AppTextStyles.bodySmall.copyWith(height: 1.5, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.menu, "Score by Category"),
                      const SizedBox(height: 16),
                      _buildScoreRow(context, "Structure & Completeness", 0.55, "55%", "Mostly complete, some details missing."),
                      _buildScoreRow(context, "Content Quality", 0.48, "48%", "Needs stronger, more impactful content."),
                      _buildScoreRow(context, "Skills & Keywords", 0.60, "60%", "Not fully optimized yet."),
                      _buildScoreRow(context, "Format & ATS Compatibility", 0.78, "78%", "Clean and ATS-friendly."),
                      _buildScoreRow(context, "First Impression", 0.58, "58%", "Good, but not standout."),
                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.check_circle, "What's Already Good"),
                      const SizedBox(height: 16),
                      _buildGoodItem("Photo and contact details are complete"),
                      _buildGoodItem("Work experience is well-structured"),
                      _buildGoodItem("CV length is ideal (1 page)"),
                      _buildGoodItem("No significant typos found"),
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/readiness-center'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop(),
          ),
          Column(
            children: [
              Text("CV Screening", style: AppTextStyles.heading1.copyWith(fontSize: 20)),
              Text("Get instant AI-powered analysis", style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
          // Invisible spacer balancing the leading back button so the title
          // stays centered in the spaceBetween row.
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Overall score ring + status, mirroring the web CVResultsView header.
  Widget _buildScoreCard(BuildContext context) {
    final status = _status;
    final score = _overallScore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(status.color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("$score", style: AppTextStyles.heading1.copyWith(fontSize: 28)),
                    Text("/100", style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Overall CV Score", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.label,
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: status.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCvPreviewMock(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("John Doe", style: AppTextStyles.heading1.copyWith(fontSize: 24, color: const Color(0xFF1E293B))),
          Text("Front End Developer", style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email, size: 10, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text("john.doe@email.com", style: AppTextStyles.bodySmall.copyWith(fontSize: 8, color: const Color(0xFF64748B))),
              const SizedBox(width: 12),
              const Icon(Icons.phone, size: 10, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text("+65 8123 4567", style: AppTextStyles.bodySmall.copyWith(fontSize: 8, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 16),
          Text("Professional Summary", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            "Recent Computer Science graduate with a passion for front end development. Proficient in React, Next.js, and modern JavaScript libraries. Eager to leverage academic background and internship experience to build responsive and user-friendly web applications.",
            style: AppTextStyles.bodySmall.copyWith(fontSize: 8, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
          Text("Skills", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)), child: Text("Core", style: AppTextStyles.bodySmall.copyWith(fontSize: 8, color: const Color(0xFF1E293B)))),
              const SizedBox(width: 4),
              Text("React 18, TypeScript, Next.js", style: AppTextStyles.bodySmall.copyWith(fontSize: 8, color: const Color(0xFF475569))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)), child: Text("Styling", style: AppTextStyles.bodySmall.copyWith(fontSize: 8, color: const Color(0xFF1E293B)))),
              const SizedBox(width: 4),
              Text("Tailwind CSS, CSS Modules", style: AppTextStyles.bodySmall.copyWith(fontSize: 8, color: const Color(0xFF475569))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.heading1.copyWith(fontSize: 16)),
      ],
    );
  }

  Widget _buildScoreRow(BuildContext context, String title, double progress, String percent, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: Text(title, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold))),
              Expanded(
                flex: 4,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).dividerColor,
                  color: AppColors.primaryBlue,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(percent, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGoodItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Color(0xFF388E3C), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildIssueItem(BuildContext context, IconData icon, Color color, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall.copyWith(height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}
