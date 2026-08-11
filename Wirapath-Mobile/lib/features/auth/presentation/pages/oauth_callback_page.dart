import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OAuthCallbackPage extends ConsumerStatefulWidget {
  final String? accessToken;
  final String? refreshToken;

  const OAuthCallbackPage({
    super.key,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  final _apiService = ApiService();
  String _statusMessage = 'Configuring your session...';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _handleCallback());
  }

  void _handleCallback() async {
    final token = widget.accessToken;
    final refresh = widget.refreshToken;

    if (token == null || token.isEmpty || refresh == null || refresh.isEmpty) {
      setState(() {
        _statusMessage = 'Failed to retrieve session tokens from Google login.';
        _isError = true;
      });
      return;
    }

    try {
      // 1. Manually set the session cookies
      _apiService.setSessionCookies(accessToken: token, refreshToken: refresh);

      // 2. Fetch/Refresh user profile
      await ref.read(userProfileProvider.notifier).refreshProfile();

      if (mounted) {
        setState(() {
          _statusMessage = 'Authentication successful! Loading...';
        });

        // 3. Navigate to home screen or onboarding
        final user = ref.read(userProfileProvider).value;
        if (user != null && !user.hasCompletedAssessment) {
          context.go('/assessment');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Authentication error: ${e.toString()}';
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isError) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _isError ? AppColors.error : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (_isError) ...[
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/sign-in'),
                    child: const Text('Back to Sign In'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
