import 'package:payment_key_client/payment_key_client.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentKeyException', () {
    test('constructs with required statusCode only', () {
      final exception = PaymentKeyException(statusCode: 400);
      expect(exception.statusCode, 400);
      expect(exception.message, isNull);
      expect(exception.cause, isNull);
    });

    test('constructs with all fields', () {
      final cause = FormatException('bad json');
      final exception = PaymentKeyException(
        statusCode: 502,
        message: 'Gateway error',
        cause: cause,
      );
      expect(exception.statusCode, 502);
      expect(exception.message, 'Gateway error');
      expect(exception.cause, same(cause));
    });

    test('implements Exception', () {
      final exception = PaymentKeyException(statusCode: 500);
      expect(exception, isA<Exception>());
    });

    group('toString', () {
      test('includes statusCode only when message and cause are null', () {
        final exception = PaymentKeyException(statusCode: 401);
        expect(exception.toString(), 'PaymentKeyException(statusCode: 401)');
      });

      test('includes statusCode and message', () {
        final exception = PaymentKeyException(
          statusCode: 400,
          message: 'Invalid card data',
        );
        expect(
          exception.toString(),
          'PaymentKeyException(statusCode: 400, message: Invalid card data)',
        );
      });

      test('includes statusCode and cause', () {
        final cause = FormatException('unexpected token');
        final exception = PaymentKeyException(statusCode: 500, cause: cause);
        String s = exception.toString();
        expect(s, contains('statusCode: 500'));
        expect(s, contains('cause:'));
        expect(s, contains('unexpected token'));
        expect(s, isNot(contains('message:')));
      });

      test('includes all fields when present', () {
        final cause = Exception('network timeout');
        final exception = PaymentKeyException(
          statusCode: 502,
          message: 'Upstream failed',
          cause: cause,
        );
        String s = exception.toString();
        expect(s, contains('statusCode: 502'));
        expect(s, contains('message: Upstream failed'));
        expect(s, contains('cause:'));
        expect(s, startsWith('PaymentKeyException('));
        expect(s, endsWith(')'));
      });

      test('omits message when it is empty string', () {
        final exception = PaymentKeyException(statusCode: 400, message: '');
        // Empty message should be treated as absent
        expect(exception.toString(), isNot(contains('message:')));
      });

      test('handles non-Exception cause objects', () {
        final exception = PaymentKeyException(
          statusCode: 500,
          cause: 'a plain string error',
        );
        expect(exception.toString(), contains('cause: a plain string error'));
      });
    });

    group('common HTTP status codes', () {
      test('400 Bad Request', () {
        final exception = PaymentKeyException(
          statusCode: 400,
          message: 'Bad Request',
        );
        expect(exception.statusCode, 400);
      });

      test('401 Unauthorized', () {
        final exception = PaymentKeyException(
          statusCode: 401,
          message: 'Unauthorized',
        );
        expect(exception.statusCode, 401);
      });

      test('403 Forbidden', () {
        final exception = PaymentKeyException(statusCode: 403);
        expect(exception.statusCode, 403);
      });

      test('404 Not Found', () {
        final exception = PaymentKeyException(statusCode: 404);
        expect(exception.statusCode, 404);
      });

      test('500 Internal Server Error', () {
        final exception = PaymentKeyException(statusCode: 500);
        expect(exception.statusCode, 500);
      });

      test('502 Bad Gateway', () {
        final exception = PaymentKeyException(statusCode: 502);
        expect(exception.statusCode, 502);
      });

      test('503 Service Unavailable', () {
        final exception = PaymentKeyException(statusCode: 503);
        expect(exception.statusCode, 503);
      });
    });

    test('can be caught as Exception', () {
      expect(
        () => throw PaymentKeyException(statusCode: 500, message: 'fail'),
        throwsA(isA<PaymentKeyException>()),
      );
    });

    test('caught exception preserves fields', () {
      try {
        throw PaymentKeyException(
          statusCode: 422,
          message: 'Unprocessable',
          cause: ArgumentError('bad input'),
        );
      } on PaymentKeyException catch (e) {
        expect(e.statusCode, 422);
        expect(e.message, 'Unprocessable');
        expect(e.cause, isA<ArgumentError>());
        return;
      }
    });
  });
}
