import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/models/user_model.dart';

class SocialLoginRow extends ConsumerWidget {
  /// Whether this row is shown on the sign-up screen. Controls whether a
  /// first-time GitHub login is allowed to create a new account.
  final bool isSignUp;

  const SocialLoginRow({super.key, this.isSignUp = false});

  /// Providers without backend support (only Google + GitHub are wired) show a
  /// lightweight "coming soon" notice instead of a dead tap.
  void _showComingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$provider sign-in is coming soon')),
      );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '197923717946-sridab2812l0tafnf3eke32277t1s3mu.apps.googleusercontent.com',
        serverClientId: kIsWeb ? null : '197923717946-sridab2812l0tafnf3eke32277t1s3mu.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      // Ensure a fresh prompt if they want to choose a different account
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        // User canceled
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('Failed to retrieve ID token from Google');
      }

      // Send the token to the backend
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'isSignUp': isSignUp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final tokens = data['result']['tokens'];
        
        // Save tokens properly to ApiService
        final apiService = ref.read(apiServiceProvider);
        await apiService.setSessionTokens(tokens['accessToken'], tokens['refreshToken']);

        // Update global user state
        final userData = data['result']?['user'];
        if (userData != null) {
          final user = UserModel.fromMap(
            Map<String, dynamic>.from(userData as Map),
            userData['id'].toString(),
          );
          
          // Fallback if name is empty
          if (user.displayName.isEmpty) {
            final fallbackName = data['result']?['user']?['email']?.toString().split('@')[0] ?? 'User';
            ref.read(userProfileProvider.notifier).setUser(user.copyWith(displayName: fallbackName));
          } else {
            ref.read(userProfileProvider.notifier).setUser(user);
          }
        } else {
          await ref.read(userProfileProvider.notifier).refreshProfile();
        }

        if (context.mounted) {
          if (isSignUp) {
            context.go('/assessment');
          } else {
            context.go('/home');
          }
        }
      } else {
        throw Exception(data['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Google Login Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Divider with "Or Continue With"
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or Continue With',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          ],
        ),
        const SizedBox(height: 24),
        // Social Icons Row (Facebook & Google)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(
              icon: Icons.facebook,
              color: AppColors.facebook,
              onTap: () => _showComingSoon(context, 'Facebook'),
            ),
            const SizedBox(width: 20),
            _SocialButton(
              svgAsset: 'assets/icons/google.svg',
              onTap: () => _handleGoogleSignIn(context, ref),
              iconSize: 24,
            ),
            const SizedBox(width: 20),
            _SocialButton(
              icon: Icons.apple,
              color: AppColors.apple,
              onTap: () => _showComingSoon(context, 'Apple'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final Color? color;
  final VoidCallback onTap;
  final double iconSize;

  const _SocialButton({
    this.icon,
    this.svgAsset,
    this.color,
    required this.onTap,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: svgAsset != null
              ? SvgPicture.asset(
                  svgAsset!,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: svgAsset!.contains('github')
                      ? ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn,
                        )
                      : null,
                )
              : Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
        ),
      ),
    );
  }
}
