import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/core/theme/app_theme.dart';
import 'package:umytpa/core/ui/glass/glass.dart';
import 'package:umytpa/features/tasks/presentation/widgets/category_filter_bar.dart';
import 'package:umytpa/features/tasks/presentation/widgets/tasks_header.dart';

void main() {
  group('Liquid Glass Adapter & UI Layer', () {
    testWidgets('TasksHeader does NOT have a calendar icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TasksHeader(now: DateTime(2026, 11, 5, 10)),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsNothing);
      expect(find.byTooltip('Week Calendar'), findsNothing);
      expect(find.text('Good morning'), findsOneWidget);
    });

    testWidgets('AppGlass renders frosted fallback in test environment', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppGlass(
              radius: 20,
              child: Text('Glass content'),
            ),
          ),
        ),
      );

      expect(find.text('Glass content'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.byType(BackdropFilter), findsWidgets);
    });

    testWidgets('AuroraBackground renders warm base and child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AuroraBackground(
              child: Text('Aurora child'),
            ),
          ),
        ),
      );

      expect(find.text('Aurora child'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('AppGlassFab renders with scale animation on press', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGlassFab(
              onPressed: () => tapped = true,
              tooltip: 'Add task',
            ),
          ),
        ),
      );

      expect(find.byTooltip('Add task'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byTooltip('Add task'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('Category chips render unselected surface and selected glass chip', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CategoryFilterBar(
              selected: null,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
    });
  });
}

