import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/models/career_simulation_model.dart';
import '../../../../core/models/chat_message_model.dart';
import '../../../../core/services/openrouter_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/voice_chat_bubble.dart';
import '../widgets/simulation_option_card.dart';
import '../widgets/company_scenario_card.dart';
import '../widgets/job_listing_card.dart';
import '../widgets/quick_reply_chips.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/salary_scenario_card.dart';
import '../widgets/skill_breakdown_bar.dart';
import '../widgets/recommendation_card.dart';
import 'voice_mode_page.dart';
import 'job_analysis_page.dart';
import '../../data/models/job_analysis_response.dart';
import '../../data/services/job_analysis_api_service.dart';
import '../widgets/webcam_helper.dart';

enum SimulationState {
  initial, // 3 option cards
  careerScenarios, // company scenario cards
  careerChat, // Responsive brief chat
  salaryScenarios, // company salary level cards
  salaryChat, // Salary negotiation chat
  jobdeskAnalyzer, // job listing cards
  jobdeskAnalyzerChat, // TypeScript interview chat
  englishInterviewChat, // Gojek SE English interview chat
}

class CareerSimulationPage extends ConsumerStatefulWidget {
  const CareerSimulationPage({super.key});

  @override
  ConsumerState<CareerSimulationPage> createState() =>
      _CareerSimulationPageState();
}

class _CareerSimulationPageState extends ConsumerState<CareerSimulationPage> {
  final _chatController = TextEditingController();
  final _englishAnswerController =
      TextEditingController(); // Dedicated input for English Interview
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SimulationState _currentState = SimulationState.initial;
  String _currentSessionId = "";
  bool _isResponding = false;
  bool _cameraActive = true;
  bool _micMuted = false;
  bool _englishInterviewDarkMode =
      true; // Dark mode by default (HackerRank style)
  bool _showTranscriptPane = true;
  Map<String, dynamic>?
  _englishInterviewReport; // Holds evaluation result for full-page report
  bool _isPlayingRecording = false;
  double _recordingProgress = 6.0; // seconds played
  Timer? _recordingTimer;

  // Salary-negotiation company list — mirrors the website's "Select Company"
  // list (Wirakarsa-FE-Web-Standalone CompanyList.tsx) so the mobile and web
  // simulation share the same set of real Indonesian companies and roles.
  static const List<Map<String, String>> _salaryCompanies = [
    {'name': 'Gojek', 'role': 'Software Engineer', 'range': 'Rp 12-18M/month'},
    {
      'name': 'Tokopedia',
      'role': 'Frontend Developer',
      'range': 'Rp 10-15M/month',
    },
    {'name': 'Bank BCA', 'role': 'IT Analyst', 'range': 'Rp 9-13M/month'},
    {
      'name': 'Telkom Indonesia',
      'role': 'Backend Developer',
      'range': 'Rp 10-14M/month',
    },
    {
      'name': 'Shopee',
      'role': 'Full Stack Developer',
      'range': 'Rp 12-17M/month',
    },
    {'name': 'Bukalapak', 'role': 'Data Engineer', 'range': 'Rp 9-14M/month'},
    {
      'name': 'Traveloka',
      'role': 'Mobile Developer',
      'range': 'Rp 10-15M/month',
    },
  ];

  // Open-ended interview/negotiation: a 30-minute countdown starts on the
  // candidate's first message; at zero the session auto-ends and is evaluated.
  // The user can also end early via the End button. Mirrors the web flow.
  static const int _interviewDurationSeconds = 30 * 60;
  Timer? _countdownTimer;
  int? _secondsLeft;
  bool _isEnding = false;
  bool _isCompleted = false;

  bool get _isSimulationChat =>
      _currentState == SimulationState.careerChat ||
      _currentState == SimulationState.salaryChat ||
      _currentState == SimulationState.englishInterviewChat;

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  final _apiService = JobAnalysisApiService();
  bool _isAnalyzing = false;
  String? _errorMessage;
  JobAnalysisResponse? _analysisResult;

  final Map<String, double> _userSkills = {
    'testing (jest)': 0.30,
    'testing': 0.30,
    'jest': 0.30,
    'web performance': 0.55,
    'performance': 0.55,
    'accessibility': 0.50,
    'a11y': 0.50,
    'state management': 0.85,
    'redux': 0.85,
    'react.js': 0.80,
    'reactjs': 0.80,
    'react': 0.80,
    'css/tailwind': 0.83,
    'css': 0.83,
    'tailwind': 0.83,
    'javascript': 0.75,
    'typescript': 0.40,
    'html5': 0.90,
    'html': 0.90,
  };

  bool _doesUserMeetSkill(String skillName) {
    final normalized = skillName.toLowerCase().trim();
    final userProfile = ref.read(userProfileProvider).value;
    final skills = (userProfile != null && userProfile.skills.isNotEmpty)
        ? userProfile.skills
        : _userSkills;
    for (final entry in skills.entries) {
      final entryKey = entry.key.toLowerCase().trim();
      if (normalized.contains(entryKey) || entryKey.contains(normalized)) {
        return entry.value >= 0.70;
      }
    }
    return false;
  }

  Future<void> _analyzeJob(
    String jobTitle, {
    String? company,
    String? location,
    String? level,
  }) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      final result = await _apiService.predictRequiredSkills(jobTitle);
      setState(() {
        _analysisResult = result;
      });

      final gaps = result.skills
          .where((s) => !_doesUserMeetSkill(s.skill))
          .map((s) => s.skill)
          .toList();
      String botMsg = 'I am analyzing the $jobTitle role';
      if (company != null) botMsg += ' at $company';
      botMsg +=
          '. Based on your profile, we found a **${result.matchedJobSimilarityPct.toStringAsFixed(0)}%** match. ';
      if (gaps.isNotEmpty) {
        botMsg +=
            'Let\'s focus on improving your ${gaps.take(2).join(" and ")} skills. Are you ready for a mock technical interview?';
      } else {
        botMsg +=
            'You meet all major requirements! Are you ready for a mock technical interview?';
      }

      await _startNewSession(
        type: 'jobdesk',
        companyName: company ?? 'Custom Search',
        role: jobTitle,
        level: level ?? 'Entry-Mid',
        initialBotMessage: botMsg,
        targetState: SimulationState.jobdeskAnalyzerChat,
      );

