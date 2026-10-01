import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/auth/presentation/views/change_password_page.dart';
import 'package:nyimpeun/features/auth/presentation/views/edit_profile_page.dart';
import 'package:nyimpeun/features/auth/presentation/views/login_page.dart';
import 'package:nyimpeun/features/auth/presentation/views/profile_page.dart';
import 'package:nyimpeun/features/auth/presentation/views/register_page.dart';
import 'package:nyimpeun/features/auth/presentation/views/terms_page.dart';
import 'package:nyimpeun/features/dashboard/presentation/views/dashboard_page.dart';
import 'package:nyimpeun/features/onboarding/presentation/views/onboarding_page.dart';
import 'package:nyimpeun/features/auth/presentation/views/telegram_integration_page.dart';

// ─── Route Names ──────────────────────────────────────────────────────────────
class AppRoutes {
  static const loading = '/loading';
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const emailConfirmation = '/email-confirmation';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileChangePassword = '/profile/change-password';
  static const telegramIntegration = '/profile/telegram-integration';
  static const terms = '/terms';
}

// ─── Router Notifier ──────────────────────────────────────────────────────────
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authStateNotifierProvider, (_, next) {
      notifyListeners();
    });
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateNotifierProvider);
    final location = state.matchedLocation;

    // Hanya tampilkan loading screen saat startup pertama (AuthInitial)
    // AuthLoading saat login/logout ditangani oleh widget loading di page itu sendiri
    if (authState is AuthInitial) {
      return location == AppRoutes.loading ? null : AppRoutes.loading;
    }

    // Saat AuthLoading (login/logout in-progress): jangan redirect, biarkan di halaman saat ini
    if (authState is AuthLoading) {
      return null;
    }

    final isAuthenticated = authState is AuthAuthenticated;
    final localStorage = _ref.read(localStorageProvider);
    final hasSeenOnboarding = localStorage.hasSeenOnboarding;

    // ── Setelah loading selesai — keluar dari /loading ────────────────────────
    if (location == AppRoutes.loading) {
      if (!hasSeenOnboarding) return AppRoutes.onboarding;
      return isAuthenticated ? AppRoutes.dashboard : AppRoutes.login;
    }

    // Auth routes — hanya saat belum login
    final isAuthRoute = [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.emailConfirmation,
    ].contains(location);

    // Protected routes — perlu login
    final isProtectedRoute = [
      AppRoutes.dashboard,
      AppRoutes.profile,
      AppRoutes.profileEdit,
      AppRoutes.profileChangePassword,
      AppRoutes.telegramIntegration,
    ].contains(location);

    // ── Onboarding ────────────────────────────────────────────────────────────
    if (!hasSeenOnboarding && location != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    // ── Email Confirmation ────────────────────────────────────────────────────
    if (authState is AuthEmailConfirmationRequired) {
      if (location != AppRoutes.emailConfirmation) {
        return AppRoutes.emailConfirmation;
      }
      return null; // Already there
    }

    // ── Sudah login ───────────────────────────────────────────────────────────
    if (isAuthenticated) {
      if (isAuthRoute || location == AppRoutes.onboarding) {
        return AppRoutes.dashboard;
      }
      return null;
    }

    // ── Belum login ───────────────────────────────────────────────────────────
    if (isProtectedRoute) {
      return AppRoutes.login;
    }

    return null;
  }
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  ref.keepAlive(); // Jangan GC — dibutuhkan selama app hidup
  return RouterNotifier(ref);
});

// ─── GoRouter ─────────────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  // PENTING: gunakan ref.read (bukan ref.watch) agar GoRouter tidak dibuat ulang
  // setiap kali auth state berubah. GoRouter cukup dibuat SEKALI dan menggunakan
  // refreshListenable untuk re-evaluasi redirect tanpa reset navigasi.
  final notifier = ref.read(routerNotifierProvider);
  ref.keepAlive();

  return GoRouter(
    initialLocation: AppRoutes.loading,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const _LoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.emailConfirmation,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return _EmailConfirmationPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.profileChangePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.telegramIntegration,
        builder: (context, state) => const TelegramIntegrationPage(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsPage(),
      ),
    ],
  );
});

// ─── Email Confirmation Page (inline, sederhana) ──────────────────────────────
class _EmailConfirmationPage extends StatelessWidget {
  const _EmailConfirmationPage({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF064E3B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 50,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Cek Email Anda!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Kami mengirim link verifikasi ke\n$email\n\nKlik link tersebut untuk mengaktifkan akun Anda.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), height: 1.6),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Kembali ke Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Splash / Loading Screen ──────────────────────────────────────────────────
class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final AnimationController _slideController;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Fade in logo
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Subtle pulse on logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide up text
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start animations sequentially
    _fadeController.forward().then((_) => _slideController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A), // Blue 900
              Color(0xFF1D4ED8), // Blue 700
              Color(0xFF2563EB), // Blue 600
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo dengan fade + pulse
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                          blurRadius: 60,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/logo_nyimpeun.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Nama & tagline dengan slide up
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _slideController,
                  child: Column(
                    children: [
                      const Text(
                        'Nyimpeun',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kelola keuangan Anda dengan cerdas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Loading indicator di bawah
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Memuat...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
