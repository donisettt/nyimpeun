/// Enum untuk semua bahasa yang didukung aplikasi Nyimpeun
enum AppLanguage {
  id('id', 'Bahasa Indonesia', '🇮🇩'),
  su('su', 'Basa Sunda', '🌿');

  const AppLanguage(this.code, this.displayName, this.flag);

  final String code;
  final String displayName;
  final String flag;
}