      setState(() {
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = appTranslate(
          ref.read(languageProvider),
          'jobdesk.error_invalid',
        );
        _isAnalyzing = false;
      });
    }
  }

  /// The user's self-assessed proficiency (0–100) for a skill, looked up the
  /// same fuzzy way as [_doesUserMeetSkill]. Returns 0 when unknown.
  int _userProficiencyPct(String skillName) {
    final normalized = skillName.toLowerCase().trim();
    final userProfile = ref.read(userProfileProvider).value;
    final skills = (userProfile != null && userProfile.skills.isNotEmpty)
        ? userProfile.skills
        : _userSkills;
    for (final entry in skills.entries) {
      final entryKey = entry.key.toLowerCase().trim();
      if (normalized.contains(entryKey) || entryKey.contains(normalized)) {
        return (entry.value * 100).round();
      }
    }
    return 0;
  }

  /// Build a full job analysis from REAL sources and open the analysis page:
  ///   1. our HF skill model (`predictRequiredSkills`) for the required skills
  ///      and the candidate's matched/missing breakdown, and
  ///   2. the OpenRouter LLM (`analyzeJobMeta`) for the job description, salary
  ///      range and concrete learning recommendations.
  /// This replaces the previous hardcoded [JobAnalysisData] so both the job
  /// cards and the custom search produce dynamic, model-driven results.
  Future<void> _buildAndOpenJobAnalysis({
    required String jobTitle,
    String? company,
    String? location,
    String? source,
  }) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      // 1. Required skills from our HF model.
      final prediction = await _apiService.predictRequiredSkills(jobTitle);
      final predicted = prediction.skills;

      final requiredSkills = <SkillTag>[];
      final breakdown = <SkillProficiency>[];
      final missingNames = <String>[];
      var matchedCount = 0;

      for (final s in predicted) {
        final matched = _doesUserMeetSkill(s.skill);
        requiredSkills.add(SkillTag(name: s.skill, isMatched: matched));

        var pct = _userProficiencyPct(s.skill);
        if (matched && pct == 0) pct = s.confidencePct.round();
        breakdown.add(
          SkillProficiency(
            name: s.skill,
            percentage: pct.clamp(0, 100).toInt(),
            isMatched: matched,
          ),
        );

        if (matched) {
          matchedCount++;
        } else {
          missingNames.add(s.skill);
        }
      }

      final total = predicted.length;
      final matchPercent = total > 0
          ? ((matchedCount / total) * 100).round()
          : prediction.matchedJobSimilarityPct.round();

      // 2. LLM enrichment via the provided OpenRouter key.
      final meta = await OpenRouterService.instance.analyzeJobMeta(
        jobTitle: jobTitle,
        company: company,
        requiredSkills: predicted.map((e) => e.skill).toList(),
        missingSkills: missingNames,
      );

      var jobDescription = meta?['description']?.toString().trim() ?? '';
      if (jobDescription.isEmpty) {
        final top = requiredSkills.take(3).map((e) => e.name).join(', ');
        jobDescription =
            'A $jobTitle role${company != null ? ' at $company' : ''}'
            '${top.isNotEmpty ? ' focused on $top.' : '.'}';
      }
      final salary = meta?['salary']?.toString().trim();
      final experienceLevel = meta?['experienceLevel']?.toString().trim();

      final recommendations = <LearningRecommendation>[];
      final recsRaw = meta?['recommendations'];
      if (recsRaw is List) {
        for (final r in recsRaw) {
          if (r is Map) {
            final name = r['skillName']?.toString().trim() ?? '';
            if (name.isEmpty) continue;
            recommendations.add(
              LearningRecommendation(
                skillName: name,
                description: r['description']?.toString().trim() ?? '',
                estimatedTime:
                    r['estimatedTime']?.toString().trim() ?? '2-3 weeks',
                difficulty:
                    r['difficulty']?.toString().trim() ?? 'Intermediate',
              ),
            );
          }
        }
      }
      if (recommendations.isEmpty) {
        for (final name in missingNames.take(3)) {
          recommendations.add(
            LearningRecommendation(
              skillName: name,
              description:
                  'Strengthen your $name skills to better match this role.',
              estimatedTime: '2-3 weeks',
              difficulty: 'Intermediate',
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      final data = JobAnalysisData(
        jobTitle: jobTitle,
        company: company ?? 'Custom Search',
        location: location ?? 'Indonesia',
        source: source ?? 'AI Search',
        matchPercent: matchPercent,
        salary: (salary == null || salary.isEmpty) ? '8-15 M/month' : salary,
        postedTime: 'Just now',
        experienceLevel: (experienceLevel == null || experienceLevel.isEmpty)
            ? 'Entry-Mid Level'
            : experienceLevel,
        jobDescription: jobDescription,
        requiredSkills: requiredSkills,
        skillBreakdown: breakdown,
        recommendations: recommendations,
      );

      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => JobAnalysisPage(jobData: data)),
      );
      if (result == 'startInterview') {
        _analyzeJob(
          jobTitle,
          company: company,
          location: location,
          level: experienceLevel,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = appTranslate(
          ref.read(languageProvider),
          'jobdesk.error_invalid',
        );
        _isAnalyzing = false;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _chatController.dispose();
    _englishAnswerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToState(SimulationState state) {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _englishAnswerController.clear();
    setState(() {
      _currentState = state;
      _secondsLeft = null;
      _isEnding = false;
      _englishInterviewReport = null;
      _isPlayingRecording = false;
      _recordingProgress = 6.0;
    });
  }

  // Begin the 30-minute interview countdown (called on the first message).
  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = _interviewDurationSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = (_secondsLeft ?? 0) - 1;
      if (remaining <= 0) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        _endSimulation(auto: true);
      } else {
        setState(() => _secondsLeft = remaining);
      }
    });
  }

  // End the interview/negotiation (button or timer expiry) and fetch the AI
  // evaluation report from the backend.
  Future<void> _endSimulation({bool auto = false}) async {
    if (_isEnding || _currentSessionId.isEmpty || !_isSimulationChat) return;
    _countdownTimer?.cancel();
    setState(() => _isEnding = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.endSimulation(_currentSessionId);
      final report =
          (res['result'] as Map?)?.cast<String, dynamic>() ??
          res.cast<String, dynamic>();
      if (!mounted) return;

      // English Interview: show full-page report (HackerRank style)
      if (_currentState == SimulationState.englishInterviewChat) {
        setState(() {
          _englishInterviewReport = report;
          _isEnding = false;
        });
      } else {
        _showResultSheet(report);
      }
    } catch (e) {
      debugPrint('End simulation error: $e');
      if (!mounted) return;

      // English Interview fallback: show mock report in full-page mode
      if (_currentState == SimulationState.englishInterviewChat) {
        final fallbackReport = <String, dynamic>{
          'is_passed': true,
          'score': 85,
          'feedback':
              '### Review\nYour answers demonstrated excellent understanding of distributed system architecture at Gojek\'s scale.\n\n### Strengths\n- Clearly designed concurrent allocation queue using Go channels and Kafka.\n- Addressed CAP theorem tradeoffs using eventual consistency and geohashing indices.\n\n### Weaknesses & Improvements\n- Try to detail specific database locking models (e.g. optimistic concurrency control vs pessimistic).',
        };
        setState(() {
          _englishInterviewReport = fallbackReport;
          _isEnding = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appTranslate(
                  ref.read(languageProvider),
                  'simulation.failed_eval',
                ),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted && _englishInterviewReport == null) {
        setState(() => _isEnding = false);
      }
    }
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 60) return const Color(0xFFEAB308); // yellow
    if (score >= 40) return const Color(0xFFF97316); // orange
    return AppColors.error;
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _cleanMarkdown(String text) {
    return text.replaceAll('**', '').replaceAll('*', '').trim();
  }

  // Render the AI feedback markdown (### headers, - bullets) into widgets.
  List<Widget> _renderFeedback(String feedback) {
    final widgets = <Widget>[];
    for (final raw in feedback.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('###')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              _cleanMarkdown(line.replaceAll('#', '')),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else if (line.startsWith('-') ||
          line.startsWith('•') ||
          line.startsWith('*')) {
        final cleanContent = _cleanMarkdown(
          line.replaceFirst(RegExp(r'^[-•*]\s*'), ''),
        );
        if (cleanContent.isEmpty) continue;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•  ',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
                Expanded(
                  child: Text(
                    cleanContent,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _cleanMarkdown(line),
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  void _showResultSheet(Map<String, dynamic> report) {
    final lang = ref.read(languageProvider);
    final isSalary = _currentState == SimulationState.salaryChat;
    final score = (report['score'] as num?)?.toInt() ?? 0;
    final isPassed = report['is_passed'] == true;
    final feedback = (report['feedback'] ?? '').toString();
    final salary = report['negotiated_salary']?.toString();
    final color = _scoreColor(score);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (ctx, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!isSalary)
                    _badge(
                      isPassed
                          ? appTranslate(lang, 'simulation.lulus')
                          : appTranslate(lang, 'simulation.belum_lulus'),
                      isPassed ? AppColors.success : AppColors.error,
                    )
                  else
                    _badge(
                      appTranslate(lang, 'simulation.negotiation_completed'),
                      AppColors.primaryBlue,
                    ),
                  if (salary != null && salary.isNotEmpty)
                    _badge(salary, const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 6,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSalary
                              ? appTranslate(
                                  lang,
                                  'simulation.salary_performance',
                                )
                              : appTranslate(
                                  lang,
                                  'simulation.interview_report',
                                ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appTranslate(lang, 'simulation.evaluation_desc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 4),
              ..._renderFeedback(feedback),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _goToState(SimulationState.initial);
                  },
                  child: Text(appTranslate(lang, 'simulation.try_another')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to scroll the list to the bottom when new messages arrive
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper to start a new simulation session via backend API
  Future<void> _startNewSession({
    required String type,
    required String companyName,
    required String role,
    required String level,
    required String initialBotMessage,
    required SimulationState targetState,
  }) async {
    final userProfile = ref.read(userProfileProvider).value;
    final uid = userProfile?.uid ?? 'guest';
    final dbService = ref.read(dbServiceProvider);
    final api = ref.read(apiServiceProvider);

    try {
      // 1. Try to create session via backend API for live AI
      String sessionId;
      String firstBotMessage = initialBotMessage;
      try {
        final apiType = (type == 'recruiter' || type == 'salary')
            ? type
            : 'recruiter';
        final result = await api.startSimulation(
          apiType,
          companyName: companyName,
          role: role,
          scenario: initialBotMessage,
        );
        // Backend shape: { simulation: {id,...}, firstMessage: {text,...} }
        sessionId =
            (result['simulation'] as Map?)?['id']?.toString() ??
            result['id']?.toString() ??
            result['session_id']?.toString() ??
            '';
        if (sessionId.isEmpty) {
          throw Exception('No simulation id in start response');
        }
        // Use the AI opening message if returned
        final firstMsg = (result['firstMessage'] as Map?)?['text']?.toString();
        if (firstMsg != null && firstMsg.isNotEmpty) {
          firstBotMessage = firstMsg;
        } else if (result['opening_message'] != null) {
          firstBotMessage = result['opening_message'].toString();
        } else if (result['messages'] is List &&
            (result['messages'] as List).isNotEmpty) {
          firstBotMessage =
              (result['messages'] as List).last['text']?.toString() ??
              initialBotMessage;
        }
      } catch (apiErr) {
        debugPrint(
          'API startSimulation failed (using local Firestore): $apiErr',
        );
        // Fallback: generate a random ID if API fails
        sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // Mirror session to local MockDbService so history works
      final session = CareerSimulationSession(
        id: sessionId,
        userId: uid,
        type: type,
        companyName: companyName,
        role: role,
        level: level,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbService.createSimulationSession(session);

      // 2. Mirror initial message to local Firestore for history stream
      if (sessionId.isNotEmpty) {
        await dbService.addChatMessage(
          sessionId,
          ChatMessage(
            id: '',
            sender: 'ai',
            text: firstBotMessage,
            timestamp: DateTime.now(),
          ),
        );
      }

      // Refresh the history list
      ref.invalidate(userSimulationSessionsProvider);

      _countdownTimer?.cancel();
      setState(() {
        _currentSessionId = sessionId;
        _currentState = targetState;
        _secondsLeft = null;
        _isEnding = false;
        _isCompleted = false;
      });
    } catch (e) {
      debugPrint("Error starting simulation session: $e");
    }
  }

  // Handle message send — calls backend API for real AI reply
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _currentSessionId.isEmpty || _isResponding)
      return;
    if (_isEnding) return;

    // Start the 30-minute interview countdown on the first message.
    if (_isSimulationChat && _secondsLeft == null) {
      _startCountdown();
    }

    final dbService = ref.read(dbServiceProvider);
    final api = ref.read(apiServiceProvider);

    try {
      // 1. Save user message locally for instant display
      await dbService.addChatMessage(
        _currentSessionId,
        ChatMessage(
          id: '',
          sender: 'user',
          text: text,
          timestamp: DateTime.now(),
        ),
      );

      _chatController.clear();
      _scrollToBottom();

      setState(() => _isResponding = true);

      // 2. Call backend API for real AI response
      String botReply;
      try {
        final result = await api.sendSimulationMessage(_currentSessionId, text);
        // Backend shape: { botMessage: {text,...} }
        final botMsg = (result['botMessage'] as Map?)?['text']?.toString();
        if (botMsg != null && botMsg.isNotEmpty) {
          botReply = botMsg;
        } else if (result['reply'] != null) {
          botReply = result['reply'].toString();
        } else if (result['message'] != null) {
          botReply = result['message'].toString();
        } else if (result['text'] != null) {
          botReply = result['text'].toString();
        } else {
          botReply = "That's a great point! Let's explore this further.";
        }
      } catch (apiErr) {
        debugPrint(
          'API sendSimulationMessage failed (using direct LLM): $apiErr',
        );
        // Fallback: call the LLM (OpenRouter) directly so the mentor still
        // gives a real, context-aware reply instead of a canned response.
        final llmReply = await _generateLlmReply(dbService, text);
        if (llmReply != null && llmReply.isNotEmpty) {
          botReply = llmReply;
        } else {
          botReply = _currentState == SimulationState.salaryChat
              ? "I hear you. Let's keep this productive — what figure are you aiming for, and what value or market data supports it?"
              : "Thanks for sharing that. Could you walk me through your reasoning in a bit more detail?";
        }
      }

      // 3. Mirror AI reply to Firestore for history stream
      await dbService.addChatMessage(
        _currentSessionId,
        ChatMessage(
          id: '',
          sender: 'ai',
          text: botReply,
          timestamp: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() => _isResponding = false);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
      if (mounted) {
        setState(() => _isResponding = false);
      }
    }
  }

  /// Build conversation history from the local store and ask OpenRouter for the
  /// next AI mentor reply. Returns null on failure so the caller can fall back.
  Future<String?> _generateLlmReply(
    dynamic dbService,
    String latestUserText,
  ) async {
    try {
      final history =
          dbService.getSessionMessagesSync(_currentSessionId)
              as List<ChatMessage>;
      final messages = <Map<String, String>>[];
      for (final m in history) {
        messages.add({
          'role': m.sender == 'ai' ? 'assistant' : 'user',
          'content': m.text,
        });
      }
      // Ensure the latest user message is present (it is saved before this call,
      // but guard against any ordering edge cases).
      if (messages.isEmpty || messages.last['content'] != latestUserText) {
        messages.add({'role': 'user', 'content': latestUserText});
      }

      final systemPrompt = _currentState == SimulationState.salaryChat
          ? OpenRouterService.salarySystemPrompt()
          : OpenRouterService.interviewerSystemPrompt();

      return await OpenRouterService.instance.chat(
        systemPrompt: systemPrompt,
        messages: messages,
      );
    } catch (e) {
      debugPrint('Direct LLM reply failed: $e');
      return null;
    }
  }

  // Show past sessions in bottom sheet
  void _showSessionHistory() {
    final lang = ref.read(languageProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final sessionsAsync = ref.watch(userSimulationSessionsProvider);
          
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    appTranslate(lang, 'simulation.history'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: sessionsAsync.when(
                    data: (sessions) {
                      if (sessions.isEmpty) {
                        return Center(
                          child: Text(appTranslate(lang, 'simulation.no_history')),
                        );
                      }
                      return ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, idx) {
                          final s = sessions[idx];
                          IconData icon = Icons.work_outline;
                          if (s.type == 'salary') {
                            icon = Icons.account_balance_wallet_outlined;
                          }
                          if (s.type == 'jobdesk') icon = Icons.search_rounded;
                          if (s.type == 'recruiter') icon = Icons.video_call_rounded;

                          return ListTile(
                            leading: Icon(icon, color: AppColors.primaryBlue),
                            title: Text(
                              "${s.role} - ${s.companyName}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              "Status: ${s.status} · Level: ${s.level}",
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              setState(() {
                                _currentSessionId = s.id;
                                _isCompleted = s.status == 'completed';
                                if (s.type == 'career' || s.type == 'recruiter') {
                                  _currentState = SimulationState.careerChat;
                                } else if (s.type == 'salary') {
                                  _currentState = SimulationState.salaryChat;
                                } else if (s.type == 'english') {
                                  _currentState = SimulationState.englishInterviewChat;
                                } else {
                                  _currentState =
                                      SimulationState.jobdeskAnalyzerChat;
                                }
                              });
                              _scrollToBottom();
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, __) => Center(child: Text("Error: $e")),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProfileProvider);
    final lang = ref.watch(languageProvider);

    // English Interview: render as a dedicated full-screen page (HackerRank style)
    if (_currentState == SimulationState.englishInterviewChat) {
      return _buildEnglishInterviewScreen(context, lang);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () {
            switch (_currentState) {
              case SimulationState.careerScenarios:
              case SimulationState.salaryScenarios:
              case SimulationState.jobdeskAnalyzer:
                _goToState(SimulationState.initial);
                break;
              case SimulationState.careerChat:
                _goToState(SimulationState.careerScenarios);
                break;
              case SimulationState.salaryChat:
                _goToState(SimulationState.salaryScenarios);
                break;
              case SimulationState.jobdeskAnalyzerChat:
                _goToState(SimulationState.jobdeskAnalyzer);
                break;
              case SimulationState.englishInterviewChat:
              case SimulationState.initial:
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
                break;
            }
          },
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appTranslate(lang, 'feature.simulation'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              appTranslate(lang, 'simulation.subtitle'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // End & evaluate — shown once the interview/negotiation has started.
          if (_isSimulationChat && _secondsLeft != null)
            _isEnding
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.error,
                    ),
                    tooltip: _currentState == SimulationState.salaryChat
                        ? appTranslate(lang, 'simulation.end_negotiation')
                        : appTranslate(lang, 'simulation.end_interview'),
                    onPressed: _endSimulation,
                  ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _goToState(SimulationState.initial),
          ),
          IconButton(
            icon: Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _showSessionHistory,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: Column(
        children: [
          // Chat area
          Expanded(child: _buildChatContent(lang)),

          // Quick reply chips (shown in active chat states)
          if (_currentState == SimulationState.careerChat)
            QuickReplyChips(
              replies: const [
                "What's the right approach?",
                "I'm not sure where to start",
              ],
              onTap: _sendMessage,
            ),
          if (_currentState == SimulationState.salaryChat)
            QuickReplyChips(
              replies: const [
                'Is the salary negotiable?',
                'I am expecting around 12 million IDR/month',
              ],
              onTap: _sendMessage,
            ),
          if (_currentState == SimulationState.jobdeskAnalyzerChat)
            QuickReplyChips(
              replies: [
                if (_analysisResult != null &&
                    _analysisResult!.skills.any(
                      (s) => !_doesUserMeetSkill(s.skill),
                    ))
                  'How to improve ${_analysisResult!.skills.firstWhere((s) => !_doesUserMeetSkill(s.skill)).skill}?'
                else
                  'How to improve TypeScript?',
                'Start mock interview',
              ],
              onTap: (reply) {
                if (reply.startsWith('How to improve')) {
                  final skill = reply
                      .replaceAll('How to improve ', '')
                      .replaceAll('?', '');
                  _sendMessage(
                    'I want to focus on learning and improving my $skill skill. What resources or steps do you suggest?',
                  );
                } else if (reply == 'Start mock interview') {
                  _sendMessage(
                    'I am ready to start the mock technical interview for the ${_analysisResult?.jobTitle ?? "Frontend Developer"} position.',
                  );
                } else {
                  _sendMessage(reply);
                }
              },
            ),

          // Chat input field
          if (_isCompleted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.5)),
                ),
                child: const Text(
                  'This simulation has been completed. You cannot send more messages.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ChatInputField(
              controller: _chatController,
              showTimer: _isSimulationChat && _secondsLeft != null,
              timerText: _secondsLeft != null ? _formatTime(_secondsLeft!) : null,
              hintText: _currentState == SimulationState.englishInterviewChat
                  ? (_isResponding
                        ? 'Interviewer speaking... Mic auto-paused'
                        : 'Speak clearly or type response...')
                  : null,
              onSend: () => _sendMessage(_chatController.text),
              onMicTap: () {
                if (_currentState == SimulationState.englishInterviewChat) {
                  setState(() {
                    _micMuted = !_micMuted;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voice Mode feature is coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              onAskTap: () => _showAskOptions(context, lang),
              onRepositoriesTap: _showSessionHistory,
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showAskOptions(BuildContext context, AppLanguage lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                appTranslate(lang, 'simulation.interesting_questions'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildOptionTile('How should I negotiate for a higher salary?'),
            _buildOptionTile(
              'What are the red flags to look for in a startup?',
            ),
            _buildOptionTile('Can you explain state management simply?'),
            _buildOptionTile('How to transition from Junior to Mid level?'),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String text) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _sendMessage(text);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildChatContent(AppLanguage lang) {
    final chatWidget = _buildActiveChatStreamWidget(lang);

    if (_currentState == SimulationState.englishInterviewChat) {
      return Column(
        children: [
          _buildEnglishInterviewWebcam(lang),
          Expanded(child: chatWidget),
        ],
      );
    }

    return chatWidget;
  }

  Widget _buildActiveChatStreamWidget(AppLanguage lang) {
    switch (_currentState) {
      case SimulationState.initial:
        return _buildInitialState(lang);
      case SimulationState.careerScenarios:
        return _buildCareerScenarios(lang);
      case SimulationState.careerChat:
        return _buildActiveChatStream(lang);
      case SimulationState.salaryScenarios:
        return _buildSalaryScenarios(lang);
      case SimulationState.salaryChat:
        return _buildActiveChatStream(lang);
      case SimulationState.jobdeskAnalyzer:
        return _buildJobdeskAnalyzer(lang);
      case SimulationState.jobdeskAnalyzerChat:
        return _buildActiveChatStream(lang);
      case SimulationState.englishInterviewChat:
        return _buildActiveChatStream(lang);
    }
  }

  /// State 1: Initial - 4 simulation options
  Widget _buildInitialState(AppLanguage lang) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        ChatBubble(
          message: appTranslate(lang, 'simulation.mentor_intro'),
          time: '12:49 AM',
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Column(
            children: [
              SimulationOptionCard(
                icon: Icons.work_outline_rounded,
                label: appTranslate(lang, 'feature.simulation'),
                onTap: () => _goToState(SimulationState.careerScenarios),
              ),
              SimulationOptionCard(
                icon: Icons.account_balance_wallet_outlined,
                label: appTranslate(lang, 'simulation.salary_negotiation'),
                onTap: () => _goToState(SimulationState.salaryScenarios),
              ),
              /* SimulationOptionCard(
                icon: Icons.video_call_rounded,
                label: appTranslate(lang, 'simulation.english_interview'),
                onTap: () => _startEnglishInterview(),
              ), */
              /* SimulationOptionCard(
                icon: Icons.search_rounded,
                label: appTranslate(lang, 'feature.jobdesk'),
                onTap: () => _goToState(SimulationState.jobdeskAnalyzer),
              ), */
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startEnglishInterview() async {
    await _startNewSession(
      type: 'recruiter',
      companyName: 'Gojek',
      role: 'Software Engineer',
      level: 'General',
      initialBotMessage:
          'Welcome to Gojek. I\'m Maya from the Engineering recruitment team. Let\'s start with a brief introduction. Can you tell me about your background and why you are interested in the Software Engineering role at Gojek?',
      targetState: SimulationState.englishInterviewChat,
    );
  }

  /// State 2: Career Simulation - Company scenario selection
  Widget _buildCareerScenarios(AppLanguage lang) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        ChatBubble(
          message: appTranslate(lang, 'simulation.select_scenario'),
          time: '12:49 AM',
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Column(
            children: [
              CompanyScenarioCard(
                companyName: 'EduNext (EdTech)',
                role: 'Junior Frontend Developer',
                focus: 'CSS/Tailwind',
                level: 'Junior',
                onTap: () => _startNewSession(
                  type: 'recruiter',
                  companyName: 'EduNext (EdTech)',
                  role: 'Junior Frontend Developer',
                  level: 'Junior',
                  initialBotMessage:
                      'The designer sent a Figma file:\n\n"Budi, here is the responsive mockup for the class page. Breakpoints: mobile (375px), tablet (768px), desktop (1440px). Please implement according to the spec, prioritizing mobile-first."',
                  targetState: SimulationState.careerChat,
                ),
              ),
              CompanyScenarioCard(
                companyName: 'TokoBuild (E-commerce)',
                role: 'Frontend Developer',
                focus: 'Web Performance',
                level: 'Mid',
                onTap: () => _startNewSession(
                  type: 'recruiter',
                  companyName: 'TokoBuild (E-commerce)',
                  role: 'Frontend Developer',
                  level: 'Mid',
                  initialBotMessage:
                      'Budi, our e-commerce checkout page load time has spiked. Review the code split settings and recommend a performance solution.',
                  targetState: SimulationState.careerChat,
                ),
              ),
              CompanyScenarioCard(
                companyName: 'HealthConnect (HealthTech)',
                role: 'Junior Frontend Developer',
                focus: 'Accessibility',
                level: 'Junior',
                onTap: () => _startNewSession(
                  type: 'recruiter',
                  companyName: 'HealthConnect (HealthTech)',
                  role: 'Junior Frontend Developer',
                  level: 'Junior',
                  initialBotMessage:
                      'Hello Budi, we need to secure WCAG 2.1 AA accessibility compliance for our health portal. Start audit on the onboarding forms.',
                  targetState: SimulationState.careerChat,
                ),
              ),
              CompanyScenarioCard(
                companyName: 'DataFlow (SaaS Analytics)',
                role: 'Frontend Developer',
                focus: 'State Management',
                level: 'Mid',
                onTap: () => _startNewSession(
                  type: 'recruiter',
                  companyName: 'DataFlow (SaaS Analytics)',
                  role: 'Frontend Developer',
                  level: 'Mid',
                  initialBotMessage:
                      'Budi, the dashboard states are causing infinite re-renders. Check the Redux/Zustand slice updates.',
                  targetState: SimulationState.careerChat,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// State 3.5: Salary Scenarios - Company level selection
  Widget _buildSalaryScenarios(AppLanguage lang) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        ChatBubble(
          message: appTranslate(lang, 'simulation.select_salary'),
          time: '12:49 AM',
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Column(
            children: [
              for (final c in _salaryCompanies)
                SalaryScenarioCard(
                  companyName: c['name']!,
                  salaryRange: c['range']!,
                  level: c['role']!,
                  onTap: () => _startNewSession(
                    type: 'salary',
                    companyName: c['name']!,
                    role: c['role']!,
                    level: c['role']!,
                    initialBotMessage:
                        'Hello! I am the HR Negotiator from ${c['name']}. We are hiring a ${c['role']} with an offer in the range of ${c['range']}. How would you like to respond to this offer?',
                    targetState: SimulationState.salaryChat,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// State 4: Salary Negotiation - HR message
  Widget _buildSalaryChat() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        VoiceChatBubble(
          message:
              'I am the HR Manager from Startup Fintech. We are offering 4-6m/month for this Junior position. What are your salary expectations?',
          time: '12:49 AM',
          onVoiceTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice Mode feature is coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  /// State 5: Jobdesk Analyzer - Job listing cards
  Widget _buildJobdeskAnalyzer(AppLanguage lang) {
    if (_isAnalyzing) {
      return _buildLoadingState(lang);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        ChatBubble(
          message: appTranslate(lang, 'simulation.jobdesk_intro'),
          time: '12:49 AM',
        ),
        const SizedBox(height: 16),

        // Error banner if any
        _buildErrorBanner(),

        // Search Bar for custom jobs
        Container(
          margin: const EdgeInsets.only(left: 46, bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: appTranslate(lang, 'simulation.enter_custom_job'),
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onChanged: (val) => setState(() {}),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _buildAndOpenJobAnalysis(jobTitle: value.trim());
                    }
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                ),
              ElevatedButton(
                onPressed: _searchController.text.trim().isEmpty
                    ? null
                    : () {
                        final query = _searchController.text.trim();
                        _buildAndOpenJobAnalysis(jobTitle: query);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Theme.of(context).dividerColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  appTranslate(lang, 'simulation.analyze_btn'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Column(
            children: [
              JobListingCard(
                jobTitle: 'Frontend Developer',
                company: 'Gojek',
                location: 'Jakarta',
                source: 'LinkedIn',
                matchPercent: 80,
                skills: const [
                  SkillTag(name: 'ReactJS'),
                  SkillTag(name: 'TypeScript', isMatched: false),
                  SkillTag(name: 'Tailwind CSS'),
                  SkillTag(name: 'Web Performance'),
                ],
                salary: '8-15 M/month',
                postedTime: '1 day ago',
                experienceLevel: 'Entry-Mid',
                onAnalyze: () => _buildAndOpenJobAnalysis(
                  jobTitle: 'Frontend Developer',
                  company: 'Gojek',
                  location: 'Jakarta, Indonesia',
                  source: 'LinkedIn',
                ),
              ),
              JobListingCard(
                jobTitle: 'React Developer',
                company: 'Tokopedia',
                location: 'Jakarta',
                source: 'Jobstreet',
                matchPercent: 60,
                skills: const [
                  SkillTag(name: 'ReactJS'),
                  SkillTag(name: 'Redux', isMatched: false),
                  SkillTag(name: 'Unit Testing', isMatched: false),
                  SkillTag(name: 'CSS-in-JS'),
                  SkillTag(name: 'Accessibility'),
                ],
                salary: '10-18 M/month',
                postedTime: '2 days ago',
                experienceLevel: 'Mid',
                onAnalyze: () => _buildAndOpenJobAnalysis(
                  jobTitle: 'React Developer',
                  company: 'Tokopedia',
                  location: 'Jakarta, Indonesia',
                  source: 'Jobstreet',
                ),
              ),
              JobListingCard(
                jobTitle: 'UI Engineer',
                company: 'Traveloka',
                location: 'Jakarta',
                source: 'Glints',
                matchPercent: 72,
                skills: const [
                  SkillTag(name: 'ReactJS'),
                  SkillTag(name: 'CSS/SCSS'),
                  SkillTag(name: 'Design System'),
                  SkillTag(name: 'Figma', isMatched: false),
                ],
                salary: '12-20 M/month',
                postedTime: '3 days ago',
                experienceLevel: 'Mid-Senior',
                onAnalyze: () => _buildAndOpenJobAnalysis(
                  jobTitle: 'UI Engineer',
                  company: 'Traveloka',
                  location: 'Jakarta, Indonesia',
                  source: 'Glints',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Real-time chat message stream builder from Firestore
  Widget _buildActiveChatStream(AppLanguage lang) {
    if (_currentSessionId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final dbService = ref.watch(dbServiceProvider);

    return StreamBuilder<List<ChatMessage>>(
      stream: dbService.getChatMessages(_currentSessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];
        if (messages.isEmpty &&
            _currentState != SimulationState.jobdeskAnalyzerChat) {
          return Center(
            child: Text(appTranslate(lang, 'simulation.initializing_chat')),
          );
        }

        _scrollToBottom();

        final showAnalysisCard =
            _currentState == SimulationState.jobdeskAnalyzerChat &&
            _analysisResult != null;
        final showMicStatus =
            _currentState == SimulationState.englishInterviewChat && !_isEnding;

        final listItems = <Widget>[];

        if (showAnalysisCard) {
          listItems.add(_buildAnalysisResultsCard(lang));
        }

        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i];
          final timeStr =
              "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";
          if (msg.sender == 'ai') {
            listItems.add(
              VoiceChatBubble(
                message: msg.text,
                time: timeStr,
                onVoiceTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voice Mode feature is coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            );
          } else {
            listItems.add(
              ChatBubble(message: msg.text, time: timeStr, isUser: true),
            );
          }
        }

        if (_isResponding) {
          listItems.add(
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 12, bottom: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appTranslate(lang, 'simulation.ai_responding'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (showMicStatus) {
          listItems.add(_buildEnglishMicStatus(context, lang));
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: listItems.length,
          itemBuilder: (context, idx) => listItems[idx],
        );
      },
    );
  }

  Widget _buildAnalysisResultsCard(AppLanguage lang) {
    final result = _analysisResult;
    if (result == null) return const SizedBox.shrink();

    final skills = result.skills;

    return Padding(
      padding: const EdgeInsets.only(left: 46, bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE1F0FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appTranslate(lang, 'simulation.market_skill_demand'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${appTranslate(lang, 'simulation.confidence_threshold')}${result.thresholdApplied}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            ...skills.map((skill) {
              final isMatched = _doesUserMeetSkill(skill.skill);
              final matchColor = isMatched
                  ? AppColors.success
                  : const Color(0xFFF59E0B);
              final progressVal = skill.confidence;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isMatched
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: matchColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              skill.skill,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isMatched
                                ? AppColors.success.withOpacity(0.08)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isMatched
                                ? appTranslate(lang, 'simulation.matched')
                                : appTranslate(lang, 'simulation.gap'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isMatched
                                  ? AppColors.success
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressVal,
                              backgroundColor: Theme.of(context).dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isMatched
                                    ? AppColors.success
                                    : AppColors.primaryBlue,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${skill.confidencePct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLanguage lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              appTranslate(lang, 'simulation.analyzing_job_reqs'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appTranslate(lang, 'simulation.fetching_db'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 46, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF991B1B), size: 16),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ENGLISH INTERVIEW: Full-screen premium dark-mode interview experience
  // Mirrors the HackerRank-style web component (EnglishInterviewSimulation.tsx)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildEnglishInterviewScreen(BuildContext context, AppLanguage lang) {
    final isDark = _englishInterviewDarkMode;
    final bgColor = isDark ? const Color(0xFF090B11) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    // Show the full-page evaluation report when the interview is finished
    if (_englishInterviewReport != null) {
      return _buildEnglishInterviewReport(context, lang, isDark);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Glowing perspective grid horizon at bottom (dark mode only)
          if (isDark)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 1.5),
                    radius: 1.0,
                    colors: [
                      const Color(0xFF1E3A5F).withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // ── Top Navigation Bar ──────────────────────────────────────
                _buildEnglishInterviewTopBar(
                  context,
                  lang,
                  isDark,
                  borderColor,
                ),

                // ── Main Content Area ───────────────────────────────────────
                if (_isEnding)
                  Expanded(child: _buildEnglishInterviewLoading(isDark))
                else
                  Expanded(
                    child: _showTranscriptPane
                        ? _buildEnglishInterviewContent(context, lang, isDark)
                        : _buildTranscriptHidden(isDark),
                  ),

                // ── Bottom Floating Control Pill ────────────────────────────
                _buildEnglishInterviewBottomPill(context, isDark, borderColor),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnglishInterviewTopBar(
    BuildContext context,
    AppLanguage lang,
    bool isDark,
    Color borderColor,
  ) {
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF090B11).withOpacity(0.9)
            : Colors.white.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => _goToState(SimulationState.initial),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Pulsing green timer badge
          if (_secondsLeft != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatTime(_secondsLeft!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      letterSpacing: 0.4,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),

          // Session label
          Expanded(
            child: Text(
              'Gojek SE Simulation',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: subColor,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Dark/Light mode toggle
          GestureDetector(
            onTap: () => setState(
              () => _englishInterviewDarkMode = !_englishInterviewDarkMode,
            ),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                size: 17,
                color: subColor,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // End Interview button (red pill)
          if (_secondsLeft != null)
            GestureDetector(
              onTap: _isEnding ? null : _endSimulation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4F60),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4F60).withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: _isEnding
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'End Interview',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnglishInterviewLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(
                isDark ? const Color(0xFF00F0FF) : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Generating your evaluation report...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptHidden(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hide_source_outlined,
            size: 40,
            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            'Transcript pane is hidden',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _showTranscriptPane = true),
            child: Text(
              'Show Pane',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF00F0FF) : AppColors.primaryBlue,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnglishInterviewContent(
    BuildContext context,
    AppLanguage lang,
    bool isDark,
  ) {
    if (_currentSessionId.isEmpty) {
      return _buildEnglishInterviewLoading(isDark);
    }

    final dbService = ref.watch(dbServiceProvider);

    return StreamBuilder<List<ChatMessage>>(
      stream: dbService.getChatMessages(_currentSessionId),
      builder: (ctx, snapshot) {
        final messages = snapshot.data ?? [];

        // Get current interviewer question (latest bot message)
        final lastBotMsg = messages.reversed
            .firstWhere(
              (m) => m.sender == 'ai',
              orElse: () => ChatMessage(
                id: '',
                sender: 'ai',
                text: 'Connecting to Gojek Recruitment Service...',
                timestamp: DateTime.now(),
              ),
            )
            .text;

        final isMicActive = !_micMuted && !_isResponding;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Webcam Preview Card ─────────────────────────────────────
              _buildEnglishInterviewWebcam(lang),
              const SizedBox(height: 16),

              // ── Interviewer Question Bubble ─────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00F0FF).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withOpacity(0.3),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '⁕',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF00F0FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lastBotMsg,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1E293B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Candidate Transcript / Mic Status Bubble ────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withOpacity(0.7)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: _englishAnswerController.text.isNotEmpty
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              _englishAnswerController.text,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 14,
                            color: const Color(0xFF00F0FF),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          if (isMicActive) ...[
                            const _MicWaveIndicator(),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            _isResponding
                                ? 'Interviewer speaking... Mic auto-paused'
                                : _micMuted
                                ? 'Microphone muted'
                                : 'Listening...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 14),

              // ── Text Input + Send Answer ────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withOpacity(0.5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: _englishAnswerController,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF1E293B),
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          hintText: _isResponding
                              ? 'Interviewer speaking... Mic auto-paused'
                              : 'Speak clearly or type response...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                            fontFamily: 'Poppins',
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        enabled: !_isResponding,
                        onSubmitted: (v) => _sendEnglishInterviewMessage(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap:
                        (_isResponding ||
                            _englishAnswerController.text.trim().isEmpty)
                        ? null
                        : _sendEnglishInterviewMessage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF00F0FF).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Send',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  (_isResponding ||
                                      _englishAnswerController.text
                                          .trim()
                                          .isEmpty)
                                  ? const Color(0xFF00F0FF).withOpacity(0.4)
                                  : const Color(0xFF00F0FF),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color:
                                (_isResponding ||
                                    _englishAnswerController.text
                                        .trim()
                                        .isEmpty)
                                ? const Color(0xFF00F0FF).withOpacity(0.4)
                                : const Color(0xFF00F0FF),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Previous messages (collapsible history)
              if (messages.length > 1) ...[
                const SizedBox(height: 20),
                Divider(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 8),
                Text(
                  'Previous Messages',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8),
                    fontFamily: 'Poppins',
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                ...messages.map((msg) {
                  final timeStr =
                      '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
                  final isAi = msg.sender == 'ai';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAi
                                ? const Color(0xFF00F0FF).withOpacity(0.1)
                                : AppColors.primaryBlue.withOpacity(0.1),
                          ),
                          child: Icon(
                            isAi
                                ? Icons.smart_toy_outlined
                                : Icons.person_outline,
                            size: 13,
                            color: isAi
                                ? const Color(0xFF00F0FF)
                                : AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 80), // Space for bottom pill
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnglishInterviewBottomPill(
    BuildContext context,
    bool isDark,
    Color borderColor,
  ) {
    final isMicActive = !_micMuted && !_isResponding;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF090B11).withOpacity(0.9)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mic toggle
            _englishPillButton(
              icon: isMicActive ? Icons.mic_rounded : Icons.mic_off_rounded,
              isActive: isMicActive,
              isRed: _micMuted,
              onTap: () => setState(() => _micMuted = !_micMuted),
              tooltip: _micMuted ? 'Unmute Mic' : 'Mute Mic',
            ),
            const SizedBox(width: 16),

            // Camera toggle
            _englishPillButton(
              icon: _cameraActive
                  ? Icons.videocam_rounded
                  : Icons.videocam_off_rounded,
              isActive: _cameraActive,
              isRed: !_cameraActive,
              onTap: () => setState(() => _cameraActive = !_cameraActive),
              tooltip: _cameraActive ? 'Disable Camera' : 'Enable Camera',
            ),
            const SizedBox(width: 16),

            // Transcript pane toggle
            _englishPillButton(
              icon: _showTranscriptPane
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.chat_bubble_rounded,
              isActive: _showTranscriptPane,
              isRed: false,
              onTap: () =>
                  setState(() => _showTranscriptPane = !_showTranscriptPane),
              tooltip: _showTranscriptPane
                  ? 'Hide Transcript'
                  : 'Show Transcript',
            ),
          ],
        ),
      ),
    );
  }

  Widget _englishPillButton({
    required IconData icon,
    required bool isActive,
    required bool isRed,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    final activeColor = const Color(0xFF00F0FF);
    final redColor = const Color(0xFFFF4F60);
    final color = isRed
        ? redColor
        : (isActive ? activeColor : const Color(0xFF64748B));

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRed
                ? redColor.withOpacity(0.1)
                : (isActive
                      ? activeColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.08)),
            border: Border.all(
              color: isRed
                  ? redColor.withOpacity(0.3)
                  : (isActive
                        ? activeColor.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2)),
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // Send message in English Interview mode using dedicated controller
  Future<void> _sendEnglishInterviewMessage() async {
    final text = _englishAnswerController.text.trim();
    if (text.isEmpty) return;
    _englishAnswerController.clear();
    setState(() {});
    await _sendMessage(text);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ENGLISH INTERVIEW: Full-page Evaluation Report (HackerRank style)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildEnglishInterviewReport(
    BuildContext context,
    AppLanguage lang,
    bool isDark,
  ) {
    final report = _englishInterviewReport!;
    final score = (report['score'] as num?)?.toInt() ?? 0;
    final isPassed = report['is_passed'] == true;
    final feedback = (report['feedback'] ?? '').toString();
    final scoreColor = _scoreColor(score);
    final userProfile = ref.watch(userProfileProvider).value;
    final candidateName = userProfile?.displayName?.trim().isNotEmpty == true
        ? userProfile!.displayName
        : 'Candidate';
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Report Header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              candidateName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isPassed
                                    ? const Color(0xFF10B981).withOpacity(0.1)
                                    : const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isPassed ? 'Strong Fit' : 'Needs Improvement',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isPassed
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gojek Software Engineering Screening Round • Just now',
                          style: TextStyle(
                            fontSize: 11,
                            color: subColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Proceed / Finish button
                  GestureDetector(
                    onTap: () => _goToState(SimulationState.initial),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isPassed
                              ? const Color(0xFF10B981)
                              : borderColor,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: isPassed
                                ? const Color(0xFF10B981)
                                : subColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isPassed ? 'Next round' : 'Finish review',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: isPassed
                                  ? const Color(0xFF10B981)
                                  : subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Report Cards ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Waveform Recording Player Card ───────────────────
                    _buildReportCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Interview Recording',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  candidateName,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: subColor,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              // Play/Pause
                              GestureDetector(
                                onTap: _toggleRecordingPlayback,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF00F0FF),
                                  ),
                                  child: Icon(
                                    _isPlayingRecording
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Waveform bars
                              Expanded(
                                child: _buildWaveformPlayer(
                                  isDark,
                                  borderColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.volume_up_outlined,
                                size: 16,
                                color: subColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Score Card ───────────────────────────────────────
                    _buildReportCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Summary Performance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Analyzed by Gojek\'s candidate evaluation engine. Covers technical accuracy, communication clarity, and engineering alignment.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subColor,
                                    height: 1.5,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor,
                                    fontFamily: 'Poppins',
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  'Score/100',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: subColor,
                                    letterSpacing: 0.4,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Detailed Feedback Card ───────────────────────────
                    _buildReportCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                'Detailed Evaluation Feedback',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._renderFeedback(feedback),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Technical Background Card ────────────────────────
                    _buildReportCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Technical Background\n(Software Engineering general)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Strong Fit',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The candidate displays solid backend development capability matching Gojek\'s standards. '
                            'Their understanding of low-latency concurrency models, event-driven architecture using Kafka, '
                            'and distributed cache strategies with Redis fits general Software Engineering requirements.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.55,
                              color: subColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Communication Card ───────────────────────────────
                    _buildReportCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Communication & Collaboration',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Strong Fit',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The candidate clearly explained technical tradeoffs and architectural decisions. '
                            'They showed ability to connect technical solutions to business problems and '
                            'articulated cross-team collaboration skills. Comfortable with ambiguity and '
                            'demonstrated ownership mentality.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.55,
                              color: subColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Restart Button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _startEnglishInterview,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF006EFF), Color(0xFF0055CC)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF006EFF,
                                ).withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Restart Gojek SE Interview Simulation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required Color cardColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildWaveformPlayer(bool isDark, Color borderColor) {
    const int barCount = 60;
    const List<double> waveHeights = [
      20,
      24,
      18,
      30,
      42,
      28,
      14,
      22,
      36,
      48,
      55,
      30,
      18,
      12,
      10,
      24,
      38,
      44,
      28,
      14,
      10,
      20,
      32,
      50,
      62,
      75,
      45,
      20,
      14,
      22,
      40,
      52,
      60,
      30,
      18,
      10,
      24,
      38,
      50,
      32,
      18,
      22,
      34,
      48,
      62,
      28,
      14,
      10,
      18,
      30,
      45,
      58,
      70,
      38,
      22,
      14,
      20,
      32,
      44,
      28,
    ];
    const double totalDuration = 18 * 60 + 35;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: List.generate(barCount, (idx) {
              final h = waveHeights[idx % waveHeights.length] / 100;
              final isActive =
                  idx < (_recordingProgress / totalDuration) * barCount;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0.8),
                  height: 32 * h + 2,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF00F0FF)
                        : (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatTime(_recordingProgress.toInt()),
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            Text(
              '18:35',
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleRecordingPlayback() {
    setState(() => _isPlayingRecording = !_isPlayingRecording);
    if (_isPlayingRecording) {
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted || !_isPlayingRecording) {
          t.cancel();
          return;
        }
        setState(() {
          _recordingProgress += 1;
          if (_recordingProgress >= 18 * 60 + 35) {
            _isPlayingRecording = false;
            _recordingProgress = 0;
            t.cancel();
          }
        });
      });
    } else {
      _recordingTimer?.cancel();
    }
  }

  Widget _buildEnglishInterviewWebcam(AppLanguage lang) {
    final userProfile = ref.watch(userProfileProvider).value;
    final displayName = userProfile?.displayName ?? '';
    final initials = displayName.trim().isNotEmpty
        ? displayName
              .trim()
              .split(' ')
              .map((p) => p.isEmpty ? '' : p[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'AC';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF090B11),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Live Cam feed visual placeholder / webcam stream
          if (_cameraActive)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFF131722),
                child: const WebcamPreview(),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F172A),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Center(
                      child: Text(
                        initials.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Camera Disabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

          // Green Pulsing Badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981), // Emerald
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE CAM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Info Badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Text(
                'Gojek SE Interview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Bottom Control Overlay
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circularWebcamControl(
                  icon: _cameraActive ? Icons.videocam : Icons.videocam_off,
                  isActive: _cameraActive,
                  onTap: () {
                    setState(() {
                      _cameraActive = !_cameraActive;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _circularWebcamControl(
                  icon: _micMuted ? Icons.mic_off : Icons.mic,
                  isActive: !_micMuted,
                  onTap: () {
                    setState(() {
                      _micMuted = !_micMuted;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularWebcamControl({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? const Color(0xFF00F0FF).withOpacity(0.15)
              : Colors.red.withOpacity(0.15),
          border: Border.all(
            color: isActive
                ? const Color(0xFF00F0FF).withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? const Color(0xFF00F0FF) : Colors.red,
        ),
      ),
    );
  }

  Widget _buildEnglishMicStatus(BuildContext context, AppLanguage lang) {
    final isMicActive = !_micMuted && !_isResponding;
    final statusText = _isResponding
        ? 'Interviewer speaking... Mic auto-paused'
        : _micMuted
        ? 'Microphone muted'
        : 'Listening...';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 46, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMicActive) ...[
              const _MicWaveIndicator(),
              const SizedBox(width: 8),
            ],
            Text(
              statusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicWaveIndicator extends StatefulWidget {
  const _MicWaveIndicator();

  @override
  State<_MicWaveIndicator> createState() => _MicWaveIndicatorState();
}

class _MicWaveIndicatorState extends State<_MicWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (idx) {
            final double phase = (idx * 0.3);
            final double value = math
                .sin((_controller.value * 2 * math.pi) + phase)
                .abs();
            final double height = 3 + (value * 9);

            return Container(
              width: 2,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}
