import 'package:cloud_functions/cloud_functions.dart';
import '../models/habit.dart';
import '../models/habit_state.dart';
import '../models/daily_stats.dart';

class CloudFunctionsService {
  late final FirebaseFunctions _functions;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      _functions = FirebaseFunctions.instance;
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Cloud Functions: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  Future<Map<String, dynamic>> syncDataToCloud({
    required String userId,
    required HabitState habitState,
    required List<Habit> habits,
    required DailyStats stats,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('syncHabitData').call({
        'userId': userId,
        'habitState': habitState.toJson(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'stats': stats.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to sync data to cloud: $e');
    }
  }

  Future<Map<String, dynamic>> loadDataFromCloud({
    required String userId,
    required int year,
    required String month,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('loadHabitData').call({
        'userId': userId,
        'year': year,
        'month': month,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load data from cloud: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistoricalData({
    required String userId,
    int? limitMonths,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('getHistoricalData').call({
        'userId': userId,
        'limitMonths': limitMonths ?? 12,
      });

      final data = result.data as List;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get historical data: $e');
    }
  }

  Future<Map<String, dynamic>> exportUserData({
    required String userId,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('exportUserData').call({
        'userId': userId,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  Future<Map<String, dynamic>> generateAnalyticsReport({
    required String userId,
    required int year,
    required String month,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('generateAnalytics').call({
        'userId': userId,
        'year': year,
        'month': month,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to generate analytics report: $e');
    }
  }

  Future<Map<String, dynamic>> backupData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('backupData').call({
        'userId': userId,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to backup data: $e');
    }
  }

  Future<Map<String, dynamic>> restoreData({
    required String userId,
    required String backupId,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('restoreData').call({
        'userId': userId,
        'backupId': backupId,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to restore data: $e');
    }
  }

  Future<Map<String, dynamic>> shareProgress({
    required String userId,
    required int year,
    required String month,
    required bool includeDetails,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('shareProgress').call({
        'userId': userId,
        'year': year,
        'month': month,
        'includeDetails': includeDetails,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to share progress: $e');
    }
  }

  Future<Map<String, dynamic>> updateSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('updateSettings').call({
        'userId': userId,
        'settings': settings,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  Future<Map<String, dynamic>> getUserSettings({
    required String userId,
  }) async {
    if (!_isInitialized) {
      throw Exception('Cloud Functions service not initialized');
    }

    try {
      final result = await _functions.httpsCallable('getUserSettings').call({
        'userId': userId,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get user settings: $e');
    }
  }

  void dispose() {
    // Clean up any resources if needed
    _isInitialized = false;
  }
}
