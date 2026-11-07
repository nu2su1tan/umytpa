import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/l10n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LocaleController localeController = getIt<LocaleController>();
    return ListenableBuilder(
      listenable: localeController,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp.router(
          onGenerateTitle: (BuildContext context) => 'Umytpa',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: appRouter,
          // null follows the system language.
          locale: localeController.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}
