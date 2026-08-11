import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QuickReplyChips extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String>? onTap;

  const QuickReplyChips({
    super.key,
    required this.replies,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: replies.map((reply) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onTap?.call(reply),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  reply,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
