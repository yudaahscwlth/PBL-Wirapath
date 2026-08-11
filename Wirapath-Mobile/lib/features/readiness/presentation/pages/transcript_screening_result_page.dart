import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/transcript_screening_model.dart';

class TranscriptScreeningResultPage extends StatelessWidget {
  final TranscriptScreening result;

  const TranscriptScreeningResultPage({super.key, required this.result});

  ({String label, Color color}) get _status {
    final s = result.overallScore;
    if (s >= 80) return (label: "Excellent", color: const Color(0xFF10B981));
    if (s >= 60) return (label: "Good", color: AppColors.primaryBlue);
    if (s >= 40) return (label: "Needs Work", color: const Color(0xFFF97316));
    return (label: "Critical", color: const Color(0xFFEF4444));
  }

  @override
  Widget build(BuildContext context) {
    final strengths = result.strengths;
    final weaknesses = result.weaknesses;
    final recommendations = result.recommendations;

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
                    Text("Your Transcript has been reviewed", style: AppTextStyles.heading1.copyWith(fontSize: 18)),
                    const SizedBox(height: 16),
                    _buildScoreCard(context),
                    const SizedBox(height: 32),
                    _buildSectionTitle(Icons.star, "AI Review Summary"),
                    const SizedBox(height: 12),
                    Text(
                      result.aiSummary.isNotEmpty
                          ? result.aiSummary
                          : "Your academic transcript has been analyzed. Review the strengths and recommendations below to improve your readiness.",
                      style: AppTextStyles.bodySmall.copyWith(height: 1.5, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(Icons.check_circle, "What's Already Good"),
                    const SizedBox(height: 16),
                    if (strengths.isEmpty)
                      Text("No specific strengths were highlighted.", style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))
                    else
                      ...strengths.map(_buildGoodItem),
                    const SizedBox(height: 32),
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
              Text("Transcript Screening", style: AppTextStyles.heading1.copyWith(fontSize: 20)),
              Text("Get instant AI-powered analysis", style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final status = _status;
    final score = result.overallScore;
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
                Text("Overall Transcript Score", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
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
