import 'package:dio/dio.dart';
import 'package:nyimpeun/core/constants/supabase_constants.dart';
import 'package:nyimpeun/core/errors/app_exception.dart';
import 'package:nyimpeun/core/network/api_interceptor.dart';
import 'package:nyimpeun/features/savings/data/models/savings_contribution_model.dart';
import 'package:nyimpeun/features/savings/data/models/savings_goal_model.dart';

class SavingsRemoteDataSource {
  SavingsRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ─── Goals ─────────────────────────────────────────────────────────────────

  Future<List<SavingsGoalModel>> getGoals(String userId) async {
    try {
      final response = await _dio.get(
        '${SupabaseConstants.restEndpoint}/savings_goals',
        queryParameters: {
          'user_id': 'eq.$userId',
          'order': 'created_at.desc',
          'select': '*,wallets(name)',
        },
      );
      final list = response.data as List;
      return list
          .map((e) => SavingsGoalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<SavingsGoalModel> createGoal(SavingsGoalModel model) async {
    try {
      final response = await _dio.post(
        '${SupabaseConstants.restEndpoint}/savings_goals',
        data: model.toInsertJson(),
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      final list = response.data as List;
      return SavingsGoalModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<SavingsGoalModel> updateGoal(
      String goalId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        '${SupabaseConstants.restEndpoint}/savings_goals',
        queryParameters: {'id': 'eq.$goalId'},
        data: data,
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      final list = response.data as List;
      return SavingsGoalModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _dio.delete(
        '${SupabaseConstants.restEndpoint}/savings_goals',
        queryParameters: {'id': 'eq.$goalId'},
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ─── Contributions ─────────────────────────────────────────────────────────

  Future<List<SavingsContributionModel>> getContributions(
      String goalId) async {
    try {
      final response = await _dio.get(
        '${SupabaseConstants.restEndpoint}/savings_contributions',
        queryParameters: {
          'goal_id': 'eq.$goalId',
          'order': 'created_at.desc',
          'select': '*',
        },
      );
      final list = response.data as List;
      return list
          .map((e) =>
              SavingsContributionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<SavingsContributionModel> addContribution(
      SavingsContributionModel model) async {
    try {
      final response = await _dio.post(
        '${SupabaseConstants.restEndpoint}/savings_contributions',
        data: model.toInsertJson(),
        options: Options(headers: {'Prefer': 'return=representation'}),
      );
      final list = response.data as List;
      return SavingsContributionModel.fromJson(
          list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}
