import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/user_provider.dart';

/// Initial test (skill assessment). Loads the same role-mapped problem set the
/// website serves from `/api/assessment/questions`, submits the answers to
/// `/api/assessment/submit`, and then invalidates the dashboard/analytics
/// providers so the overall readiness score and Growth Progress update.
///
/// Mirrors the web `/dashboard/readiness` workflow: the user first picks which
/// sections (modules) they want to attempt — they are not forced to answer all
/// 15 questions across every module — then reviews their answers before
/// submitting.
class InitialTestPage extends ConsumerStatefulWidget {
  const InitialTestPage({super.key});

  @override
  ConsumerState<InitialTestPage> createState() => _InitialTestPageState();
}

enum _Phase { intro, selecting, quizzing, reviewing }

class _InitialTestPageState extends ConsumerState<InitialTestPage> {
  // question_id -> selected answer text
  final Map<String, String> _answers = {};
  // Category ids the user chose to attempt. Defaults to all once loaded.
  final Set<String> _selectedCategoryIds = {};
  bool _selectionInitialized = false;
  _Phase _phase = _Phase.intro;
  bool _submitting = false;

  static const Color _accent = Color(0xFF066EFF);

  /// Normalize the raw category→questions response into a predictable shape:
  /// [{ id, name, questions: [...] }]. Categories without an explicit id fall
  /// back to their slug (or name) so selection stays stable.
  List<Map<String, dynamic>> _normalize(List<dynamic> categories) {
    final out = <Map<String, dynamic>>[];
    for (final cat in categories) {
      final c = Map<String, dynamic>.from(cat as Map);
      final id = (c['id'] ?? c['slug'] ?? c['name'] ?? '').toString();
      out.add({
        'id': id,
        'name': (c['name'] ?? c['slug'] ?? 'Section').toString(),
        'questions': (c['questions'] as List?) ?? const [],
      });
    }
    return out;
  }

  /// Flatten the chosen categories into a single ordered list of questions,
  /// each tagged with its category name for display.
  List<Map<String, dynamic>> _selectedQuestions(
      List<Map<String, dynamic>> categories) {
    final out = <Map<String, dynamic>>[];
    for (final c in categories) {
      if (!_selectedCategoryIds.contains(c['id'])) continue;
      for (final q in (c['questions'] as List)) {
        final qm = Map<String, dynamic>.from(q as Map);
        qm['_category'] = c['name'] ?? '';
        out.add(qm);
      }
    }
    return out;
  }

  Future<void> _submit(List<Map<String, dynamic>> questions) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final List<Map<String, String>> payload = _answers.entries
        .map((e) => {'question_id': e.key, 'user_answer': e.value})
        .toList();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final resultData = await ref.read(apiServiceProvider).submitAssessment(payload);

