import '../../../../core/error/result.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTask {
  const GetTask(this._repository);

  final TaskRepository _repository;

  Future<Result<Task>> call(int id) => _repository.getById(id);
}
