import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/core/error/failure.dart';
import 'package:umytpa/core/error/result.dart';
import 'package:umytpa/features/tasks/data/datasources/app_database.dart';
import 'package:umytpa/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';

void main() {
  late AppDatabase database;
  late TaskRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = TaskRepositoryImpl(database.tasksDao);
  });

  tearDown(() async {
    await database.close();
  });

  NewTask newTask({
    String title = 'Review pitch deck',
    DateTime? dueAt,
    TaskCategory category = TaskCategory.work,
    Duration? remindBefore = const Duration(hours: 1),
  }) {
    return NewTask(
      title: title,
      dueAt: dueAt ?? DateTime(2026, 10, 30, 17),
      category: category,
      remindBefore: remindBefore,
    );
  }

  group('TaskRepositoryImpl', () {
    test('create and getById round-trip with UTC storage', () async {
      final Result<Task> created = await repository.create(newTask());
      expect(created, isA<Success<Task>>());
      final Task task = created.valueOrNull!;

      expect(task.id, greaterThan(0));
      expect(task.title, 'Review pitch deck');
      expect(task.category, TaskCategory.work);
      expect(task.remindBefore, const Duration(hours: 1));
      expect(task.isDone, isFalse);
      expect(task.dueAt, DateTime(2026, 10, 30, 17));

      final Result<Task> loaded = await repository.getById(task.id);
      expect(loaded.valueOrNull, task);
    });

    test('create stores null reminder', () async {
      final Result<Task> created = await repository.create(
        newTask(remindBefore: null),
      );
      expect(created.valueOrNull!.remindBefore, isNull);
      expect(created.valueOrNull!.remindAt, isNull);
    });

    test('watchAll emits inserts reactively', () async {
      final List<List<Task>> emissions = <List<Task>>[];
      final subscription = repository.watchAll().listen(emissions.add);

      await pumpEventQueue();
      expect(emissions, isNotEmpty);
      expect(emissions.last, isEmpty);

      await repository.create(newTask(title: 'A'));
      await repository.create(newTask(title: 'B'));
      await pumpEventQueue();

      expect(emissions.last, hasLength(2));
      expect(
        emissions.last.map((Task t) => t.title),
        containsAll(<String>['A', 'B']),
      );

      await subscription.cancel();
    });

    test('update changes fields', () async {
      final Task created =
          (await repository.create(newTask())).valueOrNull!;

      final Result<Task> updated = await repository.update(
        created.copyWith(
          title: 'Updated title',
          category: TaskCategory.study,
          remindBefore: () => const Duration(minutes: 30),
        ),
      );

      expect(updated.valueOrNull!.title, 'Updated title');
      expect(updated.valueOrNull!.category, TaskCategory.study);
      expect(updated.valueOrNull!.remindBefore, const Duration(minutes: 30));
    });

    test('setDone toggles completion', () async {
      final Task created =
          (await repository.create(newTask())).valueOrNull!;

      final Result<Task> done = await repository.setDone(
        id: created.id,
        isDone: true,
      );
      expect(done.valueOrNull!.isDone, isTrue);

      final Result<Task> undone = await repository.setDone(
        id: created.id,
        isDone: false,
      );
      expect(undone.valueOrNull!.isDone, isFalse);
    });

    test('delete removes task', () async {
      final Task created =
          (await repository.create(newTask())).valueOrNull!;

      final Result<void> deleted = await repository.delete(created.id);
      expect(deleted.isSuccess, isTrue);

      final Result<Task> loaded = await repository.getById(created.id);
      expect(loaded, isA<Err<Task>>());
      expect(loaded.failureOrNull, isA<NotFoundFailure>());
    });

    test('getById returns NotFound for missing id', () async {
      final Result<Task> result = await repository.getById(999);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('category is stored by name for all values', () async {
      for (final TaskCategory category in TaskCategory.values) {
        final Task task = (await repository.create(
          newTask(title: category.name, category: category),
        ))
            .valueOrNull!;
        expect(task.category, category);
      }
    });
  });
}
