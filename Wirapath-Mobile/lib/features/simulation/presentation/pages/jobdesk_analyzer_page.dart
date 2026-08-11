import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/recent_activity_provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../data/models/jobdesk_analysis_result.dart';
import '../../../../core/providers/language_provider.dart';

/// Jobdesk Analyzer — mirrors the web `JobdeskAnalyzer` component.
/// Paste a job description, get a profile-match analysis from the backend
/// (`POST /api/jobdesk/analyze`). Separate from the HF skill-predictor flow.
class JobdeskAnalyzerPage extends ConsumerStatefulWidget {
  const JobdeskAnalyzerPage({super.key});

  @override
  ConsumerState<JobdeskAnalyzerPage> createState() => _JobdeskAnalyzerPageState();
}

class _JobdeskAnalyzerPageState extends ConsumerState<JobdeskAnalyzerPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  JobdeskAnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(recentActivityProvider.notifier).record(
            route: '/jobdesk-analyzer',
            title: 'Jobdesk Analyzer',
            type: 'jobdesk',
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = appTranslate(ref.read(languageProvider), 'jobdesk.error_empty'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await ref.read(apiServiceProvider).analyzeJobDescription(text);
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = appTranslate(ref.read(languageProvider), 'jobdesk.error_invalid'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          appTranslate(lang, 'feature.jobdesk'),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appTranslate(lang, 'jobdesk.subtitle'),
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: appTranslate(lang, 'jobdesk.hint'),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _analyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(appTranslate(lang, 'jobdesk.button'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13)),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResult(lang, _result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(AppLanguage lang, JobdeskAnalysisResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match score
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.primaryBlue, size: 28),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r.matchScore.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                  Text(appTranslate(lang, 'jobdesk.match_score'),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ],
          ),
        ),
        if (r.summary.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(appTranslate(lang, 'jobdesk.summary'),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text(r.summary, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5)),
        ],
        _buildSkillSection(appTranslate(lang, 'jobdesk.matching_skills'), r.matchingSkills, const Color(0xFF10B981)),
        _buildSkillSection(appTranslate(lang, 'jobdesk.missing_skills'), r.missingSkills, const Color(0xFFF59E0B)),
        _buildListSection(appTranslate(lang, 'jobdesk.recommendations'), r.recommendations),
      ],
    );
  }

  Widget _buildSkillSection(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s,
                          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 10),
          ...items.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
