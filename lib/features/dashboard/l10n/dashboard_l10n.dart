import 'package:nyimpeun/core/l10n/app_language.dart';

abstract class DashboardL10n {
  String get navHome;
  String get navWallet;
  String get navAnalytics;
  String get navProfile;

  String get greetingMorning;
  String get greetingAfternoon;
  String get greetingEvening;
  String get greetingNight;

  String get totalBalance;
  String get allAccounts;
  String get changeAccount;

  String get income;
  String get expense;
  String get savings;
  String get others;
  String get categories;

  String get expenseCategory;
  String get thisMonth;
  String get noTransactionData;

  String get recentTransactions;
  String get seeAll;
  String get noTransactions;
  String get inFlow;
  String get outFlow;

  factory DashboardL10n.of(AppLanguage language) {
    switch (language) {
      case AppLanguage.id:
        return const _DashboardL10nId();
      case AppLanguage.su:
        return const _DashboardL10nSu();
    }
  }
}

class _DashboardL10nId implements DashboardL10n {
  const _DashboardL10nId();

  @override
  String get navHome => 'Home';
  @override
  String get navWallet => 'Dompet';
  @override
  String get navAnalytics => 'Analisa';
  @override
  String get navProfile => 'Profil';

  @override
  String get greetingMorning => 'Selamat pagi';
  @override
  String get greetingAfternoon => 'Selamat siang';
  @override
  String get greetingEvening => 'Selamat sore';
  @override
  String get greetingNight => 'Selamat malam';

  @override
  String get totalBalance => 'Total Saldo';
  @override
  String get allAccounts => 'Semua Rekening';
  @override
  String get changeAccount => 'Ubah Rekening';

  @override
  String get income => 'Pemasukan';
  @override
  String get expense => 'Pengeluaran';
  @override
  String get savings => 'Tabungan';
  @override
  String get others => 'Lainnya';
  @override
  String get categories => 'Kategori';

  @override
  String get expenseCategory => 'Kategori Pengeluaran';
  @override
  String get thisMonth => 'Bulan Ini';
  @override
  String get noTransactionData => 'Belum ada data transaksi bulan ini.';

  @override
  String get recentTransactions => 'Transaksi Terbaru';
  @override
  String get seeAll => 'Lihat Semua';
  @override
  String get noTransactions => 'Belum ada transaksi';
  @override
  String get inFlow => 'Masuk';
  @override
  String get outFlow => 'Keluar';
}

class _DashboardL10nSu implements DashboardL10n {
  const _DashboardL10nSu();

  @override
  String get navHome => 'Home';
  @override
  String get navWallet => 'Dompet';
  @override
  String get navAnalytics => 'Analisa';
  @override
  String get navProfile => 'Profil';

  @override
  String get greetingMorning => 'Wilujeng enjing';
  @override
  String get greetingAfternoon => 'Wilujeng siang';
  @override
  String get greetingEvening => 'Wilujeng sonten';
  @override
  String get greetingNight => 'Wilujeng wengi';

  @override
  String get totalBalance => 'Total Saldo';
  @override
  String get allAccounts => 'Sadaya Rekening';
  @override
  String get changeAccount => 'Ubah Rekening';

  @override
  String get income => 'Panghasilan';
  @override
  String get expense => 'Pangaluaran';
  @override
  String get savings => 'Tabungan';
  @override
  String get others => 'Lainna';
  @override
  String get categories => 'Kategori';

  @override
  String get expenseCategory => 'Kategori Pangaluaran';
  @override
  String get thisMonth => 'Sasih Ieu';
  @override
  String get noTransactionData => 'Teu acan aya data transaksi sasih ieu.';

  @override
  String get recentTransactions => 'Transaksi Anyar';
  @override
  String get seeAll => 'Tingal Sadayana';
  @override
  String get noTransactions => 'Teu acan aya transaksi';
  @override
  String get inFlow => 'Lebet';
  @override
  String get outFlow => 'Kaluar';
}
