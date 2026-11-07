import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:umytpa/core/error/failure.dart';
import 'package:umytpa/core/error/result.dart';
import 'package:umytpa/features/reminders/domain/reminder_permission_status.dart';
import 'package:umytpa/features/reminders/domain/reminder_scheduler.dart';
import 'package:umytpa/features/tasks/domain/entities/reminder_preset.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';
import 'package:umytpa/features/tasks/domain/usecases/create_task.dart';
import 'package:umytpa/features/tasks/domain/usecases/delete_task.dart';
import 'package:umytpa/features/tasks/domain/usecases/update_task.dart';
import 'package:umytpa/features/tasks/presentation/cubit/task_form_cubit.dart';
import 'package:umytpa/features/tasks/presentation/cubit/task_form_state.dart';

class _MockCreateTask extends Mock implements CreateTask {}

class _MockUpdateTask extends Mock implements UpdateTask {}

class _MockDeleteTask extends Mock implements DeleteTask {}

class _MockReminderScheduler extends Mock implements ReminderScheduler {}

void main() {
  late _MockCreateTask createTask;
  late _MockUpdateTask updateTask;
  late _MockDeleteTask deleteTask;
  late _MockReminderScheduler scheduler;

  final DateTime now = DateTime(2026, 10, 30, 12);

  Task buildTask({
    String title = 'Review pitch deck',
    Duration? remindBefore = const Duration(hours: 1),
  }) {
    return Task(
      id: 7,
      title: title,
      dueAt: DateTime(2026, 10, 30, 17),
      category: TaskCategory.work,
      remindBefore: remindBefore,
      isDone: false,
      createdAt: DateTime.parse('2026-01-01'),
    );
  }

  TaskFormCubit buildCreateCubit() {
    return TaskFormCubit(
      createTask: createTask,
      updateTask: updateTask,
      deleteTask: deleteTask,
      reminderScheduler: scheduler,
      now: () => now,
    );
  }

  TaskFormCubit buildEditCubit({Task? task}) {
    return TaskFormCubit(
      createTask: createTask,
      updateTask: updateTask,
      deleteTask: deleteTask,
      reminderScheduler: scheduler,
      initialTask: task ?? buildTask(),
      now: () => now,
    );
  }

  setUpAll(() {
    registerFallbackValue(buildTask());
    registerFallbackValue(
      NewTask(
        title: 'x',
        dueAt: now,
        category: TaskCategory.other,
        remindBefore: null,
      ),
    );
    registerFallbackValue(ReminderPreset.oneHour);
  });

  setUp(() {
    createTask = _MockCreateTask();
    updateTask = _MockUpdateTask();
    deleteTask = _MockDeleteTask();
    scheduler = _MockReminderScheduler();
    when(() => scheduler.requestNotificationsPermission()).thenAnswer(
      (_) async => ReminderPermissionStatus.granted,
    );
    when(() => scheduler.checkNotificationsPermission()).thenAnswer(
      (_) async => ReminderPermissionStatus.granted,
    );
    when(() => scheduler.checkExactAlarmsPermission()).thenAnswer(
      (_) async => ReminderPermissionStatus.granted,
    );
    when(() => scheduler.requestExactAlarmsPermission()).thenAnswer(
      (_) async => ReminderPermissionStatus.granted,
    );
    when(() => scheduler.checkFullScreenIntentPermission()).thenAnswer(
      (_) async => ReminderPermissionStatus.granted,
    );
    when(() => scheduler.requestFullScreenIntentPermission()).thenAnswer(
      (_) async => ReminderPermissionStatus.granted,
    );
    when(() => scheduler.openSystemSettings()).thenAnswer((_) async {});
  });

  group('TaskFormCubit create', () {
    blocTest<TaskFormCubit, TaskFormState>(
      'starts ready with next rounded hour and default reminder',
      build: buildCreateCubit,
      verify: (TaskFormCubit cubit) {
        final TaskFormReady state = cubit.state as TaskFormReady;
        expect(state.isEdit, isFalse);
        expect(state.dueAt, DateTime(2026, 10, 30, 13));
        expect(state.reminder, ReminderPreset.oneHour);
        expect(state.category, TaskCategory.study);
        expect(state.canSave, isFalse);
      },
    );

    blocTest<TaskFormCubit, TaskFormState>(
      'titleChanged enables save when valid',
      build: buildCreateCubit,
      act: (TaskFormCubit cubit) => cubit.titleChanged('Buy groceries'),
      expect: () => <Matcher>[
        isA<TaskFormReady>()
            .having((TaskFormReady s) => s.title, 'title', 'Buy groceries')
            .having((TaskFormReady s) => s.canSave, 'canSave', isTrue)
            .having((TaskFormReady s) => s.isDirty, 'dirty', isTrue),
      ],
    );

    blocTest<TaskFormCubit, TaskFormState>(
      'save creates task and emits success',
      build: buildCreateCubit,
      setUp: () {
        when(() => createTask(any(), now: any(named: 'now'))).thenAnswer(
          (_) async => Success<Task>(buildTask()),
        );
      },
      act: (TaskFormCubit cubit) async {
        cubit.titleChanged('Buy groceries');
        await cubit.save();
      },
      expect: () => <Matcher>[
        isA<TaskFormReady>(),
        isA<TaskFormReady>().having(
          (TaskFormReady s) => s.isSubmitting,
          'submitting',
          isTrue,
        ),
        isA<TaskFormSaveSuccess>(),
      ],
      verify: (_) {
        verify(() => createTask(any(), now: now)).called(1);
      },
    );

    blocTest<TaskFormCubit, TaskFormState>(
      'reminderChanged requests permission once and shows help when denied',
      build: buildCreateCubit,
      setUp: () {
        when(() => scheduler.requestNotificationsPermission()).thenAnswer(
          (_) async => ReminderPermissionStatus.notificationsDenied,
        );
      },
      act: (TaskFormCubit cubit) async {
        await cubit.reminderChanged(ReminderPreset.fiveMinutes);
        await cubit.reminderChanged(ReminderPreset.oneDay);
      },
      verify: (_) {
        verify(() => scheduler.requestNotificationsPermission()).called(1);
      },
      expect: () => <Matcher>[
        isA<TaskFormReady>().having(
          (TaskFormReady s) => s.showPermissionHelp,
          'help',
          isTrue,
        ),
        isA<TaskFormReady>()
            .having(
              (TaskFormReady s) => s.reminder,
              'reminder',
              ReminderPreset.oneDay,
            )
            .having(
              (TaskFormReady s) => s.showPermissionHelp,
              'help still',
              isTrue,
            ),
      ],
    );

    blocTest<TaskFormCubit, TaskFormState>(
      'reminderChanged prompts exact alarms rationale when notifications granted but exact alarms missing',
      build: buildCreateCubit,
      setUp: () {
        when(() => scheduler.checkExactAlarmsPermission()).thenAnswer(
          (_) async => ReminderPermissionStatus.exactAlarmsMissing,
        );
      },
      act: (TaskFormCubit cubit) async {
        await cubit.reminderChanged(ReminderPreset.fiveMinutes);
      },
      verify: (_) {
        verify(() => scheduler.requestNotificationsPermission()).called(1);
        verify(() => scheduler.checkExactAlarmsPermission()).called(1);
      },
      expect: () => <Matcher>[
        isA<TaskFormReady>().having(
          (TaskFormReady s) => s.pendingRationale,
          'pendingRationale',
          ReminderPermissionRationale.exactAlarms,
        ),
      ],
    );

    blocTest<TaskFormCubit, TaskFormState>(
      'confirmPermissionRationale requests exact alarms and checks full screen',
      build: buildCreateCubit,
      setUp: () {
        when(() => scheduler.checkFullScreenIntentPermission()).thenAnswer(
          (_) async => ReminderPermissionStatus.fullScreenMissing,
        );
      },
      act: (TaskFormCubit cubit) async {
        await cubit.confirmPermissionRationale(
          ReminderPermissionRationale.exactAlarms,
        );
      },
      verify: (_) {
        verify(() => scheduler.requestExactAlarmsPermission()).called(1);
        verify(() => scheduler.checkFullScreenIntentPermission()).called(1);
      },
      expect: () => <Matcher>[
        isA<TaskFormReady>().having(
          (TaskFormReady s) => s.pendingRationale,
          'pendingRationale',
          ReminderPermissionRationale.fullScreenIntent,
        ),
      ],
    );
  });

  group('TaskFormCubit edit', () {
    blocTest<TaskFormCubit, TaskFormState>(
      'loads existing task values',
      build: buildEditCubit,
      verify: (TaskFormCubit cubit) {
        final TaskFormReady state = cubit.state as TaskFormReady;
        expect(state.isEdit, isTrue);
        expect(state.title, 'Review pitch deck');
        expect(state.category, TaskCategory.work);
        expect(state.isDirty, isFalse);
      },
    );

    blocTest<TaskFormCubit, TaskFormState>(
      'delete emits delete success',
      build: buildEditCubit,
      setUp: () {
        when(() => deleteTask(7)).thenAnswer(
          (_) async => const Success<void>(null),
        );
      },
      act: (TaskFormCubit cubit) => cubit.delete(),
      expect: () => <Matcher>[
        isA<TaskFormReady>().having(
          (TaskFormReady s) => s.isSubmitting,
          'submitting',
          isTrue,
        ),
        isA<TaskFormDeleteSuccess>().having(
          (TaskFormDeleteSuccess s) => s.task.id,
          'id',
          7,
        ),
      ],
    );

    blocTest<TaskFormCubit, TaskFormState>(
      'save update failure surfaces submitError',
      build: buildEditCubit,
      setUp: () {
        when(() => updateTask(any(), now: any(named: 'now'))).thenAnswer(
          (_) async => const Err<Task>(DatabaseFailure('boom')),
        );
      },
      act: (TaskFormCubit cubit) async {
        cubit.titleChanged('Updated');
        await cubit.save();
      },
      expect: () => <Matcher>[
        isA<TaskFormReady>(),
        isA<TaskFormReady>().having(
          (TaskFormReady s) => s.isSubmitting,
          'submitting',
          isTrue,
        ),
        isA<TaskFormReady>()
            .having(
              (TaskFormReady s) => s.isSubmitting,
              'done',
              isFalse,
            )
            .having(
              (TaskFormReady s) => s.submitError,
              'error',
              'boom',
            ),
      ],
    );
  });
}
