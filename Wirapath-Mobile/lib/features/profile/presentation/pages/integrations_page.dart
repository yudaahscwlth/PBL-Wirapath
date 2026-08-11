import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/user_provider.dart';

class IntegrationsPage extends ConsumerStatefulWidget {
  const IntegrationsPage({super.key});

  @override
  ConsumerState<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends ConsumerState<IntegrationsPage> {
  // Whether the GitHub detail/connect view is open.
  bool _showGithubDetail = false;
  bool _isConnecting = false;
  final _githubUsernameController = TextEditingController();

  @override
  void dispose() {
    _githubUsernameController.dispose();
    super.dispose();
  }

  void _goBackToList() {
    setState(() {
      _showGithubDetail = false;
      _githubUsernameController.clear();
    });
  }

  String _githubUsernameFromProfile(Map<String, dynamic> profile) {
    final value = profile['github_username'];
    if (value == null) return '';
    return value.toString();
  }

  Future<void> _connectGithub(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      _showSnack('Please enter your GitHub username', isError: true);
      return;
    }

    final user = ref.read(userProfileProvider).value;
    if (user == null) {
      _showSnack('You need to be signed in to connect GitHub', isError: true);
      return;
    }

    setState(() => _isConnecting = true);
    try {
      await ref.read(apiServiceProvider).connectGithub(
            userId: user.uid,
            githubUsername: trimmed,
          );

      // Refresh the integration status and the dashboard (readiness score
      // changes after a GitHub sync).
      ref.invalidate(githubProfileProvider);
      await ref.read(userProfileProvider.notifier).refreshProfile();

      if (mounted) {
        _showSnack('GitHub connected as @$trimmed');
        _goBackToList();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to connect GitHub: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final githubAsync = ref.watch(githubProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () {
            if (_showGithubDetail) {
              _goBackToList();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Integrations',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Text(
            'Manage connected services',
            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _showGithubDetail
                ? _buildGithubDetail(githubAsync)
                : _buildServiceList(githubAsync),
          ),
        ],
      ),
    );
  }

  // ── List View ──────────────────────────────────────────────────────────

  Widget _buildServiceList(AsyncValue<Map<String, dynamic>> githubAsync) {
    final githubUsername = githubAsync.maybeWhen(
      data: _githubUsernameFromProfile,
      orElse: () => '',
    );
    final githubConnected = githubUsername.isNotEmpty;
    final githubLoading = githubAsync.isLoading;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        _buildServiceCard(
          name: 'Github',
          svgAsset: 'assets/icons/github.svg',
          subtitle: githubLoading
              ? 'Checking connection…'
              : (githubConnected
                  ? 'github.com/$githubUsername'
                  : 'Repository analysis & code review'),
          isConnected: githubConnected,
          loading: githubLoading,
          onTap: () => setState(() => _showGithubDetail = true),
        ),
        const SizedBox(height: 12),
        _buildServiceCard(
          name: 'Google Drive',
          svgAsset: 'assets/icons/google_drive.svg',
          subtitle: 'Cloud storage & file sharing',
          isConnected: false,
          comingSoon: true,
          onTap: () => _showSnack('Google Drive integration is coming soon'),
        ),
        const SizedBox(height: 12),
        _buildServiceCard(
          name: 'LinkedIn',
          svgAsset: 'assets/icons/linkedin.svg',
          subtitle: 'Professional network & profile',
          isConnected: false,
          comingSoon: true,
          onTap: () => _showSnack('LinkedIn integration is coming soon'),
        ),
        const SizedBox(height: 12),
        _buildServiceCard(
          name: 'Notion',
          svgAsset: 'assets/icons/notion.svg',
          subtitle: 'Notes & knowledge base',
          isConnected: false,
          comingSoon: true,
          onTap: () => _showSnack('Notion integration is coming soon'),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String name,
    required String svgAsset,
    required String subtitle,
    required bool isConnected,
    required VoidCallback onTap,
    bool loading = false,
    bool comingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            _buildServiceIcon(svgAsset),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusLabel(
              isConnected: isConnected,
              loading: loading,
              comingSoon: comingSoon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLabel({
    required bool isConnected,
    bool loading = false,
    bool comingSoon = false,
  }) {
    if (loading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (comingSoon) {
      return Text(
        'Coming soon',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      isConnected ? 'Connected' : 'Not Connected',
      style: TextStyle(
        color: isConnected ? AppColors.success : AppColors.error,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── GitHub Detail View ─────────────────────────────────────────────────

  Widget _buildGithubDetail(AsyncValue<Map<String, dynamic>> githubAsync) {
    return githubAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildGithubConnectForm(error: '$e'),
      data: (profile) {
        final username = _githubUsernameFromProfile(profile);
        if (username.isNotEmpty) {
          return _buildGithubConnected(username);
        }
        return _buildGithubConnectForm();
      },
    );
  }

  Widget _buildGithubConnected(String username) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGithubHeader(isConnected: true),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B3B22) : const Color(0xFFE8F5E9),
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2E7D32) : const Color(0xFFC8E6C9)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$username',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'github.com/$username',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFA5D6A7) : const Color(0xFF4CAF50),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your GitHub account is connected. WiraPath analyzes your public '
            'repositories to keep your readiness score up to date.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isConnecting ? null : () => _connectGithub(username),
              icon: _isConnecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: Text(_isConnecting ? 'Syncing…' : 'Re-sync Repositories'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGithubConnectForm({String? error}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGithubHeader(isConnected: false),
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3E1F21) : const Color(0xFFFFEBEE),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD32F2F) : const Color(0xFFFFCDD2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Could not load connection status. You can still connect below.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE57373) : const Color(0xFFD32F2F)),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'GitHub Username',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _githubUsernameController,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (v) => _connectGithub(v),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. octocat',
              prefixIcon: Icon(
                Icons.alternate_email,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                size: 20,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We use your public GitHub profile to analyze your repositories '
            'and tailor your readiness score.',
            style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConnecting
                  ? null
                  : () => _connectGithub(_githubUsernameController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Connect GitHub',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGithubHeader({required bool isConnected}) {
    return Row(
      children: [
        _buildServiceIcon('assets/icons/github.svg'),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Github',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Repository analysis & code review',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _buildStatusLabel(isConnected: isConnected),
      ],
    );
  }

  // ── Shared icon builder ────────────────────────────────────────────────

  Widget _buildServiceIcon(String svgAsset) {
    final bool isGithub = svgAsset.contains('github');
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: SvgPicture.asset(
          svgAsset,
          width: 28,
          height: 28,
          colorFilter: isGithub
              ? ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                )
              : null,
        ),
      ),
    );
  }
}