      // Refresh everything the score & growth progress are derived from.
      ref.invalidate(assessmentAnalyticsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(skillGapProvider);
      ref.invalidate(marketDemandProvider);

      if (!mounted) return;
      router.go('/readiness-center/review-test', extra: resultData);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to submit test: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(assessmentQuestionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: _handleBack,
        ),
        title: Text(
          "Skill Assessment",
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError('$e'),
        data: (raw) {
          final categories = _normalize(raw);
          if (categories.isEmpty ||
              categories.every((c) => (c['questions'] as List).isEmpty)) {
            return _buildError('No assessment questions are available yet.');
          }
          // Default every section to selected on first load.
          if (!_selectionInitialized) {
            _selectedCategoryIds
              ..clear()
              ..addAll(categories.map((c) => c['id'] as String));
            _selectionInitialized = true;
          }

          switch (_phase) {
            case _Phase.intro:
              return _buildIntro(categories);
            case _Phase.selecting:
              return _buildSelector(categories);
            case _Phase.quizzing:
              return _buildForm(_selectedQuestions(categories));
            case _Phase.reviewing:
              return _buildReview(_selectedQuestions(categories));
          }
        },
      ),
    );
  }

  void _handleBack() {
    switch (_phase) {
      case _Phase.reviewing:
        setState(() => _phase = _Phase.quizzing);
        break;
      case _Phase.quizzing:
        setState(() => _phase = _Phase.selecting);
        break;
      case _Phase.selecting:
        setState(() => _phase = _Phase.intro);
        break;
      case _Phase.intro:
        context.go('/readiness-center', extra: {'initialTabIndex': 1});
        break;
    }
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(assessmentQuestionsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Intro Phase — start assessment intro screen
  // -------------------------------------------------------------------------
  Widget _buildIntro(List<Map<String, dynamic>> categories) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    
    // Count total questions across all categories.
    final totalQuestions = categories.fold<int>(0, (acc, c) => acc + (c['questions'] as List).length);
    final totalCategories = categories.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: _accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'Initial Skill Assessment',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 10),
                // Description
                Text(
                  "Complement your CV and GitHub analysis with a direct knowledge "
                  "assessment. This test evaluates your skills across $totalCategories categories to "
                  "give a more accurate readiness score.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Grid of 3 stats
                Row(
                  children: [
                    Expanded(
                      child: _buildIntroStatCard(
                        '$totalQuestions Questions',
                        'Multi-choice format',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildIntroStatCard(
                        '~${totalCategories * 2} Minutes',
                        'No time pressure',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildIntroStatCard(
                        '$totalCategories Categories',
                        'Full-stack coverage',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Blue Card banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How this helps your readiness score',
                        style: GoogleFonts.poppins(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Currently your score is based on CV analysis and GitHub '
                        'activity. Taking this assessment adds a third evaluation dimension, '
                        'making your Skill Map and Skill Gap analysis significantly more '
                        'accurate.',
                        style: GoogleFonts.poppins(
                          color: onSurface.withValues(alpha: 0.6),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() => _phase = _Phase.selecting),
                  style: _primaryButtonStyle(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Assessment',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntroStatCard(String title, String subtitle) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: onSurface.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Phase 1 — section (module) picker
  // -------------------------------------------------------------------------
  Widget _buildSelector(List<Map<String, dynamic>> categories) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selectedCount = _selectedCategoryIds.length;
    final allSelected = selectedCount == categories.length;
    final selectedQuestionCount = categories
        .where((c) => _selectedCategoryIds.contains(c['id']))
        .fold<int>(0, (acc, c) => acc + (c['questions'] as List).length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose what to work on',
            style: GoogleFonts.poppins(
              color: onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Pick only the sections you want to attempt now — you don't have "
            "to do all of them at once.",
            style: GoogleFonts.poppins(
              color: onSurface.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$selectedQuestionCount questions • $selectedCount of '
                    '${categories.length} sections • ~${selectedCount * 7} min',
                    style: GoogleFonts.poppins(
                      color: onSurface.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SECTIONS',
                style: GoogleFonts.poppins(
                  color: onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  if (allSelected) {
                    _selectedCategoryIds.clear();
                  } else {
                    _selectedCategoryIds
                      ..clear()
                      ..addAll(
                          categories.map((c) => c['id'] as String));
                  }
                }),
                child: Text(
                  allSelected ? 'Clear all' : 'Select all',
                  style: GoogleFonts.poppins(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...categories.map((c) => _buildSectionTile(c)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: selectedCount == 0
                ? null
                : () => setState(() => _phase = _Phase.quizzing),
            style: _primaryButtonStyle(),
            child: Text(
              selectedCount == 0
                  ? 'Select at least one section'
                  : 'Start Assessment ($selectedCount '
                      '${selectedCount == 1 ? 'section' : 'sections'})',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTile(Map<String, dynamic> category) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final id = category['id'] as String;
    final selected = _selectedCategoryIds.contains(id);
    final questionCount = (category['questions'] as List).length;

    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedCategoryIds.remove(id);
        } else {
          _selectedCategoryIds.add(id);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accent : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.layers_outlined, color: _accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'] as String,
                    style: GoogleFonts.poppins(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$questionCount evaluation '
                    '${questionCount == 1 ? 'task' : 'tasks'}',
                    style: GoogleFonts.poppins(
                      color: onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _accent : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? _accent
                      : onSurface.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Phase 2 — quiz
  // -------------------------------------------------------------------------
  Widget _buildForm(List<Map<String, dynamic>> questions) {
    final allAnswered = questions.isNotEmpty &&
        questions.every((q) => _answers.containsKey(q['id'].toString()));
    final answeredCount =
        questions.where((q) => _answers.containsKey(q['id'].toString())).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$answeredCount of ${questions.length} answered",
            style: GoogleFonts.poppins(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(questions.length,
              (index) => _buildQuestionCard(index, questions[index])),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: !allAnswered
                ? null
                : () => setState(() => _phase = _Phase.reviewing),
            style: _primaryButtonStyle(),
            child: Text(
              allAnswered
                  ? "Review Answers"
                  : "Answer all ($answeredCount/${questions.length})",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final id = question['id'].toString();
    final type = (question['question_type'] ?? 'multiple_choice').toString();

    final normalizedOptions = _optionsFor(question, type);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question ${index + 1} • ${question['_category'] != null && (question['_category'] as String).isNotEmpty ? question['_category'] : 'Assessment'}",
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question['question_text']?.toString() ?? '',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          ...normalizedOptions.map((opt) {
            final optId = opt['id'] ?? '';
            final optText = opt['text'] ?? '';
            final isSelected = _answers[id] == optId;
            final displayText = type == 'yes_no' ? optText : "$optId. $optText";
            return GestureDetector(
              onTap: () => setState(() => _answers[id] = optId),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? _accent
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                          width: isSelected ? 6 : 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayText,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Phase 3 — review answers before submitting
  // -------------------------------------------------------------------------
  Widget _buildReview(List<Map<String, dynamic>> questions) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final answeredCount =
        questions.where((q) => _answers.containsKey(q['id'].toString())).length;
    final unanswered = questions.length - answeredCount;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Your Answers',
                  style: GoogleFonts.poppins(
                    color: onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.poppins(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                          text:
                              'Double-check your responses before submitting. You answered '),
                      TextSpan(
                        text: '$answeredCount',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' of ${questions.length} questions.'),
                      if (unanswered > 0)
                        TextSpan(
                          text: ' $unanswered still unanswered.',
                          style: const TextStyle(
                            color: Color(0xFFF57F17),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(
                    questions.length, (i) => _buildReviewItem(i, questions[i])),
              ],
            ),
          ),
        ),
        _buildBottomBar(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _phase = _Phase.quizzing),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Back to Edit',
                    style: GoogleFonts.poppins(
                      color: onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => _submit(questions),
                  style: _primaryButtonStyle(),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(int index, Map<String, dynamic> question) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final id = question['id'].toString();
    final type = (question['question_type'] ?? 'multiple_choice').toString();
    final selectedId = _answers[id];
    final options = _optionsFor(question, type);
    String? answerLabel;
    if (selectedId != null) {
      final match = options.where((o) => o['id'] == selectedId);
      answerLabel = match.isNotEmpty ? match.first['text'] : selectedId;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question['question_text'] ?? ''}',
            style: GoogleFonts.poppins(
              color: onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          if (answerLabel != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your answer: ',
                  style: GoogleFonts.poppins(
                    color: onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    answerLabel,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _phase = _Phase.quizzing),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                      color: _accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              'Not answered yet',
              style: GoogleFonts.poppins(
                color: const Color(0xFFF57F17),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Shared helpers
  // -------------------------------------------------------------------------
  List<Map<String, String>> _optionsFor(
      Map<String, dynamic> question, String type) {
    final normalizedOptions = <Map<String, String>>[];
    if (type == 'yes_no') {
      normalizedOptions.addAll([
        {'id': 'yes', 'text': 'Yes'},
        {'id': 'no', 'text': 'No'},
      ]);
    } else {
      final list = (question['options'] as List?) ?? const [];
      for (final item in list) {
        if (item is Map) {
          normalizedOptions.add({
            'id': (item['id'] ?? '').toString(),
            'text': (item['text'] ?? '').toString(),
          });
        }
      }
    }
    return normalizedOptions;
  }

  ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: _accent,
        disabledBackgroundColor: _accent.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size.fromHeight(56),
      );

  Widget _buildBottomBar({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: child,
    );
  }
}
