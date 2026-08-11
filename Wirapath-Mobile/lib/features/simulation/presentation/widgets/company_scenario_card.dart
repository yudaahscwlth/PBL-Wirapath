import 'package:flutter/material.dart';

class CompanyScenarioCard extends StatelessWidget {
  final String companyName;
  final String role;
  final String focus;
  final String level; // 'Junior' or 'Mid'
  final VoidCallback? onTap;

  const CompanyScenarioCard({
    super.key,
    required this.companyName,
    required this.role,
    required this.focus,
    required this.level,
    this.onTap,
  });

  Color get _levelColor {
    switch (level.toLowerCase()) {
      case 'junior':
        return const Color(0xFF10B981); // green
      case 'mid':
        return const Color(0xFFF59E0B); // amber/yellow
      case 'senior':
        return const Color(0xFFEF4444); // red
      default:
        return const Color(0xFF94A3B8); // neutral slate, theme-agnostic
    }
  }

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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company name
                Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                // Role - Focus
                Text(
                  '$role – $focus',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _levelColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _levelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
