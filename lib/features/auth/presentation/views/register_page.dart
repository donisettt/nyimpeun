import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';
import 'package:nyimpeun/core/l10n/language_selector_button.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/core/utils/validators.dart';
import 'package:nyimpeun/features/auth/l10n/auth_l10n.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:nyimpeun/shared/widgets/app_button.dart';
import 'package:nyimpeun/shared/widgets/app_snackbar.dart';
import 'package:nyimpeun/shared/widgets/app_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  late final RegisterViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(registerViewModelProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final lang = ref.watch(languageProvider);
    final l10n = AuthL10n.of(lang);

    ref.listen<RegisterFormState>(registerViewModelProvider, (prev, next) {
      if (next.errorMessage != null) {
        AppSnackBar.error(context, next.errorMessage!);
        _viewModel.clearError();
      }
    });

    // Listen to auth state — jika register berhasil, router akan otomatis redirect
    ref.listen<AuthState>(authStateNotifierProvider, (prev, next) {
      if (next is AuthError) {
        AppSnackBar.error(context, next.message);
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2FE), // Light blue top
              Colors.white, // White bottom
            ],
            stops: [0.0, 0.4], // Transition to white starts around 40%
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo & Text
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/logo_nyimpeun.png',
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'NYIMPEUN',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),

                    // Language Selector
                    const LanguageSelectorButton(),
                  ],
                ),
              ),

              // Form Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        l10n.registerGreeting,
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.registerSubtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Form(
                        key: _viewModel.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              controller: _viewModel.nameController,
                              label: l10n.nameLabel,
                              hint: l10n.nameHint,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              validator: Validators.fullName,
                              enabled: !state.isLoading,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _viewModel.emailController,
                              label: 'Email',
                              hint: 'email@contoh.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.email,
                              enabled: !state.isLoading,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _viewModel.passwordController,
                              label: l10n.passwordLabel,
                              hint: l10n.passwordHint,
                              isPassword: true,
                              textInputAction: TextInputAction.next,
                              validator: Validators.password,
                              enabled: !state.isLoading,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _viewModel.confirmPasswordController,
                              label: l10n.confirmPasswordLabel,
                              hint: l10n.confirmPasswordHint,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: (value) => Validators.confirmPassword(
                                _viewModel.passwordController.text,
                              )(value),
                              enabled: !state.isLoading,
                              onSubmitted: (_) => _viewModel.register(),
                            ),
                            const SizedBox(height: 32),
                            AppButton(
                              label: l10n.btnRegister,
                              onPressed: _viewModel.register,
                              isLoading: state.isLoading,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.orDivider,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.btnLogin,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
