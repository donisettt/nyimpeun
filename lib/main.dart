import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nyimpeun/app/app.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/core/constants/supabase_constants.dart';
import 'package:nyimpeun/core/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lock ke portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Inisialisasi locale Indonesia untuk format tanggal & angka
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey, // ignore: deprecated_member_use
    debug: false,
  );

  // Inisialisasi Firebase
  await Firebase.initializeApp();

  // Inisialisasi SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Setup Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Semua inisialisasi lokal selesai — lepas native splash sekarang.
  // Auth check (network) akan ditangani oleh loading screen di dalam app.
  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NyimpeunApp(),
    ),
  );
}
