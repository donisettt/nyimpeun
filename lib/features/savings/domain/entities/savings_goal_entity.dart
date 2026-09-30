class SavingsGoalEntity {
  const SavingsGoalEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.linkedWalletId,
    this.linkedWalletName,
    this.deadline,
    this.icon,
    this.color,
    this.status = 'active',
    this.autoAllocatePercent = 0,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final int targetAmount;
  final int currentAmount;
  final String? linkedWalletId;   // Dompet tempat uang tabungan disimpan
  final String? linkedWalletName; // Nama dompet untuk ditampilkan di UI
  final DateTime? deadline;
  final String? icon;
  final String? color;
  final String status; // 'active' | 'completed' | 'paused'
  final int autoAllocatePercent; // 0-100
  final DateTime? createdAt;

  bool get hasLinkedWallet => linkedWalletId != null && linkedWalletId!.isNotEmpty;

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  int get remainingAmount =>
      (targetAmount - currentAmount).clamp(0, targetAmount);

  bool get isCompleted =>
      currentAmount >= targetAmount || status == 'completed';

  bool get isPaused => status == 'paused';

  int? get daysLeft => deadline != null
      ? deadline!.difference(DateTime.now()).inDays
      : null;

  SavingsGoalEntity copyWith({
    String? id,
    String? userId,
    String? name,
    int? targetAmount,
    int? currentAmount,
    String? linkedWalletId,
    String? linkedWalletName,
    DateTime? deadline,
    String? icon,
    String? color,
    String? status,
    int? autoAllocatePercent,
    DateTime? createdAt,
  }) {
    return SavingsGoalEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      linkedWalletId: linkedWalletId ?? this.linkedWalletId,
      linkedWalletName: linkedWalletName ?? this.linkedWalletName,
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      status: status ?? this.status,
      autoAllocatePercent: autoAllocatePercent ?? this.autoAllocatePercent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
