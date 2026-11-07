import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/focus_session.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/task_stats.dart';

/// Streaks, badges, charts and focus history, recomputed as data changes.
class StatsCubit extends Cubit<TaskStats> {
  StatsCubit({required this.repository, DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(
          TaskStats.compute(
            const <Task>[],
            const <FocusSession>[],
            now: (now ?? DateTime.now)(),
          ),
        ) {
    _subs.add(repository.watchAll().listen((List<Task> t) {
      _tasks = t;
      _recompute();
    }));
    _subs.add(repository.watchFocusSessions().listen((List<FocusSession> s) {
      _sessions = s;
      _recompute();
    }));
  }

  final TaskRepository repository;
  final DateTime Function() _now;
  final List<StreamSubscription<Object?>> _subs =
      <StreamSubscription<Object?>>[];
  List<Task> _tasks = const <Task>[];
  List<FocusSession> _sessions = const <FocusSession>[];

  /// Re-reads everything, e.g. after a background notification action.
  void refresh() {
    for (final StreamSubscription<Object?> s in _subs) {
      unawaited(s.cancel());
    }
    _subs
      ..clear()
      ..add(repository.watchAll().listen((List<Task> t) {
        _tasks = t;
        _recompute();
      }))
      ..add(repository.watchFocusSessions().listen((List<FocusSession> s) {
        _sessions = s;
        _recompute();
      }));
  }

  void _recompute() {
    emit(TaskStats.compute(_tasks, _sessions, now: _now()));
  }

  Future<void> addFocusSession(FocusSession session) async {
    final Result<void> result = await repository.addFocusSession(session);
    if (result is Success<void>) {
      _recompute();
    }
  }

  @override
  Future<void> close() async {
    for (final StreamSubscription<Object?> s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
