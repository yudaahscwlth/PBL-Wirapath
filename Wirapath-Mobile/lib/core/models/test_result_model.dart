import 'dart:convert';

import 'package:flutter/material.dart';

class TestResultData {
  Color get badgeColor => Color(int.parse(badgeColorHex));
  Color get badgeTextColor => Color(int.parse(badgeTextColorHex));
  Color get statusColor => Color(int.parse(statusColorHex));
  Color get statusTextColor => Color(int.parse(statusTextColorHex));

  final String id;
  final String userId;
  final String testId;
  final String testTitle;
  final String testSubtitle;
  final String badgeText;
  final String badgeColorHex;
  final String badgeTextColorHex;
  final String scoreValue;
  final double maxScore;
  final double numericScore;
  final DateTime submittedDate;
  final String statusText;
  final String statusColorHex;
  final String statusTextColorHex;
  final String aiSummary;
  final String? quotedText;
  final List<TestMetric>? metrics;
  final List<TestIssue> issues;
  final String? uploadedFileUrl;
  final Map<String, String>? essayAnswers;

  TestResultData({
    required this.id,
    required this.userId,
    required this.testId,
    required this.testTitle,
    required this.testSubtitle,
    required this.badgeText,
    required this.badgeColorHex,
    required this.badgeTextColorHex,
    required this.scoreValue,
    required this.maxScore,
    required this.numericScore,
    required this.submittedDate,
    required this.statusText,
    required this.statusColorHex,
    required this.statusTextColorHex,
    required this.aiSummary,
    this.quotedText,
    this.metrics,
    required this.issues,
    this.uploadedFileUrl,
    this.essayAnswers,
  });

