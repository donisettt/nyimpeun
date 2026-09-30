import 'package:nyimpeun/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:nyimpeun/features/wallet/data/models/category_model.dart';
import 'package:nyimpeun/features/wallet/data/models/transaction_model.dart';
import 'package:nyimpeun/features/wallet/data/models/wallet_model.dart';
import 'package:nyimpeun/features/wallet/domain/entities/category_entity.dart';
import 'package:nyimpeun/features/wallet/domain/entities/transaction_entity.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';
import 'package:nyimpeun/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({required WalletRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final WalletRemoteDataSource _remote;

  // ─── Wallets ───────────────────────────────────────────────────────────────

  @override
  Future<List<WalletEntity>> getWallets(String userId) async {
    final models = await _remote.getWallets(userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<WalletEntity> createWallet(WalletEntity wallet) async {
    final model = WalletModel.fromEntity(wallet);
    final result = await _remote.createWallet(model);
    return result.toEntity();
  }

  @override
  Future<WalletEntity> updateWallet(WalletEntity wallet) async {
    final data = WalletModel.fromEntity(wallet).toJson();
    final result = await _remote.updateWallet(wallet.id, data);
    return result.toEntity();
  }

  @override
  Future<void> deleteWallet(String walletId) => _remote.deleteWallet(walletId);

  @override
  Future<WalletEntity?> getDefaultWallet(String userId) async {
    final wallets = await _remote.getWallets(userId);
    if (wallets.isEmpty) return null;
    final defaultWallet = wallets.firstWhere(
      (w) => w.isDefault,
      orElse: () => wallets.first,
    );
    return defaultWallet.toEntity();
  }

  // ─── Transactions ──────────────────────────────────────────────────────────

  @override
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    String? walletId,
    String? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    final models = await _remote.getTransactions(
      userId: userId,
      walletId: walletId,
      categoryId: categoryId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TransactionEntity> createTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    final result = await _remote.createTransaction(model);
    return result.toEntity();
  }

  @override
  Future<TransactionEntity> updateTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    final data = model.toInsertJson();
    final result = await _remote.updateTransaction(transaction.id, data);
    return result.toEntity();
  }

  @override
  Future<void> deleteTransaction(String transactionId) =>
      _remote.deleteTransaction(transactionId);

  // ─── Categories ────────────────────────────────────────────────────────────

  @override
  Future<List<CategoryEntity>> getCategories(String userId) async {
    final models = await _remote.getCategories(userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CategoryEntity> createCategory(CategoryEntity category) async {
    final model = CategoryModel(
      id: '',
      userId: category.userId,
      name: category.name,
      type: category.type,
      icon: category.icon,
      color: category.color,
      isDefault: category.isDefault,
    );
    final result = await _remote.createCategory(model);
    return result.toEntity();
  }

  @override
  Future<void> deleteCategory(String categoryId) =>
      _remote.deleteCategory(categoryId);

  // ─── Summary ───────────────────────────────────────────────────────────────

  @override
  Future<Map<String, int>> getMonthlySummary({
    required String userId,
    required int year,
    required int month,
  }) =>
      _remote.getMonthlySummary(userId: userId, year: year, month: month);
}
