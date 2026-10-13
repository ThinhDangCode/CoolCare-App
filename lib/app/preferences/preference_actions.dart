import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../theme/coolcare_theme.dart';
import 'app_preferences_controller.dart';

class PreferenceActions extends StatelessWidget {
  const PreferenceActions({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesScope.of(context);
    final dark = preferences.themeMode == ThemeMode.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          tooltip: context.tr('language'),
          initialValue: preferences.locale.languageCode,
          onSelected: (value) => preferences.setLocale(Locale(value)),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'vi',
              child: _LanguageItem(
                flag: '🇻🇳',
                label: context.tr('vietnamese'),
              ),
            ),
            PopupMenuItem(
              value: 'en',
              child: _LanguageItem(flag: '🇬🇧', label: context.tr('english')),
            ),
          ],
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.appSoftSurface,
              border: Border.all(color: context.appBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                preferences.locale.languageCode == 'vi' ? '🇻🇳' : '🇬🇧',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip:
              '${context.tr('theme')}: ${context.tr(dark ? 'dark' : 'light')}',
          onPressed: preferences.toggleTheme,
          icon: Icon(
            dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _LanguageItem extends StatelessWidget {
  const _LanguageItem({required this.flag, required this.label});
  final String flag;
  final String label;

  @override
  Widget build(BuildContext context) =>
      Row(children: [Text(flag), const SizedBox(width: 10), Text(label)]);
}
