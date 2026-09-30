import 'package:nyimpeun/core/l10n/app_language.dart';
import 'package:nyimpeun/features/analytics/presentation/viewmodels/analytics_viewmodel.dart';

/// Semua teks pada halaman Analitik / Laporan Keuangan
abstract class AnalyticsL10n {
  // AppBar
  String get pageTitle;

  // Wallet Picker
  String get walletPickerTitle;
  String get allWallets;

  // Date Picker
  String get pickMonth;

  // Net Balance Card
  String totalBalanceLabel(String walletName);
  String get incomeThisMonth;
  String get expenseLabel;

  // Donut Chart
  String get chartIncomeVsExpense;
  String get surplus;
  String get deficit;
  String get incomeLabel;
  String get noDataThisMonth;

  // Bar Chart
  String get barChartTitle;
  String get barTooltipIncome;
  String get barTooltipExpense;

  // Trend Card
  String get trendTitle;
  String get trendSame;

  // Category Breakdown
  String get categoryBreakdownTitle;
  String get noCategoryThisMonth;

  // Insight
  String? getInsight(AnalyticsState state);

  factory AnalyticsL10n.of(AppLanguage language) {
    switch (language) {
      case AppLanguage.su:
        return AnalyticsL10nSu();
      case AppLanguage.id:
        return AnalyticsL10nId();
    }
  }
}

// ─── Bahasa Indonesia ─────────────────────────────────────────────────────────
class AnalyticsL10nId implements AnalyticsL10n {
  @override String get pageTitle => 'Laporan Keuangan';

  @override String get walletPickerTitle => 'Pilih Dompet';
  @override String get allWallets => 'Semua Dompet';
  @override String get pickMonth => 'Pilih Bulan';

  @override String totalBalanceLabel(String walletName) => 'Total Saldo $walletName';
  @override String get incomeThisMonth => 'Pemasukan Bulan Ini';
  @override String get expenseLabel => 'Pengeluaran';

  @override String get chartIncomeVsExpense => 'Pemasukan vs Pengeluaran';
  @override String get surplus => 'Surplus';
  @override String get deficit => 'Defisit';
  @override String get incomeLabel => 'Pemasukan';
  @override String get noDataThisMonth => 'Belum ada data bulan ini';

  @override String get barChartTitle => 'Tren 6 Bulan Terakhir';
  @override String get barTooltipIncome => 'Masuk';
  @override String get barTooltipExpense => 'Keluar';

  @override String get trendTitle => 'Bulan Ini vs Bulan Lalu';
  @override String get trendSame => 'Sama';

  @override String get categoryBreakdownTitle => 'Pengeluaran per Kategori';
  @override String get noCategoryThisMonth => 'Belum ada pengeluaran bulan ini';

  @override
  String? getInsight(AnalyticsState state) {
    if (state.currentMonthIncome == 0 && state.currentMonthExpense == 0) {
      return 'Belum ada catatan keuangan di bulan ini. Yuk, mulai catat agar keuanganmu lebih terpantau! ✨';
    }
    
    if (state.currentMonthExpense == 0) {
      return 'Keren! Belum ada pengeluaran sama sekali bulan ini. Saldo kamu masih utuh, pertahankan ya! 🎯';
    }

    final topCategory = state.categoryBreakdowns.isNotEmpty ? state.categoryBreakdowns.first : null;
    final topPct = topCategory != null ? (topCategory.percentage * 100).toStringAsFixed(0) : '0';

    if (state.currentMonthIncome == 0 && state.currentMonthExpense > 0) {
      return 'Oops, pengeluaran terus berjalan walau belum ada pemasukan yang tercatat. Paling banyak habis untuk "${topCategory?.categoryName}" ($topPct%). Jangan lupa catat pemasukanmu juga ya! 💡';
    }

    final expenseDiff = state.currentMonthExpense - state.prevMonthExpense;
    final expensePercent = state.prevMonthExpense == 0 ? 0.0 : (expenseDiff / state.prevMonthExpense * 100).abs();

    if (state.isSurplus) {
      final savePct = (state.currentMonthIncome == 0 ? 0 : (state.currentMonthNet / state.currentMonthIncome * 100)).toStringAsFixed(0);
      if (state.prevMonthExpense > 0 && expenseDiff < 0) {
        return 'Hebat! Pengeluaranmu lebih hemat ${expensePercent.toStringAsFixed(0)}% dari bulan lalu. Kamu berhasil menyisihkan $savePct% dari pemasukanmu! 🚀';
      }
      return 'Bagus sekali! Keuanganmu stabil bulan ini dengan menyisihkan $savePct% dari pemasukan. Terus tingkatkan kebiasaan baik ini! 🌟';
    } else {
      if (topCategory != null) {
        return 'Wah, sepertinya pengeluaranmu lebih besar dari pemasukan nih. Kategori "${topCategory.categoryName}" memakan porsi terbanyak ($topPct%). Yuk, atur lagi strategi belanjamu! 📊';
      }
      return 'Wah, pengeluaranmu sedang lebih besar dari pemasukan nih. Yuk, tinjau ulang dan kurangi pengeluaran yang tidak terlalu penting! 📊';
    }
  }
}

