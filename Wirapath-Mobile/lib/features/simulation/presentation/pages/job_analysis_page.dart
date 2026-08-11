import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/skill_match_ring.dart';
import '../widgets/skill_breakdown_bar.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/job_listing_card.dart';

/// Data model for a job to be analyzed
class JobAnalysisData {
  final String jobTitle;
  final String company;
  final String location;
  final String source;
  final String sourceIcon;
  final int matchPercent;
  final String salary;
  final String postedTime;
  final String experienceLevel;
  final String jobDescription;
  final List<SkillTag> requiredSkills;
  final List<SkillProficiency> skillBreakdown;
  final List<LearningRecommendation> recommendations;

  const JobAnalysisData({
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.source,
    this.sourceIcon = '',
    required this.matchPercent,
    required this.salary,
    required this.postedTime,
    required this.experienceLevel,
    required this.jobDescription,
    required this.requiredSkills,
    required this.skillBreakdown,
    required this.recommendations,
  });

  int get matchedCount => requiredSkills.where((s) => s.isMatched).length;
  int get missingCount => requiredSkills.where((s) => !s.isMatched).length;
}

class JobAnalysisPage extends StatefulWidget {
  final JobAnalysisData jobData;

  const JobAnalysisPage({
    super.key,
    required this.jobData,
  });

  @override
  State<JobAnalysisPage> createState() => _JobAnalysisPageState();
}

class _JobAnalysisPageState extends State<JobAnalysisPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isJobSaved = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Job Analysis',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isJobSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isJobSaved ? AppColors.primaryBlue : Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() => _isJobSaved = !_isJobSaved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isJobSaved ? 'Job saved!' : 'Job removed from saved',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primaryDark,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildJobHeader(),
                  const SizedBox(height: 20),
                  _buildMatchOverview(),
                  const SizedBox(height: 20),
                  _buildSkillBreakdown(),
                  const SizedBox(height: 20),
                  _buildJobDescription(),
                  const SizedBox(height: 20),
                  _buildRecommendations(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  /// Opens a web search to learn the recommended skill. Recommendations carry
  /// only a skill name (no dedicated resource URL), so we route the user to a
  /// learning-oriented search in the system browser.
  Future<void> _openLearningResource(String skillName) async {
    final query = Uri.encodeComponent('learn $skillName course tutorial');
    final url = Uri.parse('https://www.google.com/search?q=$query');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open learning resources for $skillName')),
        );
      }
    } catch (e) {
      debugPrint('Failed to open learning resource: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open learning resources for $skillName')),
        );
      }
    }
  }

  /// Job title, company, location header section
  Widget _buildJobHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Company icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.15),
                  AppColors.primaryBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Job info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.jobData.jobTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.jobData.company,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildSourceBadge(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_outlined,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text(
                          widget.jobData.postedTime,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge() {
    Color badgeColor;
    IconData badgeIcon;
    
    switch (widget.jobData.source.toLowerCase()) {
      case 'linkedin':
        badgeColor = const Color(0xFF0A66C2);
        badgeIcon = Icons.link;
        break;
      case 'jobstreet':
        badgeColor = const Color(0xFF1D2742);
        badgeIcon = Icons.work_outline;
        break;
      case 'glints':
        badgeColor = const Color(0xFF00BFA5);
        badgeIcon = Icons.auto_awesome;
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
        badgeIcon = Icons.public;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 10, color: badgeColor),
          const SizedBox(width: 3),
          Text(
            widget.jobData.source,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Match overview section with ring chart and stat cards
  Widget _buildMatchOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Skill Match Analysis',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Match ring
          SkillMatchRing(
            matchPercent: widget.jobData.matchPercent,
            size: 150,
          ),
          const SizedBox(height: 20),
          // Stat cards row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Skills\nMatched',
                  value: '${widget.jobData.matchedCount}',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.cancel_outlined,
                  label: 'Skills\nMissing',
                  value: '${widget.jobData.missingCount}',
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.monetization_on_outlined,
                  label: 'Salary\nRange',
                  value: widget.jobData.salary.split(' ').first,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Skill breakdown section with animated progress bars
  Widget _buildSkillBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skill Breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              // Legend
              Row(
                children: [
                  _buildLegendDot(const Color(0xFF10B981), 'Matched'),
                  const SizedBox(width: 10),
                  _buildLegendDot(const Color(0xFFEF4444), 'Missing'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.jobData.skillBreakdown.asMap().entries.map((entry) {
            return SkillBreakdownBar(
              skill: entry.value,
              index: entry.key,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// Job description section
  Widget _buildJobDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Job Description',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.jobData.jobDescription,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          // Meta info row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(Icons.work_outline, widget.jobData.experienceLevel),
              _buildMetaChip(Icons.location_on_outlined, widget.jobData.location),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Recommendations section
  Widget _buildRecommendations() {
    if (widget.jobData.recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        ...widget.jobData.recommendations.map((rec) {
          return RecommendationCard(
            recommendation: rec,
            onTap: () => _openLearningResource(rec.skillName),
          );
        }),
      ],
    );
  }

  /// Bottom action buttons
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Save Job button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _isJobSaved = !_isJobSaved);
              },
              icon: Icon(
                _isJobSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 18,
              ),
              label: Text(
                _isJobSaved ? 'Saved' : 'Save Job',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Start Mock Interview button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                // Pop back and navigate to interview
                Navigator.of(context).pop('startInterview');
              },
              icon: const Icon(Icons.mic_none_rounded, size: 18),
              label: Text(
                'Start Mock Interview',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
