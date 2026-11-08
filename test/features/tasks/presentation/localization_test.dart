import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:umytpa/core/copy/copy_pack.dart';
import 'package:umytpa/core/theme/app_theme.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';
import 'package:umytpa/features/tasks/presentation/utils/task_l10n.dart';
import 'package:umytpa/features/tasks/presentation/widgets/tasks_header.dart';
import 'package:umytpa/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Locale locale, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('header greets in Russian', (tester) async {
    await _pump(
      tester,
      const Locale('ru'),
      TasksHeader(now: DateTime(2026, 11, 5, 10)),
    );
    expect(
      find.text(
        CopyPack.of('ru', CopyTone.friendly).greeting(
          now: DateTime(2026, 11, 5, 10),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('header greets in English', (tester) async {
    await _pump(
      tester,
      const Locale('en'),
      TasksHeader(now: DateTime(2026, 11, 5, 10)),
    );
    expect(
      find.text(
        CopyPack.of('en', CopyTone.friendly).greeting(
          now: DateTime(2026, 11, 5, 10),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('domain values are translated', (tester) async {
    late AppLocalizations ru;
    await _pump(
      tester,
      const Locale('ru'),
      Builder(
        builder: (context) {
          ru = context.l10n;
          return const SizedBox();
        },
      ),
    );
    expect(ru.categoryLabel(TaskCategory.work), 'Работа');
    expect(ru.reminderBefore(const Duration(hours: 1)), 'за 1 ч');
    expect(ru.reminderBefore(const Duration(days: 2)), 'за 2 дня');
    expect(ru.domainMessage('Title is required'), 'Напиши, что надо сделать');
    // Technical messages never reach the user in English.
    expect(ru.domainMessage('Database error'), ru.errorTitle);
    expect(ru.domainMessage('Task not found'), ru.errorTitle);
    expect(ru.domainMessage('Exception: SqliteException(1)'), ru.errorTitle);
  });
}
