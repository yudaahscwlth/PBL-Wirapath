import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/models/mini_project_model.dart';
import '../widgets/project_card.dart';
import '../widgets/radar_chart.dart';

class DevhubPage extends ConsumerStatefulWidget {
  const DevhubPage({super.key});

  @override
  ConsumerState<DevhubPage> createState() => _DevhubPageState();
}

class _DevhubPageState extends ConsumerState<DevhubPage> {
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
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
              appTranslate(lang, 'feature.devhub'),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              appTranslate(lang, 'devhub.subtitle'),
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
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
          child: _buildMainContent(lang),
        ),
      ),
    );
  }

  Widget _buildMainContent(AppLanguage lang) {
    final skillGapAsync = ref.watch(skillGapProvider);
    final miniProjectsAsync = ref.watch(miniProjectsProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final analytics = ref.watch(assessmentAnalyticsProvider).value;
    final targetRole = userProfile?.role ?? '';

    // Build role-specific skill map data from real assessment analytics
    final Map<String, double> roleSkills = _getRoleSkills(targetRole, analytics);
    final skillLabels = roleSkills.keys.toList();
    final skillValues = roleSkills.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appTranslate(lang, 'devhub.skill_map'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        // Radar chart from skill gap data (only if initial test completed)
        if (analytics != null && analytics['has_assessment'] == true && roleSkills.isNotEmpty)
          skillGapAsync.when(
            data: (skills) => AspectRatio(
              aspectRatio: 1.1,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: CustomPaint(
                  painter: RadarChartPainter(
                    labels: skillLabels,
                    values: skillValues,
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => AspectRatio(
              aspectRatio: 1.1,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: CustomPaint(
                  painter: RadarChartPainter(
                    labels: skillLabels,
                    values: skillValues,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.radar, size: 48, color: AppColors.primaryBlue.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    appTranslate(lang, 'devhub.skill_map_empty_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appTranslate(lang, 'devhub.skill_map_empty_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/readiness-center'),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(appTranslate(lang, 'devhub.start_initial_test')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ],
              ),
            ),
          ),
        const SizedBox(height: 30),
        Text(
          appTranslate(lang, 'devhub.projects_for_you'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        // Dynamic project list
        miniProjectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return _buildProjectsFallback(lang);
            }
            return Column(
              children: projects
                  .map((p) => _buildProjectCard(p, lang))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => _buildProjectsFallback(lang),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Map<String, double> _getRoleSkills(String targetRole, Map<String, dynamic>? analytics) {
    if (analytics != null && analytics['has_assessment'] == true) {
      final cats = (analytics['categories'] as List?) ?? [];
      if (cats.isNotEmpty) {
        final map = <String, double>{};
        for (final c in cats) {
          final rawName = (c['name'] ?? c['slug'] ?? 'Skill').toString();
          final label = rawName
              .replaceAll(' & Design Systems', ' & Design')
              .replaceAll(' Principles & Usability (HCI)', ' Principles')
              .replaceAll(' & Wireframing', '')
              .replaceAll(' & Dart Fundamentals', ' & Dart')
              .replaceAll(' Device APIs & Storage', ' APIs')
              .replaceAll(' & Server Logic', '')
              .replaceAll(' & SQL Optimization', ' & SQL')
              .replaceAll(' & Authentication', ' Auth');
          final scoreNum = c['score'];
          final score = scoreNum is num ? scoreNum.toDouble() : 0.0;
          map[label] = (score / 100.0).clamp(0.0, 1.0);
        }
        return map;
      }
    }
    // Return empty map when initial test has not been completed yet
    return {};
  }

  Widget _buildProjectCard(MiniProject project, AppLanguage lang) {
    // Calculate skill gap percentage to display (use overallScore or default)
    final gapPercent = project.overallScore != null
        ? '${(100 - project.overallScore!).round()}%'
        : '—';
    final gapLabel = project.overallScore != null
        ? '${appTranslate(lang, 'readiness.skill_gap')}: $gapPercent'
        : appTranslate(lang, 'devhub.not_submitted');

    // Progress based on submission status
    double progress = 0.0;
    if (project.submissionStatus == 'reviewed' && project.overallScore != null) {
      progress = project.overallScore! / 100;
    } else if (project.submissionStatus == 'submitted') {
      progress = 0.5;
    } else {
      progress = 0.0;
    }

    final tags = [
      project.level,
      project.duration,
      if (project.tag.isNotEmpty) project.tag,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: ProjectCard(
        title: project.title,
        description: project.description,
        gap: gapLabel,
        tags: tags,
        progress: progress,
        onTapStartProject: () {
          context.push('/devhub/project/${project.id}', extra: project);
        },
      ),
    );
  }

  Widget _buildEmptyProjects(AppLanguage lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              appTranslate(lang, 'devhub.no_projects'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsFallback(AppLanguage lang) {
    final userProfile = ref.watch(userProfileProvider).value;
    final r = (userProfile?.role ?? '').toLowerCase();

    if (r.contains('ui') || r.contains('ux') || r.contains('design')) {
      return Column(
        children: [
          ProjectCard(
            title: "Figma Design System & Auto Layout Library",
            description: "Construct a scalable, responsive Figma design system incorporating Auto Layout, color design tokens, and interactive component variants.",
            gap: "${appTranslate(lang, 'readiness.skill_gap')}: 40%",
            tags: const ["Intermediate", "6 hrs", "3 tasks"],
            progress: 0.0,
            onTapStartProject: () => context.push('/devhub/project/mp-ux-1'),
          ),
          const SizedBox(height: 15),
          ProjectCard(
            title: "Mobile Usability Audit & Redesign",
            description: "Perform a Nielsen Heuristic Usability Audit on a mobile app flow, identify accessibility friction points, and deliver a high-fi interactive prototype.",
            gap: "${appTranslate(lang, 'readiness.skill_gap')}: 20%",
            tags: const ["Intermediate", "5 hrs", "3 tasks"],
            progress: 0.0,
            onTapStartProject: () => context.push('/devhub/project/mp-ux-2'),
          ),
          const SizedBox(height: 15),
          ProjectCard(
            title: "User Research & Wireframing Flow",
            description: "Conduct user interviews, construct target User Personas and Journey Maps, and map out low-fidelity wireframe user navigation flows.",
            gap: "${appTranslate(lang, 'readiness.skill_gap')}: 40%",
            tags: const ["Intermediate", "4 hrs", "3 tasks"],
            progress: 0.0,
            onTapStartProject: () => context.push('/devhub/project/mp-ux-3'),
          ),
        ],
      );
    } else if (r.contains('mobile')) {
      return Column(
        children: [
          ProjectCard(
            title: "Flutter Multi-Tab App with Riverpod",
            description: "Develop a multi-tab mobile application using Flutter, declarative Go Router navigation, and Riverpod reactive state management.",
            gap: "${appTranslate(lang, 'readiness.skill_gap')}: 40%",
            tags: const ["Intermediate", "6 hrs", "3 tasks"],
            progress: 0.0,
            onTapStartProject: () => context.push('/devhub/project/mp-mb-1'),
          ),
          const SizedBox(height: 15),
          ProjectCard(
            title: "Offline-First Local Storage App",
            description: "Build a Flutter mobile app that operates seamlessly offline using Hive / Isar local database caching and network connectivity listeners.",
            gap: "${appTranslate(lang, 'readiness.skill_gap')}: 50%",
            tags: const ["Advanced", "6 hrs", "3 tasks"],
            progress: 0.0,
            onTapStartProject: () => context.push('/devhub/project/mp-mb-2'),
          ),
        ],
      );
    } else if (r.contains('backend')) {
      return Column(
        children: [
          ProjectCard(
            title: "Express REST API with JWT Auth",
            description: "Design and deploy a secure Node.js Express REST API featuring bcrypt password hashing, JWT stateless authentication, and input validation.",
            gap: "${appTranslate(lang, 'readiness.skill_gap')}: 30%",
            tags: const ["Intermediate", "6 hrs", "3 tasks"],
            progress: 0.0,
            onTapStartProject: () => context.push('/devhub/project/mp-be-1'),
          ),
          const SizedBox(height: 15),
          ProjectCard(
            title: "Database Query Optimization Lab",
            description: "Optimize slow relational database queries using B-Tree indexing, EXPLAIN execution plan analysis, and connection pooling.",
            gap: "${appTranslate(lang, 'readiness.skill_gap')}: 35%",
            tags: const ["Advanced", "5 hrs", "3 tasks"],
            progress: 0.0,
            onTapStartProject: () => context.push('/devhub/project/mp-be-2'),
          ),
        ],
      );
    }

    // Default Frontend Developer fallback
    return Column(
      children: [
        ProjectCard(
          title: "React E-Commerce Dashboard",
          description: "Build a dynamic, responsive e-commerce management dashboard using React, Tailwind CSS, and custom hooks.",
          gap: "${appTranslate(lang, 'readiness.skill_gap')}: 30%",
          tags: const ["Intermediate", "6 hrs", "3 tasks"],
          progress: 0.0,
          onTapStartProject: () => context.push('/devhub/project/mp-fe-1'),
        ),
        const SizedBox(height: 15),
        ProjectCard(
          title: "Web Performance & CLS Optimization",
          description: "Audit and fix performance bottlenecks in a heavy web page, optimizing Largest Contentful Paint (LCP) and eliminating Cumulative Layout Shift (CLS).",
          gap: "${appTranslate(lang, 'readiness.skill_gap')}: 20%",
          tags: const ["Advanced", "5 hrs", "3 tasks"],
          progress: 0.0,
          onTapStartProject: () => context.push('/devhub/project/mp-fe-2'),
        ),
      ],
    );
  }
}
