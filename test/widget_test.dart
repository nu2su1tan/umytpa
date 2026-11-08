import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:umytpa/core/copy/copy_pack.dart';
import 'package:umytpa/core/theme/app_theme.dart';
import 'package:umytpa/core/ui/language_sheet.dart';
import 'package:umytpa/core/ui/profile_sheet.dart';
import 'package:umytpa/features/tasks/domain/entities/focus_session.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';
import 'package:umytpa/features/tasks/domain/repositories/task_repository.dart';
import 'package:umytpa/features/tasks/domain/usecases/create_task.dart';
import 'package:umytpa/features/tasks/presentation/cubit/stats_cubit.dart';
import 'package:umytpa/features/tasks/domain/usecases/delete_task.dart';
import 'package:umytpa/features/tasks/domain/usecases/group_tasks_by_date.dart';
import 'package:umytpa/features/tasks/domain/usecases/toggle_task_done.dart';
import 'package:umytpa/features/tasks/domain/usecases/watch_tasks.dart';
import 'package:umytpa/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:umytpa/features/tasks/presentation/pages/tasks_page.dart';

class _MockWatchTasks extends Mock implements WatchTasks {}

class _MockRepository extends Mock implements TaskRepository {}

class _MockToggleTaskDone extends Mock implements ToggleTaskDone {}

class _MockDeleteTask extends Mock implements DeleteTask {}

class _MockCreateTask extends Mock implements CreateTask {}

void main() {
  setUpAll(initializeDateFormatting);

  late _MockWatchTasks watchTasks;
  late StreamController<List<Task>> controller;
  late _MockRepository repository;

  setUp(() {
    watchTasks = _MockWatchTasks();
    controller = StreamController<List<Task>>.broadcast();
    when(() => watchTasks()).thenAnswer((_) => controller.stream);
    repository = _MockRepository();
    when(() => repository.watchAll()).thenAnswer((_) => controller.stream);
    when(
      () => repository.watchFocusSessions(),
    ).thenAnswer((_) => const Stream<List<FocusSession>>.empty());
  });

  tearDown(() async {
    await controller.close();
  });

  Future<void> pumpTasksView(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<StatsCubit>(
              create: (_) => StatsCubit(
                repository: repository,
                now: () => DateTime(2026, 10, 30, 9),
              ),
            ),
            BlocProvider<TasksCubit>(
              create: (_) => TasksCubit(
                watchTasks: watchTasks,
                toggleTaskDone: _MockToggleTaskDone(),
                deleteTaskUseCase: _MockDeleteTask(),
                createTask: _MockCreateTask(),
                groupTasksByDate: const GroupTasksByDate(),
                now: () => DateTime(2026, 10, 30, 9),
              )..start(),
            ),
          ],
          child: TasksView(now: DateTime(2026, 10, 30, 9)),
        ),
      ),
    );
  }

  testWidgets('no tasks shows the usual page with an empty list', (tester) async {
    await pumpTasksView(tester);
    controller.add(const <Task>[]);
    await tester.pumpAndSettle();

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Throw in your first task'), findsOneWidget);
    expect(find.byType(LanguageButton), findsOneWidget);
    expect(find.byType(ProfileButton), findsOneWidget);
    expect(find.byTooltip('Add task'), findsOneWidget);
  });

  testWidgets('list shows greeting, chips and reminder label', (tester) async {
    await pumpTasksView(tester);
    controller.add(<Task>[
      Task(
        id: 1,
        title: 'Review pitch deck',
        dueAt: DateTime(2026, 10, 30, 17),
        category: TaskCategory.work,
        remindBefore: const Duration(hours: 1),
        isDone: false,
        createdAt: DateTime.parse('2026-01-01'),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(
      find.text(
        CopyPack.of('en', CopyTone.friendly).greeting(
          now: DateTime(2026, 10, 30, 9),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Review pitch deck'), findsOneWidget);
    expect(find.text('1h before'), findsOneWidget);
    expect(find.byTooltip('Add task'), findsOneWidget);
  });
}
