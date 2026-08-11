/// Result of the backend Jobdesk Analyzer (`POST /api/jobdesk/analyze`).
///
/// Mirrors the web `JobdeskAnalysisResult` shape (lib/api.ts) so the mobile app
/// stays consistent with the website and shares the same backend/LLM pipeline.
/// This is separate from the HF skill-predictor ([JobAnalysisResponse]) which
/// remains available as a mobile-only extra.
class JobdeskAnalysisResult {
  final double matchScore;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final List<String> recommendations;
  final String summary;

  JobdeskAnalysisResult({
    required this.matchScore,
    required this.matchingSkills,
    required this.missingSkills,
    required this.recommendations,
    required this.summary,
  });

  factory JobdeskAnalysisResult.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    return JobdeskAnalysisResult(
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      matchingSkills: toStringList(json['matching_skills']),
      missingSkills: toStringList(json['missing_skills']),
      recommendations: toStringList(json['recommendations']),
      summary: json['summary'] as String? ?? '',
    );
  }
}
