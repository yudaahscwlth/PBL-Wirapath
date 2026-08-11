import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/language_provider.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../devhub/presentation/widgets/radar_chart.dart';

class ReadinessCenterPage extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const ReadinessCenterPage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ReadinessCenterPage> createState() => _ReadinessCenterPageState();
}

class _ReadinessCenterPageState extends ConsumerState<ReadinessCenterPage> {
  late int _selectedTabIndex;

  bool _uploadingCv = false;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Let the user pick a CV / academic transcript document, upload it to the
  // backend for analysis, then refresh the profile so the card reflects it.
  Future<void> _pickAndUploadDocument() async {
    if (_uploadingCv) return;

    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc'],
        allowMultiple: false,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      if (file.path == null && file.bytes == null) {
        _showSnack(appTranslate(ref.read(languageProvider), 'profile.cannot_read_file'));
        return;
      }

      final userId = ref.read(userProfileProvider).value?.uid;
      if (userId == null) {
        _showSnack(appTranslate(ref.read(languageProvider), 'readiness.sign_in_required'));
        return;
      }

      setState(() {
        _uploadingCv = true;
      });

      final api = ref.read(apiServiceProvider);
      await api.uploadOnboardingCv(
        userId: userId,
        cvPath: file.path,
        cvBytes: file.bytes,
        cvName: file.name,
      );

      await ref.read(userProfileProvider.notifier).refreshProfile();
      _showSnack(appTranslate(ref.read(languageProvider), 'readiness.cv_upload_success'));
    } catch (e) {
      debugPrint('Document upload error: $e');
      _showSnack(appTranslate(ref.read(languageProvider), 'readiness.upload_failed'));
    } finally {
      if (mounted) {
        setState(() {
          _uploadingCv = false;
        });
      }
    }
  }

  Map<String, double> _getRoleDefaultSkills(String targetRole) {
    final r = targetRole.toLowerCase();
    if (r.contains('ui') || r.contains('ux') || r.contains('design')) {
      return {
        "Figma & Design Systems": 0.60,
        "UX Principles & Usability (HCI)": 0.80,
        "User Research & Wireframing": 0.60,
      };
    } else if (r.contains('mobile')) {
      return {
        "Flutter & Dart Fundamentals": 0.60,
        "Mobile State & Navigation": 0.60,
        "Native Device APIs & Storage": 0.50,
      };
    } else if (r.contains('backend')) {
      return {
        "REST APIs & Server Logic": 0.70,
        "Database & SQL Optimization": 0.65,
        "API Security & Authentication": 0.60,
      };
    } else if (r.contains('fullstack')) {
      return {
        "Fullstack Frontend Web": 0.70,
        "Fullstack Backend & APIs": 0.70,
        "Database & ORM Integration": 0.65,
      };
    } else if (r.contains('data') || r.contains('scientist') || r.contains('ai')) {
      return {
        "Python Data Stack": 0.75,
        "Machine Learning & Models": 0.60,
        "Data Engineering & SQL": 0.65,
      };
    }
    // Default Frontend Developer
    return {
      "React & Web Frameworks": 0.70,
      "CSS Architecture & Layouts": 0.80,
      "DOM & Client Performance": 0.60,
    };
  }

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              appTranslate(lang, 'feature.readiness'),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              appTranslate(lang, 'readiness.subtitle'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabBar(lang),
              const SizedBox(height: 16),
              _buildTabContent(lang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(AppLanguage lang) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(lang);
      case 1:
        return _buildInitialTestTab(lang);
      case 2:
        return _buildSkillMapTab(lang);
      case 3:
        return _buildSkillGapTab(lang);
      default:
        return _buildOverviewTab(lang);
    }
  }

  // Helper to extract the user's skills. Primary source is the backend
  // assessment analytics (same data the website uses), so the mobile Skill Map /
  // Skill Gap / Overview always match the web. Falls back to the user profile
  // skills, then to static defaults.
  Map<String, double> _getSkills() {
    final analytics = ref.watch(assessmentAnalyticsProvider).value;
    if (analytics != null && analytics['has_assessment'] == true) {
      final cats = (analytics['categories'] as List?) ?? [];
      if (cats.isNotEmpty) {
        final map = <String, double>{};
        for (final c in cats) {
          final name = (c['name'] ?? c['slug'] ?? 'Skill').toString();
          final scoreNum = c['score'];
          final score = scoreNum is num ? scoreNum.toDouble() : 0.0;
          map[name] = (score / 100.0).clamp(0.0, 1.0);
        }
        return map;
      }
    }
    final userProfile = ref.watch(userProfileProvider).value;
    if (userProfile != null && userProfile.skills.isNotEmpty) {
      return userProfile.skills;
    }
    // Return empty map if no assessment done — don't show dummy values
    return {};
  }

  // --- TAB 0: OVERVIEW ---
  Widget _buildOverviewTab(AppLanguage lang) {
    final userProfile = ref.watch(userProfileProvider).value;
    final analytics = ref.watch(assessmentAnalyticsProvider).value;
    final results = ref.watch(userTestResultsProvider).value ?? [];
    final skills = _getSkills();

    final hasAssessment =
        analytics != null && analytics['has_assessment'] == true;

    String readinessStr;
    String skillsMappedStr;
    String criticalGapsStr;
    String strengthsStr;

    if (hasAssessment) {
      // Use the same backend analytics the website does so the numbers match.
      final overall = analytics['overall_score'];
      final overallVal = overall is num ? overall.toDouble() : 0.0;
      readinessStr = "${overallVal.round()}%";
      skillsMappedStr = "${analytics['skills_mapped'] ?? 0}";
      criticalGapsStr = "${analytics['critical_gaps_count'] ?? 0}";
      strengthsStr = "${analytics['strengths_count'] ?? 0}";
    } else {
      // User has not taken the Initial Test yet.
      // Show overall readiness from CV if available, but set test stats to 0.
      final overall = analytics?['overall_score'];
      final overallVal = overall is num ? overall.toDouble() : 0.0;
      readinessStr = "${overallVal.round()}%";
      skillsMappedStr = "0";
      criticalGapsStr = "0";
      strengthsStr = "0";
    }

    // Real document state (no more hardcoded JohnDoe files).
    final cvUrl = (userProfile?.preferences['cvUrl'] ?? '').toString();
    final cvName =
        cvUrl.isNotEmpty ? (cvUrl.split('/').last) : null;

    final hasInitialTest = (analytics != null &&
            analytics['has_assessment'] == true &&
            analytics['assessment_id'] != null &&
            analytics['assessment_id'] != 'cv-assessment' &&
            analytics['assessment_id'] != 'github-sync') ||
        results.isNotEmpty;

    if (!hasInitialTest) {
      skillsMappedStr = "0";
      criticalGapsStr = "0";
      strengthsStr = "0";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid(
          lang: lang,
          readiness: readinessStr,
          skillsMapped: skillsMappedStr,
          criticalGaps: criticalGapsStr,
          strengths: strengthsStr,
        ),
        const SizedBox(height: 24),
        Text(appTranslate(lang, 'readiness.cv_analysis'), style: AppTextStyles.heading1.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        _buildDocumentAnalysisCard(
          lang,
          cvName ?? appTranslate(lang, 'readiness.cv_name_empty'),
          cvName != null
              ? appTranslate(lang, 'readiness.cv_desc_present')
              : appTranslate(lang, 'readiness.cv_desc_empty'),
          cvName != null
              ? appTranslate(lang, 'readiness.cv_action_reupload')
              : appTranslate(lang, 'readiness.cv_action_upload'),
          hasFile: cvName != null,
          isUploading: _uploadingCv,
          onTap: () => _pickAndUploadDocument(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- TAB 1: INITIAL TEST ---
  Widget _buildInitialTestTab(AppLanguage lang) {
    final analyticsAsync = ref.watch(assessmentAnalyticsProvider);

    return analyticsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text("Error loading assessment: $err"),
        ),
      ),
      data: (data) {
        final hasAssessment = data['has_assessment'] == true &&
            data['assessment_id'] != null &&
            data['assessment_id'] != "github-sync";

        if (!hasAssessment) {
          return _buildIntroView(lang);
        } else {
          return _buildCompletedView(lang, data);
        }
      },
    );
  }

  Widget _buildIntroView(AppLanguage lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Color(0xFF066EFF),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appTranslate(lang, 'readiness.initial_test_title'),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                appTranslate(lang, 'readiness.initial_test_desc'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Key Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIntroItem(appTranslate(lang, 'readiness.stats_questions'), appTranslate(lang, 'readiness.stats_questions_val'), isDark),
                  _buildIntroItem(appTranslate(lang, 'readiness.stats_duration'), appTranslate(lang, 'readiness.stats_duration_val'), isDark),
                  _buildIntroItem(appTranslate(lang, 'readiness.stats_targeted'), appTranslate(lang, 'readiness.stats_targeted_val'), isDark),
                ],
              ),
              const SizedBox(height: 24),
              
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.2) : const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF1E40AF).withValues(alpha: 0.4) : const Color(0xFFE0EFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appTranslate(lang, 'readiness.helps_title'),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF066EFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appTranslate(lang, 'readiness.helps_desc'),
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/readiness-center/initial-test');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF066EFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        appTranslate(lang, 'readiness.start_assessment'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntroItem(String title, String subtitle, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView(AppLanguage lang, Map<String, dynamic> data) {
    final double scorePercentage = (data['score_percentage'] ?? data['overall_score'] ?? 0.0).toDouble();
    final completedAt = data['completed_at'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor;
    final Color statusBgColor;
    final String statusText;

    if (scorePercentage >= 75) {
      statusColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF158031);
      statusBgColor = isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE3);
      statusText = appTranslate(lang, 'readiness.status_ready');
    } else if (scorePercentage >= 45) {
      statusColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      statusBgColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      statusText = appTranslate(lang, 'readiness.status_developing');
    } else {
      statusColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
      statusBgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
      statusText = appTranslate(lang, 'readiness.status_needs_focus');
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              // Circular progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: scorePercentage / 100,
                      strokeWidth: 10,
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${scorePercentage.round()}%",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      Text(
                        appTranslate(lang, 'readiness.score'),
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                scorePercentage >= 75 ? appTranslate(lang, 'readiness.result_excellent') : scorePercentage >= 45 ? appTranslate(lang, 'readiness.result_good') : appTranslate(lang, 'readiness.result_focus'),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${appTranslate(lang, 'readiness.completed_on')}${_formatDateCompleted(lang, completedAt)}",
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          context.go('/readiness-center/review-test');
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(
                          appTranslate(lang, 'readiness.view_details'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.invalidate(assessmentQuestionsProvider);
                          context.go('/readiness-center/initial-test');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF066EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          appTranslate(lang, 'readiness.retake_test'),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateCompleted(AppLanguage lang, dynamic dateStr) {
    if (dateStr == null) return appTranslate(lang, 'readiness.recently');
    try {
      final dt = DateTime.parse(dateStr.toString());
      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
    } catch (_) {
      return dateStr.toString();
    }
  }

  // --- TAB 2: SKILL MAP ---
  Widget _buildSkillMapTab(AppLanguage lang) {
    final analytics = ref.watch(assessmentAnalyticsProvider).value;
    final hasAssessment = analytics != null && analytics['has_assessment'] == true;
    final skills = _getSkills();
    final sortedKeys = skills.keys.toList();
    final sortedValues = sortedKeys.map((k) => skills[k] ?? 0.0).toList();

    // If no assessment done yet (or skills map is empty), show clean empty state
    if (!hasAssessment || sortedKeys.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.bar_chart_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            lang == AppLanguage.id
                ? 'Skill Map Belum Tersedia'
                : 'Skill Map Not Available Yet',
            style: AppTextStyles.heading1.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            lang == AppLanguage.id
                ? 'Selesaikan Initial Test untuk melihat peta kemampuanmu.'
                : 'Complete the Initial Test to see your skill map.',
            style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedTabIndex = 1),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(lang == AppLanguage.id ? 'Mulai Initial Test' : 'Start Initial Test'),
          ),
          const SizedBox(height: 40),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appTranslate(lang, 'readiness.skill_map_title'), style: AppTextStyles.heading1.copyWith(fontSize: 18)),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: RadarChartPainter(
                      labels: sortedKeys.map((k) => k
                          .replaceAll(' & Design Systems', ' & Design')
                          .replaceAll(' Principles & Usability (HCI)', ' Principles')
                          .replaceAll(' & Wireframing', '')
                          .replaceAll(' & Dart Fundamentals', ' & Dart')
                          .replaceAll(' Device APIs & Storage', ' APIs')
                          .replaceAll(' & Server Logic', '')
                          .replaceAll(' & SQL Optimization', ' & SQL')
                          .replaceAll(' & Authentication', ' Auth')
                      ).toList(),
                      values: sortedValues,
                      labelColor: Theme.of(context).colorScheme.onSurface,
                      gridColor: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appTranslate(lang, 'readiness.skill_details_title'), style: AppTextStyles.heading1.copyWith(fontSize: 18)),
              const SizedBox(height: 24),
              ...sortedKeys.map((key) {
                final val = skills[key] ?? 0.0;
                Color statusColor = const Color(0xFFD32F2F); // Red (< 40%)
                if (val >= 0.70) {
                  statusColor = const Color(0xFF388E3C); // Green
                } else if (val >= 0.40) {
                  statusColor = const Color(0xFFF57F17); // Orange
                }

                return _buildSkillDetailRow(
                  lang,
                  key,
                  "${(val * 100).toStringAsFixed(0)}%",
                  "${appTranslate(lang, 'readiness.skill_level')}${(val * 10).toStringAsFixed(1)}/10",
                  val,
                  statusColor,
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSkillDetailRow(AppLanguage lang, String title, String percentText, String subtitle, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              Text(percentText, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).dividerColor,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10)),
        ],
      ),
    );
  }

  // --- TAB 3: SKILL GAP ---
  Widget _buildSkillGapTab(AppLanguage lang) {
    final skills = _getSkills();
    
    final needsToLearn = <String, double>{};
    final needsImprovement = <String, double>{};
    final alreadyStrong = <String, double>{};

    skills.forEach((k, v) {
      if (v < 0.40) {
        needsToLearn[k] = v;
      } else if (v < 0.70) {
        needsImprovement[k] = v;
      } else {
        alreadyStrong[k] = v;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsToLearn.isNotEmpty) ...[
          _buildGapSectionHeader(appTranslate(lang, 'readiness.gap_to_learn'), const Color(0xFFD32F2F)),
          ...needsToLearn.entries.map((e) => _buildGapCard(
                e.key,
                appTranslate(lang, 'readiness.desc_to_learn'),
                "${(e.value * 100).toStringAsFixed(0)}%",
                const Color(0xFFFFF1F1),
                const Color(0xFFD32F2F),
              )),
          const SizedBox(height: 16),
        ],
        
        if (needsImprovement.isNotEmpty) ...[
          _buildGapSectionHeader(appTranslate(lang, 'readiness.gap_to_improve'), const Color(0xFFF57F17)),
          ...needsImprovement.entries.map((e) => _buildGapCard(
                e.key,
                appTranslate(lang, 'readiness.desc_to_improve'),
                "${(e.value * 100).toStringAsFixed(0)}%",
                const Color(0xFFFFF9E6),
                const Color(0xFFF57F17),
              )),
          const SizedBox(height: 16),
        ],

        if (alreadyStrong.isNotEmpty) ...[
          _buildGapSectionHeader(appTranslate(lang, 'readiness.gap_already_strong'), const Color(0xFF388E3C)),
          ...alreadyStrong.entries.map((e) => _buildGapCard(
                e.key,
                appTranslate(lang, 'readiness.desc_already_strong'),
                "${(e.value * 100).toStringAsFixed(0)}%",
                const Color(0xFFEAF6EA),
                const Color(0xFF388E3C),
              )),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appTranslate(lang, 'readiness.market_demand'), style: AppTextStyles.heading1.copyWith(fontSize: 18)),
              const SizedBox(height: 24),
              ..._buildMarketDemandRows(),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGapSectionHeader(String title, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.heading1.copyWith(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildGapCard(String title, String subtitle, String percent, Color bgColor, Color textColor) {
    // Use a translucent tint of the accent color so the card reads correctly on
    // both light and dark scaffolds (the hardcoded pastel bgColor washed out and
    // hid the inherited light text in dark mode).
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Text(percent, style: AppTextStyles.heading1.copyWith(color: textColor, fontSize: 18)),
        ],
      ),
    );
  }

  // Build the market-demand rows from the backend (top in-demand skills for the
  // user's role), so the mobile list matches the website.
  List<Widget> _buildMarketDemandRows() {
    final demand = ref.watch(marketDemandProvider).value ?? [];
    if (demand.isEmpty) {
      return [
        _buildMarketDemandRow("React.js", 0.94, "94%"),
        const SizedBox(height: 16),
        _buildMarketDemandRow("TypeScript", 0.82, "82%"),
      ];
    }
    final rows = <Widget>[];
    final top = demand.take(8).toList();
    for (var i = 0; i < top.length; i++) {
      final item = Map<String, dynamic>.from(top[i] as Map);
      final skill =
          (item['skill'] ?? item['skill_name'] ?? 'Skill').toString();
      final trendRaw =
          item['trend_score'] ?? item['trend'] ?? item['bar_width'] ?? 0;
      final trend = trendRaw is num ? trendRaw.toDouble() : 0.0;
      rows.add(_buildMarketDemandRow(
          skill, (trend / 100).clamp(0.0, 1.0), "${trend.round()}%"));
      if (i < top.length - 1) rows.add(const SizedBox(height: 16));
    }
    return rows;
  }

  Widget _buildMarketDemandRow(String title, double progress, String percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percent,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).dividerColor,
          color: AppColors.primaryBlue,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // --- SHARED WIDGETS ---

  Widget _buildTabBar(AppLanguage lang) {
    final tabs = [
      appTranslate(lang, 'readiness.overview'),
      appTranslate(lang, 'readiness.initial_test'),
      appTranslate(lang, 'readiness.skill_map'),
      appTranslate(lang, 'readiness.skill_gap')
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (index) {
          bool isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              width: 76,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Theme.of(context).cardColor,
                border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tabs[index],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: isSelected ? AppColors.white : AppColors.primaryBlue,
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsGrid({
    required AppLanguage lang,
    required String readiness,
    required String skillsMapped,
    required String criticalGaps,
    required String strengths,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatItem(Icons.cloud_upload_outlined, const Color(0xFFE8EAF6), readiness, appTranslate(lang, 'readiness.overall_readiness'))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatItem(Icons.bar_chart, const Color(0xFFE8F5E9), skillsMapped, appTranslate(lang, 'readiness.skills_mapped'))),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildStatItem(Icons.warning_amber_rounded, const Color(0xFFFFEBEE), criticalGaps, appTranslate(lang, 'readiness.critical_gaps'), iconColor: const Color(0xFFD32F2F))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatItem(Icons.check_circle_outline, const Color(0xFFE8F5E9), strengths, appTranslate(lang, 'readiness.strengths'), iconColor: const Color(0xFF388E3C))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, Color iconBgColor, String value, String label, {Color? iconColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primaryBlue, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: AppTextStyles.heading1.copyWith(fontSize: 24)),
              Text(label, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentAnalysisCard(
    AppLanguage lang,
    String filename,
    String description,
    String actionText, {
    required bool hasFile,
    bool isUploading = false,
    bool isAnalyzing = false,
    VoidCallback? onTap,
    VoidCallback? onViewResult,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFE1F0FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.description, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(filename, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (isAnalyzing)
                Text("Analyzing...", style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFF97316), fontWeight: FontWeight.bold))
              else if (hasFile)
                Text("Uploaded & Analyzed", style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    onTap: (isUploading || isAnalyzing) ? null : onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          if (isUploading || isAnalyzing)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                            )
                          else
                            const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isUploading
                                ? appTranslate(lang, 'readiness.uploading')
                                : isAnalyzing
                                    ? "Analyzing..."
                                    : actionText,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasFile && !isUploading) ...[
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => context.push('/cv-screening'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.rate_review_outlined, color: AppColors.primaryBlue, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              "ATS Review",
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlueBanner(AppLanguage lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appTranslate(lang, 'readiness.banner_title'), style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF1046A0), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  appTranslate(lang, 'readiness.banner_desc'),
                  style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF1046A0)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.plagiarism_outlined, size: 64, color: Color(0xFF90CAF9)),
        ],
      ),
    );
  }
}

class _SkillMapPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color labelColor;
  final Color gridColor;

  _SkillMapPainter({
    required this.values,
    required this.labels,
    this.labelColor = const Color(0xFF757575),
    this.gridColor = const Color(0xFFE1F0FF),
  });

  final List<Color> dotColors = [
    const Color(0xFFD32F2F), // Testing
    const Color(0xFFD32F2F), // Web Performance
    const Color(0xFFF57F17), // Accessibility
    const Color(0xFF388E3C), // State Management
    const Color(0xFF388E3C), // React.js
    const Color(0xFF388E3C), // CSS
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 60; // leave room for labels

    final outlinePaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = const Color(0xFF90CAF9).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw concentric hexagons
    final n = values.length;
    for (int i = 1; i <= 4; i++) {
      final path = Path();
      final r = radius * (i / 4);
      for (int j = 0; j < n; j++) {
        final angle = j * (2 * pi / n) - (pi / 2);
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, outlinePaint);
    }

    // Draw axes
    for (int j = 0; j < n; j++) {
      final angle = j * (2 * pi / n) - (pi / 2);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), outlinePaint);
    }

    // Draw values polygon
    final valuePath = Path();
    for (int j = 0; j < n; j++) {
      final angle = j * (2 * pi / n) - (pi / 2);
      final val = values[j];
      final r = radius * val;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (j == 0) {
        valuePath.moveTo(x, y);
      } else {
        valuePath.lineTo(x, y);
      }
    }
    valuePath.close();

    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, strokePaint);

    // Draw labels
    for (int j = 0; j < n; j++) {
      final angle = j * (2 * pi / n) - (pi / 2);
      final labelRadius = radius + 15; // padding for label
      final labelX = center.dx + labelRadius * cos(angle);
      final labelY = center.dy + labelRadius * sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[j],
          style: TextStyle(color: labelColor, fontSize: 10, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      final dotColor = j < dotColors.length ? dotColors[j] : const Color(0xFF388E3C);
      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;

      double totalWidth = 12 + 8 + textPainter.width;
      double startX = labelX;
      double startY = labelY - textPainter.height / 2;

      if (cos(angle) > 0.1) {
        // Right side
        startX = labelX;
      } else if (cos(angle) < -0.1) {
        // Left side
        startX = labelX - totalWidth;
      } else {
        // Top/Bottom
        startX = labelX - totalWidth / 2;
        if (sin(angle) < 0) {
          startY = labelY - textPainter.height - 10;
        } else {
          startY = labelY + 10;
        }
      }

      canvas.drawCircle(
          Offset(startX + 6, startY + textPainter.height / 2), 6, dotPaint);
      textPainter.paint(canvas, Offset(startX + 12 + 8, startY));
    }
  }

  @override
  bool shouldRepaint(covariant _SkillMapPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}
