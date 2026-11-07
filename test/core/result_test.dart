import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/core/error/failure.dart';
import 'package:umytpa/core/error/result.dart';

void main() {
  group('Result', () {
    test('map transforms success', () {
      const Result<int> result = Success<int>(2);
      expect(result.map((int v) => v * 2).valueOrNull, 4);
    });

    test('map preserves error', () {
      const Result<int> result = Err<int>(NotFoundFailure());
      expect(result.map((int v) => v * 2).failureOrNull, isA<NotFoundFailure>());
    });

    test('fold covers both branches', () {
      expect(
        const Success<int>(1).fold(
          onErr: (_) => 'err',
          onSuccess: (int v) => 'ok:$v',
        ),
        'ok:1',
      );
      expect(
        const Err<int>(UnexpectedFailure()).fold(
          onErr: (Failure f) => f.message,
          onSuccess: (_) => 'ok',
        ),
        'Something went wrong',
      );
    });
  });
}
