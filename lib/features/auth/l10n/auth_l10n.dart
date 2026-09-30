import 'package:nyimpeun/core/l10n/app_language.dart';

/// Semua teks pada fitur Auth (Login & Register)
abstract class AuthL10n {
  // --- Login ---
  String get loginGreeting;
  String get loginSubtitle;
  String get emailLabel;
  String get emailHint;
  String get passwordLabel;
  String get passwordHint;
  String get passwordRequired;
  String get forgotPassword;
  String get btnLogin;
  String get btnRegister;
  String get orDivider;

  // --- Register ---
  String get registerGreeting;
  String get registerSubtitle;
  String get nameLabel;
  String get nameHint;
  String get confirmPasswordLabel;
  String get confirmPasswordHint;

  factory AuthL10n.of(AppLanguage language) {
    switch (language) {
      case AppLanguage.su:
        return AuthL10nSu();
      case AppLanguage.id:
      default:
        return AuthL10nId();
    }
  }
}

// ─── Bahasa Indonesia ────────────────────────────────────────────────────────
class AuthL10nId implements AuthL10n {
  @override
  String get loginGreeting => 'Halo,\nSelamat Datang.';

  @override
  String get loginSubtitle =>
      'Mulai gunakan Nyimpeun dengan masuk atau registrasi terlebih dahulu.';

  @override
  String get emailLabel => 'Masukkan email';

  @override
  String get emailHint => 'email@contoh.com';

  @override
  String get passwordLabel => 'Masukkan kata sandi';

  @override
  String get passwordHint => 'Masukkan Kata Sandi';

  @override
  String get passwordRequired => 'Password tidak boleh kosong';

  @override
  String get forgotPassword => 'Lupa Password?';

  @override
  String get btnLogin => 'Masuk';

  @override
  String get btnRegister => 'Registrasi';

  @override
  String get orDivider => 'atau';

  @override
  String get registerGreeting => 'Halo,\nBuat Akun Baru.';

  @override
  String get registerSubtitle =>
      'Mulai perjalanan finansial Anda bersama Nyimpeun.';

  @override
  String get nameLabel => 'Nama Lengkap';

  @override
  String get nameHint => 'Masukkan nama lengkap';

  @override
  String get confirmPasswordLabel => 'Konfirmasi Kata Sandi';

  @override
  String get confirmPasswordHint => 'Ulangi Kata Sandi';
}

// ─── Basa Sunda ──────────────────────────────────────────────────────────────
class AuthL10nSu implements AuthL10n {
  @override
  String get loginGreeting => 'Halo,\nWilujeng Sumping.';

  @override
  String get loginSubtitle =>
      'Mimiti anggo Nyimpeun ku cara asup atanapi daptar heula.';

  @override
  String get emailLabel => 'Lebetkeun email';

  @override
  String get emailHint => 'email@conto.com';

  @override
  String get passwordLabel => 'Lebetkeun kecap akses';

  @override
  String get passwordHint => 'Lebetkeun Kecap Akses';

  @override
  String get passwordRequired => 'Kecap akses teu kenging kosong';

  @override
  String get forgotPassword => 'Hilap Kecap Akses?';

  @override
  String get btnLogin => 'Lebet';

  @override
  String get btnRegister => 'Ngadaptar';

  @override
  String get orDivider => 'atawa';

  @override
  String get registerGreeting => 'Halo,\nBikin Akun Anyar.';

  @override
  String get registerSubtitle =>
      'Mimiti perjalanan finansial Anjeun sareng Nyimpeun.';

  @override
  String get nameLabel => 'Nami Lengkep';

  @override
  String get nameHint => 'Lebetkeun nami lengkep';

  @override
  String get confirmPasswordLabel => 'Konfirmasi Kecap Akses';

  @override
  String get confirmPasswordHint => 'Ulang Kecap Akses';
}
