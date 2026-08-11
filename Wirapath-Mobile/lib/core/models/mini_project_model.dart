import 'dart:convert';

class UserMiniProjectSubmission {
  final String id;
  final String userId;
  final String miniProjectId;
  final String status; // 'not_started', 'in_progress', 'submitted', 'reviewed'
  final String? fileName;
  final String? fileUrl;
  final String? fileType;
  final double? overallScore;
  final List<String>? strengths;
  final List<String>? improvements;
  final List<Map<String, dynamic>>? objectivesMet;
  final String? aiSummary;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  UserMiniProjectSubmission({
    required this.id,
    required this.userId,
    required this.miniProjectId,
    required this.status,
    this.fileName,
    this.fileUrl,
    this.fileType,
    this.overallScore,
    this.strengths,
    this.improvements,
    this.objectivesMet,
    this.aiSummary,
    this.submittedAt,
    this.reviewedAt,
    required this.createdAt,
  });

  factory UserMiniProjectSubmission.fromMap(Map<String, dynamic> map) {
    // Backend usually returns these as parsed arrays, but they may also arrive
    // as raw JSON strings depending on the query path — handle both.
    List<String>? parseStringList(dynamic val) {
      if (val == null) return null;
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String) {
        try {
          final decoded = json.decode(val);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return null;
    }

    List<Map<String, dynamic>>? parseObjectives(dynamic val) {
      dynamic raw = val;
      if (raw is String) {
        try {
          raw = json.decode(raw);
        } catch (_) {
          return null;
        }
      }
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList();
      }
      return null;
    }

    return UserMiniProjectSubmission(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      miniProjectId: map['mini_project_id'] ?? '',
      status: map['status'] ?? 'not_started',
      fileName: map['file_name'],
      fileUrl: map['file_url'],
      fileType: map['file_type'],
      overallScore: (map['overall_score'] as num?)?.toDouble(),
      strengths: parseStringList(map['strengths']),
      improvements: parseStringList(map['improvements']),
      objectivesMet: parseObjectives(map['objectives_met']),
      aiSummary: map['ai_summary'],
      submittedAt: map['submitted_at'] != null ? DateTime.parse(map['submitted_at']) : null,
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at']) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }
}

class MiniProject {
  final String id;
  final String title;
  final String description;
  final String brief;
  final String level; // 'Beginner', 'Intermediate', 'Advanced'
  final String duration;
  final String tag;
  final List<String> relatedSkills;
  final List<String> evaluationCriteria;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final String submissionStatus; // 'not_started', 'in_progress', 'submitted', 'reviewed'
  final String? submissionId;
  final double? overallScore;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  MiniProject({
    required this.id,
    required this.title,
    required this.description,
    required this.brief,
    required this.level,
    required this.duration,
    required this.tag,
    required this.relatedSkills,
    required this.evaluationCriteria,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.submissionStatus,
    this.submissionId,
    this.overallScore,
    this.submittedAt,
    this.reviewedAt,
  });

  factory MiniProject.fromMap(Map<String, dynamic> map, String id) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return List<String>.from(val);
      if (val is String) {
        try {
          return List<String>.from(json.decode(val));
        } catch (_) {}
      }
      return [];
    }

    return MiniProject(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      brief: map['brief'] ?? '',
      level: map['level'] ?? map['difficulty'] ?? 'Intermediate',
      duration: (map['duration'] != null && map['duration'].toString().isNotEmpty)
          ? map['duration'].toString()
          : (map['estimated_hours'] != null ? '${map['estimated_hours']} hrs' : ''),
      tag: (map['tag'] != null && map['tag'].toString().isNotEmpty)
          ? map['tag'].toString()
          : (parseList(map['tech_stack']).isNotEmpty ? parseList(map['tech_stack']).first : ''),
      relatedSkills: parseList(map['related_skills']),
      evaluationCriteria: parseList(map['evaluation_criteria']),
      sortOrder: map['sort_order'] ?? 0,
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      submissionStatus: map['submission_status'] ?? 'not_started',
      submissionId: map['submission_id']?.toString(),
      overallScore: (map['overall_score'] as num?)?.toDouble(),
      submittedAt: map['submitted_at'] != null ? DateTime.parse(map['submitted_at']) : null,
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at']) : null,
    );
  }
}
