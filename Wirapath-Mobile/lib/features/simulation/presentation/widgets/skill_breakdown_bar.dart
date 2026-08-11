import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Model for a single skill with its proficiency level
class SkillProficiency {
  final String name;
  final int percentage;
  final bool isMatched;

  const SkillProficiency({
    required this.name,
    required this.percentage,
    this.isMatched = true,
  });

  Color get barColor {
    if (percentage >= 75) return const Color(0xFF10B981);
    if (percentage >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color get barBgColor {
    if (percentage >= 75) return const Color(0xFF10B981).withValues(alpha: 0.12);
    if (percentage >= 50) return const Color(0xFFF59E0B).withValues(alpha: 0.12);
    return const Color(0xFFEF4444).withValues(alpha: 0.12);
  }

  String get levelLabel {
    if (percentage >= 75) return 'Strong';
    if (percentage >= 50) return 'Moderate';
    if (percentage >= 25) return 'Beginner';
    return 'Not Started';
  }
}

/// Animated horizontal progress bar for individual skill proficiency
class SkillBreakdownBar extends StatefulWidget {
  final SkillProficiency skill;
  final int index;

  const SkillBreakdownBar({
    super.key,
    required this.skill,
    this.index = 0,
  });

  @override
  State<SkillBreakdownBar> createState() => _SkillBreakdownBarState();
}

class _SkillBreakdownBarState extends State<SkillBreakdownBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.skill.percentage / 100.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Stagger the animation based on index
    Future.delayed(Duration(milliseconds: 200 + (widget.index * 100)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Match indicator
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: widget.skill.isMatched
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFEF4444).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.skill.isMatched ? Icons.check : Icons.close,
                          size: 11,
                          color: widget.skill.isMatched
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.skill.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        widget.skill.levelLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: widget.skill.barColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.skill.percentage}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: widget.skill.barBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: _animation.value,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.skill.barColor,
                              widget.skill.barColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
