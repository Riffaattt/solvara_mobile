/// Typed application exceptions surfaced from the data layer.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// HTTP or network-level error (includes status codes).
final class NetworkException extends AppException {
  const NetworkException(super.message, {this.statusCode});

  final int? statusCode;
}

/// The user is not authenticated or the session expired.
final class UnauthorizedException extends AppException {
  const UnauthorizedException()
      : super('Sesi Anda telah berakhir. Silakan masuk kembali.');
}

/// The server returned validation errors.
final class ValidationException extends AppException {
  const ValidationException(super.message, {this.errors = const {}});

  /// Field-level errors returned by the server.
  final Map<String, List<String>> errors;
}

/// A catch-all for unexpected failures.
final class UnknownException extends AppException {
  const UnknownException([super.message = 'Terjadi kesalahan yang tidak diketahui.']);
}
