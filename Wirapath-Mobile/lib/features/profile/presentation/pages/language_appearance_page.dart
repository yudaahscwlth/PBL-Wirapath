import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/providers/language_provider.dart';

class LanguageAppearancePage extends ConsumerStatefulWidget {
  const LanguageAppearancePage({super.key});

  @override
  ConsumerState<LanguageAppearancePage> createState() =>
      _LanguageAppearancePageState();
}

class _LanguageAppearancePageState
    extends ConsumerState<LanguageAppearancePage> {
  int _selectedTheme = 0; // 0 = Light, 1 = Dark, 2 = System

  int _indexFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 0;
      case ThemeMode.dark:
        return 1;
      case ThemeMode.system:
        return 2;
    }
  }

  ThemeMode _modeFromIndex(int index) {
    switch (index) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Matches the web reference (AppearanceSettings.tsx) language list.
  static const List<AppLanguage> _languages = AppLanguage.values;

  @override
  Widget build(BuildContext context) {
    // Keep the selected option in sync with the persisted theme preference.
    _selectedTheme = _indexFromMode(ref.watch(themeModeProvider));
    final AppLanguage selectedLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          appTranslate(selectedLanguage, 'appearance.title'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Subtitle
          Text(
            appTranslate(selectedLanguage, 'appearance.subtitle'),
            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          ),
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Section
                  Text(
                    appTranslate(selectedLanguage, 'appearance.language'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppLanguage>(
                        value: selectedLanguage,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        dropdownColor: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        items: _languages
                            .map(
                              (lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(lang.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(languageProvider.notifier)
                                .setLanguage(value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Theme Section
                  Text(
                    appTranslate(selectedLanguage, 'appearance.theme'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildThemeOption(
                        index: 0,
                        icon: Icons.light_mode_outlined,
                        label: appTranslate(selectedLanguage, 'theme.light'),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        index: 1,
                        icon: Icons.dark_mode_outlined,
                        label: appTranslate(selectedLanguage, 'theme.dark'),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        index: 2,
                        icon: Icons.smartphone_outlined,
                        label: appTranslate(selectedLanguage, 'theme.system'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedTheme == index;

    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(themeModeProvider.notifier).setThemeMode(_modeFromIndex(index)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Theme.of(context).dividerColor,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? AppColors.primaryBlue
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
