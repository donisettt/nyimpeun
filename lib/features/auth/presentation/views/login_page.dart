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
import 'package:nyimpeun/shared/widgets/app_button.dart';
import 'package:nyimpeun/shared/widgets/app_snackbar.dart';
import 'package:nyimpeun/shared/widgets/app_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final isLoading = authState is AuthLoading;
    final lang = ref.watch(languageProvider);
    final l10n = AuthL10n.of(lang);

    // Listen for auth errors
    ref.listen<AuthState>(authStateNotifierProvider, (prev, next) {
      if (next is AuthError) {
        AppSnackBar.error(context, next.message);
        ref.read(authStateNotifierProvider.notifier).clearError();
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
                        l10n.loginGreeting,
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.loginSubtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              controller: _emailController,
                              label: l10n.emailLabel,
                              hint: l10n.emailHint,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.email,
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: l10n.passwordLabel,
                              hint: l10n.passwordHint,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: (v) => v == null || v.isEmpty
                                  ? l10n.passwordRequired
                                  : null,
                              onSubmitted: (_) => _onLogin(),
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  l10n.forgotPassword,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppButton(
                              label: l10n.btnLogin,
                              onPressed: _onLogin,
                              isLoading: isLoading,
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
                          onPressed: () => context.push('/register'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.btnRegister,
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

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }
}
