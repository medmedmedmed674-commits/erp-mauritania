import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../utils/locale_provider.dart';

/// Compact language switcher for the top-right header.
///
/// Renders a small pill button showing the active language's display
/// name + icon. Tapping it cycles through the supported languages
/// (Arabic ↔ French in this app).
///
/// Uses `context.watch<LocaleProvider>()` so the chip rebuilds when
/// the language changes.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key, this.compact = false});

  /// When true, only the icon is shown (used in tight app bars).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.language == AppLanguage.arabic;
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<LocaleProvider>().toggle(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isArabic ? Icons.language_outlined : Icons.language,
                size: 14,
                color: Colors.white,
              ),
              if (!compact) ...[
                const SizedBox(width: 4),
                Text(
                  isArabic ? 'ع' : 'FR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Larger variant of the switcher suitable for placement in the body
/// of the welcome screen (white pill on a colored background).
class LanguageSwitcherLarge extends StatelessWidget {
  const LanguageSwitcherLarge({
    super.key,
    this.background = Colors.white,
    this.foreground = AppTheme.primary,
  });

  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.language == AppLanguage.arabic;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<LocaleProvider>().toggle(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isArabic ? Icons.language_outlined : Icons.language,
                size: 16,
                color: foreground,
              ),
              const SizedBox(width: 6),
              Text(
                locale.language.displayName,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.swap_horiz,
                size: 14,
                color: foreground.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
