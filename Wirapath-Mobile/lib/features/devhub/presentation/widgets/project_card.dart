import 'package:flutter/material.dart';

/// Reusable project card widget for the DevHub mini projects list.
class ProjectCard extends StatelessWidget {
  final String title;
  final String description;
  final String gap;
  final List<String> tags;
  final double progress;
  final VoidCallback? onTapStartProject;

  const ProjectCard({
    super.key,
    required this.title,
    required this.description,
    required this.gap,
    required this.tags,
    required this.progress,
    this.onTapStartProject,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark navy reads well on light cards; switch to light blue on dark cards.
    final Color titleColor =
        isDark ? const Color(0xFFBBD7FF) : const Color(0xFF1E3A8A);
    final Color descColor =
        isDark ? const Color(0xFF93C5FD) : Colors.blue;
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -40,
            bottom: -40,
            child: Container(
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF90CAF9).withOpacity(0.3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: titleColor)),
                    ),
                    Text(gap,
                        style: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: descColor, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: tags
                      .where((tag) => tag.trim().isNotEmpty)
                      .map((tag) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF71C4FF).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(tag,
                                style: const TextStyle(color: Color(0xFF0055A4), fontSize: 11, fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(context).dividerColor,
                        color: Colors.orange,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onTapStartProject ?? () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text("Start Project",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
