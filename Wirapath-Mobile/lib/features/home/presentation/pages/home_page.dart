import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/recent_activity_provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/feature_search_delegate.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final skillGapsAsync = ref.watch(skillGapProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(skillGapProvider);
            await ref.read(userProfileProvider.notifier).refreshProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  userProfileAsync.when(
                    data: (user) => _buildHeader(context, lang, user?.displayName ?? appTranslate(lang, 'common.user')),
                    loading: () => _buildHeader(context, lang, appTranslate(lang, 'common.loading')),
                    error: (_, __) => _buildHeader(context, lang, appTranslate(lang, 'common.user')),
                  ),
                  const SizedBox(height: 24),
                  _buildSearchBar(context, ref),
                  const SizedBox(height: 32),

                  summaryAsync.when(
                    data: (summary) => _buildReadinessCard(
                      context: context,
                      lang: lang,
                      score: summary['readinessScore']?.toString() ?? "0",
                      role: summary['role'] ?? appTranslate(lang, 'home.career_seeker'),
                    ),
                    loading: () => _buildReadinessCard(context: context, lang: lang, score: "...", role: appTranslate(lang, 'common.loading'), isLoading: true),
                    error: (e, __) => _buildReadinessCard(context: context, lang: lang, score: "0", role: appTranslate(lang, 'home.error_profile')),
                  ),

                  const SizedBox(height: 16),

                  summaryAsync.when(
                    data: (summary) => _buildStatsRow(
                      lang: lang,
                      trend: summary['readinessTrend']?.toString() ?? "0%",
                      streak: summary['streak']?.toString() ?? "0",
                    ),
                    loading: () => _buildStatsRow(lang: lang, trend: "...", streak: "..."),
                    error: (e, __) => _buildStatsRow(lang: lang, trend: "0%", streak: "0"),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    lang,
                    appTranslate(lang, 'home.skills_attention'),
                    onViewAll: () => context.go('/readiness-center', extra: {'initialTabIndex': 3}),
                  ),
                  const SizedBox(height: 16),

                  skillGapsAsync.when(
                    data: (gaps) {
                      // Filter for skills with current < 70 (Weak or Enough)
                      final attentionSkills = gaps.where((item) {
                        final current = (item['current'] as num?)?.toDouble() ?? 0.0;
                        return current < 70;
                      }).toList();

                      if (gaps.isEmpty) {
                        final bool isDark = Theme.of(context).brightness == Brightness.dark;
                        const Color blue = Color(0xFF066EFF);
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF3B82F6).withOpacity(0.3) : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.rocket_launch_outlined, color: blue, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "No Skills Mapped Yet",
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Upload your CV or complete the Assessment Test to evaluate your skills.",
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (attentionSkills.isEmpty) {
                        final bool isDark = Theme.of(context).brightness == Brightness.dark;
                        const Color green = Color(0xFF388E3C);
                        final Color accent = isDark ? _brighten(green) : green;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Color.alphaBlend(accent.withValues(alpha: 0.16), Theme.of(context).cardColor)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: isDark
                                ? Border.all(color: accent.withValues(alpha: 0.35))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: accent, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(appTranslate(lang, 'home.great_job'), style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : const Color(0xFF2E7D32))),
                                    Text(appTranslate(lang, 'home.skills_all_strong'), style: AppTextStyles.bodySmall.copyWith(color: accent)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: attentionSkills.length.clamp(0, 3), // show top 3 maximum
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = attentionSkills[index];
                          final skillName = item['skill'] ?? "Unknown Skill";
                          final currentScore = (item['current'] as num?)?.toDouble() ?? 0.0;

                          String statusStr = appTranslate(lang, 'status.weak');
                          Color cardBg = const Color(0xFFFFF1F1);
                          Color textIconColor = const Color(0xFFD32F2F);
                          IconData attentionIcon = Icons.warning_amber_rounded;

                          if (currentScore >= 40) {
                            statusStr = appTranslate(lang, 'status.enough');
                            cardBg = const Color(0xFFFFF9E6);
                            textIconColor = const Color(0xFFF57F17);
                            attentionIcon = Icons.remove_circle_outline;
                          }

                          return _buildSkillAttentionCard(context,
                            skillName,
                            statusStr,
                            "${currentScore.toStringAsFixed(0)}%",
                            cardBg,
                            textIconColor,
                            attentionIcon,
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, __) => Text("${appTranslate(lang, 'home.failed_skills')}: $e", style: const TextStyle(color: AppColors.error)),
                  ),



                  // Growth Progress — mirrors web GrowthProgressCard,
                  // fed by the same /api/dashboard/summary growthProgress data.
                  summaryAsync.when(
                    data: (summary) => _buildGrowthProgress(
                      context,
                      lang,
                      Map<String, dynamic>.from(summary['growthProgress'] ?? {}),
                    ),
                    loading: () => _buildGrowthProgress(context, lang, const {}),
                    error: (e, st) => _buildGrowthProgress(context, lang, const {}),
                  ),
                  const SizedBox(height: 24),

                  // Continue Working — recently visited pages first, then real
                  // /api/dashboard/summary activities (deduped).
                  Builder(builder: (context) {
                    final recent = ref
                        .watch(recentActivityProvider)
                        .map((p) => <String, dynamic>{
                              'type': p.type,
                              'title': p.title,
                              'status': appTranslate(lang, 'home.recently_visited'),
                              'progress': null,
                              'route': p.route,
                            })
                        .toList();
                    final db = summaryAsync.maybeWhen(
                      data: (summary) => List<Map<String, dynamic>>.from(
                        (summary['activities'] as List? ?? [])
                            .map((e) => Map<String, dynamic>.from(e as Map)),
                      ),
                      orElse: () => <Map<String, dynamic>>[],
                    );
                    final titles = recent.map((e) => e['title']).toSet();
                    final merged = [
                      ...recent,
                      ...db.where((a) => !titles.contains(a['title'])),
                    ].take(4).toList();
                    return _buildContinueWorking(context, lang, merged);
                  }),
                  const SizedBox(height: 32),

                  // Upcoming Tasks — mirrors web UpcomingTasks
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      appTranslate(lang, 'home.upcoming_tasks'),
                      style: AppTextStyles.heading1.copyWith(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  summaryAsync.when(
                    data: (summary) => _buildUpcomingTasks(
                      context,
                      lang,
                      List<Map<String, dynamic>>.from(
                        (summary['activities'] as List? ?? [])
                            .map((e) => Map<String, dynamic>.from(e as Map)),
                      ),
                    ),
                    loading: () => _buildUpcomingTasks(context, lang, const []),
                    error: (e, st) => _buildUpcomingTasks(context, lang, const []),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLanguage lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appTranslate(lang, 'home.quick_actions'),
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _quickActionTile(
            context,
            Icons.shield_outlined,
            appTranslate(lang, 'feature.readiness'),
            "/readiness-center",
            const Color(0xFF066EFF),
            const Color(0xFFEFF6FF),
          ),
          const SizedBox(height: 8),
          _quickActionTile(
            context,
            Icons.code_rounded,
            appTranslate(lang, 'feature.devhub'),
            "/devhub",
            const Color(0xFF10B981),
            const Color(0xFFECFDF5),
          ),
          const SizedBox(height: 8),
          _quickActionTile(
            context,
            Icons.work_outline_rounded,
            appTranslate(lang, 'feature.simulation'),
            "/simulation",
            const Color(0xFFF59E0B),
            const Color(0xFFFFF7ED),
          ),
          const SizedBox(height: 8),
          _quickActionTile(
            context,
            Icons.search_rounded,
            appTranslate(lang, 'feature.jobdesk'),
            "/jobdesk-analyzer",
            const Color(0xFF8B5CF6),
            const Color(0xFFF5F3FF),
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    Color color,
    Color bg,
  ) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTasks(BuildContext context, AppLanguage lang, List<Map<String, dynamic>> activities) {
    final tiles = <Widget>[];
    for (final a in activities.take(2)) {
      final type = a['type'] as String? ?? 'project';
      IconData icon = Icons.code_rounded;
      Color iconColor = const Color(0xFF10B981);
      Color iconBg = const Color(0xFFECFDF5);
      String route = '/devhub';
      if (type == 'simulation') {
        icon = Icons.work_outline_rounded;
        iconColor = const Color(0xFFF97316);
        iconBg = const Color(0xFFFFF7ED);
        route = '/simulation';
      } else if (type == 'review') {
        icon = Icons.description_outlined;
        iconColor = const Color(0xFF066EFF);
        iconBg = const Color(0xFFEFF6FF);
      }
      final progress = (a['progress'] as num?);
      tiles.add(_taskTile(
        context: context,
        icon: icon,
        iconColor: iconColor,
        iconBg: iconBg,
        title: a['title'] as String? ?? '',
        status: a['status'] as String? ?? '',
        statusColor: progress != null ? const Color(0xFFF59E0B) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        progress: progress != null ? progress / 100 : null,
        onTap: () => context.go(route),
      ));
      tiles.add(const SizedBox(height: 12));
    }

    return Column(
      children: [
        ...tiles,
        InkWell(
          onTap: () => context.go('/readiness-center/initial-test'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF5D6AF2), Color(0xFF066EFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appTranslate(lang, 'home.take_initial'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appTranslate(lang, 'home.boost_accuracy'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _taskTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String status,
    required Color statusColor,
    double? progress,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 18),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildGrowthProgress(BuildContext context, AppLanguage lang, Map<String, dynamic> gp) {
    int asInt(dynamic v, int fallback) => (v as num?)?.toInt() ?? fallback;
    final skillsMapped = asInt(gp['skillsMapped'], 0);
    final totalSkills = asInt(gp['totalSkills'], 3);
    final projectsDone = asInt(gp['projectsDone'], 0);
    final totalProjects = asInt(gp['totalProjects'], 3);
    final simulationsDone = asInt(gp['simulationsDone'], 0);
    final totalSimulations = asInt(gp['totalSimulations'], 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appTranslate(lang, 'home.growth_progress'),
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _growthRing(context, skillsMapped, totalSkills, const Color(0xFF3B82F6), Icons.track_changes_rounded, appTranslate(lang, 'home.skills_mapped')),
              _growthRing(context, projectsDone, totalProjects, const Color(0xFF10B981), Icons.code_rounded, appTranslate(lang, 'home.projects_done')),
              _growthRing(context, simulationsDone, totalSimulations, const Color(0xFFF59E0B), Icons.work_outline_rounded, appTranslate(lang, 'home.simulations')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _growthRing(BuildContext context, int value, int total, Color color, IconData icon, String label) {
    final pct = total > 0 ? value / total : 0.0;
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 7,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(icon, color: color, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "$value",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: "/$total",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueWorking(BuildContext context, AppLanguage lang, List<Map<String, dynamic>> activities) {
    Widget body;
    if (activities.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 26, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(height: 8),
              Text(
                appTranslate(lang, 'home.nothing_progress'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    } else {
      final tiles = <Widget>[];
      for (final a in activities) {
        final type = a['type'] as String? ?? 'project';
        IconData icon = Icons.code_rounded;
        Color iconColor = const Color(0xFF10B981);
        Color iconBg = const Color(0xFFECFDF5);
        String route = '/devhub';
        if (type == 'simulation') {
          icon = Icons.work_outline_rounded;
          iconColor = const Color(0xFFF59E0B);
          iconBg = const Color(0xFFFFFBEB);
          route = '/simulation';
        } else if (type == 'review') {
          icon = Icons.description_outlined;
          iconColor = const Color(0xFF066EFF);
          iconBg = const Color(0xFFEFF6FF);
        } else if (type == 'readiness') {
          icon = Icons.shield_outlined;
          iconColor = const Color(0xFF066EFF);
          iconBg = const Color(0xFFEFF6FF);
          route = '/readiness-center';
        } else if (type == 'jobdesk') {
          icon = Icons.search_rounded;
          iconColor = const Color(0xFF8B5CF6);
          iconBg = const Color(0xFFF5F3FF);
          route = '/jobdesk-analyzer';
        }
        // Visited pages carry their own route.
        route = (a['route'] as String?) ?? route;
        if (tiles.isNotEmpty) tiles.add(const SizedBox(height: 12));
        tiles.add(_continueItem(
          context,
          icon,
          iconColor,
          iconBg,
          a['title'] as String? ?? '',
          a['status'] as String? ?? '',
          (a['progress'] as num?) != null ? (a['progress'] as num) / 100 : null,
          route: route,
        ));
      }
      body = Column(children: tiles);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                appTranslate(lang, 'home.continue_working'),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          body,
        ],
      ),
    );
  }

  Widget _continueItem(BuildContext context, IconData icon, Color iconColor, Color iconBg, String title, String status, double? progress, {String route = '/devhub'}) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 16),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLanguage lang, String displayName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appTranslate(lang, 'home.welcome_back'), style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    Text(displayName, style: AppTextStyles.heading1.copyWith(fontSize: 22), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final hint = appTranslate(lang, 'search.hint');

    // A read-only field that launches the feature search experience. Tapping it
    // opens a live, filterable list of app features that navigates on select —
    // mirroring the website's "Search features..." box on the dashboard.
    return GestureDetector(
      onTap: () => _openFeatureSearch(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(Icons.search,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFeatureSearch(BuildContext context, WidgetRef ref) async {
    final lang = ref.read(languageProvider);
    await showSearch<String?>(
      context: context,
      delegate: FeatureSearchDelegate(
        hint: appTranslate(lang, 'search.hint'),
        emptyLabel: appTranslate(lang, 'search.empty'),
      ),
    );
  }

  Widget _buildReadinessCard({
    required BuildContext context,
    required AppLanguage lang,
    required String score,
    required String role,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1046A0), // Deep blue from design
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appTranslate(lang, 'home.readiness_index'), style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text(isLoading ? score : "$score%", style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 48)),
              const SizedBox(height: 4),
              Text(isLoading ? appTranslate(lang, 'common.analyzing') : appTranslate(lang, 'home.growing'), style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${appTranslate(lang, 'home.predicted_role')} $role",
                  style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF1046A0), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Positioned(
            right: -20,
            top: -10,
            child: Icon(Icons.folder_copy, size: 120, color: Colors.white.withOpacity(0.2)), // Placeholder for illustration
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({required AppLanguage lang, required String trend, required String streak}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(trend, style: AppTextStyles.heading1.copyWith(color: const Color(0xFF1046A0), fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  trend.startsWith('-')
                      ? (lang == AppLanguage.id ? '↓ Turun dari minggu lalu' : '↓ Down from last week')
                      : (trend.startsWith('+') || (trend != '0%' && trend != '...'))
                          ? appTranslate(lang, 'home.up_last_week')
                          : (lang == AppLanguage.id ? 'Tren Kesiapan' : 'Readiness Trend'),
                  style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF1046A0)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(streak, style: AppTextStyles.heading1.copyWith(color: const Color(0xFF1046A0), fontSize: 24)),
                const SizedBox(height: 4),
                Text(appTranslate(lang, 'home.day_streak'), style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF1046A0))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(AppLanguage lang, String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.heading1.copyWith(fontSize: 18)),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(appTranslate(lang, 'common.view_all'), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          )
        else
          Text(appTranslate(lang, 'common.view_all'), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Lighten a (typically saturated) accent colour so it stays legible on the
  // dark slate cards used in dark mode.
  static Color _brighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.9).clamp(0.0, 1.0))
        .toColor();
  }

  Widget _buildSkillAttentionCard(BuildContext context, String title, String subtitle, String percent, Color bgColor, Color iconColor, IconData icon) {
    double progress = double.tryParse(percent.replaceAll('%', '')) ?? 0.0;
    progress /= 100.0;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // The pastel light backgrounds wash out the (light) default text in dark
    // mode, so tint the dark surface with the accent colour and brighten the
    // accent itself for readable contrast on a dark card.
    final Color accent = isDark ? _brighten(iconColor) : iconColor;
    final Color cardBg = isDark
        ? Color.alphaBlend(accent.withValues(alpha: 0.16), Theme.of(context).cardColor)
        : bgColor;
    final Color titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: accent.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: titleColor)),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: accent)),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Theme.of(context).scaffoldBackgroundColor
                        : Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    color: accent,
                    strokeWidth: 4,
                  ),
                ),
                Center(
                  child: Text(percent, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 12, color: titleColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementList(BuildContext context, AppLanguage lang) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildAchievementCard(context, lang, "Mar 8, 2026", "React Testing\nFundamentals", "Meta Front-End\nDeveloper (Module 5)", "30%", 0.3),
          const SizedBox(width: 16),
          _buildAchievementCard(context, lang, "Mar 2, 2026", "CSS Responsive\nMastery", "W3C FWD Certificate\n(Module 3)", "90%", 0.9),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, AppLanguage lang, String date, String title, String subtitle, String progressText, double progress) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1F0FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.code, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appTranslate(lang, 'common.progress'), style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10)),
              Text(progressText, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).dividerColor,
            color: const Color(0xFFFFA600),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}
