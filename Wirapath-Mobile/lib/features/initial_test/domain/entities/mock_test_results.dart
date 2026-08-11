import 'package:flutter/material.dart';
import 'test_result_data.dart';

/// Mock data matching the Figma screenshots for all 4 test types

final programmingResult = TestResultData(
  testTitle: 'Programming /\nSoftware Development',
  testSubtitle: 'Multiple Choice · 5 questions',
  badgeText: 'PROG',
  badgeColor: const Color(0xFFFFF3CD),
  badgeTextColor: const Color(0xFF856404),
  scoreValue: '4/5',
  maxScore: 5,
  numericScore: 4,
  submittedDate: 'Submitted March 3, 2026',
  statusText: 'Passed',
  statusColor: const Color(0xFFD4EDDA),
  statusTextColor: const Color(0xFF155724),
  aiSummary:
      'Strong performance overall. You answered data structures, HTTP methods, recursion, and unit testing correctly. The one miss was on distributed systems — a common gap for junior developers at this stage.',
  issues: [
    const TestIssue(
      title: '',
      description:
          'On Q5 you selected "A replication strategy" — that describes how data is copied between nodes, not the consistency model itself. Eventual consistency means replicas don\'t need to be in sync immediately; they\'ll converge to the same state over time given no new updates. Replication is the mechanism; eventual consistency is the guarantee.',
      cardColor: Color(0xFFEFF6FF),
      borderColor: Color(0xFFBFDBFE),
      titleColor: Color(0xFF1D4ED8),
    ),
  ],
);

final dataAnalysisResult = TestResultData(
  testTitle: 'Data Analysis',
  testSubtitle: 'File Upload + Short Essay',
  badgeText: 'DTAN',
  badgeColor: const Color(0xFFFFE8CC),
  badgeTextColor: const Color(0xFF8B5E00),
  scoreValue: '76',
  maxScore: 100,
  numericScore: 76,
  submittedDate: 'Submitted March 4, 2026',
  statusText: 'Needs Revision',
  statusColor: const Color(0xFFFFF3CD),
  statusTextColor: const Color(0xFF856404),
  aiSummary:
      'Data cleaning and revenue analysis are well done. The regression model was implemented but R² was not interpreted in the notebook. The essay covers customer segment insight but misses the limitations question entirely.',
  metrics: [
    const TestMetric(label: 'Data Cleaning', sublabel: 'Documented Well', checkStatus: true),
    const TestMetric(label: 'Visualizations', sublabel: 'Both Charts', checkStatus: true),
    const TestMetric(
      label: 'Regression R²',
      sublabel: 'Not Interpreted',
      checkStatus: false,
    ),
    const TestMetric(
      label: 'Essay Length',
      sublabel: 'Target 150 – 250 words',
      valueText: '118',
      valueColor: Color(0xFF10B981),
    ),
  ],
  issues: [
    const TestIssue(
      title: 'R² result not interpreted',
      description:
          'You reported R² = 0.43 but didn\'t explain what it means. Add 1-2 sentences: \'The model explains 43% of variance in units sold, suggesting moderate predictive power\'',
      cardColor: Color(0xFFFEE2E2),
      borderColor: Color(0xFFFCA5A5),
      titleColor: Color(0xFF991B1B),
    ),
    const TestIssue(
      title: 'Essay missing limitations section',
      description:
          'Question 3 of the essay prompt asks for limitations and what additional data would improve the analysis. Your essay skipped this entirely — it\'s a required part.',
      cardColor: Color(0xFFFFEDD5),
      borderColor: Color(0xFFFDBA74),
      titleColor: Color(0xFF9A3412),
    ),
    const TestIssue(
      title: 'Essay too short (118 words)',
      description:
          'Minimum is 150 words. Expand on the limitations section to reach the target while answering all 3 questions.',
      cardColor: Color(0xFFFFEDD5),
      borderColor: Color(0xFFFDBA74),
      titleColor: Color(0xFF9A3412),
    ),
  ],
);

final uxDesignResult = TestResultData(
  testTitle: 'User Experience Design',
  testSubtitle: 'Design Brief + Portfolio Upload',
  badgeText: 'HCEV',
  badgeColor: const Color(0xFFFFF3CD),
  badgeTextColor: const Color(0xFF856404),
  scoreValue: '88',
  maxScore: 100,
  numericScore: 88,
  submittedDate: 'Submitted March 4, 2026',
  statusText: 'Strong Submission',
  statusColor: const Color(0xFFD4EDDA),
  statusTextColor: const Color(0xFF155724),
  aiSummary:
      'User flow and wireframes are well structured — the 3-step onboarding is clear and logical. Visual hierarchy is strong. Two gaps: persona lacks a tech comfort level, and the design rationale is only 72 words (below 100).',
  metrics: [
    const TestMetric(label: 'User Persona', sublabel: 'Documented Well', checkStatus: true),
    const TestMetric(label: 'User Flow', sublabel: 'Clear', checkStatus: true),
    const TestMetric(label: 'Wireframes', sublabel: 'Rationale', checkStatus: true),
    const TestMetric(
      label: 'Rationale',
      sublabel: 'Target 100 – 150w',
      valueText: '72w',
      valueColor: Color(0xFFF59E0B),
    ),
  ],
  issues: [
    const TestIssue(
      title: 'Prototype not clickable on screen 4',
      description:
          'The \'Connect bank\' CTA on frame 4 has no interaction linked in Figma. Connect it to the success confirmation screen to complete the primary path.',
      cardColor: Color(0xFFFFEDD5),
      borderColor: Color(0xFFFDBA74),
      titleColor: Color(0xFF9A3412),
    ),
  ],
);

final testingResult = TestResultData(
  testTitle: 'Testing',
  testSubtitle: 'Multiple Choice · 5 questions',
  badgeText: 'TEST',
  badgeColor: const Color(0xFFDBEAFE),
  badgeTextColor: const Color(0xFF1E40AF),
  scoreValue: '71',
  maxScore: 100,
  numericScore: 71,
  submittedDate: 'Submitted March 2, 2026',
  statusText: 'Needs Revision',
  statusColor: const Color(0xFFFFF3CD),
  statusTextColor: const Color(0xFF856404),
  aiSummary:
      'MCQ score is solid at 4/5. The uploaded test case document covers the happy path well but is missing 3 of the 8 required scenarios: expired link, already-used reset link, and non-existent email address.',
  metrics: [
    const TestMetric(label: 'MCQ Score', sublabel: 'Test Passed', valueText: '4/5', valueColor: Color(0xFF10B981)),
    const TestMetric(
      label: 'Test Scenarios',
      sublabel: 'Missing',
      valueText: '3',
      valueColor: Color(0xFFEF4444),
    ),
    const TestMetric(label: 'Happy Path', sublabel: 'Complete', checkStatus: true),
    const TestMetric(label: 'Doc Format', sublabel: 'All Columns Present', checkStatus: true),
  ],
  issues: [
    const TestIssue(
      title: '3 test scenarios missing',
      description:
          'Add test cases for: (1) expired reset link, (2) already-used reset link, (3) non-existent email address. All 8 scenarios are required — you submitted only 5.',
      cardColor: Color(0xFFFEE2E2),
      borderColor: Color(0xFFFCA5A5),
      titleColor: Color(0xFF991B1B),
    ),
  ],
);

/// List of all mock test results for iteration
final allTestResults = [
  programmingResult,
  dataAnalysisResult,
  uxDesignResult,
  testingResult,
];
