import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;
  final String? route;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.trailingText,
    this.onTap,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            size: 16,
          ),
        ],
      ),
      onTap: onTap ?? (route != null ? () => context.push(route!) : () {}),
    );
  }
}
