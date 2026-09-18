import 'package:equatable/equatable.dart';

/// Immutable domain-level failure objects formatted for UI display.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection available. Please check your network.',
    String? code,
  ]) : super(code: code);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Server error occurred. Please try again later.',
    String? code,
  ]) : super(code: code);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
    String? code,
  ]) : super(code: code);
}
