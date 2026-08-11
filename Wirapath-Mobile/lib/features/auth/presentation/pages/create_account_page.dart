import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_login_row.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/models/user_model.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _apiService = ApiService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('Registration started for: $email');

    try {
      final res = await _apiService.register(
        email: email,
        password: password,
      );
      debugPrint('Registration successful, navigating to /assessment');

      // Populate the global user state directly from the register response
      // (same DB-backed record the website uses) rather than depending on a
      // second /api/auth/me round-trip.
      final userData = res['result']?['user'];
      if (userData != null) {
        final user = UserModel.fromMap(
          Map<String, dynamic>.from(userData as Map),
          userData['id'].toString(),
        );
        ref.read(userProfileProvider.notifier).setUser(user);
      } else {
        await ref.read(userProfileProvider.notifier).refreshProfile();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/assessment');
      }
    } catch (e) {
      debugPrint('Registration failed: $e');
      if (mounted) {
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Title
              Center(
                child: Column(
                  children: [
                    Text('Create Account', style: AppTextStyles.heading1),
                    const SizedBox(height: 8),
                    Text(
                      "Let's begin with your account setup.",
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Email Field
              CustomTextField(
                label: 'Email',
                hintText: 'Enter Your Email',
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // Create Password Field
              CustomTextField(
                label: 'Create Password',
                hintText: 'Enter Your Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                controller: _passwordController,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),

              const SizedBox(height: 20),

              // Confirm Password Field
              CustomTextField(
                label: 'Confirm Your Password',
                hintText: 'Enter Your Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                controller: _confirmPasswordController,
                onToggleVisibility: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),

              const SizedBox(height: 16),

              // Terms & Conditions Checkbox
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() => _agreeToTerms = value ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "I'm Agree with ",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/terms'),
                    child: Text(
                      'Terms & Conditions',
                      style: AppTextStyles.link,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Create Account'),
                    ),

              const SizedBox(height: 28),

              // Social Login
              const SocialLoginRow(isSignUp: true),

              const SizedBox(height: 32),

              // Sign In Link
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already on the path?',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => context.go('/sign-in'),
                      child: Text(
                        'Sign In',
                        style: AppTextStyles.link,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
