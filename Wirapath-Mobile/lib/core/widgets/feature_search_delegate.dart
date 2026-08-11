import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// A searchable app feature: what the user sees plus where it routes to.
class AppFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final List<String> keywords;

  const AppFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.keywords = const [],
  });

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        subtitle.toLowerCase().contains(q) ||
        keywords.any((k) => k.toLowerCase().contains(q));
  }
}

/// The canonical list of navigable features, mirroring the bottom-nav
/// destinations plus the key sub-features reachable from Home/Profile.
const List<AppFeature> kAppFeatures = [
  AppFeature(
    title: 'Home',
    subtitle: 'Your dashboard overview',
    icon: Icons.home_outlined,
    route: '/home',
    keywords: ['dashboard', 'beranda', 'overview'],
  ),
  AppFeature(
    title: 'Readiness Center',
    subtitle: 'Assess and track your readiness',
    icon: Icons.analytics_outlined,
    route: '/readiness-center',
    keywords: ['readiness', 'assessment', 'test', 'kesiapan', 'score'],
  ),
  AppFeature(
    title: 'Development Hub',
    subtitle: 'Mini projects and code review',
    icon: Icons.terminal_outlined,
    route: '/devhub',
    keywords: ['dev hub', 'projects', 'coding', 'code review', 'practice'],
  ),
  AppFeature(
    title: 'Career Simulation',
    subtitle: 'Practice real interview scenarios',
    icon: Icons.sms_outlined,
    route: '/simulation',
    keywords: ['simulation', 'interview', 'simulasi', 'career'],
  ),
  AppFeature(
    title: 'Job Description Analyzer',
    subtitle: 'Analyze a job posting',
    icon: Icons.work_outline,
    route: '/jobdesk-analyzer',
    keywords: ['jobdesk', 'job', 'analyzer', 'lowongan'],
  ),
  AppFeature(
    title: 'CV Screening',
    subtitle: 'Upload and screen your CV',
    icon: Icons.description_outlined,
    route: '/cv-screening',
    keywords: ['cv', 'resume', 'screening'],
  ),
  AppFeature(
    title: 'Profile',
    subtitle: 'Your account and settings',
    icon: Icons.account_circle_outlined,
    route: '/profile',
    keywords: ['profile', 'account', 'profil', 'settings'],
  ),
  AppFeature(
    title: 'Personal Information',
    subtitle: 'Edit your personal details',
    icon: Icons.person_outline,
    route: '/personal-information',
    keywords: ['personal', 'information', 'edit profile'],
  ),
  AppFeature(
    title: 'Password & Security',
    subtitle: 'Manage your password',
    icon: Icons.lock_outline,
    route: '/password-security',
    keywords: ['password', 'security', 'keamanan'],
  ),
  AppFeature(
    title: 'Notifications',
    subtitle: 'Notification preferences',
    icon: Icons.notifications_outlined,
    route: '/notifications',
    keywords: ['notifications', 'notifikasi', 'alerts'],
  ),
  AppFeature(
    title: 'Language & Appearance',
    subtitle: 'Theme and language settings',
    icon: Icons.palette_outlined,
    route: '/language-appearance',
    keywords: ['language', 'appearance', 'theme', 'dark', 'bahasa', 'tema'],
  ),
  AppFeature(
    title: 'Integrations',
    subtitle: 'Connect GitHub and more',
    icon: Icons.extension_outlined,
    route: '/integrations',
    keywords: ['integrations', 'github', 'connect', 'integrasi'],
  ),
  AppFeature(
    title: 'Help & Support',
    subtitle: 'Get help with the app',
    icon: Icons.help_outline,
    route: '/help-support',
    keywords: ['help', 'support', 'bantuan', 'faq'],
  ),
];

/// Search delegate that filters [kAppFeatures] and navigates on selection.
class FeatureSearchDelegate extends SearchDelegate<String?> {
  FeatureSearchDelegate({required this.emptyLabel, required String hint})
      : super(searchFieldLabel: hint);

  final String emptyLabel;

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results =
        kAppFeatures.where((f) => f.matches(query)).toList(growable: false);

    if (results.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withOpacity(0.5),
      ),
      itemBuilder: (context, index) {
        final feature = results[index];
        return ListTile(
          leading: Icon(feature.icon, color: AppColors.primaryBlue),
          title: Text(
            feature.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(feature.subtitle),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () {
            close(context, feature.route);
            context.go(feature.route);
          },
        );
      },
    );
  }
}
