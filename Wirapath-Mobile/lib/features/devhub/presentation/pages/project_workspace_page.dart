import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models/mini_project_model.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';

class ProjectWorkspacePage extends ConsumerStatefulWidget {
  final String projectId;
  final MiniProject? projectFromExtra;

  const ProjectWorkspacePage({
    super.key,
    required this.projectId,
    this.projectFromExtra,
  });

  @override
  ConsumerState<ProjectWorkspacePage> createState() =>
      _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState
    extends ConsumerState<ProjectWorkspacePage> {
  // State
  MiniProject? _project;
  UserMiniProjectSubmission? _submission;
  bool _isLoadingProject = false;
  bool _isSubmitting = false;

  // Submission mode: 'file' or 'github'
  String _mode = 'file';

  // File picker
  PlatformFile? _pickedFile;

  // GitHub URL
  final TextEditingController _githubController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.projectFromExtra != null) {
      _project = widget.projectFromExtra;
      // Also refresh in background to get latest submission data
      _fetchDetail();
    } else {
      _fetchDetail();
    }
  }

  @override
  void dispose() {
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    if (_project == null) {
      setState(() => _isLoadingProject = true);
    }
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.fetchMiniProjectDetail(widget.projectId);
      if (mounted) {
        setState(() {
          final projectMap = data['project'] != null
              ? Map<String, dynamic>.from(data['project'] as Map)
              : Map<String, dynamic>.from(data);
          _project = MiniProject.fromMap(
            projectMap,
            projectMap['id']?.toString() ?? widget.projectId,
          );
          // Capture the AI-graded submission (strengths / improvements /
          // objectives / summary) so the detailed feedback can be rendered
          // on mobile, matching the website's review screen.
          final submissionRaw = data['submission'];
          if (submissionRaw is Map) {
            _submission = UserMiniProjectSubmission.fromMap(
              Map<String, dynamic>.from(submissionRaw),
            );
          }
          _isLoadingProject = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProject = false);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'rar', 'tar', 'gz', '7z'],
        allowMultiple: false,
        // On web there is no file path — we need the bytes to upload.
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitProject() async {
    if (_project == null || _isSubmitting) return;

    // Validation
    if (_mode == 'file' && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a ZIP/RAR file to submit.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_mode == 'github') {
      final url = _githubController.text.trim();
      final isUrlValid = Uri.tryParse(url)?.hasAbsolutePath ?? false;
      if (url.isEmpty || !url.startsWith('http') || !isUrlValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFigmaOrDesign
                ? 'Please enter a valid Figma project link URL.'
                : 'Please enter a valid repository URL.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(apiServiceProvider);
      Map<String, dynamic> result;

      if (_mode == 'file' && _pickedFile != null) {
        result = await api.submitMiniProjectFile(
          _project!.id,
          _pickedFile!.path,
          _pickedFile!.name,
          bytes: _pickedFile!.bytes,
        );
      } else {
        result = await api.submitMiniProjectGitHub(
          _project!.id,
          _githubController.text.trim(),
        );
      }

      // Invalidate to refresh list
      ref.invalidate(miniProjectsProvider);

      // Reload detail to get updated submission data (and possibly AI review)
      await _fetchDetail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project submitted successfully! AI review in progress.'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset pick state
        setState(() {
          _pickedFile = null;
          _githubController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool get _isFigmaOrDesign {
    final title = _project?.title.toLowerCase() ?? '';
    final tag = _project?.tag?.toLowerCase() ?? '';
    final skills = _project?.relatedSkills.join(' ').toLowerCase() ?? '';
    return title.contains('figma') || title.contains('design') || title.contains('ux') || 
           tag.contains('figma') || tag.contains('ux') || skills.contains('figma');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProject && _project == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: Theme.of(context).colorScheme.onSurface, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final project = _project;
    final title = project?.title ?? 'Project';
    final status = project?.submissionStatus ?? 'not_started';
    final hasReview = status == 'reviewed' && project != null;
    final hasSubmitted = status == 'submitted' || hasReview;

    return Scaffold(
      extendBody: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/devhub');
            }
          },
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'My Workspace',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
        toolbarHeight: 72,
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AI Review Results (if reviewed) ──────────────────────────
              if (hasReview) ...[
                _buildAiReviewSection(project!),
                const SizedBox(height: 30),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 20),
              ],

              // ── Submission section ────────────────────────────────────────
              const Text(
                'Submit Your Work',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                hasSubmitted
                    ? 'You can resubmit to improve your score.'
                    : (_isFigmaOrDesign
                        ? 'Upload a ZIP/RAR archive or link your Figma design.'
                        : 'Upload a ZIP/RAR archive or link your GitHub repo.'),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Mode toggle
              Row(
                children: [
                  Expanded(
                    child: _ModeTab(
                      label: '📁  Upload File',
                      isActive: _mode == 'file',
                      onTap: () => setState(() => _mode = 'file'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModeTab(
                      label: _isFigmaOrDesign ? '🔗  Figma Link' : '🔗  GitHub URL',
                      isActive: _mode == 'github',
                      onTap: () => setState(() => _mode = 'github'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_mode == 'file') _buildFilePicker(),
              if (_mode == 'github') _buildGithubInput(),

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          hasSubmitted
                              ? 'Resubmit Project'
                              : 'Submit Project',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _pickedFile != null
                    ? Colors.blue.shade300
                    : Theme.of(context).dividerColor,
                width: _pickedFile != null ? 1.5 : 1,
              ),
            ),
            child: _pickedFile == null
                ? Column(
                    children: [
                      Icon(Icons.upload_file_outlined,
                          size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(height: 10),
                      Text(
                        'Tap to select ZIP / RAR file',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supported: .zip, .rar, .tar, .gz, .7z',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 11),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined,
                          color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedFile!.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatBytes(_pickedFile!.size),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _pickedFile = null),
                        child: Icon(Icons.close,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 20),
                      ),
                    ],
                  ),
          ),
        ),
        if (_pickedFile == null) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file, color: Colors.blue, size: 18),
            label: const Text(
              'Attach File',
              style:
                  TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGithubInput() {
    final isFigma = _isFigmaOrDesign;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isFigma ? 'Figma Design URL' : 'GitHub Repository URL',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _githubController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: isFigma
                ? 'https://www.figma.com/file/your-design-link'
                : 'https://github.com/yourusername/repo',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.link, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 20),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isFigma
              ? 'Make sure your Figma link is viewable so our AI can analyze your design.'
              : 'Make sure your repo is public so our AI can analyze it.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildAiReviewSection(MiniProject project) {
    final score = project.overallScore;
    Color scoreColor = Colors.green;
    if (score != null && score < 60) scoreColor = Colors.red;
    else if (score != null && score < 80) scoreColor = Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'AI Review Results',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Score and status row
        Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: score != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${score.round()}',
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            color: scoreColor.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '—',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Project Graded',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (project.reviewedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reviewed ${_formatDate(project.reviewedAt!)}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: score != null && score >= 80
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      score != null && score >= 80
                          ? 'Passed'
                          : 'Needs Revision',
                      style: TextStyle(
                        color: score != null && score >= 80
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // AI Summary + detailed feedback (mirrors the website review screen)
        if (project.submissionId != null) ...[
          const SizedBox(height: 20),
          const Text(
            'AI Feedback Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withOpacity(0.15)),
            ),
            child: Text(
              (_submission?.aiSummary != null &&
                      _submission!.aiSummary!.trim().isNotEmpty)
                  ? _submission!.aiSummary!.trim()
                  : 'Detailed AI feedback is available. Submit or resubmit to see full analysis.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),

          // Evaluation criteria coverage
          if (_submission?.objectivesMet != null &&
              _submission!.objectivesMet!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(
                Icons.flag_outlined, 'Evaluation Criteria Coverage'),
            const SizedBox(height: 12),
            ..._submission!.objectivesMet!.map(_buildObjectiveRow),
          ],

          // Strengths
          if (_submission?.strengths != null &&
              _submission!.strengths!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(Icons.star_outline, 'Strengths',
                color: Colors.green),
            const SizedBox(height: 12),
            ..._submission!.strengths!.map(
              (s) => _buildBulletRow(
                  s, Icons.check_circle_outline, Colors.green),
            ),
          ],

          // Improvements
          if (_submission?.improvements != null &&
              _submission!.improvements!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(
                Icons.trending_up, 'Recommended Improvements',
                color: Colors.orange),
            const SizedBox(height: 12),
            ..._submission!.improvements!.map(
              (s) => _buildBulletRow(
                  s, Icons.error_outline, Colors.orange),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {Color? color}) {
    final c = color ?? AppColors.primaryBlue;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildObjectiveRow(Map<String, dynamic> item) {
    final isSuccess = (item['status']?.toString() ?? 'success') == 'success';
    final color = isSuccess ? Colors.green : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item['title']?.toString() ?? '',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletRow(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

/// Small toggle tab widget for file/github mode
class _ModeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0D6EFD) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
