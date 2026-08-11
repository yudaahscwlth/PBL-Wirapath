import 'package:flutter/material.dart';
import 'initial_test_data.dart';

/// Mock data for the 4 initial tests based on Figma screenshots
// Initial Test 1
final programmingTestData = InitialTestData(
  id: 'programming',
  testTitle: 'Programming /\nSoftware Development',
  testSubtitle: 'Multiple Choice · 5 questions',
  badgeText: 'PROG',
  badgeColor: const Color(0xFFFFF3CD),
  badgeTextColor: const Color(0xFF856404),
  questions: const [
    TestQuestion(
      questionText: 'Which data structure uses LIFO (Last In, First Out) order?',
      options: [
        QuestionOption(text: 'Queue'),
        QuestionOption(text: 'Stack', isCorrect: true),
        QuestionOption(text: 'Linked List'),
        QuestionOption(text: 'Tree'),
      ],
    ),
    TestQuestion(
      questionText: 'Which HTTP method is idempotent and used to fully update a resource?',
      options: [
        QuestionOption(text: 'POST'),
        QuestionOption(text: 'PATCH'),
        QuestionOption(text: 'PUT', isCorrect: true),
        QuestionOption(text: 'DELETE'),
      ],
    ),
    TestQuestion(
      questionText: 'What is tail recursion?',
      options: [
        QuestionOption(text: 'Recursion that never terminates'),
        QuestionOption(text: 'Recursion where the recursive call is the last operation', isCorrect: true),
        QuestionOption(text: 'A loop disguised as recursion'),
        QuestionOption(text: 'Recursion with two base cases'),
      ],
    ),
    TestQuestion(
      questionText: 'Which testing approach tests a module in isolation with mocked dependencies?',
      options: [
        QuestionOption(text: 'Integration testing'),
        QuestionOption(text: 'End-to-end testing'),
        QuestionOption(text: 'Unit testing', isCorrect: true),
        QuestionOption(text: 'Smoke testing'),
      ],
    ),
    TestQuestion(
      questionText: 'What is eventual consistency in distributed systems?',
      options: [
        QuestionOption(text: 'All nodes are always in sync'),
        QuestionOption(text: 'A transaction rollback mechanism'),
        QuestionOption(text: 'A replication strategy'),
        QuestionOption(text: 'Data updates propagate to all nodes over time, not instantly', isCorrect: true),
      ],
    ),
  ],
);

final dataAnalysisTestData = InitialTestData(
  id: 'data_analysis',
  testTitle: 'Data Analysis',
  testSubtitle: 'File Upload + Short Essay',
  badgeText: 'DTAN',
  badgeColor: const Color(0xFFFFE8CC),
  badgeTextColor: const Color(0xFF8B5E00),
  practicalTaskDescription:// // Initial Test 2
      'You are given a retail sales dataset (sales_dataset) containing columns: date, product_id, category, region, units_sold, unit_price, discount_customer_segment.\n\n'
      'Complete the following in a Jupyter Notebook or Excel and upload your file:\n\n'
      '1. Clean the dataset — identify and handle missing values, duplicates, and outliers. Document your approach.\n'
      '2. Calculate total revenue per category per month. Which category performed best in Q1?\n'
      '3. Compute the average discount rate per customer segment. Does higher discount correlate with higher unit sales?\n'
      '4. Identify the top 5 products by revenue in the "tech" region.\n'
      '5. Create at least 2 visualizations: one showing monthly revenue trend, one showing category breakdown by region.\n'
      '6. Build a simple linear regression model to predict unit_sold based on unit_price and discount. Report R² and interpret the result.',
  uploadFields: const [
    UploadField(
      label: 'Upload The Analysis Results',
      supportedFormats: 'Supports only .xlsx (Max 10 MB)',
    ),
  ],
  essayFields: const [
    EssayField(
      label: 'Interpretation Essay',
      placeholder: 'Based on the analysis above, answer the following in 150-250 words:\n\n'
          '• What is the most significant business insight you found?\n'
          '• Which customer segment should the company prioritize, and why?\n'
          '• What are the limitations of your analysis, and what additional data would improve it?',
    ),
    EssayField(
      label: 'Interpretation of Results',
      placeholder: 'Write the main insights from your analysis.',
    ),
  ],
);

