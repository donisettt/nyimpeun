sealed class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

/// Kesalahan jaringan / koneksi
class NetworkException extends AppException {
  const NetworkException([String message = 'Tidak ada koneksi internet'])
      : super(message, statusCode: null);
}

/// Response error dari server (4xx, 5xx)
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode, super.data});
}

/// Error autentikasi (401, token expired)
class AuthException extends AppException {
  const AuthException([String message = 'Sesi telah berakhir, silahkan login kembali'])
      : super(message, statusCode: 401);
}

/// Resource tidak ditemukan (404)
class NotFoundException extends AppException {
  const NotFoundException([String message = 'Data tidak ditemukan'])
      : super(message, statusCode: 404);
}

/// Validasi gagal (422)
class ValidationException extends AppException {
  const ValidationException(super.message, {super.data});
}

/// Error penyimpanan lokal
class StorageException extends AppException {
  const StorageException([String message = 'Gagal mengakses penyimpanan'])
      : super(message);
}

/// Error tidak diketahui
class UnknownException extends AppException {
  const UnknownException([String message = 'Terjadi kesalahan tidak terduga'])
      : super(message);
}
