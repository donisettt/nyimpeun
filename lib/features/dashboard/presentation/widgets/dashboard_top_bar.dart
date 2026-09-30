import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/auth/domain/entities/user_entity.dart';
import 'package:nyimpeun/features/dashboard/l10n/dashboard_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

class DashboardTopBar extends ConsumerWidget {
  const DashboardTopBar({super.key, required this.user, required this.onLogout});
  
  final UserEntity? user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = DashboardL10n.of(ref.watch(languageProvider));
    final userName = user?.fullName ?? 'Pengguna';
    final initials = userName.trim().split(' ').length > 1
        ? '${userName.trim().split(' ')[0][0]}${userName.trim().split(' ')[1][0]}'
            .toUpperCase()
        : (userName.isNotEmpty ? userName[0].toUpperCase() : 'U');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile Info
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: user?.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user!.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: Text(
                            initials,
                            style: AppTypography.titleMedium.copyWith(color: Colors.white),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            initials,
                            style: AppTypography.titleMedium.copyWith(color: Colors.white),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: AppTypography.titleMedium.copyWith(color: Colors.white),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(l10n),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  userName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        
        // Actions
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                color: Colors.white,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textPrimary),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  String _getGreeting(DashboardL10n l10n) {
    final hour = DateTime.now().hour;
    if (hour < 11) return l10n.greetingMorning;
    if (hour < 15) return l10n.greetingAfternoon;
    if (hour < 18) return l10n.greetingEvening;
    return l10n.greetingNight;
  }
}
