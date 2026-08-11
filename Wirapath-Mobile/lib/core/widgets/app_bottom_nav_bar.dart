import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/language_provider.dart';

/// Shared bottom navigation bar used across multiple pages.
class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (currentIndex == index) return;
    
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/readiness-center');
        break;
      case 2:
        context.go('/devhub');
        break;
      case 3:
        context.go('/simulation');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    // Figma Design Specifications
    const Color activeColor = Color(0xFF066EFF);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveColor = isDark ? Colors.white : Colors.black;
    final Color barColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Container(
          height: 66,
          constraints: const BoxConstraints(maxWidth: 364),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14131927), // #13192714
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Color(0x1F131927), // #1319271F
                blurRadius: 4,
                offset: Offset(0, 2),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: appTranslate(lang, 'nav.home'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
                label: appTranslate(lang, 'nav.readiness'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.terminal_outlined,
                activeIcon: Icons.terminal,
                label: appTranslate(lang, 'nav.devhub'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.sms_outlined,
                activeIcon: Icons.sms,
                label: appTranslate(lang, 'nav.simulation'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.account_circle_outlined,
                activeIcon: Icons.account_circle,
                label: appTranslate(lang, 'nav.profile'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(context, index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
