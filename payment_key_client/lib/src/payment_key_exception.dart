/// Thrown when the payment provider key endpoint returns a non-2xx response
/// or when the response body cannot be parsed.
///
/// Callers should handle [PaymentKeyException] and network errors when calling
/// [PaymentKeyClient.createPaymentKey].
class PaymentKeyException implements Exception {
  /// Creates a [PaymentKeyException].
  ///
  /// [statusCode] is the HTTP status (e.g. 400, 401, 502).
  /// [message] is an optional description or response body excerpt.
  /// [cause] is the original exception if this wraps one (e.g. [FormatException]).
  PaymentKeyException({
    required this.statusCode,
    this.message,
    this.cause,
  });

  /// HTTP status code from the key endpoint response.
  final int statusCode;

  /// Optional message or response body (avoid logging full body in production).
  final String? message;

  /// Original exception when this wraps a parse or network error.
  final Object? cause;

  @override
  String toString() {
    StringBuffer buf = StringBuffer('PaymentKeyException(statusCode: $statusCode');
    if (message != null && message!.isNotEmpty) {
      buf.write(', message: $message');
    }
    if (cause != null) {
      buf.write(', cause: $cause');
    }
    buf.write(')');
    return buf.toString();
  }
}
