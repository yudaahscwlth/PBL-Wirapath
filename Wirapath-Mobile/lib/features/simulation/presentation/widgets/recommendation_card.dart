import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Model for a learning recommendation
class LearningRecommendation {
  final String skillName;
  final String description;
  final String estimatedTime;
  final String difficulty;
  final IconData icon;

  const LearningRecommendation({
    required this.skillName,
    required this.description,
    required this.estimatedTime,
    required this.difficulty,
    this.icon = Icons.school_outlined,
  });

  Color get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981);
      case 'intermediate':
        return const Color(0xFFF59E0B);
      case 'advanced':
        return const Color(0xFFEF4444);
      default:
        return AppColors.textSecondary;
    }
  }

  Color get difficultyBgColor {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981).withValues(alpha: 0.1);
      case 'intermediate':
        return const Color(0xFFF59E0B).withValues(alpha: 0.1);
      case 'advanced':
        return const Color(0xFFEF4444).withValues(alpha: 0.1);
      default:
        return AppColors.inputBackground;
    }
  }
}

/// Card showing a learning recommendation for a missing/weak skill
class RecommendationCard extends StatelessWidget {
  final LearningRecommendation recommendation;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.12),
                        AppColors.primaryBlue.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    recommendation.icon,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learn ${recommendation.skillName}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recommendation.description,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Time estimate
                          Icon(
                            Icons.schedule_outlined,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recommendation.estimatedTime,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Difficulty badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: recommendation.difficultyBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              recommendation.difficulty,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: recommendation.difficultyColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
