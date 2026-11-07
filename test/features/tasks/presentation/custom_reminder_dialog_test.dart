import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/core/theme/app_theme.dart';
import 'package:umytpa/features/tasks/presentation/widgets/custom_reminder_dialog.dart';
import 'package:umytpa/l10n/app_localizations.dart';

void main() {
  testWidgets('custom reminder dialog opens, edits and returns a duration',
      (WidgetTester tester) async {
    Duration? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result = await showCustomReminderDialog(context, null),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '47');
    await tester.pump();
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(result, const Duration(minutes: 47));
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching the unit works and cancel returns null',
      (WidgetTester tester) async {
    Duration? result = const Duration(minutes: 1);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showCustomReminderDialog(
                context,
                const Duration(hours: 2),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('days'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
