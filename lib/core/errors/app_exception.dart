/// Custom application exceptions thrown at data or network layers.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No internet connection available.',
    dynamic originalError,
  ]) : super(originalError: originalError);
}

class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.originalError,
  });
}

class UnknownException extends AppException {
  const UnknownException([
    super.message = 'An unexpected error occurred.',
    dynamic originalError,
  ]) : super(originalError: originalError);
}
