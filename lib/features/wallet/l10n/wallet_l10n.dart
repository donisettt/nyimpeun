import 'package:nyimpeun/core/l10n/app_language.dart';

abstract class WalletL10n {
  String get pageTitle;
  String get allWallets;
  String get addWallet;
  String get allTransactions;
  String get filterAll;
  String get filterIncome;
  String get filterExpense;
  String get emptyWalletTitle;
  String get emptyWalletDesc;
  String get emptyTransactions;
  String get deleteTransaction;
  String get deleteTransactionConfirm;
  String get cancel;
  String get delete;
  String get totalBalance;
  String get monthSummary;
  String get income;
  String get expense;

  String get mainWallet;
  String get changeWallet;
  String get selectWallet;
  String get editWallet;
  String get deleteWallet;
  String get deleteWalletConfirmTitle;
  String deleteWalletConfirmDesc(String walletName);
  String get search;
  String get seeAll;
  String get noRecentTransactions;
  String get today;
  String get yesterday;

  // Add Transaction Sheet
  String get newTransaction;
  String get editTransaction;
  String get incomeType;
  String get expenseType;
  String get amount;
  String get category;
  String get date;
  String get note;
  String get noteHint;
  String get wallet;
  String get noWallet;
  String get save;
  String get saveChanges;
  String get addIncome;
  String get addExpense;
  String get selectCategory;
  String get pickCategory;
  String get manageCategories;
  String get manageLabel;
  String get addNewCategory;
  String get categoryName;
  String get pickColor;
  String availableCategories(int count);
  String get noCategory;
  String get deleteCategory;
  String deleteCategoryConfirm(String name);
  String get incomeCategory;
  String get expenseCategory;
  String get invalidAmount;
  String get selectCategoryFirst;

  factory WalletL10n.of(AppLanguage language) {
    switch (language) {
      case AppLanguage.su:
        return WalletL10nSu();
      case AppLanguage.id:
        return WalletL10nId();
    }
  }
}

// ─── Bahasa Indonesia ─────────────────────────────────────────────────────────
class WalletL10nId implements WalletL10n {
  @override String get pageTitle => 'Dompet Saya';
  @override String get allWallets => 'Semua Dompet';
  @override String get addWallet => 'Tambah Dompet';
  @override String get allTransactions => 'Transaksi';
  @override String get filterAll => 'Semua';
  @override String get filterIncome => 'Masuk';
  @override String get filterExpense => 'Keluar';
  @override String get emptyWalletTitle => 'Belum ada dompet';
  @override String get emptyWalletDesc => 'Tambahkan dompet pertama Anda untuk mulai mencatat keuangan.';
  @override String get emptyTransactions => 'Belum ada transaksi';
  @override String get deleteTransaction => 'Hapus Transaksi?';
  @override String get deleteTransactionConfirm => 'Transaksi ini akan dihapus secara permanen.';
  @override String get cancel => 'Batal';
  @override String get delete => 'Hapus';
  @override String get totalBalance => 'Total Saldo';
  @override String get monthSummary => 'Ringkasan';
  @override String get income => 'Pemasukan';
  @override String get expense => 'Pengeluaran';

  @override String get mainWallet => 'Dompet Utama';
  @override String get changeWallet => 'Ubah Dompet';
  @override String get selectWallet => 'Pilih Dompet';
  @override String get editWallet => 'Edit Dompet';
  @override String get deleteWallet => 'Hapus Dompet';
  @override String get deleteWalletConfirmTitle => 'Hapus Dompet?';
  @override String deleteWalletConfirmDesc(String walletName) => '"$walletName" akan dihapus. Semua transaksi terkait akan terputus dari dompet ini.';
  @override String get search => 'Pencarian';
  @override String get seeAll => 'Lihat Semua';
  @override String get noRecentTransactions => 'Tidak ada transaksi seminggu terakhir';
  @override String get today => 'Hari ini';
  @override String get yesterday => 'Kemarin';

