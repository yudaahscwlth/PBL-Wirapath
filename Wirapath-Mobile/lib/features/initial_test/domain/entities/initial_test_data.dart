import 'package:flutter/material.dart';
import '../../../../core/models/initial_test_model.dart' as core;


/// Represents a single question option
class QuestionOption {
  final String text;
  final bool isCorrect;

  const QuestionOption({
    required this.text,
    this.isCorrect = false,
  });
}

/// Represents a single question
class TestQuestion {
  final String questionText;
  final List<QuestionOption> options;

  const TestQuestion({
    required this.questionText,
    required this.options,
  });
}

/// Represents an upload field for file-based tests
class UploadField {
  final String label;
  final String supportedFormats;

  const UploadField({
    required this.label,
    this.supportedFormats = 'Supports only .xlsx (Max 10 MB)',
  });
}

/// Represents a text input field for essay-based tests
class EssayField {
  final String label;
  final String placeholder;

  const EssayField({
    required this.label,
    this.placeholder = '',
  });
}

/// All data needed to render an initial test page
class InitialTestData {
  final String id;
  final String testTitle;
  final String testSubtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;

  /// Multiple choice questions (if any)
  final List<TestQuestion>? questions;

  /// Practical task description (for file upload tests)
  final String? practicalTaskDescription;

  /// Upload fields
  final List<UploadField>? uploadFields;

  /// Essay fields
  final List<EssayField>? essayFields;

  const InitialTestData({
    required this.id,
    required this.testTitle,
    required this.testSubtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    this.questions,
    this.practicalTaskDescription,
    this.uploadFields,
    this.essayFields,
  });
}

extension InitialTestDataConv on InitialTestData {
  core.InitialTestData toCore() {
    return core.InitialTestData(
      id: id,
      testTitle: testTitle,
      testSubtitle: testSubtitle,
      badgeText: badgeText,
      badgeColorHex: '0x${badgeColor.value.toRadixString(16)}',
      badgeTextColorHex: '0x${badgeTextColor.value.toRadixString(16)}',
      practicalTaskDescription: practicalTaskDescription,
      questions: questions?.map((q) => core.TestQuestion(
        questionText: q.questionText,
        options: q.options.map((o) => core.QuestionOption(
          text: o.text,
          isCorrect: o.isCorrect,
        )).toList(),
      )).toList(),
      uploadFields: uploadFields?.map((u) => core.UploadField(
        label: u.label,
        supportedFormats: u.supportedFormats,
      )).toList(),
      essayFields: essayFields?.map((e) => core.EssayField(
        label: e.label,
        placeholder: e.placeholder,
      )).toList(),
    );
  }
}

