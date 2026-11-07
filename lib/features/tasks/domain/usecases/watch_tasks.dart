import '../entities/task.dart';
import '../repositories/task_repository.dart';

class WatchTasks {
  const WatchTasks(this._repository);

  final TaskRepository _repository;

  Stream<List<Task>> call() => _repository.watchAll();
}
