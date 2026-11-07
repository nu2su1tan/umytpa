import 'package:equatable/equatable.dart';

/// Domain-level failure. Repositories and use cases return these via [Result].
sealed class Failure extends Equatable {
  const Failure();

  String get message;

  @override
  List<Object?> get props => <Object?>[message];
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([this.message = 'Database error']);

  @override
  final String message;
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([this.message = 'Not found']);

  @override
  final String message;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(this.message);

  @override
  final String message;
}

final class PermissionFailure extends Failure {
  const PermissionFailure([
    this.message = 'Notification permission is required',
  ]);

  @override
  final String message;
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([this.message = 'Something went wrong']);

  @override
  final String message;
}
