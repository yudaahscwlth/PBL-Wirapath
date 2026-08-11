import 'dart:convert';

class TranscriptScreening {
  final String id;
  final String userId;
  final String fileName;
  final String fileUrl;
  final int overallScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final String aiSummary;
  final String createdAt;

  TranscriptScreening({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileUrl,
    required this.overallScore,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.aiSummary,
    required this.createdAt,
  });

  factory TranscriptScreening.fromMap(Map<String, dynamic> map) {
    List<String> parseStringList(dynamic val) {
      if (val == null) return const [];
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      return const [];
    }

    int parseOverallScore(dynamic val) {
      if (val is num) return val.round();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return TranscriptScreening(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      fileName: map['file_name']?.toString() ?? map['fileName']?.toString() ?? '',
      fileUrl: map['file_url']?.toString() ?? map['fileUrl']?.toString() ?? '',
      overallScore: parseOverallScore(map['overall_score'] ?? map['overallScore']),
      strengths: parseStringList(map['strengths']),
      weaknesses: parseStringList(map['weaknesses']),
      recommendations: parseStringList(map['recommendations']),
      aiSummary: map['ai_summary']?.toString() ?? map['aiSummary']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? map['createdAt']?.toString() ?? '',
    );
  }

  factory TranscriptScreening.fromJson(String source) =>
      TranscriptScreening.fromMap(json.decode(source));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'file_name': fileName,
      'file_url': fileUrl,
      'overall_score': overallScore,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations,
      'ai_summary': aiSummary,
      'created_at': createdAt,
    };
  }
}
