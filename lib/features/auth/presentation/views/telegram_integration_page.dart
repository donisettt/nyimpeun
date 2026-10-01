import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/shared/widgets/app_snackbar.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';

import 'package:dio/dio.dart';
import 'package:nyimpeun/core/constants/supabase_constants.dart';

final telegramProvider = StateNotifierProvider<TelegramNotifier, TelegramState>((ref) {
  final dio = ref.watch(dioProvider);
  return TelegramNotifier(dio);
});

class TelegramState {
  final bool isLoading;
  final String? otpCode;
  final bool isLinked;

  TelegramState({this.isLoading = false, this.otpCode, this.isLinked = false});

  TelegramState copyWith({bool? isLoading, String? otpCode, bool? isLinked}) {
    return TelegramState(
      isLoading: isLoading ?? this.isLoading,
      otpCode: otpCode ?? this.otpCode,
      isLinked: isLinked ?? this.isLinked,
    );
  }
}

class TelegramNotifier extends StateNotifier<TelegramState> {
  TelegramNotifier(this._dio) : super(TelegramState());

  final Dio _dio;

  Future<void> checkStatus(String userId) async {
    try {
      state = state.copyWith(isLoading: true);

      final response = await _dio.get(
        '${SupabaseConstants.restEndpoint}/telegram_bindings',
        queryParameters: {
          'user_id': 'eq.$userId',
          'status': 'eq.LINKED',
          'select': '*',
          'limit': 1,
        },
        options: Options(headers: {'apikey': SupabaseConstants.anonKey}),
      );
      final list = response.data as List;
      final data = list.isNotEmpty ? list.first : null;
      
      if (data != null) {
        state = state.copyWith(isLinked: true, isLoading: false);
      } else {
        state = state.copyWith(isLinked: false, isLoading: false);
      }
    } catch (e) {
      debugPrint('Telegram checkStatus error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> generateOtp(String userId) async {
    debugPrint('=== generateOtp CALLED ===');
    try {
      state = state.copyWith(isLoading: true);
      
      debugPrint('Deleting old pending...');
      await _dio.delete(
        '${SupabaseConstants.restEndpoint}/telegram_bindings',
        queryParameters: {
          'user_id': 'eq.$userId',
          'status': 'eq.PENDING',
        },
        options: Options(headers: {'apikey': SupabaseConstants.anonKey}),
      );

      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rnd = Random();
      final code = 'NYMP-${String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))))}';
      
      debugPrint('Inserting new code: $code');
      await _dio.post(
        '${SupabaseConstants.restEndpoint}/telegram_bindings',
        data: {
          'user_id': userId,
          'otp_code': code,
        },
        options: Options(headers: {
          'apikey': SupabaseConstants.anonKey,
          'Prefer': 'return=minimal',
        }),
      );

      debugPrint('Success insert');

      state = state.copyWith(isLoading: false, otpCode: code);
    } catch (e) {
      if (e is DioException) {
        debugPrint('Telegram generateOtp Dio error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        debugPrint('Telegram generateOtp error: $e');
      }
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> unlink(String userId) async {
    try {
      state = state.copyWith(isLoading: true);

      await _dio.delete(
        '${SupabaseConstants.restEndpoint}/telegram_bindings',
        queryParameters: {
          'user_id': 'eq.$userId',
        },
        options: Options(headers: {'apikey': SupabaseConstants.anonKey}),
      );
      state = state.copyWith(isLoading: false, isLinked: false, otpCode: null);
    } catch (e) {
      debugPrint('Telegram unlink error: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

class TelegramIntegrationPage extends ConsumerStatefulWidget {
  const TelegramIntegrationPage({super.key});

  @override
  ConsumerState<TelegramIntegrationPage> createState() => _TelegramIntegrationPageState();
}

class _TelegramIntegrationPageState extends ConsumerState<TelegramIntegrationPage> {
  late String _userId;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to read from provider after build starts
    Future.microtask(() {
      final authState = ref.read(authStateNotifierProvider);
      if (authState is AuthAuthenticated) {
        _userId = authState.user.id;
        ref.read(telegramProvider.notifier).checkStatus(_userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(telegramProvider);
    final notifier = ref.read(telegramProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('Integrasi Telegram', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.telegram_rounded, size: 80, color: Color(0xFF229ED9)),
                const SizedBox(height: 24),
                Text(
                  'Catat Transaksi Lebih Mudah\nlewat Telegram',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kamu bisa mengirimkan pengeluaran seperti "Makan siang 50rb pakai BCA" ke bot Telegram, dan transaksi akan otomatis tersimpan di sini menggunakan teknologi AI!',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 48),

                if (state.isLinked) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Akun Telegram Terhubung',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => notifier.unlink(_userId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Putuskan Tautan'),
                        )
                      ],
                    ),
                  ),
                ] else if (state.otpCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Column(
                      children: [
                        // Step 1 — Copy code
                        Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Salin kode berikut',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: state.otpCode!));
                            AppSnackBar.success(context, 'Kode disalin ke clipboard!');
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  state.otpCode!,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 20),

                        // Step 2 — Open Bot
                        Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Buka bot Telegram lalu kirimkan kode di atas',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final botUrl = Uri.parse('https://t.me/NyimpeunAppBot');
                              try {
                                // Coba buka app Telegram langsung
                                await launchUrl(botUrl, mode: LaunchMode.externalNonBrowserApplication);
                              } catch (_) {
                                try {
                                  // Fallback: buka via browser jika Telegram tidak terinstall
                                  await launchUrl(botUrl, mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  if (context.mounted) {
                                    AppSnackBar.error(context, 'Tidak dapat membuka Telegram. Silakan buka @NyimpeunAppBot secara manual.');
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Buka @NyimpeunAppBot'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF229ED9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ] else ...[
                  ElevatedButton(
                    onPressed: () => notifier.generateOtp(_userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Hubungkan Sekarang', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  )
                ]
              ],
            ),
          ),
    );
  }
}
