import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/profile_viewmodel.dart';
import 'package:nyimpeun/shared/widgets/app_snackbar.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);

    ref.listen<ProfileState>(profileViewModelProvider, (_, next) {
      if (next.successMessage != null) {
        AppSnackBar.success(context, next.successMessage!);
        ref.read(profileViewModelProvider.notifier).clearMessages();
        if (mounted) Navigator.pop(context);
      }
      if (next.errorMessage != null) {
        AppSnackBar.error(context, next.errorMessage!);
        ref.read(profileViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Ubah Password',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gunakan password minimal 8 karakter yang kuat dan unik.',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _FieldLabel('Password Saat Ini'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _currentPassCtrl,
              obscureText: !_showCurrent,
              style: AppTypography.bodyMedium,
              decoration: _inputDeco(
                hint: 'Masukkan password saat ini',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showCurrent = !_showCurrent),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password tidak boleh kosong' : null,
            ),
            const SizedBox(height: 20),

            _FieldLabel('Password Baru'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPassCtrl,
              obscureText: !_showNew,
              style: AppTypography.bodyMedium,
              decoration: _inputDeco(
                hint: 'Minimal 8 karakter',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                if (v.length < 8) return 'Password minimal 8 karakter';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _FieldLabel('Konfirmasi Password Baru'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: !_showConfirm,
              style: AppTypography.bodyMedium,
              decoration: _inputDeco(
                hint: 'Ulangi password baru',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                if (v != _newPassCtrl.text) return 'Password tidak cocok';
                return null;
              },
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Ubah Password',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(profileViewModelProvider.notifier).updatePassword(
          currentPassword: _currentPassCtrl.text,
          newPassword: _newPassCtrl.text,
        );
  }

  InputDecoration _inputDeco({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
