import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyimpeun/core/network/dio_client.dart';
import 'package:nyimpeun/core/storage/local_storage.dart';
import 'package:nyimpeun/core/storage/secure_storage.dart';
import 'package:nyimpeun/core/services/notification_service.dart';
import 'package:nyimpeun/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:nyimpeun/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nyimpeun/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nyimpeun/features/auth/domain/repositories/auth_repository.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/profile_viewmodel.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/register_viewmodel.dart';

// ─── Platform / Infrastructure ────────────────────────────────────────────────

/// Dioverride di main.dart dengan instance dari SharedPreferences.getInstance()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

// ─── Storage Layer ────────────────────────────────────────────────────────────

final secureStorageProvider = Provider<SecureStorage>((ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return SecureStorage(storage);
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs);
});

// ─── Services ─────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ─── Network Layer ────────────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient.create(secureStorage: secureStorage);
});

// ─── Auth Data Layer ──────────────────────────────────────────────────────────

final authRemoteDatasourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio: dio);
});

final authLocalDatasourceProvider = Provider<AuthLocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final localStorage = ref.watch(localStorageProvider);
  return AuthLocalDataSource(
    secureStorage: secureStorage,
    localStorage: localStorage,
  );
});

// ─── Auth Repository ──────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDatasource: ref.watch(authRemoteDatasourceProvider),
    localDatasource: ref.watch(authLocalDatasourceProvider),
  );
});

// ─── Auth Presentation ────────────────────────────────────────────────────────

final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(
    repository: ref.watch(authRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

final registerViewModelProvider =
    StateNotifierProvider.autoDispose<RegisterViewModel, RegisterFormState>((ref) {
  return RegisterViewModel(
    repository: ref.watch(authRepositoryProvider),
    authNotifier: ref.read(authStateNotifierProvider.notifier),
  );
});

final profileViewModelProvider =
    StateNotifierProvider.autoDispose<ProfileViewModel, ProfileState>((ref) {
  return ProfileViewModel(repository: ref.watch(authRepositoryProvider));
});
