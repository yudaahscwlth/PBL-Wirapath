import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/models/user_model.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/competition_card.dart';
import '../widgets/skill_progress.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int _selectedTab = 0; // 0 for My Profile, 1 for Settings
  bool _isUploadingDoc = false;

  List<String> _getRoleDefaultCategories(String targetRole) {
    final r = targetRole.toLowerCase();
    if (r.contains('ui') || r.contains('ux') || r.contains('design')) {
      return [
        "Figma & Design Systems",
        "UX Principles & Usability (HCI)",
        "User Research & Wireframing",
      ];
    } else if (r.contains('mobile')) {
      return [
        "Flutter & Dart Fundamentals",
        "Mobile State & Navigation",
        "Native Device APIs & Storage",
      ];
    } else if (r.contains('backend')) {
      return [
        "REST APIs & Server Logic",
        "Database & SQL Optimization",
        "API Security & Authentication",
      ];
    } else if (r.contains('fullstack')) {
      return [
        "Fullstack Frontend Web",
        "Fullstack Backend & APIs",
        "Database & ORM Integration",
      ];
    } else if (r.contains('data') || r.contains('scientist')) {
      return [
        "Python Data Stack",
        "Machine Learning & Models",
        "Data Engineering & SQL",
      ];
    }
    return [
      "React & Web Frameworks",
      "CSS Architecture & Layouts",
      "DOM & Client Performance",
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
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
        title: Text(
          appTranslate(lang, 'profile.title'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: _selectedTab == 0
                        ? AppColors.primaryBlue
                        : Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTab = 0;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            appTranslate(lang, 'profile.tab_my'),
                            style: TextStyle(
                              color: _selectedTab == 0
                                  ? Colors.white
                                  : AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: _selectedTab == 1
                        ? AppColors.primaryBlue
                        : Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTab = 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            appTranslate(lang, 'profile.tab_settings'),
                            style: TextStyle(
                              color: _selectedTab == 1
                                  ? Colors.white
                                  : AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            if (_selectedTab == 0)
              _buildProfileContent(userProfileAsync)
            else
              _buildSettingsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(AsyncValue<UserModel?> userProfileAsync) {
    final lang = ref.watch(languageProvider);
    final userProfile = userProfileAsync.value;

    // Real stats from the same backend analytics the website uses.
    final analytics = ref.watch(assessmentAnalyticsProvider).value;
    final hasAssessment =
        analytics != null && analytics['has_assessment'] == true;
    final overallRaw = analytics?['overall_score'];
    final readinessVal = overallRaw is num ? overallRaw.round() : 0;
    final readinessStr = hasAssessment ? '$readinessVal%' : '0%';
    final gapsStr =
        hasAssessment ? '${analytics['critical_gaps_count'] ?? 0}' : '0';

    final miniProjects = ref.watch(miniProjectsProvider).value ?? [];
    final testResults = ref.watch(userTestResultsProvider).value ?? [];

    // Retrieve completed mini-projects (submitted or reviewed) and test results
    final completedProjects = miniProjects.where((p) => p.submissionStatus == 'submitted' || p.submissionStatus == 'reviewed').toList();

    // Helper functions for mapping:
    String getEquivalentCertForProject(String titleOrId) {
      final title = titleOrId.toLowerCase();
      if (title.contains('testing') || title.contains('test')) {
        return 'Meta Front-End Developer (Module 5)';
      } else if (title.contains('responsive') || title.contains('css')) {
        return 'W3C FWD Certificate (Module 3)';
      } else if (title.contains('component') || title.contains('react')) {
        return 'Meta Front-End Developer (Module 6)';
      } else if (title.contains('async') || title.contains('javascript') || title.contains('js')) {
        return 'Meta Front-End Developer (Module 4)';
      } else if (title.contains('portfolio') || title.contains('landing')) {
        return 'freeCodeCamp Responsive Web Design';
      } else if (title.contains('task tracker') || title.contains('tracker')) {
        return 'Meta Front-End Developer (Module 2)';
      } else if (title.contains('analytics') || title.contains('chart')) {
        return 'Google Data Analytics Professional';
      } else if (title.contains('rest api') || title.contains('api')) {
        return 'IBM Full Stack Developer (Module 3)';
      } else if (title.contains('jwt') || title.contains('auth')) {
        return 'Meta Back-End Developer (Module 5)';
      } else if (title.contains('websocket') || title.contains('chat')) {
        return 'Google Cloud Engineering Certificate';
      } else if (title.contains('house price') || title.contains('regression')) {
        return 'Google Advanced Data Analytics (Module 3)';
      } else if (title.contains('churn') || title.contains('classification')) {
        return 'IBM Data Science Professional (Module 6)';
      } else if (title.contains('deep learning') || title.contains('transformer') || title.contains('text classifier')) {
        return 'Google TensorFlow Developer Certificate';
      } else if (title.contains('wireframe') || title.contains('prototype')) {
        return 'Google UX Design Certificate (Module 2)';
      } else if (title.contains('design system') || title.contains('saas')) {
        return 'Google UX Design Certificate (Module 4)';
      } else if (title.contains('wallet') || title.contains('e-wallet')) {
        return 'Google UX Design Certificate (Module 6)';
      } else if (title.contains('proposal') || title.contains('sow')) {
        return 'Google Project Management Certificate';
      } else if (title.contains('contract') || title.contains('sla')) {
        return 'ITIL Foundation Certification';
      }
      return 'Google Career Certification';
    }

    String getCertCodeForProject(String titleOrId) {
      final title = titleOrId.toLowerCase();
      if (title.contains('testing')) return 'TEST L3';
      if (title.contains('responsive') || title.contains('css')) return 'HCEV L3';
      if (title.contains('component') || title.contains('react')) return 'PROG-REACT L3';
      if (title.contains('async') || title.contains('javascript')) return 'PROG-JS L3';
      if (title.contains('portfolio')) return 'HTML L1';
      if (title.contains('tracker')) return 'REACT L2';
      if (title.contains('analytics')) return 'ANALYTICS L3';
      if (title.contains('rest api') || title.contains('api')) return 'BE-REST L1';
      if (title.contains('jwt') || title.contains('auth')) return 'BE-AUTH L2';
      if (title.contains('websocket') || title.contains('chat')) return 'BE-WS L3';
      if (title.contains('house price')) return 'DS-REG L1';
      if (title.contains('churn')) return 'DS-CLASS L2';
      if (title.contains('deep learning') || title.contains('text classifier')) return 'DS-DL L3';
      if (title.contains('wireframe')) return 'UI-WIRE L1';
      if (title.contains('design system')) return 'UI-SYS L2';
      if (title.contains('wallet')) return 'UI-HI L3';
      if (title.contains('proposal')) return 'FL-SOW L2';
      if (title.contains('contract')) return 'FL-SLA L3';
      return 'CERT-WD L3';
    }

    String getEquivalentCertForTest(String testId, String title) {
      final id = testId.toLowerCase();
      if (id.contains('test') || title.toLowerCase().contains('testing')) {
        return 'Meta Front-End Developer (Module 5)';
      } else if (id.contains('prog') || id.contains('code') || title.toLowerCase().contains('programming')) {
        return 'Google Crash Course on Python';
      } else if (id.contains('hcev') || id.contains('ux') || title.toLowerCase().contains('ux')) {
        return 'Google UX Design (Module 1)';
      } else if (id.contains('dtan') || id.contains('data') || title.toLowerCase().contains('data')) {
        return 'Google Data Analytics (Module 1)';
      }
      return 'Google Career Certification';
    }

    String getCertCodeForTest(String testId, String title) {
      final id = testId.toLowerCase();
      if (id.contains('test') || title.toLowerCase().contains('testing')) return 'TEST L3';
      if (id.contains('prog') || id.contains('code') || title.toLowerCase().contains('programming')) return 'PROG L3';
      if (id.contains('hcev') || id.contains('ux') || title.toLowerCase().contains('ux')) return 'HCEV L3';
      if (id.contains('dtan') || id.contains('data') || title.toLowerCase().contains('data')) return 'DTAN L3';
      return 'CERT L3';
    }

    String formatDate(DateTime? date) {
      if (date == null) return appTranslate(lang, 'common.recent');
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    final List<Widget> certCards = [];

    for (final project in completedProjects) {
      certCards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CompetitionCard(
            title: project.title,
            date: formatDate(project.submittedAt ?? project.reviewedAt),
          ),
        ),
      );
    }

    for (final test in testResults) {
      certCards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CompetitionCard(
            title: test.testTitle,
            date: formatDate(test.submittedDate),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileHeaderCard(
          name: userProfile?.displayName ?? appTranslate(lang, 'common.user'),
          role: userProfile?.role ?? appTranslate(lang, 'profile.role_default'),
        ),
        const SizedBox(height: 16),

        // Stats (driven by real data)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatCard(value: readinessStr, label: appTranslate(lang, 'profile.stat_readiness')),
            StatCard(value: gapsStr, label: appTranslate(lang, 'profile.stat_gaps')),
            StatCard(value: '${miniProjects.length}', label: appTranslate(lang, 'profile.stat_projects')),
            StatCard(
                value: '${testResults.length}x', label: appTranslate(lang, 'profile.stat_tests')),
          ],
        ),
        const SizedBox(height: 24),

        // Validated Competitions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appTranslate(lang, 'profile.validated_competitions'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (certCards.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        appTranslate(lang, 'profile.no_competitions'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        appTranslate(lang, 'profile.no_competitions_desc'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: certCards.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => certCards[index],
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Your Skill Details
        // Your Skill Details (Driven dynamically by backend analytics)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appTranslate(lang, 'profile.skill_details'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (analytics != null && analytics['has_assessment'] == true && analytics['categories'] is List && (analytics['categories'] as List).isNotEmpty)
                ...() {
                  final cats = (analytics['categories'] as List).cast<Map<String, dynamic>>();
                  return cats.map((cat) {
                    final String title = cat['name'] ?? cat['slug'] ?? 'Skill';
                    final num rawScore = cat['score'] ?? 0;
                    final int score = rawScore.round().clamp(0, 100);
                    final Color color = score >= 75
                        ? AppColors.success
                        : (score >= 50 ? const Color(0xFFF59E0B) : AppColors.error);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SkillProgress(
                        title: title,
                        percentage: score,
                        date: formatDate(DateTime.now()),
                        progressColor: color,
                      ),
                    );
                  }).toList();
                }()
              else ...() {
                final roleName = userProfile?.role ?? 'Frontend Developer';
                final defaultCats = _getRoleDefaultCategories(roleName);
                return defaultCats.map((catTitle) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SkillProgress(
                    title: catTitle,
                    percentage: 0,
                    date: appTranslate(lang, 'readiness.not_evaluated'),
                    progressColor: AppColors.error,
                  ),
                )).toList();
              }(),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Documents (CV + Transcript) — mirrors the web DocumentsCard.
        _buildDocumentsSection(userProfile),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDocumentsSection(UserModel? userProfile) {
    final lang = ref.watch(languageProvider);
    final cvUrl = (userProfile?.preferences['cvUrl'] ?? '') as String;
    final transcriptUrl =
        (userProfile?.preferences['transcriptUrl'] ?? '') as String;
    final hasDocs = cvUrl.isNotEmpty || transcriptUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appTranslate(lang, 'profile.documents'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasDocs)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 28,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appTranslate(lang, 'profile.no_documents'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // upload rows below (kept) ...
            if (cvUrl.isNotEmpty)
              _buildDocumentRow(
                icon: Icons.description_outlined,
                iconColor: AppColors.primaryBlue,
                title: 'CV',
                filename: cvUrl.split('/').last,
                url: cvUrl,
              ),
          ],
          const SizedBox(height: 16),
          // Upload actions — let the user add/replace CV directly
          _buildUploadButton(
            label: cvUrl.isEmpty
                ? appTranslate(lang, 'profile.upload_cv')
                : appTranslate(lang, 'profile.replace_cv'),
            icon: Icons.description_outlined,
            onTap: _isUploadingDoc ? null : () => _uploadDocument('cv'),
          ),
          if (_isUploadingDoc) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        side: const BorderSide(color: AppColors.primaryBlue),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _uploadDocument(String type) async {
    final messenger = ScaffoldMessenger.of(context);
    final lang = ref.read(languageProvider);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null && file.bytes == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(appTranslate(lang, 'profile.cannot_read_file'))),
        );
        return;
      }

      setState(() => _isUploadingDoc = true);

      final apiService = ref.read(apiServiceProvider);
      final session = await apiService.getCurrentUser();
      final userId = session['result']['user']?['id'] ??
          session['result']['id'];

      if (type == 'cv') {
        await apiService.uploadOnboardingCv(
          userId: userId.toString(),
          cvPath: file.path,
          cvBytes: file.bytes,
          cvName: file.name,
        );
      } else {
        await apiService.uploadOnboardingTranscript(
          userId: userId.toString(),
          transcriptPath: file.path,
          transcriptBytes: file.bytes,
          transcriptName: file.name,
        );
      }

      // Refresh the profile so the new document URL is reflected immediately.
      await ref.read(userProfileProvider.notifier).refreshProfile();

      final docLabel =
          type == 'cv' ? 'CV' : appTranslate(lang, 'profile.transcript');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              '$docLabel ${appTranslate(lang, 'profile.doc_uploaded_suffix')}'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${appTranslate(lang, 'profile.upload_failed')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingDoc = false);
    }
  }

  Widget _buildDocumentRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String filename,
    required String url,
  }) {
    return InkWell(
      onTap: () => _openDocument(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final lang = ref.read(languageProvider);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(appTranslate(lang, 'profile.cannot_open_doc'))),
      );
    }
  }

  Widget _buildSettingsContent() {
    final lang = ref.watch(languageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: appTranslate(lang, 'profile.account_settings'),
          items: [
            SettingsTile(
              icon: Icons.person_outline,
              title: appTranslate(lang, 'profile.personal_info'),
              route: '/personal-information',
            ),
            SettingsTile(
              icon: Icons.security,
              title: appTranslate(lang, 'profile.password_security'),
              route: '/password-security',
            ),
            SettingsTile(
              icon: Icons.notifications_none,
              title: appTranslate(lang, 'profile.notifications'),
              route: '/notifications',
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: appTranslate(lang, 'profile.preferences'),
          items: [
            SettingsTile(
              icon: Icons.language,
              title: appTranslate(lang, 'settings.appearance'),
              route: '/language-appearance',
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: appTranslate(lang, 'profile.integrations_support'),
          items: [
            SettingsTile(
              icon: Icons.link,
              title: appTranslate(lang, 'profile.integrations'),
              route: '/integrations',
            ),
            SettingsTile(
              icon: Icons.help_outline,
              title: appTranslate(lang, 'profile.help_support'),
              route: '/help-support',
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Logout Button
        ElevatedButton(
          onPressed: () async {
            final router = GoRouter.of(context);
            await ref.read(apiServiceProvider).logout();
            ref.read(userProfileProvider.notifier).logout();
            router.go('/sign-in');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            appTranslate(lang, 'profile.logout'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
