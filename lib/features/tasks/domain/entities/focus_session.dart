import 'package:equatable/equatable.dart';

/// One finished focus (Pomodoro) block.
class FocusSession extends Equatable {
  const FocusSession({
    required this.startedAt,
    required this.minutes,
    this.taskId,
  });

  final DateTime startedAt;
  final int minutes;
  final int? taskId;

  @override
  List<Object?> get props => <Object?>[startedAt, minutes, taskId];
}