// ─── Basa Sunda ───────────────────────────────────────────────────────────────
class AnalyticsL10nSu implements AnalyticsL10n {
  @override String get pageTitle => 'Laporan Kauangan';

  @override String get walletPickerTitle => 'Pilih Dompét';
  @override String get allWallets => 'Sadaya Dompét';
  @override String get pickMonth => 'Pilih Bulan';

  @override String totalBalanceLabel(String walletName) => 'Total Saldo $walletName';
  @override String get incomeThisMonth => 'Panghasilan Bulan Ieu';
  @override String get expenseLabel => 'Pangaluaran';

  @override String get chartIncomeVsExpense => 'Panghasilan vs Pangaluaran';
  @override String get surplus => 'Surplus';
  @override String get deficit => 'Défisit';
  @override String get incomeLabel => 'Panghasilan';
  @override String get noDataThisMonth => 'Acan aya data bulan ieu';

  @override String get barChartTitle => 'Tren 6 Bulan Katukang';
  @override String get barTooltipIncome => 'Asup';
  @override String get barTooltipExpense => 'Kaluar';

  @override String get trendTitle => 'Bulan Ieu vs Bulan Kamari';
  @override String get trendSame => 'Sarua';

  @override String get categoryBreakdownTitle => 'Pangaluaran per Kategori';
  @override String get noCategoryThisMonth => 'Acan aya pangaluaran bulan ieu';

  @override
  String? getInsight(AnalyticsState state) {
    if (state.currentMonthIncome == 0 && state.currentMonthExpense == 0) {
      return 'Acan aya catétan kauangan di bulan ieu. Hayu, mimitian nyatet améh kauangan langkung kapantau! ✨';
    }
    
    if (state.currentMonthExpense == 0) {
      return 'Kéren! Acan aya pangaluaran pisan bulan ieu. Saldo masih gembleng, pertahankeun nya! 🎯';
    }

    final topCategory = state.categoryBreakdowns.isNotEmpty ? state.categoryBreakdowns.first : null;
    final topPct = topCategory != null ? (topCategory.percentage * 100).toStringAsFixed(0) : '0';

    if (state.currentMonthIncome == 0 && state.currentMonthExpense > 0) {
      return 'Oops, pangaluaran teras-terasan sanaos acan aya panghasilan nu kacatet. Paling ageung kanggo "${topCategory?.categoryName}" ($topPct%). Tong hilap nyatet panghasilan ogé nya! 💡';
    }

    final expenseDiff = state.currentMonthExpense - state.prevMonthExpense;
    final expensePercent = state.prevMonthExpense == 0 ? 0.0 : (expenseDiff / state.prevMonthExpense * 100).abs();

    if (state.isSurplus) {
      final savePct = (state.currentMonthIncome == 0 ? 0 : (state.currentMonthNet / state.currentMonthIncome * 100)).toStringAsFixed(0);
      if (state.prevMonthExpense > 0 && expenseDiff < 0) {
        return 'Hebat! Pangaluaran langkung hémat ${expensePercent.toStringAsFixed(0)}% ti bulan kamari. Anjeun hasil nyisihkeun $savePct% tina panghasilan! 🚀';
      }
      return 'Saé pisan! Kauangan stabil bulan ieu bari nyisihkeun $savePct% tina panghasilan. Teras tingkatkeun kabiasaan ieu! 🌟';
    } else {
      if (topCategory != null) {
        return 'Wah, rupina pangaluaran langkung ageung batan panghasilan yeuh. Kategori "${topCategory.categoryName}" nyéépkeun porsi pangageungna ($topPct%). Hayu atur deui strategi balanjana! 📊';
      }
      return 'Wah, pangaluaran nuju langkung ageung batan panghasilan yeuh. Hayu urang parios deui sareng kurangan pangaluaran nu teu penting! 📊';
    }
  }
}