  TestResultData copyWith({
    String? id,
    String? userId,
    String? testId,
    String? testTitle,
    String? testSubtitle,
    String? badgeText,
    String? badgeColorHex,
    String? badgeTextColorHex,
    String? scoreValue,
    double? maxScore,
    double? numericScore,
    DateTime? submittedDate,
    String? statusText,
    String? statusColorHex,
    String? statusTextColorHex,
    String? aiSummary,
    String? quotedText,
    List<TestMetric>? metrics,
    List<TestIssue>? issues,
    String? uploadedFileUrl,
    Map<String, String>? essayAnswers,
  }) {
    return TestResultData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      testId: testId ?? this.testId,
      testTitle: testTitle ?? this.testTitle,
      testSubtitle: testSubtitle ?? this.testSubtitle,
      badgeText: badgeText ?? this.badgeText,
      badgeColorHex: badgeColorHex ?? this.badgeColorHex,
      badgeTextColorHex: badgeTextColorHex ?? this.badgeTextColorHex,
      scoreValue: scoreValue ?? this.scoreValue,
      maxScore: maxScore ?? this.maxScore,
      numericScore: numericScore ?? this.numericScore,
      submittedDate: submittedDate ?? this.submittedDate,
      statusText: statusText ?? this.statusText,
      statusColorHex: statusColorHex ?? this.statusColorHex,
      statusTextColorHex: statusTextColorHex ?? this.statusTextColorHex,
      aiSummary: aiSummary ?? this.aiSummary,
      quotedText: quotedText ?? this.quotedText,
      metrics: metrics ?? this.metrics,
      issues: issues ?? this.issues,
      uploadedFileUrl: uploadedFileUrl ?? this.uploadedFileUrl,
      essayAnswers: essayAnswers ?? this.essayAnswers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'testId': testId,
      'testTitle': testTitle,
      'testSubtitle': testSubtitle,
      'badgeText': badgeText,
      'badgeColorHex': badgeColorHex,
      'badgeTextColorHex': badgeTextColorHex,
      'scoreValue': scoreValue,
      'maxScore': maxScore,
      'numericScore': numericScore,
      'submittedDate': submittedDate.toIso8601String(),
      'statusText': statusText,
      'statusColorHex': statusColorHex,
      'statusTextColorHex': statusTextColorHex,
      'aiSummary': aiSummary,
      'quotedText': quotedText,
      'metrics': metrics?.map((x) => x.toMap()).toList(),
      'issues': issues.map((x) => x.toMap()).toList(),
      'uploadedFileUrl': uploadedFileUrl,
      'essayAnswers': essayAnswers,
    };
  }

  factory TestResultData.fromMap(Map<String, dynamic> map, String id) {
    return TestResultData(
      id: id,
      userId: map['userId'] ?? '',
      testId: map['testId'] ?? '',
      testTitle: map['testTitle'] ?? '',
      testSubtitle: map['testSubtitle'] ?? '',
      badgeText: map['badgeText'] ?? '',
      badgeColorHex: map['badgeColorHex'] ?? '0xFF000000',
      badgeTextColorHex: map['badgeTextColorHex'] ?? '0xFFFFFFFF',
      scoreValue: map['scoreValue'] ?? '',
      maxScore: (map['maxScore'] as num?)?.toDouble() ?? 0.0,
      numericScore: (map['numericScore'] as num?)?.toDouble() ?? 0.0,
      submittedDate:
          map['submittedDate'] != null ? DateTime.parse(map['submittedDate']) : null ?? DateTime.now(),
      statusText: map['statusText'] ?? '',
      statusColorHex: map['statusColorHex'] ?? '0xFF000000',
      statusTextColorHex: map['statusTextColorHex'] ?? '0xFFFFFFFF',
      aiSummary: map['aiSummary'] ?? '',
      quotedText: map['quotedText'],
      metrics: map['metrics'] != null
          ? List<TestMetric>.from(
              map['metrics']?.map((x) => TestMetric.fromMap(x)))
          : null,
      issues: List<TestIssue>.from(
          map['issues']?.map((x) => TestIssue.fromMap(x)) ?? []),
      uploadedFileUrl: map['uploadedFileUrl'],
      essayAnswers: map['essayAnswers'] != null
          ? Map<String, String>.from(map['essayAnswers'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TestResultData.fromJson(String source) =>
      TestResultData.fromMap(json.decode(source), '');
}

class TestMetric {
  Color? get valueColor => valueColorHex != null ? Color(int.parse(valueColorHex!)) : null;

  final String label;
  final String? sublabel;
  final bool? checkStatus;
  final String? valueText;
  final String? valueColorHex;

  TestMetric({
    required this.label,
    this.sublabel,
    this.checkStatus,
    this.valueText,
    this.valueColorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'sublabel': sublabel,
      'checkStatus': checkStatus,
      'valueText': valueText,
      'valueColorHex': valueColorHex,
    };
  }

  factory TestMetric.fromMap(Map<String, dynamic> map) {
    return TestMetric(
      label: map['label'] ?? '',
      sublabel: map['sublabel'],
      checkStatus: map['checkStatus'],
      valueText: map['valueText'],
      valueColorHex: map['valueColorHex'],
    );
  }
}

class TestIssue {
  Color get cardColor => Color(int.parse(cardColorHex));
  Color get borderColor => Color(int.parse(borderColorHex));
  Color get titleColor => Color(int.parse(titleColorHex));

  final String title;
  final String description;
  final String cardColorHex;
  final String borderColorHex;
  final String titleColorHex;

  TestIssue({
    required this.title,
    required this.description,
    required this.cardColorHex,
    required this.borderColorHex,
    required this.titleColorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'cardColorHex': cardColorHex,
      'borderColorHex': borderColorHex,
      'titleColorHex': titleColorHex,
    };
  }

  factory TestIssue.fromMap(Map<String, dynamic> map) {
    return TestIssue(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      cardColorHex: map['cardColorHex'] ?? '0xFFFFFFFF',
      borderColorHex: map['borderColorHex'] ?? '0xFFE0E0E0',
      titleColorHex: map['titleColorHex'] ?? '0xFF000000',
    );
  }
}
