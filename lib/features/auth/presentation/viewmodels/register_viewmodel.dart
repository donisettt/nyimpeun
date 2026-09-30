import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/features/auth/domain/repositories/auth_repository.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';

// ─── Register Form State ──────────────────────────────────────────────────────

class RegisterFormState {
  const RegisterFormState({
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;

  RegisterFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegisterFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Register ViewModel ───────────────────────────────────────────────────────

class RegisterViewModel extends StateNotifier<RegisterFormState> {
  RegisterViewModel({
    required AuthRepository repository,
    required AuthStateNotifier authNotifier,
  })  : _repository = repository,
        _authNotifier = authNotifier,
        super(const RegisterFormState());

  final AuthRepository _repository;
  final AuthStateNotifier _authNotifier;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Gunakan AuthStateNotifier.signUp agar auth state otomatis terupdate
      // dan router akan redirect ke dashboard secara otomatis
      await _authNotifier.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: nameController.text.trim(),
      );
    } finally {
      // Cek mounted sebelum update state (widget mungkin sudah navigate away)
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
