import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/features/wallet/domain/entities/category_entity.dart';
import 'package:nyimpeun/features/wallet/domain/repositories/wallet_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class CategoryState {
  const CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<CategoryEntity> categories;
  final bool isLoading;
  final String? errorMessage;

  List<CategoryEntity> get incomeCategories =>
      categories.where((c) => c.isIncome).toList();

  List<CategoryEntity> get expenseCategories =>
      categories.where((c) => c.isExpense).toList();

  CategoryState copyWith({
    List<CategoryEntity>? categories,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CategoryNotifier extends StateNotifier<CategoryState> {
  CategoryNotifier({required this._repository}) : super(const CategoryState());

  final WalletRepository _repository;

  Future<void> loadCategories(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cats = await _repository.getCategories(userId);
      state = state.copyWith(categories: cats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<CategoryEntity?> addCategory({
    required String userId,
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      final created = await _repository.createCategory(
        CategoryEntity(
          id: '',
          userId: userId,
          name: name,
          type: type,
          icon: icon,
          color: color,
        ),
      );
      state = state.copyWith(
        categories: [...state.categories, created],
      );
      return created;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final prev = state.categories;
    state = state.copyWith(
      categories: prev.where((c) => c.id != categoryId).toList(),
    );
    try {
      await _repository.deleteCategory(categoryId);
    } catch (e) {
      state = state.copyWith(categories: prev, errorMessage: e.toString());
    }
  }
}
