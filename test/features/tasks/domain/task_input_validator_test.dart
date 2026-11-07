import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/features/tasks/domain/validation/task_input_validator.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 30, 12);

  group('TaskInputValidator', () {
    test('rejects empty title', () {
      final TaskInputValidation result = TaskInputValidator.validate(
        title: '   ',
        dueAt: now.add(const Duration(hours: 2)),
        remindBefore: const Duration(hours: 1),
        isNew: true,
        now: now,
      );
      expect(result.isValid, isFalse);
      expect(result.titleError, isNotNull);
    });

    test('rejects title longer than 120 characters', () {
      final TaskInputValidation result = TaskInputValidator.validate(
        title: 'a' * 121,
        dueAt: now.add(const Duration(hours: 2)),
        remindBefore: null,
        isNew: true,
        now: now,
      );
      expect(result.isValid, isFalse);
      expect(result.titleError, contains('120'));
    });

    test('rejects past deadline for new tasks', () {
      final TaskInputValidation result = TaskInputValidator.validate(
        title: 'Lab',
        dueAt: now.subtract(const Duration(minutes: 1)),
        remindBefore: null,
        isNew: true,
        now: now,
      );
      expect(result.isValid, isFalse);
      expect(result.dueAtError, isNotNull);
    });

    test('accepts a deadline within the current minute for new tasks', () {
      final TaskInputValidation result = TaskInputValidator.validate(
        title: 'Lab',
        dueAt: now,
        remindBefore: null,
        isNew: true,
        now: now,
      );
      expect(result.dueAtError, isNull);
    });

    test('rejects a deadline in a previous minute for new tasks', () {
      final TaskInputValidation result = TaskInputValidator.validate(
        title: 'Lab',
        dueAt: now.subtract(const Duration(minutes: 1)),
        remindBefore: null,
        isNew: true,
        now: now,
      );
      expect(result.dueAtError, isNotNull);
    });

    test('allows past deadline when editing', () {
      final TaskInputValidation result = TaskInputValidator.validate(
        title: 'Lab',
        dueAt: now.subtract(const Duration(hours: 2)),
        remindBefore: null,
        isNew: false,
        now: now,
      );
      expect(result.isValid, isTrue);
      expect(result.dueAtError, isNull);
    });

    test('warns when reminder moment already passed but stays valid', () {
      final TaskInputValidation result = TaskInputValidator.validate(
        title: 'Lab',
        dueAt: now.add(const Duration(minutes: 30)),
        remindBefore: const Duration(hours: 1),
        isNew: true,
        now: now,
      );
      expect(result.isValid, isTrue);
      expect(result.hasReminderWarning, isTrue);
      expect(result.reminderWarning, isNotNull);
    });

    test('no warning when reminder is in the future', () {
      final TaskInputValidation result = TaskInputValidator.validate(
        title: 'Lab',
        dueAt: now.add(const Duration(hours: 2)),
        remindBefore: const Duration(hours: 1),
        isNew: true,
        now: now,
      );
      expect(result.isValid, isTrue);
      expect(result.hasReminderWarning, isFalse);
    });

    test('accepts valid new task', () {
      final TaskInputValidation result = TaskInputValidator.validate(
        title: '  Review pitch  ',
        dueAt: now.add(const Duration(hours: 5)),
        remindBefore: const Duration(hours: 1),
        isNew: true,
        now: now,
      );
      expect(result.isValid, isTrue);
      expect(result.titleError, isNull);
      expect(result.dueAtError, isNull);
      expect(result.reminderWarning, isNull);
    });
  });
}
