import 'package:nyimpeun/core/errors/app_exception.dart';

/// Representasi kegagalan di domain layer
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Tidak ada koneksi internet'])
      : super(message);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Autentikasi gagal']) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Data tidak ditemukan']) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure([String message = 'Gagal mengakses penyimpanan'])
      : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Terjadi kesalahan tidak terduga'])
      : super(message);
}

/// Helper: konversi AppException ke Failure
Failure exceptionToFailure(AppException e) {
  return switch (e) {
    NetworkException() => NetworkFailure(e.message),
    AuthException() => AuthFailure(e.message),
    NotFoundException() => NotFoundFailure(e.message),
    ValidationException() => ValidationFailure(e.message),
    StorageException() => StorageFailure(e.message),
    ServerException() => ServerFailure(e.message, statusCode: e.statusCode),
    UnknownException() => UnknownFailure(e.message),
  };
}
