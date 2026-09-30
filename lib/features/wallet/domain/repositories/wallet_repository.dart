import 'package:nyimpeun/features/wallet/domain/entities/category_entity.dart';
import 'package:nyimpeun/features/wallet/domain/entities/transaction_entity.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  // ─── Wallets ───────────────────────────────────────────────────────────────
  Future<List<WalletEntity>> getWallets(String userId);
  Future<WalletEntity> createWallet(WalletEntity wallet);
  Future<WalletEntity> updateWallet(WalletEntity wallet);
  Future<void> deleteWallet(String walletId);
  Future<WalletEntity?> getDefaultWallet(String userId);

  // ─── Transactions ──────────────────────────────────────────────────────────
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    String? walletId,
    String? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  });
  Future<TransactionEntity> createTransaction(TransactionEntity transaction);
  Future<TransactionEntity> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String transactionId);

  // ─── Categories ────────────────────────────────────────────────────────────
  Future<List<CategoryEntity>> getCategories(String userId);
  Future<CategoryEntity> createCategory(CategoryEntity category);
  Future<void> deleteCategory(String categoryId);

  // ─── Summary ───────────────────────────────────────────────────────────────
  Future<Map<String, int>> getMonthlySummary({
    required String userId,
    required int year,
    required int month,
  });
}
