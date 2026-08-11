import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/custom_text_field.dart';

/// Forgot Password screen.
///
/// Collects the account email and asks the backend to send a reset link
/// (see ApiService.requestPasswordReset). To avoid leaking whether an address
/// is registered, the success state is shown for any non-error response.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _apiService = ApiService();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String _sentTo = '';

  static final RegExp _emailRegex =
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.requestPasswordReset(email);
      if (mounted) {
        setState(() {
          _emailSent = true;
          _sentTo = email;
        });
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        _showError(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/sign-in'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _emailSent ? _buildSentState(context) : _buildFormState(context),
        ),
      ),
    );
  }

  Widget _buildFormState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withOpacity(0.1),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    size: 36, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 20),
              Text('Forgot Password?', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text(
                'Enter the email linked to your account and we’ll send you a link to reset your password.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        CustomTextField(
          label: 'Email',
          hintText: 'Enter Your Email',
          prefixIcon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 28),
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              )
            : ElevatedButton(
                onPressed: _sendResetLink,
                child: const Text('Send Reset Link'),
              ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/sign-in'),
            child: Text('Back to Sign In', style: AppTextStyles.link),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSentState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x1A10B981),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              size: 40, color: Color(0xFF10B981)),
        ),
        const SizedBox(height: 24),
        Text('Check your email', style: AppTextStyles.heading1),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: AppTextStyles.bodyMedium,
            children: [
              const TextSpan(
                  text:
                      'If an account exists for that address, we’ve sent a password reset link to '),
              TextSpan(
                text: _sentTo,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const TextSpan(text: '. The link expires in 30 minutes.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/sign-in'),
          child: const Text('Back to Sign In'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() => _emailSent = false);
                },
          child: Text('Didn’t get it? Try again', style: AppTextStyles.link),
        ),
      ],
    );
  }
}
