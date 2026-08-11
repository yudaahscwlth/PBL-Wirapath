import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/user_provider.dart';

class CvScreeningPage extends ConsumerStatefulWidget {
  const CvScreeningPage({super.key});

  @override
  ConsumerState<CvScreeningPage> createState() => _CvScreeningPageState();
}

class _CvScreeningPageState extends ConsumerState<CvScreeningPage> {
  String? _pickedFilePath;
  List<int>? _pickedFileBytes;
  String? _pickedFileName;
  bool _loadingHistory = true;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _checkExistingHistory();
  }

  Future<void> _checkExistingHistory() async {
    try {
      final api = ref.read(apiServiceProvider);
      final history = await api.getCvScreeningHistory();
      if (mounted && history.isNotEmpty) {
        // Automatically open the latest CV screening result!
        context.pushReplacement('/cv-screening-result', extra: history.first);
        return;
      }
    } catch (e) {
      debugPrint('Check CV history error: $e');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickFile() async {
    if (_analyzing) return;
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc'],
        allowMultiple: false,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      if (file.path == null && file.bytes == null) {
        _showSnack('Could not read the selected file. Please try another file.');
        return;
      }
      setState(() {
        _pickedFilePath = file.path;
        _pickedFileBytes = file.bytes;
        _pickedFileName = file.name;
      });
    } catch (e) {
      debugPrint('CV pick error: $e');
      _showSnack('Could not open the file picker. Please try again.');
    }
  }

  Future<void> _analyze() async {
    if (_analyzing) return;
    if (_pickedFilePath == null && _pickedFileBytes == null) {
      _showSnack('Please upload your CV first.');
      return;
    }
    setState(() => _analyzing = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.uploadCvScreening(
        filePath: _pickedFilePath,
        bytes: _pickedFileBytes,
        fileName: _pickedFileName ?? 'cv.pdf',
      );
      // Keep the readiness score / profile in sync after analysis.
      await ref.read(userProfileProvider.notifier).refreshProfile();
      if (!mounted) return;
      context.push('/cv-screening-result', extra: result);
    } catch (e) {
      debugPrint('CV analyze error: $e');
      _showSnack('Analysis failed. Please try again.');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingHistory) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Upload CV", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildUploadBox(context),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _analyzing ? null : _analyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _analyzing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Analyze'),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text("AI will analyze", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildAnalysisItem(context, Icons.list_alt, const Color(0xFFE1F0FF), "Structure & Completeness", "Photo, contact details, summary, and more"),
                    _buildAnalysisItem(context, Icons.check_circle_outline, const Color(0xFFE1F0FF), "Strengths & Weaknesses", "What's already strong and what needs improvement"),
                    _buildAnalysisItem(context, Icons.bookmark_outline, const Color(0xFFE1F0FF), "ATS Score & Readability", "How easily your CV can be read and evaluated by recruiters"),
                    _buildAnalysisItem(context, Icons.error_outline, const Color(0xFFE1F0FF), "Specific Improvement Suggestions", "What to add and what to refine"),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop(),
          ),
          Column(
            children: [
              Text("CV Screening", style: AppTextStyles.heading1.copyWith(fontSize: 20)),
              Text("Get instant AI-powered analysis", style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
          // Invisible spacer balancing the leading back button so the title
          // stays centered in the spaceBetween row.
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildUploadBox(BuildContext context) {
    final hasFile = _pickedFileName != null;
    return GestureDetector(
      onTap: _analyzing ? null : _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? AppColors.primaryBlue : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE1F0FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile ? Icons.description_outlined : Icons.cloud_upload_outlined,
                color: AppColors.primaryBlue,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFile ? _pickedFileName! : "Upload Your CV",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasFile ? "Tap to choose a different file" : "Supports PDF, DOCX (Max 10 MB)",
              style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(BuildContext context, IconData icon, Color iconBg, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
