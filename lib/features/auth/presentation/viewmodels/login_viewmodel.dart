import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/core/errors/app_exception.dart';
import 'package:nyimpeun/core/services/notification_service.dart';
import 'package:nyimpeun/features/auth/domain/entities/user_entity.dart';
import 'package:nyimpeun/features/auth/domain/repositories/auth_repository.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});
  final UserEntity user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

class AuthEmailConfirmationRequired extends AuthState {
  const AuthEmailConfirmationRequired({required this.email});
  final String email;
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier({
    required AuthRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService,
        super(const AuthInitial()) {
    _initialize();
  }

  final AuthRepository _repository;
  final NotificationService _notificationService;

  Future<void> _initialize() async {
    state = const AuthLoading();
    try {
      // Timeout 5 detik agar tidak menggantung terlalu lama di loading screen
      final user = await _repository.getCurrentUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (user != null) {
        state = AuthAuthenticated(user: user);
        await _notificationService.saveTokenToSupabase(user.id);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signInWithPassword(
        email: email,
        password: password,
      );
      state = AuthAuthenticated(user: user);
      await _notificationService.saveTokenToSupabase(user.id);
    } on AppException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Cek dari userId apakah session sudah ada (bisa langsung login)
      // atau perlu konfirmasi email
      final userId = user.id;
      if (userId.isNotEmpty) {
        // Verifikasi apakah token sudah tersimpan (session granted)
        final hasSession = await _repository.hasSession();
        if (hasSession) {
          state = AuthAuthenticated(user: user);
          await _notificationService.saveTokenToSupabase(user.id);
        } else {
          // Session tidak ada — perlu konfirmasi email
          state = AuthEmailConfirmationRequired(email: email);
        }
      } else {
        state = AuthEmailConfirmationRequired(email: email);
      }
    } on AppException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    final currentUser = state is AuthAuthenticated 
        ? (state as AuthAuthenticated).user 
        : null;
        
    state = const AuthLoading();
    try {
      if (currentUser != null) {
        await _notificationService.removeTokenFromSupabase(currentUser.id);
      }
      await _repository.signOut();
      state = const AuthUnauthenticated();
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user: user);
      }
    } catch (_) {
      // Silently fail — existing state is kept
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}
