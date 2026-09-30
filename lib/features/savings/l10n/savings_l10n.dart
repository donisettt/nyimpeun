import 'package:nyimpeun/core/l10n/app_language.dart';

abstract class SavingsL10n {
  String get pageTitle;
  String get tabActive;
  String get tabCompleted;
  String get tabPaused;

  String get milestoneReached;

  String get emptyActiveTitle;
  String get emptyActiveSubtitle;
  String get emptyCompletedTitle;
  String get emptyCompletedSubtitle;
  String get emptyPausedTitle;
  String get emptyPausedSubtitle;

  String get createSavings;

  String get totalAllocated;
  String get totalTarget;
  String get ofAllTargets; // For '% dari semua target'
  String get activeStatus; // For 'aktif'
  String get completedStatus; // For 'selesai'

  String get milestoneReachedDialogTitle;
  String get btnContinue;
  String get deleteGoalTitle;

  factory SavingsL10n.of(AppLanguage language) {
    switch (language) {
      case AppLanguage.id:
        return const _SavingsL10nId();
      case AppLanguage.su:
        return const _SavingsL10nSu();
    }
  }
}

class _SavingsL10nId implements SavingsL10n {
  const _SavingsL10nId();

  @override
  String get pageTitle => 'Tabungan Saya';
  @override
  String get tabActive => 'Aktif';
  @override
  String get tabCompleted => 'Selesai';
  @override
  String get tabPaused => 'Dijeda';

  @override
  String get milestoneReached => 'Tercapai!';

  @override
  String get emptyActiveTitle => 'Belum ada tabungan aktif';
  @override
  String get emptyActiveSubtitle =>
      'Tap tombol + di bawah\\nuntuk mulai menabung!';
  @override
  String get emptyCompletedTitle => 'Belum ada tabungan selesai';
  @override
  String get emptyCompletedSubtitle => 'Terus semangat mencapai target!';
  @override
  String get emptyPausedTitle => 'Tidak ada tabungan dijeda';
  @override
  String get emptyPausedSubtitle => 'Semua tabungan sedang berjalan aktif';

  @override
  String get createSavings => 'Buat Tabungan';

  @override
  String get totalAllocated => 'Total Dialokasikan';
  @override
  String get totalTarget => 'Total Target';
  @override
  String get ofAllTargets => 'dari semua target';
  @override
  String get activeStatus => 'aktif';
  @override
  String get completedStatus => 'selesai';

  @override
  String get milestoneReachedDialogTitle => 'Tercapai!';
  @override
  String get btnContinue => 'Sip, Lanjutkan!';
  @override
  String get deleteGoalTitle => 'Hapus Tabungan?';
}

class _SavingsL10nSu implements SavingsL10n {
  const _SavingsL10nSu();

  @override
  String get pageTitle => 'Tabungan Abdi';
  @override
  String get tabActive => 'Aktip';
  @override
  String get tabCompleted => 'Réngsé';
  @override
  String get tabPaused => 'Dipotong';

  @override
  String get milestoneReached => 'Kahontal!';

  @override
  String get emptyActiveTitle => 'Teu acan aya tabungan aktip';
  @override
  String get emptyActiveSubtitle =>
      'Ketok tombol + di handap\\npikeun ngawitan nabung!';
  @override
  String get emptyCompletedTitle => 'Teu acan aya tabungan réngsé';
  @override
  String get emptyCompletedSubtitle => 'Terasang sumanget ngahontal udagan!';
  @override
  String get emptyPausedTitle => 'Teu aya tabungan anu dipotong';
  @override
  String get emptyPausedSubtitle => 'Sadayana tabungan nuju aktip';

  @override
  String get createSavings => 'Jieun Tabungan';

  @override
  String get totalAllocated => 'Total Dialokasikeun';
  @override
  String get totalTarget => 'Total Udagan';
  @override
  String get ofAllTargets => 'tina sadaya udagan';
  @override
  String get activeStatus => 'aktip';
  @override
  String get completedStatus => 'réngsé';

  @override
  String get milestoneReachedDialogTitle => 'Kahontal!';
  @override
  String get btnContinue => 'Sip, Terasang!';
  @override
  String get deleteGoalTitle => 'Hapus Tabungan?';
}