final uxDesignTestData = InitialTestData(
  id: 'ux_design',
  testTitle: 'User Experience Design',
  testSubtitle: 'Design Brief + Portfolio Upload',
  badgeText: 'HCEV',
  badgeColor: const Color(0xFFD4EDDA),
  badgeTextColor: const Color(0xFF155724),
  practicalTaskDescription: // Initial Test 3
      'You are a UX designer at a fintech startup launching a personal finance app targeting young professionals aged 22-35. The product team has identified a key problem: users abandon the app within the first week because the onboarding feels overwhelming and they don\'t understand the app\'s core value.\n\n'
      'Your task:\n\n'
      'Design the onboarding experience for this app. Your submission must include:\n\n'
      '1. User persona — define one target user (name, age, goals, pain points, tech comfort level).\n'
      '2. User flow — map out the full onboarding journey from app launch to first meaningful action (e.g., connecting a bank account or setting a budget goal). Minimum 6 steps.\n'
      '3. Wireframes — low or mid-fidelity screens for at least 5 key screens in the onboarding flow.\n'
      '4. Prototype — a clickable prototype (Figma preferred) demonstrating the primary onboarding path.\n'
      '5. Design rationale — a written section (100-150 words) explaining your key design decisions, especially how you addressed the abandonment problem.\n\n'
      'Evaluation criteria: Clarity of user flow, visual hierarchy, accessibility considerations, quality of rationale.\n\n'
      'Upload your complete work as a .fig, .pdf report, or .zip containing all assets.',
  uploadFields: const [
    UploadField(
      label: 'Upload Mockup or Prototype',
      supportedFormats: 'Supports .fig, .pdf, .zip (Max 10 MB)',
    ),
  ],
);

final testingTestData = InitialTestData(
  id: 'testing',
  testTitle: 'Testing',
  testSubtitle: 'Multiple Choice · 5 questions',
  badgeText: 'TEST',
  badgeColor: const Color(0xFFDBEAFE),
  badgeTextColor: const Color(0xFF1E40AF),
  questions: const [
    TestQuestion( // Initial Test 4
      questionText: 'What is a flaky test?',
      options: [
        QuestionOption(text: 'A test with no assertions'),
        QuestionOption(text: 'A skipped test'),
        QuestionOption(text: 'A test that passes and fails intermittently without code changes', isCorrect: true),
        QuestionOption(text: 'A test with too many assertions'),
      ],
    ),
    TestQuestion(
      questionText: 'Which tool is primarily used for API testing?',
      options: [
        QuestionOption(text: 'Selenium'),
        QuestionOption(text: 'Postman', isCorrect: true),
        QuestionOption(text: 'Jest'),
        QuestionOption(text: 'Playwright'),
      ],
    ),
    TestQuestion(
      questionText: 'What does "boundary value analysis" mean?',
      options: [
        QuestionOption(text: 'Testing only the center of input ranges'),
        QuestionOption(text: 'Testing at the edges of input ranges', isCorrect: true),
        QuestionOption(text: 'Skipping boundary checks'),
        QuestionOption(text: 'Boundary is only for UI testing'),
      ],
    ),
    TestQuestion(
      questionText: 'What is a test suite?',
      options: [
        QuestionOption(text: 'A single test'),
        QuestionOption(text: 'A bug report'),
        QuestionOption(text: 'A structured set of conditions, steps, and expected results to verify a feature', isCorrect: true),
        QuestionOption(text: 'An alternative name for production code'),
      ],
    ),
    TestQuestion(
      questionText: 'In the testing pyramid, which layer should have the most tests?',
      options: [
        QuestionOption(text: 'UI', isCorrect: false),
        QuestionOption(text: 'Integration'),
        QuestionOption(text: 'Unit', isCorrect: true),
        QuestionOption(text: 'Manual'),
      ],
    ),
  ],
  practicalTaskDescription:
      'Using the following test story, write a complete test case document for a "Password Reset" feature:\n\n'
      'The user clicks "Forgot Password", enters their email, receives a reset link, clicks the link, creates a new password (min 8 chars, 1 uppercase, 1 number), and is redirected to login. Consider edge cases: expired link, invalid email, password mismatch, and already-used link.',
  uploadFields: const [
    UploadField(
      label: 'Upload Test Case Document',
      supportedFormats: 'Supports only .xlsx (Max 10 MB)',
    ),
  ],
);

/// List of all mock initial test data for iteration
final allInitialTests = [
  programmingTestData,
  dataAnalysisTestData,
  uxDesignTestData,
  testingTestData,
];
