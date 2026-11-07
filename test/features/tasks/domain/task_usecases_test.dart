import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:umytpa/core/error/failure.dart';
import 'package:umytpa/core/error/result.dart';
import 'package:umytpa/features/reminders/domain/reminder_scheduler.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';
import 'package:umytpa/features/tasks/domain/repositories/task_repository.dart';
import 'package:umytpa/features/tasks/domain/usecases/create_task.dart';
import 'package:umytpa/features/tasks/domain/usecases/delete_task.dart';
import 'package:umytpa/features/tasks/domain/usecases/toggle_task_done.dart';
import 'package:umytpa/features/tasks/domain/usecases/update_task.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

class _MockReminderScheduler extends Mock implements ReminderScheduler {}

void main() {
  late _MockTaskRepository repository;
  late _MockReminderScheduler scheduler;

  final DateTime now = DateTime(2026, 10, 30, 12);
  final DateTime dueAt = DateTime(2026, 10, 30, 17);

  Task buildTask({
    int id = 1,
    String title = 'Review pitch deck',
    bool isDone = false,
    Duration? remindBefore = const Duration(hours: 1),
    DateTime? due,
  }) {
    return Task(
      id: id,
      title: title,
      dueAt: due ?? dueAt,
      category: TaskCategory.work,
      remindBefore: remindBefore,
      isDone: isDone,
      createdAt: DateTime.parse('2026-01-01'),
    );
  }

  setUpAll(() {
    registerFallbackValue(buildTask());
    registerFallbackValue(
      NewTask(
        title: 'x',
        dueAt: dueAt,
        category: TaskCategory.other,
        remindBefore: null,
      ),
    );
  });

  setUp(() {
    repository = _MockTaskRepository();
    scheduler = _MockReminderScheduler();
    when(() => scheduler.schedule(any())).thenAnswer(
      (_) async => const Success<void>(null),
    );
    when(() => scheduler.cancel(any())).thenAnswer(
      (_) async => const Success<void>(null),
    );
  });

  group('CreateTask', () {
    test('persists and schedules when remindAt is in the future', () async {
      final Task saved = buildTask();
      when(() => repository.create(any())).thenAnswer(
        (_) async => Success<Task>(saved),
      );

      final CreateTask useCase = CreateTask(
        repository: repository,
        reminderScheduler: scheduler,
      );

      final Result<Task> result = await useCase(
        NewTask(
          title: '  Review pitch deck  ',
          dueAt: dueAt,
          category: TaskCategory.work,
          remindBefore: const Duration(hours: 1),
        ),
        now: now,
      );

      expect(result, isA<Success<Task>>());
      verify(() => repository.create(any())).called(1);
      verify(() => scheduler.schedule(saved)).called(1);
    });

    test('does not schedule when reminder already passed', () async {
      final Task saved = buildTask(
        due: now.add(const Duration(minutes: 30)),
      );
      when(() => repository.create(any())).thenAnswer(
        (_) async => Success<Task>(saved),
      );

      final CreateTask useCase = CreateTask(
        repository: repository,
        reminderScheduler: scheduler,
      );

      final Result<Task> result = await useCase(
        NewTask(
          title: 'Soon',
          dueAt: saved.dueAt,
          category: TaskCategory.work,
          remindBefore: const Duration(hours: 1),
        ),
        now: now,
      );

      expect(result.isSuccess, isTrue);
      verifyNever(() => scheduler.schedule(any()));
    });

    test('returns ValidationFailure for empty title', () async {
      final CreateTask useCase = CreateTask(
        repository: repository,
        reminderScheduler: scheduler,
      );

      final Result<Task> result = await useCase(
        NewTask(
          title: '   ',
          dueAt: dueAt,
          category: TaskCategory.work,
          remindBefore: null,
        ),
        now: now,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => repository.create(any()));
    });
  });

  group('UpdateTask', () {
    test('cancels previous notification and schedules again', () async {
      final Task updated = buildTask(title: 'Updated');
      when(() => repository.update(any())).thenAnswer(
        (_) async => Success<Task>(updated),
      );

      final UpdateTask useCase = UpdateTask(
        repository: repository,
        reminderScheduler: scheduler,
      );

      await useCase(updated, now: now);

      verify(() => repository.update(any())).called(1);
      verify(() => scheduler.cancel(updated.id)).called(1);
      verify(() => scheduler.schedule(updated)).called(1);
    });
  });

  group('DeleteTask', () {
    test('cancels notification then deletes', () async {
      when(() => repository.delete(1)).thenAnswer(
        (_) async => const Success<void>(null),
      );

      final DeleteTask useCase = DeleteTask(
        repository: repository,
        reminderScheduler: scheduler,
      );

      await useCase(1);

      verify(() => scheduler.cancel(1)).called(1);
      verify(() => repository.delete(1)).called(1);
    });
  });

  group('ToggleTaskDone', () {
    test('cancels reminder when marked done', () async {
      final Task done = buildTask(isDone: true);
      when(
        () => repository.setDone(id: 1, isDone: true),
      ).thenAnswer((_) async => Success<Task>(done));

      final ToggleTaskDone useCase = ToggleTaskDone(
        repository: repository,
        reminderScheduler: scheduler,
      );

      await useCase(id: 1, isDone: true, now: now);

      verify(() => scheduler.cancel(1)).called(1);
      verifyNever(() => scheduler.schedule(any()));
    });

    test('reschedules when unmarked and remindAt is future', () async {
      final Task open = buildTask();
      when(
        () => repository.setDone(id: 1, isDone: false),
      ).thenAnswer((_) async => Success<Task>(open));

      final ToggleTaskDone useCase = ToggleTaskDone(
        repository: repository,
        reminderScheduler: scheduler,
      );

      await useCase(id: 1, isDone: false, now: now);

      verify(() => scheduler.schedule(open)).called(1);
    });
  });
}
