import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../../core/providers/user_provider.dart';

/// Connect GitHub during onboarding.
///
/// Mirrors the website's GitHub integration flow (onboarding Step6 / the
/// Integrations settings): the user supplies their GitHub username and we call
/// `POST /api/users/:id/github/sync` on the backend, which fetches the account's
/// public repositories and recomputes the readiness score. The previous version
/// was a hardcoded mock (email/password form that faked success); this talks to
/// the real backend so the connection is genuine and reflected everywhere the
/// app reads `github_username` / readiness data.
class ConnectGithubPage extends ConsumerStatefulWidget {
  const ConnectGithubPage({super.key});

  @override
  ConsumerState<ConnectGithubPage> createState() => _ConnectGithubPageState();
}

class _ConnectGithubPageState extends ConsumerState<ConnectGithubPage> {
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = "";
  bool _isSuccess = false;
  String _githubUsername = "";
  int? _repoCount;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthorize() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = "Please enter your GitHub username.";
      });
      return;
    }

    final user = ref.read(userProfileProvider).value;
    if (user == null) {
      setState(() {
        _hasError = true;
        _errorMessage = "You need to be signed in to connect GitHub.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = "";
    });

    try {
      final result = await ref.read(apiServiceProvider).connectGithub(
            userId: user.uid,
            githubUsername: username,
          );

      // Refresh downstream data: integration status + dashboard/readiness all
      // change once GitHub repositories are synced.
      ref.invalidate(githubProfileProvider);
      await ref.read(userProfileProvider.notifier).refreshProfile();

      // The backend returns the synced user; surface repo count when present.
      final repos = result['github_repos_count'] ??
          result['repos_count'] ??
          result['public_repos'];

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _githubUsername = username;
        _repoCount = repos is int ? repos : int.tryParse('${repos ?? ''}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = _friendlyError(e.toString());
      });
    }
  }

  String _friendlyError(String raw) {
    final cleaned = raw.replaceFirst('Exception: ', '');
    if (cleaned.contains('404') || cleaned.toLowerCase().contains('not found')) {
      return "GitHub user not found. Check the username and try again.";
    }
    return cleaned.isEmpty
        ? "Failed to connect GitHub. Please try again."
        : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // GitHub Logo
              Center(
                child: SvgPicture.asset(
                  'assets/icons/github.svg',
                  height: 80,
                  // Tint to onSurface so the dark GitHub mark stays visible in dark mode.
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Connect GitHub",
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Link your GitHub so WiraPath can analyze your public repositories and tailor your readiness.",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (_isSuccess)
                _buildSuccessState()
              else
                _buildFormState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasError)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE), // Light red background
              border: Border.all(color: const Color(0xFFFFCDD2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage,
              style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFD32F2F)),
              textAlign: TextAlign.center,
            ),
          ),

        CustomTextField(
          label: 'GitHub Username',
          hintText: 'e.g. octocat',
          prefixIcon: Icons.alternate_email,
          controller: _usernameController,
        ),
        const SizedBox(height: 12),
        Text(
          "We only read public repository data. Your code stays yours.",
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAuthorize,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Authorize Wirapath'),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => context.go('/home'),
            child: Text("Skip for now", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    final displayUsername = _githubUsername;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9), // Light green background
            border: Border.all(color: const Color(0xFFC8E6C9)),
            borderRadius: BorderRadius.circular(8),
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
                    Text("@$displayUsername", style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    Text("github.com/$displayUsername", style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF4CAF50))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          _repoCount != null
              ? "Your GitHub account has been successfully connected.\nWiraPath analyzed $_repoCount public repositories."
              : "Your GitHub account has been successfully connected.\nWiraPath has begun analyzing your contributions.",
          style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
