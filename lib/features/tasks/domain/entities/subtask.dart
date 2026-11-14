import 'package:equatable/equatable.dart';

/// A checklist step inside a task.
class Subtask extends Equatable {
  const Subtask({required this.title, this.isDone = false});

  final String title;
  final bool isDone;

  Subtask copyWith({String? title, bool? isDone}) =>
      Subtask(title: title ?? this.title, isDone: isDone ?? this.isDone);

  Map<String, Object?> toJson() => <String, Object?>{'t': title, 'd': isDone};

  static Subtask fromJson(Map<String, Object?> json) => Subtask(
    title: (json['t'] as String?) ?? '',
    isDone: (json['d'] as bool?) ?? false,
  );

  @override
  List<Object?> get props => <Object?>[title, isDone];
}
