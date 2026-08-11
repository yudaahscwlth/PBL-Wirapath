
import 'dart:convert';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool hasCompletedAssessment;
  final String role;
  final Map<String, double> skills;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.lastActive,
    this.hasCompletedAssessment = false,
    this.role = 'user',
    this.skills = const {},
    this.preferences = const {},
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? hasCompletedAssessment,
    String? role,
    Map<String, double>? skills,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      hasCompletedAssessment:
          hasCompletedAssessment ?? this.hasCompletedAssessment,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'hasCompletedAssessment': hasCompletedAssessment,
      'role': role,
      'skills': skills,
      'preferences': preferences,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final university = map['university'] ?? map['preferences']?['university'] ?? '';
    final major = map['field_of_study'] ?? map['preferences']?['major'] ?? '';
    final graduationYear = map['graduation_year']?.toString() ?? map['preferences']?['graduationYear'] ?? '';
    final cvUrl = map['cv_url'] ?? map['preferences']?['cvUrl'] ?? '';
    final transcriptUrl = map['transcript_url'] ?? map['preferences']?['transcriptUrl'] ?? '';

    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 
          ((map['first_name'] != null || map['last_name'] != null)
              ? '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'.trim()
              : '') ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : (map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now()),
      lastActive: map['lastActive'] != null 
          ? DateTime.parse(map['lastActive']) 
          : (map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now()),
      hasCompletedAssessment: map['hasCompletedAssessment'] ?? map['onboarding_completed'] ?? false,
      role: map['role'] ?? map['target_role'] ?? 'user',
      skills: Map<String, double>.from(map['skills'] ?? {}),
      preferences: {
        'university': university,
        'major': major,
        'graduationYear': graduationYear,
        'cvUrl': cvUrl,
        'transcriptUrl': transcriptUrl,
      },
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source), '');
}
