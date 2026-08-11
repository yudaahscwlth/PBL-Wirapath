import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/user_provider.dart';

class PersonalInformationPage extends ConsumerStatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  ConsumerState<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends ConsumerState<PersonalInformationPage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _universityController;
  late TextEditingController _majorController;
  late TextEditingController _graduationYearController;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _universityController = TextEditingController();
    _majorController = TextEditingController();
    _graduationYearController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _graduationYearController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // Watch (not read) so the page rebuilds and fills the fields once the
    // profile finishes loading from the backend, instead of staying empty.
    final userProfile = ref.watch(userProfileProvider).value;
    if (userProfile != null && !_isInitialized) {
      // The model exposes a combined displayName; split it into first/last to
      // mirror the web Account Settings (first_name / last_name in the DB).
      final parts = userProfile.displayName.trim().split(RegExp(r'\s+'));
      _firstNameController.text = parts.isNotEmpty ? parts.first : '';
      _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _emailController.text = userProfile.email;
      _universityController.text = userProfile.preferences['university'] ?? '';
      _majorController.text = userProfile.preferences['major'] ?? '';
      _graduationYearController.text = userProfile.preferences['graduationYear'] ?? '';
      _isInitialized = true;
    }
  }

  Future<void> _handleSave() async {
    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    final gradYearStr = _graduationYearController.text.trim();
    if (gradYearStr.isNotEmpty) {
      final gradYear = int.tryParse(gradYearStr);
      final currentYear = DateTime.now().year;
      final maxYear = currentYear + 6;
      final minYear = 1990;

      if (gradYear == null || gradYear < minYear || gradYear > maxYear) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Graduation year must be between $minYear and $maxYear'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(apiServiceProvider).updateProfileSettings(
        userId: user.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        university: _universityController.text.trim(),
        fieldOfStudy: _majorController.text.trim(),
        graduationYear: gradYearStr,
      );

      // Refresh profile data
      await ref.read(userProfileProvider.notifier).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeData();

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Account Info',
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
          // Subtitle
          Text(
            'Manage your personal information',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Profile Photo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryBlue,
                            width: 2.5,
                          ),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Changing profile photo is coming soon'),
                          ),
                        );
                    },
                    child: Text(
                      'Change Photo',
                      style: AppTextStyles.label.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // First Name & Last Name (Side by Side)
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledField(
                          label: 'First Name',
                          controller: _firstNameController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledField(
                          label: 'Last Name',
                          controller: _lastNameController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Email
                  _buildLabeledField(
                    label: 'Email Address',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 20),

                  // University
                  _buildLabeledField(
                    label: 'University',
                    controller: _universityController,
                  ),
                  const SizedBox(height: 20),

                  // Major
                  _buildLabeledField(
                    label: 'Major',
                    controller: _majorController,
                  ),
                  const SizedBox(height: 20),

                  // Graduation Year
                  _buildLabeledField(
                    label: 'Graduation Year',
                    controller: _graduationYearController,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),

          // Save Button fixed at bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          decoration: InputDecoration(
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
      ],
    );
  }
}
