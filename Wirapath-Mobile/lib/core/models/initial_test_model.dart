import 'dart:convert';
import 'package:flutter/material.dart';

class InitialTestData {
  Color get badgeColor => Color(int.parse(badgeColorHex));
  Color get badgeTextColor => Color(int.parse(badgeTextColorHex));
  final String id;
  final String testTitle;
  final String testSubtitle;
  final String badgeText;
  final String badgeColorHex;
  final String badgeTextColorHex;
  final String? practicalTaskDescription;
  final List<TestQuestion>? questions;
  final List<UploadField>? uploadFields;
  final List<EssayField>? essayFields;

  InitialTestData({
    required this.id,
    required this.testTitle,
    required this.testSubtitle,
    required this.badgeText,
    required this.badgeColorHex,
    required this.badgeTextColorHex,
    this.practicalTaskDescription,
    this.questions,
    this.uploadFields,
    this.essayFields,
  });

  InitialTestData copyWith({
    String? id,
    String? testTitle,
    String? testSubtitle,
    String? badgeText,
    String? badgeColorHex,
    String? badgeTextColorHex,
    String? practicalTaskDescription,
    List<TestQuestion>? questions,
    List<UploadField>? uploadFields,
    List<EssayField>? essayFields,
  }) {
    return InitialTestData(
      id: id ?? this.id,
      testTitle: testTitle ?? this.testTitle,
      testSubtitle: testSubtitle ?? this.testSubtitle,
      badgeText: badgeText ?? this.badgeText,
      badgeColorHex: badgeColorHex ?? this.badgeColorHex,
      badgeTextColorHex: badgeTextColorHex ?? this.badgeTextColorHex,
      practicalTaskDescription:
          practicalTaskDescription ?? this.practicalTaskDescription,
      questions: questions ?? this.questions,
      uploadFields: uploadFields ?? this.uploadFields,
      essayFields: essayFields ?? this.essayFields,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'testTitle': testTitle,
      'testSubtitle': testSubtitle,
      'badgeText': badgeText,
      'badgeColorHex': badgeColorHex,
      'badgeTextColorHex': badgeTextColorHex,
      'practicalTaskDescription': practicalTaskDescription,
      'questions': questions?.map((x) => x.toMap()).toList(),
      'uploadFields': uploadFields?.map((x) => x.toMap()).toList(),
      'essayFields': essayFields?.map((x) => x.toMap()).toList(),
    };
  }

  factory InitialTestData.fromMap(Map<String, dynamic> map, String id) {
    return InitialTestData(
      id: id,
      testTitle: map['testTitle'] ?? '',
      testSubtitle: map['testSubtitle'] ?? '',
      badgeText: map['badgeText'] ?? '',
      badgeColorHex: map['badgeColorHex'] ?? '0xFF000000',
      badgeTextColorHex: map['badgeTextColorHex'] ?? '0xFFFFFFFF',
      practicalTaskDescription: map['practicalTaskDescription'],
      questions: map['questions'] != null
          ? List<TestQuestion>.from(
              map['questions']?.map((x) => TestQuestion.fromMap(x)))
          : null,
      uploadFields: map['uploadFields'] != null
          ? List<UploadField>.from(
              map['uploadFields']?.map((x) => UploadField.fromMap(x)))
          : null,
      essayFields: map['essayFields'] != null
          ? List<EssayField>.from(
              map['essayFields']?.map((x) => EssayField.fromMap(x)))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory InitialTestData.fromJson(String source) =>
      InitialTestData.fromMap(json.decode(source), '');
}

class TestQuestion {
  final String questionText;
  final List<QuestionOption> options;

  TestQuestion({
    required this.questionText,
    required this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options.map((x) => x.toMap()).toList(),
    };
  }

  factory TestQuestion.fromMap(Map<String, dynamic> map) {
    return TestQuestion(
      questionText: map['questionText'] ?? '',
      options: List<QuestionOption>.from(
          map['options']?.map((x) => QuestionOption.fromMap(x)) ?? []),
    );
  }
}

class QuestionOption {
  final String text;
  final bool isCorrect;

  QuestionOption({
    required this.text,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isCorrect': isCorrect,
    };
  }

  factory QuestionOption.fromMap(Map<String, dynamic> map) {
    return QuestionOption(
      text: map['text'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
    );
  }
}

class UploadField {
  final String label;
  final String supportedFormats;

  UploadField({
    required this.label,
    required this.supportedFormats,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'supportedFormats': supportedFormats,
    };
  }

  factory UploadField.fromMap(Map<String, dynamic> map) {
    return UploadField(
      label: map['label'] ?? '',
      supportedFormats: map['supportedFormats'] ?? '',
    );
  }
}

class EssayField {
  final String label;
  final String placeholder;

  EssayField({
    required this.label,
    required this.placeholder,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'placeholder': placeholder,
    };
  }

  factory EssayField.fromMap(Map<String, dynamic> map) {
    return EssayField(
      label: map['label'] ?? '',
      placeholder: map['placeholder'] ?? '',
    );
  }
}
