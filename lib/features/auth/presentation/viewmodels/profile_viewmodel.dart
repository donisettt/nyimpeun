import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/core/errors/app_exception.dart';
import 'package:nyimpeun/features/auth/domain/repositories/auth_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.isUploadingAvatar = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isUploadingAvatar;
  final String? errorMessage;
  final String? successMessage;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingAvatar,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ProfileViewModel extends StateNotifier<ProfileState> {
  ProfileViewModel({required AuthRepository repository})
      : _repository = repository,
        super(const ProfileState());

  final AuthRepository _repository;

  void clearMessages() => state = state.copyWith(clearMessages: true);

  // ─── Update Profile ────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? currency,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
        currency: currency,
      );
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Profil berhasil diperbarui',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  // ─── Update Email ──────────────────────────────────────────────────────────

  Future<bool> updateEmail(String newEmail) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _repository.updateEmail(newEmail);
      state = state.copyWith(
        isSaving: false,
        successMessage:
            'Link konfirmasi telah dikirim ke $newEmail. Cek email Anda untuk mengonfirmasi perubahan.',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  // ─── Update Password ───────────────────────────────────────────────────────

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _repository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Password berhasil diubah',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  // ─── Upload Avatar ─────────────────────────────────────────────────────────

  Future<String?> uploadAndUpdateAvatar({
    required String userId,
    required String filePath,
  }) async {
    state = state.copyWith(isUploadingAvatar: true, clearMessages: true);
    try {
      final url = await _repository.uploadAvatar(
        userId: userId,
        filePath: filePath,
      );
      await _repository.updateAvatar(url);
      state = state.copyWith(
        isUploadingAvatar: false,
        successMessage: 'Foto profil berhasil diperbarui',
      );
      return url;
    } on AppException catch (e) {
      state = state.copyWith(isUploadingAvatar: false, errorMessage: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isUploadingAvatar: false, errorMessage: e.toString());
      return null;
    }
  }

}
