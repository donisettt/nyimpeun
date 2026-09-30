import 'package:dio/dio.dart';
import 'package:nyimpeun/core/errors/app_exception.dart';

/// Konversi DioException menjadi AppException yang lebih deskriptif
AppException handleDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException('Koneksi timeout, coba lagi');

    case DioExceptionType.connectionError:
      return const NetworkException('Tidak dapat terhubung ke server');

    case DioExceptionType.badResponse:
      return _handleResponseError(e.response);

    case DioExceptionType.cancel:
      return const UnknownException('Request dibatalkan');

    default:
      return const UnknownException();
  }
}

AppException _handleResponseError(Response? response) {
  if (response == null) return const UnknownException();

  final statusCode = response.statusCode;
  final data = response.data;

  // Supabase error format
  final message = _extractMessage(data);

  return switch (statusCode) {
    400 => ValidationException(message ?? 'Request tidak valid'),
    401 => AuthException(message ?? 'Sesi berakhir, silahkan login kembali'),
    403 => AuthException(message ?? 'Akses ditolak'),
    404 => NotFoundException(message ?? 'Data tidak ditemukan'),
    409 => ServerException(message ?? 'Data sudah ada', statusCode: statusCode),
    422 => ValidationException(message ?? 'Validasi gagal'),
    429 =>
      ServerException('Terlalu banyak request, coba lagi nanti', statusCode: statusCode),
    500 => ServerException('Server sedang bermasalah, coba lagi nanti', statusCode: statusCode),
    _ => ServerException(message ?? 'Terjadi kesalahan', statusCode: statusCode),
  };
}

String? _extractMessage(dynamic data) {
  if (data == null) return null;
  if (data is Map) {
    // Supabase auth error: { "error": "...", "error_description": "..." }
    if (data['error_description'] != null) {
      return _translateSupabaseError(data['error_description'].toString());
    }
    if (data['error'] != null) {
      return _translateSupabaseError(data['error'].toString());
    }
    // PostgREST error: { "message": "...", "hint": "..." }
    if (data['message'] != null) return data['message'].toString();
  }
  if (data is String) return data;
  return null;
}

String _translateSupabaseError(String error) {
  return switch (error.toLowerCase()) {
    String e when e.contains('invalid login credentials') =>
      'Email atau password salah',
    String e when e.contains('email not confirmed') =>
      'Email belum dikonfirmasi, cek inbox Anda',
    String e when e.contains('user already registered') =>
      'Email sudah terdaftar',
    String e when e.contains('password should be') =>
      'Password tidak memenuhi syarat',
    String e when e.contains('signup is disabled') =>
      'Registrasi sedang tidak tersedia',
    String e when e.contains('rate limit') =>
      'Terlalu banyak percobaan, coba lagi nanti',
    _ => error,
  };
}