  @override String get newTransaction => 'Transaksi Baru';
  @override String get editTransaction => 'Edit Transaksi';
  @override String get incomeType => 'Pemasukan';
  @override String get expenseType => 'Pengeluaran';
  @override String get amount => 'Nominal';
  @override String get category => 'Kategori';
  @override String get date => 'Tanggal';
  @override String get note => 'Catatan (opsional)';
  @override String get noteHint => 'Tambahkan catatan...';
  @override String get wallet => 'Dompet';
  @override String get noWallet => 'Belum ada dompet';
  @override String get save => 'Simpan';
  @override String get saveChanges => 'Simpan Perubahan';
  @override String get addIncome => 'Tambah Pemasukan';
  @override String get addExpense => 'Tambah Pengeluaran';
  @override String get selectCategory => 'Pilih kategori...';
  @override String get pickCategory => 'Pilih Kategori';
  @override String get manageCategories => 'Atur';
  @override String get manageLabel => 'Atur Kategori';
  @override String get addNewCategory => 'Tambah Kategori Baru';
  @override String get categoryName => 'Nama kategori...';
  @override String get pickColor => 'Pilih warna:';
  @override String availableCategories(int count) => 'Kategori Tersedia ($count)';
  @override String get noCategory => 'Belum ada kategori';
  @override String get deleteCategory => 'Hapus Kategori?';
  @override String deleteCategoryConfirm(String name) => 'Kategori "$name" akan dihapus.';
  @override String get incomeCategory => 'Kategori Pemasukan';
  @override String get expenseCategory => 'Kategori Pengeluaran';
  @override String get invalidAmount => 'Masukkan nominal yang valid';
  @override String get selectCategoryFirst => 'Pilih kategori terlebih dahulu';
}

// ─── Basa Sunda ───────────────────────────────────────────────────────────────
class WalletL10nSu implements WalletL10n {
  @override String get pageTitle => 'Kantong Abdi';
  @override String get allWallets => 'Sadaya Kantong';
  @override String get addWallet => 'Tambih Kantong';
  @override String get allTransactions => 'Transaksi';
  @override String get filterAll => 'Sadaya';
  @override String get filterIncome => 'Asup';
  @override String get filterExpense => 'Kaluar';
  @override String get emptyWalletTitle => 'Kantong acan aya';
  @override String get emptyWalletDesc => 'Tambihkeun kantong kahiji Anjeun kanggo mimiti nyatet kauangan.';
  @override String get emptyTransactions => 'Transaksi acan aya';
  @override String get deleteTransaction => 'Hapus Transaksi?';
  @override String get deleteTransactionConfirm => 'Transaksi ieu bakal dihapus permanén.';
  @override String get cancel => 'Batal';
  @override String get delete => 'Hapus';
  @override String get totalBalance => 'Total Saldo';
  @override String get monthSummary => 'Ringkesan';
  @override String get income => 'Pemasukan';
  @override String get expense => 'Pengeluaran';

  @override String get mainWallet => 'Kantong Utama';
  @override String get changeWallet => 'Ubah Kantong';
  @override String get selectWallet => 'Pilih Kantong';
  @override String get editWallet => 'Edit Kantong';
  @override String get deleteWallet => 'Hapus Kantong';
  @override String get deleteWalletConfirmTitle => 'Hapus Kantong?';
  @override String deleteWalletConfirmDesc(String walletName) => '"$walletName" bakal dihapus. Sadaya transaksi nu patali bakal dipegatkeun ti kantong ieu.';
  @override String get search => 'Pamilarian';
  @override String get seeAll => 'Tingali Sadaya';
  @override String get noRecentTransactions => 'Acan aya transaksi saminggu katukang';
  @override String get today => 'Dinten ieu';
  @override String get yesterday => 'Kamari';

  @override String get newTransaction => 'Transaksi Anyar';
  @override String get editTransaction => 'Edit Transaksi';
  @override String get incomeType => 'Panghasilan';
  @override String get expenseType => 'Pangaluaran';
  @override String get amount => 'Nominal';
  @override String get category => 'Kategori';
  @override String get date => 'Tanggal';
  @override String get note => 'Catetan (opsional)';
  @override String get noteHint => 'Tambihkeun catetan...';
  @override String get wallet => 'Kantong';
  @override String get noWallet => 'Kantong acan aya';
  @override String get save => 'Simpen';
  @override String get saveChanges => 'Simpen Parobahan';
  @override String get addIncome => 'Tambih Panghasilan';
  @override String get addExpense => 'Tambih Pangaluaran';
  @override String get selectCategory => 'Pilih kategori...';
  @override String get pickCategory => 'Pilih Kategori';
  @override String get manageCategories => 'Atur';
  @override String get manageLabel => 'Atur Kategori';
  @override String get addNewCategory => 'Tambih Kategori Anyar';
  @override String get categoryName => 'Nami kategori...';
  @override String get pickColor => 'Pilih warna:';
  @override String availableCategories(int count) => 'Kategori Anu Aya ($count)';
  @override String get noCategory => 'Kategori acan aya';
  @override String get deleteCategory => 'Hapus Kategori?';
  @override String deleteCategoryConfirm(String name) => 'Kategori "$name" bakal dihapus.';
  @override String get incomeCategory => 'Kategori Panghasilan';
  @override String get expenseCategory => 'Kategori Pangaluaran';
  @override String get invalidAmount => 'Lebetkeun nominal nu valid';
  @override String get selectCategoryFirst => 'Pilih kategori heula';
}
