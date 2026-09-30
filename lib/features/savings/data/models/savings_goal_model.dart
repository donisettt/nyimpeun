import 'package:nyimpeun/features/savings/domain/entities/savings_goal_entity.dart';

class SavingsGoalModel {
  const SavingsGoalModel({
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
  final String? linkedWalletId;
  final String? linkedWalletName;
  final DateTime? deadline;
  final String? icon;
  final String? color;
  final String status;
  final int autoAllocatePercent;
  final DateTime? createdAt;

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    // Support optional joined wallet name from Supabase select
    final wallet = json['wallets'] as Map<String, dynamic>?;
    return SavingsGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num?)?.toInt() ?? 0,
      currentAmount: (json['current_amount'] as num?)?.toInt() ?? 0,
      linkedWalletId: json['linked_wallet_id'] as String?,
      linkedWalletName: wallet?['name'] as String? ?? json['linked_wallet_name'] as String?,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      status: json['status'] as String? ?? 'active',
      autoAllocatePercent:
          (json['auto_allocate_percent'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'linked_wallet_id': linkedWalletId,
        'deadline': deadline?.toIso8601String().split('T').first,
        'icon': icon,
        'color': color,
        'status': status,
        'auto_allocate_percent': autoAllocatePercent,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'linked_wallet_id': linkedWalletId,
        'deadline': deadline?.toIso8601String().split('T').first,
        'icon': icon,
        'color': color,
        'status': status,
        'auto_allocate_percent': autoAllocatePercent,
      };

  SavingsGoalEntity toEntity() => SavingsGoalEntity(
        id: id,
        userId: userId,
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        linkedWalletId: linkedWalletId,
        linkedWalletName: linkedWalletName,
        deadline: deadline,
        icon: icon,
        color: color,
        status: status,
        autoAllocatePercent: autoAllocatePercent,
        createdAt: createdAt,
      );

  static SavingsGoalModel fromEntity(SavingsGoalEntity e) => SavingsGoalModel(
        id: e.id,
        userId: e.userId,
        name: e.name,
        targetAmount: e.targetAmount,
        currentAmount: e.currentAmount,
        linkedWalletId: e.linkedWalletId,
        linkedWalletName: e.linkedWalletName,
        deadline: e.deadline,
        icon: e.icon,
        color: e.color,
        status: e.status,
        autoAllocatePercent: e.autoAllocatePercent,
        createdAt: e.createdAt,
      );
}
