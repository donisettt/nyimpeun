import 'package:nyimpeun/core/l10n/app_language.dart';

/// Semua teks pada halaman Profile
abstract class ProfileL10n {
  // Page
  String get pageTitle;

  // Account Section
  String get sectionAccount;
  String get menuPersonalInfo;
  String get menuPersonalInfoSub;
  String get menuEmail;
  String get menuEmailSub;
  String get menuPassword;
  String get menuPasswordSub;
  String get menuPin;
  String get menuPinSub;

  // General Section
  String get sectionGeneral;
  String get menuLanguage;
  String get menuUserGuide;
  String get menuHelp;
  String get menuLogout;

  // Image Picker
  String get pickFromGallery;
  String get takePhoto;

  // Change Email Dialog
  String get changeEmailTitle;
  String get changeEmailBody;
  String get changeEmailFieldLabel;
  String get btnSend;
  String get btnCancel;

  // Logout Dialog
  String get logoutTitle;
  String get logoutBody;
  String get btnLogout;

  // Maintenance Dialog
  String get maintenanceTitle;
  String get maintenanceBody;
  String get btnOk;

  // Pin menu
  String get pinLabel;
  String get pinSubNotSet;
  String get pinSubSet;

  // App version
  String get appVersion;

  factory ProfileL10n.of(AppLanguage language) {
    switch (language) {
      case AppLanguage.su:
        return ProfileL10nSu();
      case AppLanguage.id:
        return ProfileL10nId();
    }
  }
}

// ─── Bahasa Indonesia ─────────────────────────────────────────────────────────
class ProfileL10nId implements ProfileL10n {
  @override String get pageTitle => 'Profil Saya';

  @override String get sectionAccount => 'Pusat Akun';
  @override String get menuPersonalInfo => 'Informasi Pribadi';
  @override String get menuPersonalInfoSub => 'Kelola detail akun Anda';
  @override String get menuEmail => 'Alamat Email';
  @override String get menuEmailSub => 'Ubah alamat email Anda';
  @override String get menuPassword => 'Kata Sandi';
  @override String get menuPasswordSub => 'Jaga keamanan akun Anda';
  @override String get menuPin => 'PIN Keamanan';
  @override String get menuPinSub => 'Atur PIN login';

  @override String get sectionGeneral => 'Umum';
  @override String get menuLanguage => 'Bahasa';
  @override String get menuUserGuide => 'Panduan Pengguna';
  @override String get menuHelp => 'Ketentuan Aplikasi';
  @override String get menuLogout => 'Keluar Akun';

  @override String get pickFromGallery => 'Pilih dari Galeri';
  @override String get takePhoto => 'Ambil Foto';

  @override String get changeEmailTitle => 'Ubah Email';
  @override String get changeEmailBody => 'Kami akan mengirim link konfirmasi ke email baru Anda.';
  @override String get changeEmailFieldLabel => 'Email baru';
  @override String get btnSend => 'Kirim';
  @override String get btnCancel => 'Batal';

  @override String get logoutTitle => 'Keluar Akun';
  @override String get logoutBody => 'Apakah Anda yakin ingin keluar dari akun ini?';
  @override String get btnLogout => 'Keluar';

  @override String get maintenanceTitle => 'Dalam Perbaikan';
  @override String get maintenanceBody => 'Fitur ini belum tersedia atau sedang dalam tahap perbaikan.';
  @override String get btnOk => 'Oke';

  @override String get pinLabel => 'PIN Keamanan';
  @override String get pinSubNotSet => 'Belum diatur';
  @override String get pinSubSet => 'Sudah diatur';

  @override String get appVersion => 'Nyimpeun v1.0.0';
}

// ─── Basa Sunda ───────────────────────────────────────────────────────────────
class ProfileL10nSu implements ProfileL10n {
  @override String get pageTitle => 'Profil Abdi';

  @override String get sectionAccount => 'Pusat Akun';
  @override String get menuPersonalInfo => 'Inpormasi Pribadi';
  @override String get menuPersonalInfoSub => 'Ngatur detil akun Anjeun';
  @override String get menuEmail => 'Alamat Email';
  @override String get menuEmailSub => 'Robih alamat email Anjeun';
  @override String get menuPassword => 'Kecap Akses';
  @override String get menuPasswordSub => 'Jaga kaamanan akun Anjeun';
  @override String get menuPin => 'PIN Kaamanan';
  @override String get menuPinSub => 'Atur PIN lebet';

  @override String get sectionGeneral => 'Umum';
  @override String get menuLanguage => 'Basa';
  @override String get menuUserGuide => 'Pituduh Pamaké';
  @override String get menuHelp => 'Katangtuan Aplikasi';
  @override String get menuLogout => 'Kaluar Akun';

  @override String get pickFromGallery => 'Pilih ti Galeri';
  @override String get takePhoto => 'Potret Foto';

  @override String get changeEmailTitle => 'Robih Email';
  @override String get changeEmailBody => 'Kami bade ngirim link konfirmasi ka email anyar Anjeun.';
  @override String get changeEmailFieldLabel => 'Email anyar';
  @override String get btnSend => 'Kirim';
  @override String get btnCancel => 'Batal';

  @override String get logoutTitle => 'Kaluar Akun';
  @override String get logoutBody => 'Naha Anjeun yakin badé kaluar tina akun ieu?';
  @override String get btnLogout => 'Kaluar';

  @override String get maintenanceTitle => 'Nuju Dioméan';
  @override String get maintenanceBody => 'Fitur ieu acan sayogi atanapi nuju dioméan.';
  @override String get btnOk => 'Mangga';

  @override String get pinLabel => 'PIN Kaamanan';
  @override String get pinSubNotSet => 'Acan diatur';
  @override String get pinSubSet => 'Parantos diatur';

  @override String get appVersion => 'Nyimpeun v1.0.0';
}
