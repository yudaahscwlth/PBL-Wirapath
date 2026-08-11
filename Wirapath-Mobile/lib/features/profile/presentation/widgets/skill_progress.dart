import 'package:flutter/material.dart';

class SkillProgress extends StatelessWidget {
  final String title;
  final int percentage;
  final String date;
  final Color progressColor;

  const SkillProgress({
    super.key,
    required this.title,
    required this.percentage,
    required this.date,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Last evaluated $date',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
