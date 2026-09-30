import 'package:dio/dio.dart';
import 'package:nyimpeun/core/constants/supabase_constants.dart';
import 'package:nyimpeun/core/errors/app_exception.dart';
import 'package:nyimpeun/features/wallet/data/models/category_model.dart';
import 'package:nyimpeun/features/wallet/data/models/transaction_model.dart';
import 'package:nyimpeun/features/wallet/data/models/wallet_model.dart';

class WalletRemoteDataSource {
  WalletRemoteDataSource({required this._dio});

  final Dio _dio;

  // ─── Wallets ───────────────────────────────────────────────────────────────

  Future<List<WalletModel>> getWallets(String userId) async {
    try {
      final response = await _dio.get(
        '${SupabaseConstants.restEndpoint}/wallets',
        queryParameters: {
          'user_id': 'eq.$userId',
          'order': 'is_default.desc,created_at.asc',
          'select': '*',
        },
      );
      final list = response.data as List;
      return list.map((e) => WalletModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<WalletModel> createWallet(WalletModel model) async {
    try {
      final response = await _dio.post(
        '${SupabaseConstants.restEndpoint}/wallets',
        data: model.toInsertJson(),
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      final list = response.data as List;
      return WalletModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<WalletModel> updateWallet(String walletId, Map<String, dynamic> data) async {
    try {
      // If setting as default, first un-default all other wallets for this user
      if (data['is_default'] == true) {
        final userId = data['user_id'];
        if (userId != null) {
          await _dio.patch(
            '${SupabaseConstants.restEndpoint}/wallets',
            queryParameters: {
              'user_id': 'eq.$userId',
              'id': 'neq.$walletId',
            },
            data: {'is_default': false},
          );
        }
      }

      final response = await _dio.patch(
        '${SupabaseConstants.restEndpoint}/wallets',
        queryParameters: {'id': 'eq.$walletId'},
        data: data,
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      final list = response.data as List;
      return WalletModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<void> deleteWallet(String walletId) async {
    try {
      await _dio.delete(
        '${SupabaseConstants.restEndpoint}/wallets',
        queryParameters: {'id': 'eq.$walletId'},
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ─── Transactions ──────────────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions({
    required String userId,
    String? walletId,
    String? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{
        'user_id': 'eq.$userId',
        'order': 'date.desc,created_at.desc',
        'limit': limit,
        'offset': offset,
        'select': '*, wallets(name), categories(name, icon, color)',
      };

      if (walletId != null) params['wallet_id'] = 'eq.$walletId';
      if (categoryId != null) params['category_id'] = 'eq.$categoryId';
      if (type != null) params['type'] = 'eq.$type';
      final dateFilters = <String>[];
      if (startDate != null) dateFilters.add('gte.${startDate.toUtc().toIso8601String()}');
      if (endDate != null) dateFilters.add('lte.${endDate.toUtc().toIso8601String()}');
      
      if (dateFilters.isNotEmpty) {
        if (dateFilters.length == 1) {
          params['date'] = dateFilters.first;
        } else {
          // Dio will convert list to date=gte...&date=lte...
          params['date'] = dateFilters;
        }
      }

      final response = await _dio.get(
        '${SupabaseConstants.restEndpoint}/transactions',
        queryParameters: params,
      );
      final list = response.data as List;
      return list
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<TransactionModel> createTransaction(TransactionModel model) async {
    try {
      final response = await _dio.post(
        '${SupabaseConstants.restEndpoint}/transactions',
        data: model.toInsertJson(),
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      final list = response.data as List;
      return TransactionModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<TransactionModel> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        '${SupabaseConstants.restEndpoint}/transactions',
        queryParameters: {'id': 'eq.$transactionId'},
        data: data,
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      final list = response.data as List;
      return TransactionModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _dio.delete(
        '${SupabaseConstants.restEndpoint}/transactions',
        queryParameters: {'id': 'eq.$transactionId'},
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ─── Categories ────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories(String userId) async {
    try {
      final response = await _dio.get(
        '${SupabaseConstants.restEndpoint}/categories',
        queryParameters: {
          'or': '(user_id.eq.$userId,is_default.eq.true)',
          'order': 'is_default.desc,name.asc',
          'select': '*',
        },
      );
      final list = response.data as List;
      return list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<CategoryModel> createCategory(CategoryModel model) async {
    try {
      final response = await _dio.post(
        '${SupabaseConstants.restEndpoint}/categories',
        data: model.toInsertJson(),
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      final list = response.data as List;
      return CategoryModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _dio.delete(
        '${SupabaseConstants.restEndpoint}/categories',
        queryParameters: {'id': 'eq.$categoryId'},
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ─── Summary ───────────────────────────────────────────────────────────────

  Future<Map<String, int>> getMonthlySummary({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final response = await _dio.get(
        '${SupabaseConstants.restEndpoint}/transactions',
        queryParameters: {
          'user_id': 'eq.$userId',
          'date': 'gte.${start.toIso8601String()}',
          'select': 'type,amount',
        },
      );

      // Apply end date filter via header (Supabase PostgREST supports AND via multiple params)
      final list = (response.data as List)
          .map((e) => e as Map<String, dynamic>)
          .where((e) {
        final d = DateTime.tryParse(e['date']?.toString() ?? '');
        return d != null && d.isBefore(end);
      }).toList();

      int totalIncome = 0;
      int totalExpense = 0;
      for (final item in list) {
        final amount = (item['amount'] as num?)?.toInt() ?? 0;
        if (item['type'] == 'income') {
          totalIncome += amount;
        } else if (item['type'] == 'expense') {
          totalExpense += amount;
        }
      }

      return {'income': totalIncome, 'expense': totalExpense};
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}

/// Helper from auth — reused for wallet errors too
AppException handleDioException(DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout) {
    return const NetworkException();
  }
  final statusCode = e.response?.statusCode;
  if (statusCode == 401) return const AuthException();
  if (statusCode == 404) return const NotFoundException();
  return ServerException(
    e.response?.data?.toString() ?? e.message ?? 'Server error',
    statusCode: statusCode,
  );
}
