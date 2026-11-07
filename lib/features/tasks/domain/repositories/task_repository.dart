import '../../../../core/error/result.dart';
import '../entities/task.dart';

abstract interface class TaskRepository {
  Stream<List<Task>> watchAll();

  Future<Result<Task>> getById(int id);

  Future<Result<Task>> create(NewTask task);

  Future<Result<Task>> update(Task task);

  Future<Result<void>> delete(int id);

  Future<Result<Task>> setDone({required int id, required bool isDone});
}
