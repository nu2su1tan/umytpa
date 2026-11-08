import 'package:flutter/material.dart';

import '../../features/reminders/domain/usecases/reschedule_all_reminders.dart';
import '../../features/week_counter/ui/kit/glass.dart';
import '../../features/week_counter/ui/kit/group.dart';
import '../../features/week_counter/ui/kit/sheet.dart';
import '../../features/week_counter/ui/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../di/injection.dart';
import '../l10n/locale_controller.dart';

/// The label shown for the current choice, e.g. in a settings row.
String languageName(BuildContext context, Locale? locale) {
  final l10n = context.l10n;
  return switch (locale?.languageCode) {
    'ru' => l10n.languageRussian,
    'kk' => l10n.languageKazakh,
    'en' => l10n.languageEnglish,
    _ => l10n.languageSystem,
  };
}

/// Opens the language picker: system, English, Russian, Kazakh.
Future<void> showLanguageSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: context.l10n.languageTitle,
    builder: (_) => const _LanguageOptions(),
  );
}

/// Round glass button that opens the picker; used in screen headers.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      icon: Icons.translate_rounded,
      label: context.l10n.languageButton,
      onTap: () => showLanguageSheet(context),
    );
  }
}

class _LanguageOptions extends StatelessWidget {
  const _LanguageOptions();

  @override
  Widget build(BuildContext context) {
    final LocaleController controller = getIt<LocaleController>();
    final l10n = context.l10n;

    Future<void> choose(Locale? locale) async {
      final NavigatorState navigator = Navigator.of(context);
      await controller.setLocale(locale);
      // Notification text is fixed when it is scheduled, so redo it.
      await getIt<RescheduleAllReminders>()();
      if (navigator.mounted) {
        navigator.pop();
      }
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final String? current = controller.locale?.languageCode;
        return Group(
          margin: EdgeInsets.zero,
          color: context.tokens.sheetCard,
          children: <Widget>[
            GroupRow(
              icon: Icons.phone_iphone_rounded,
              title: l10n.languageSystem,
              selected: current == null,
              onTap: () => choose(null),
            ),
            GroupRow(
              icon: Icons.language_rounded,
              title: l10n.languageEnglish,
              selected: current == 'en',
              onTap: () => choose(const Locale('en')),
            ),
            GroupRow(
              icon: Icons.language_rounded,
              title: l10n.languageRussian,
              selected: current == 'ru',
              onTap: () => choose(const Locale('ru')),
            ),
            GroupRow(
              icon: Icons.language_rounded,
              title: l10n.languageKazakh,
              selected: current == 'kk',
              onTap: () => choose(const Locale('kk')),
            ),
          ],
        );
      },
    );
  }
}
