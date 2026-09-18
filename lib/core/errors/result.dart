import 'package:fpdart/fpdart.dart';
import 'package:farmer_market_app/core/errors/failure.dart';

/// Functional Result type using fpdart `Either<Failure, T>`.
typedef AppResult<T> = Either<Failure, T>;
