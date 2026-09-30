import 'package:nyimpeun/core/l10n/app_language.dart';

/// Data teks per slide onboarding
class OnboardingSlideL10n {
  const OnboardingSlideL10n({
    required this.title,
    required this.description,
  });
  final String title;
  final String description;
}

/// Semua teks pada halaman Onboarding
abstract class OnboardingL10n {
  List<OnboardingSlideL10n> get slides;
  String get btnLogin;
  String get btnRegister;

  factory OnboardingL10n.of(AppLanguage language) {
    switch (language) {
      case AppLanguage.su:
        return OnboardingL10nSu();
      case AppLanguage.id:
      default:
        return OnboardingL10nId();
    }
  }
}

// ─── Bahasa Indonesia ────────────────────────────────────────────────────────
class OnboardingL10nId implements OnboardingL10n {
  @override
  List<OnboardingSlideL10n> get slides => const [
    OnboardingSlideL10n(
      title: 'Selamat datang di Nyimpeun!',
      description:
          'Aplikasi tracker keuangan personal untuk mencatat setiap transaksi Anda dengan mudah. Duit aman, hate tenang.',
    ),
    OnboardingSlideL10n(
      title: 'Pantau Arus Kas Anda',
      description:
          'Ketahui persis ke mana perginya uang Anda setiap bulan dengan pencatatan otomatis yang terorganisir.',
    ),
    OnboardingSlideL10n(
      title: 'Capai Tujuan Finansial',
      description:
          'Tetapkan target tabungan impian Anda dan pantau terus perkembangannya. Nyimpeun bantu kelola keuangan jadi lebih terarah.',
    ),
  ];

  @override
  String get btnLogin => 'Masuk';

  @override
  String get btnRegister => 'Daftar Akun';
}

// ─── Basa Sunda ──────────────────────────────────────────────────────────────
class OnboardingL10nSu implements OnboardingL10n {
  @override
  List<OnboardingSlideL10n> get slides => const [
    OnboardingSlideL10n(
      title: 'Wilujeng sumping di Nyimpeun!',
      description:
          'Aplikasi tracker kauangan personal kanggo nyatet unggal transaksi Anjeun kalayan gampil. Artos aman, hate tenang.',
    ),
    OnboardingSlideL10n(
      title: 'Pantau Arus Kas Anjeun',
      description:
          'Pikanyaho sacara pasti ka mana lungsurna artos Anjeun unggal sasih ku pencatatan otomatis anu terorganisir.',
    ),
    OnboardingSlideL10n(
      title: 'Kahontal Tujuan Finansial',
      description:
          'Tangtoskeun udagan tabungan impian Anjeun sareng pantau teras perkawis perkembanganna. Nyimpeun ngabantos ngatur kauangan janten langkung kaarah.',
    ),
  ];

  @override
  String get btnLogin => 'Lebet';

  @override
  String get btnRegister => 'Ngadaptar';
}
