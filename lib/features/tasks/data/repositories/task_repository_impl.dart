import 'dart:async';
import 'dart:developer' as developer;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/app_database.dart';
import '../datasources/tasks_dao.dart';
import '../mappers/task_mapper.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._dao);

  final TasksDao _dao;

  @override
  Stream<List<Task>> watchAll() {
    return _dao.watchAll().map(
          (List<TaskRecord> rows) =>
              rows.map(TaskMapper.toDomain).toList(growable: false),
        );
  }

  @override
  Future<Result<Task>> getById(int id) async {
    try {
      final TaskRecord? record = await _dao.getById(id);
      if (record == null) {
        return const Err<Task>(NotFoundFailure('Task not found'));
      }
      return Success<Task>(TaskMapper.toDomain(record));
    } on Object catch (error, stackTrace) {
      return _databaseErr<Task>(error, stackTrace);
    }
  }

  @override
  Future<Result<Task>> create(NewTask task) async {
    try {
      final int id = await _dao.insertTask(
        TaskMapper.toInsertCompanion(task, now: DateTime.now()),
      );
      final TaskRecord? record = await _dao.getById(id);
      if (record == null) {
        return const Err<Task>(
          DatabaseFailure('Task was inserted but could not be loaded'),
        );
      }
      return Success<Task>(TaskMapper.toDomain(record));
    } on Object catch (error, stackTrace) {
      return _databaseErr<Task>(error, stackTrace);
    }
  }

  @override
  Future<Result<Task>> update(Task task) async {
    try {
      final bool ok = await _dao.replaceTask(TaskMapper.toRecord(task));
      if (!ok) {
        return const Err<Task>(NotFoundFailure('Task not found'));
      }
      final TaskRecord? record = await _dao.getById(task.id);
      if (record == null) {
        return const Err<Task>(NotFoundFailure('Task not found'));
      }
      return Success<Task>(TaskMapper.toDomain(record));
    } on Object catch (error, stackTrace) {
      return _databaseErr<Task>(error, stackTrace);
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      final int deleted = await _dao.deleteById(id);
      if (deleted == 0) {
        return const Err<void>(NotFoundFailure('Task not found'));
      }
      return const Success<void>(null);
    } on Object catch (error, stackTrace) {
      return _databaseErr<void>(error, stackTrace);
    }
  }

  @override
  Future<Result<Task>> setDone({
    required int id,
    required bool isDone,
  }) async {
    try {
      final int updated = await _dao.setDone(id: id, isDone: isDone);
      if (updated == 0) {
        return const Err<Task>(NotFoundFailure('Task not found'));
      }
      final TaskRecord? record = await _dao.getById(id);
      if (record == null) {
        return const Err<Task>(NotFoundFailure('Task not found'));
      }
      return Success<Task>(TaskMapper.toDomain(record));
    } on Object catch (error, stackTrace) {
      return _databaseErr<Task>(error, stackTrace);
    }
  }

  Err<T> _databaseErr<T>(Object error, StackTrace stackTrace) {
    developer.log(
      'TaskRepository error',
      name: 'TaskRepositoryImpl',
      error: error,
      stackTrace: stackTrace,
    );
    return Err<T>(DatabaseFailure(error.toString()));
  }
}
