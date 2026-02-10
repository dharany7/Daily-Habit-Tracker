import 'package:equatable/equatable.dart';

class DailyStats extends Equatable {
  final List<int> dailyTotals;
  final List<double> dailyEfficiency;
  final int totalChecks;
  final int totalCapacity;
  final double monthlyProgress;
  final double successRate;
  final int currentStreak;
  final int firstEmptyIndex;

  const DailyStats({
    required this.dailyTotals,
    required this.dailyEfficiency,
    required this.totalChecks,
    required this.totalCapacity,
    required this.monthlyProgress,
    required this.successRate,
    required this.currentStreak,
    required this.firstEmptyIndex,
  });

  static DailyStats calculate({
    required List<bool> daysElapsedMask,
    required List<int> dailyTotals,
    required int activeHabitCount,
    required List<double> habitProgressScores,
  }) {
    // Calculate daily efficiency
    final dailyEfficiency = dailyTotals.map((total) {
      return activeHabitCount > 0 ? total / activeHabitCount : 0.0;
    }).toList();

    // Calculate total checks and capacity
    final totalChecks = dailyTotals.reduce((a, b) => a + b);
    final totalCapacity = activeHabitCount * daysElapsedMask.where((mask) => mask).length;

    // Calculate monthly progress
    final monthlyProgress = totalCapacity > 0 ? totalChecks / totalCapacity : 0.0;

    // Calculate success rate (average of individual habit progress scores)
    final successRate = habitProgressScores.isNotEmpty
        ? habitProgressScores.reduce((a, b) => a + b) / habitProgressScores.length
        : 0.0;

    // Calculate current streak
    final currentStreak = _calculateCurrentStreak(
      dailyTotals: dailyTotals,
      daysElapsedMask: daysElapsedMask,
      activeHabitCount: activeHabitCount,
    );

    // Find first empty index
    final firstEmptyIndex = _findFirstEmptyIndex(
      dailyTotals: dailyTotals,
      daysElapsedMask: daysElapsedMask,
    );

    return DailyStats(
      dailyTotals: dailyTotals,
      dailyEfficiency: dailyEfficiency,
      totalChecks: totalChecks,
      totalCapacity: totalCapacity,
      monthlyProgress: monthlyProgress,
      successRate: successRate,
      currentStreak: currentStreak,
      firstEmptyIndex: firstEmptyIndex,
    );
  }

  static int _calculateCurrentStreak({
    required List<int> dailyTotals,
    required List<bool> daysElapsedMask,
    required int activeHabitCount,
  }) {
    int streak = 0;
    for (int i = dailyTotals.length - 1; i >= 0; i--) {
      if (!daysElapsedMask[i]) break;
      
      final efficiency = activeHabitCount > 0 
          ? dailyTotals[i] / activeHabitCount 
          : 0.0;
      
      if (efficiency >= 0.5) { // 50% threshold for successful day
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static int _findFirstEmptyIndex({
    required List<int> dailyTotals,
    required List<bool> daysElapsedMask,
  }) {
    for (int i = 0; i < dailyTotals.length; i++) {
      if (daysElapsedMask[i] && dailyTotals[i] == 0) {
        return i;
      }
    }
    return dailyTotals.length; // No empty days found
  }

  double get averageDailyEfficiency {
    if (dailyEfficiency.isEmpty) return 0.0;
    return dailyEfficiency.reduce((a, b) => a + b) / dailyEfficiency.length;
  }

  List<int> get lastThreeDaysTotals {
    final startIndex = (dailyTotals.length - 3).clamp(0, dailyTotals.length - 1);
    return dailyTotals.sublist(startIndex);
  }

  double get lastThreeDaysAverage {
    final lastThree = lastThreeDaysTotals;
    if (lastThree.isEmpty) return 0.0;
    return lastThree.reduce((a, b) => a + b) / lastThree.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyTotals': dailyTotals,
      'dailyEfficiency': dailyEfficiency,
      'totalChecks': totalChecks,
      'totalCapacity': totalCapacity,
      'monthlyProgress': monthlyProgress,
      'successRate': successRate,
      'currentStreak': currentStreak,
      'firstEmptyIndex': firstEmptyIndex,
    };
  }

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      dailyTotals: List<int>.from(json['dailyTotals']),
      dailyEfficiency: List<double>.from(json['dailyEfficiency']),
      totalChecks: json['totalChecks'],
      totalCapacity: json['totalCapacity'],
      monthlyProgress: json['monthlyProgress'].toDouble(),
      successRate: json['successRate'].toDouble(),
      currentStreak: json['currentStreak'],
      firstEmptyIndex: json['firstEmptyIndex'],
    );
  }

  @override
  List<Object?> get props => [
        dailyTotals,
        dailyEfficiency,
        totalChecks,
        totalCapacity,
        monthlyProgress,
        successRate,
        currentStreak,
        firstEmptyIndex,
      ];
}
