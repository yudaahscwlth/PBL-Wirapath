class JobAnalysisResponse {
  final String jobTitle;
  final double matchedJobSimilarity;
  final double matchedJobSimilarityPct;
  final List<PredictedSkill> skills;
  final String status;
  final double thresholdApplied;

  JobAnalysisResponse({
    required this.jobTitle,
    required this.matchedJobSimilarity,
    required this.matchedJobSimilarityPct,
    required this.skills,
    required this.status,
    required this.thresholdApplied,
  });

  factory JobAnalysisResponse.fromJson(Map<String, dynamic> json) {
    var skillsList = json['skills'] as List? ?? [];
    List<PredictedSkill> parsedSkills = skillsList
        .map((skillJson) => PredictedSkill.fromJson(skillJson as Map<String, dynamic>))
        .toList();

    return JobAnalysisResponse(
      jobTitle: json['job_title'] as String? ?? '',
      matchedJobSimilarity: (json['matched_job_similarity'] as num?)?.toDouble() ?? 0.0,
      matchedJobSimilarityPct: (json['matched_job_similarity_pct'] as num?)?.toDouble() ?? 0.0,
      skills: parsedSkills,
      status: json['status'] as String? ?? '',
      thresholdApplied: (json['threshold_applied'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_title': jobTitle,
      'matched_job_similarity': matchedJobSimilarity,
      'matched_job_similarity_pct': matchedJobSimilarityPct,
      'skills': skills.map((skill) => skill.toJson()).toList(),
      'status': status,
      'threshold_applied': thresholdApplied,
    };
  }
}

class PredictedSkill {
  final double confidence;
  final double confidencePct;
  final String skill;

  PredictedSkill({
    required this.confidence,
    required this.confidencePct,
    required this.skill,
  });

  factory PredictedSkill.fromJson(Map<String, dynamic> json) {
    return PredictedSkill(
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      confidencePct: (json['confidence_pct'] as num?)?.toDouble() ?? 0.0,
      skill: json['skill'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'confidence': confidence,
      'confidence_pct': confidencePct,
      'skill': skill,
    };
  }
}
