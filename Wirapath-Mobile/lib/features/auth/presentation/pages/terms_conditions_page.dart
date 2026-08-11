import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Terms & Conditions screen.
///
/// Placeholder/general terms content for now — replace with the final legal
/// copy once it is available.
class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  static const String _lastUpdated = 'Last updated: June 2026';

  static const List<_TermsSection> _sections = [
    _TermsSection(
      title: '1. Acceptance of Terms',
      body:
          'By creating an account or using Wirapath, you agree to be bound by '
          'these Terms & Conditions. If you do not agree with any part of these '
          'terms, please do not use the application.',
    ),
    _TermsSection(
      title: '2. Use of the Service',
      body:
          'Wirapath provides career-readiness tools, skill assessments, mini '
          'projects, and simulations for educational purposes. You agree to use '
          'the service only for lawful purposes and not to misuse, disrupt, or '
          'attempt to gain unauthorized access to any part of the platform.',
    ),
    _TermsSection(
      title: '3. Accounts',
      body:
          'You are responsible for maintaining the confidentiality of your '
          'account credentials and for all activity that occurs under your '
          'account. You agree to provide accurate information and to keep it up '
          'to date.',
    ),
    _TermsSection(
      title: '4. User Content',
      body:
          'Documents, code, and other materials you upload remain yours. By '
          'uploading them, you grant Wirapath permission to process and analyze '
          'this content solely to provide and improve the service.',
    ),
    _TermsSection(
      title: '5. Privacy',
      body:
          'We handle your personal data in accordance with our Privacy Policy. '
          'We do not sell your personal information to third parties.',
    ),
    _TermsSection(
      title: '6. Limitation of Liability',
      body:
          'Wirapath is provided "as is" without warranties of any kind. '
          'Assessment results and recommendations are informational and do not '
          'guarantee any particular career outcome.',
    ),
    _TermsSection(
      title: '7. Changes to These Terms',
      body:
          'We may update these terms from time to time. Continued use of the '
          'application after changes take effect constitutes acceptance of the '
          'revised terms.',
    ),
    _TermsSection(
      title: '8. Contact',
      body:
          'For questions about these Terms & Conditions, contact us at '
          'support@wirapath.com.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        children: [
          Text(
            _lastUpdated,
            style: AppTextStyles.bodySmall.copyWith(
              color: onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          for (final section in _sections) ...[
            Text(
              section.title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _TermsSection {
  final String title;
  final String body;
  const _TermsSection({required this.title, required this.body});
}
