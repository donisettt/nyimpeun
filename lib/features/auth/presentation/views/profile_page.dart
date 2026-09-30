import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/router/app_router.dart';
import 'package:nyimpeun/core/l10n/app_language.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/auth/domain/entities/user_entity.dart';
import 'package:nyimpeun/features/auth/l10n/profile_l10n.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/profile_viewmodel.dart';
import 'package:nyimpeun/shared/widgets/app_snackbar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = authState.user;
    final profileState = ref.watch(profileViewModelProvider);
    final lang = ref.watch(languageProvider);
    final l10n = ProfileL10n.of(lang);

    ref.listen<ProfileState>(profileViewModelProvider, (_, next) {
      if (next.successMessage != null) {
        AppSnackBar.success(context, next.successMessage!);
        ref.read(profileViewModelProvider.notifier).clearMessages();
        ref.read(authStateNotifierProvider.notifier).refreshUser();
      }
      if (next.errorMessage != null) {
        AppSnackBar.error(context, next.errorMessage!);
        ref.read(profileViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9), // Light background like mockup
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.pageTitle,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Top Profile Card
              _ProfileHeader(
                user: user,
                isUploadingAvatar: profileState.isUploadingAvatar,
                onAvatarTap: () => _pickImage(context, ref, user),
              ),

              const SizedBox(height: 32),

              // Account Section
              _ProfileMenuSection(
                title: l10n.sectionAccount,
                items: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: l10n.menuPersonalInfo,
                    subtitle: l10n.menuPersonalInfoSub,
                    onTap: () => context.push(AppRoutes.profileEdit),
                  ),
                  _MenuItem(
                    icon: Icons.email_outlined,
                    label: l10n.menuEmail,
                    subtitle: l10n.menuEmailSub,
                    onTap: () => _showChangeEmailDialog(context, ref, l10n),
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: l10n.menuPassword,
                    subtitle: l10n.menuPasswordSub,
                    onTap: () => context.push(AppRoutes.profileChangePassword),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // General Section
              _ProfileMenuSection(
                title: l10n.sectionGeneral,
                items: [
                  _MenuItem(
                    icon: Icons.language_rounded,
                    label: l10n.menuLanguage,
                    subtitle: lang.displayName,
                    onTap: () => _showLanguagePicker(context, ref, lang, l10n),
                  ),
                  _MenuItem(
                    icon: Icons.menu_book_rounded,
                    label: l10n.menuUserGuide,
                    onTap: () => _showMaintenanceDialog(context, l10n),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: l10n.menuHelp,
                    onTap: () => context.push(AppRoutes.terms),
                  ),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: l10n.menuLogout,
                    iconColor: AppColors.error,
                    labelColor: AppColors.error,
                    onTap: () => _showLogoutDialog(context, ref, l10n),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  l10n.appVersion,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref, UserEntity user) async {
    final lang = ref.read(languageProvider);
    final l10n = ProfileL10n.of(lang);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text(l10n.pickFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    if (!context.mounted) return;
    await ref.read(profileViewModelProvider.notifier).uploadAndUpdateAvatar(
          userId: user.id,
          filePath: picked.path,
        );
    if (context.mounted) {
      await ref.read(authStateNotifierProvider.notifier).refreshUser();
    }
  }

  void _showChangeEmailDialog(BuildContext context, WidgetRef ref, ProfileL10n l10n) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.changeEmailTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.changeEmailBody,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.changeEmailFieldLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.btnCancel),
          ),
          Consumer(builder: (_, ref2, __) {
            final state = ref2.watch(profileViewModelProvider);
            return FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final email = ctrl.text.trim();
                      if (email.isEmpty) return;
                      final ok = await ref2
                          .read(profileViewModelProvider.notifier)
                          .updateEmail(email);
                      if (ok && ctx.mounted) Navigator.pop(ctx);
                    },
              child: state.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.btnSend),
            );
          }),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, ProfileL10n l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.btnCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateNotifierProvider.notifier).signOut();
            },
            child: Text(l10n.btnLogout),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDialog(BuildContext context, ProfileL10n l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.maintenanceTitle),
        content: Text(
          l10n.maintenanceBody,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.btnOk),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, AppLanguage current, ProfileL10n l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.menuLanguage,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your preferred language',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ...AppLanguage.values.map((lang) {
                final isSelected = lang == current;
                return GestureDetector(
                  onTap: () {
                    ref.read(languageProvider.notifier).state = lang;
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.displayName,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                lang.code == 'id' ? 'Bahasa resmi nasional' : 'Basa daérah Jawa Barat',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

//─ Profile Header─

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
  });

  final UserEntity user;
  final bool isUploadingAvatar;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5), // Light gray card like mockup
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: isUploadingAvatar
                        ? Container(
                            color: Colors.black12,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2),
                            ),
                          )
                        : (user.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    _InitialsAvatar(initials: user.initials),
                                errorWidget: (_, __, ___) =>
                                    _InitialsAvatar(initials: user.initials),
                              )
                            : _InitialsAvatar(initials: user.initials)),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF0F0F5), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          initials,
          style: AppTypography.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

//─ Menu Section─

class _ProfileMenuSection extends StatelessWidget {
  const _ProfileMenuSection({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5), // Light gray card background
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppColors.textPrimary.withValues(alpha: 0.8),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: labelColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
