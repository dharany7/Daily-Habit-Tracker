import 'dart:math';
import '../models/habit.dart';
import '../models/habit_state.dart';
import '../models/daily_stats.dart';

class HabitService {
  static HabitState createHabitState({required int year, required String month}) {
    return HabitState.create(year: year, month: month);
  }

  static Habit createHabit({
    required String name,
    int? targetGoal,
    required int daysInMonth,
  }) {
    final id = _generateId();
    return Habit.empty(
      id: id,
      name: name,
      targetGoal: targetGoal,
      daysInMonth: daysInMonth,
    );
  }

  static Habit toggleHabitDay({
    required Habit habit,
    required int dayIndex,
  }) {
    if (dayIndex < 0 || dayIndex >= habit.dailyLogs.length) {
      return habit;
    }

    final updatedLogs = List<bool>.from(habit.dailyLogs);
    updatedLogs[dayIndex] = !updatedLogs[dayIndex];

    return habit.copyWith(dailyLogs: updatedLogs);
  }

  static List<int> calculateDailyTotals({required List<Habit> habits}) {
    if (habits.isEmpty) return [];

    final daysInMonth = habits.first.dailyLogs.length;
    final dailyTotals = List<int>.filled(daysInMonth, 0);

    for (final habit in habits) {
      if (!habit.isActive) continue;

      for (int i = 0; i < habit.dailyLogs.length; i++) {
        if (habit.dailyLogs[i]) {
          dailyTotals[i]++;
        }
      }
    }

    return dailyTotals;
  }

  static DailyStats calculateStats({
    required HabitState habitState,
    required List<Habit> habits,
  }) {
    final activeHabits = habits.where((habit) => habit.isActive).toList();
    
    if (activeHabits.isEmpty) {
      return DailyStats(
        dailyTotals: List.filled(habitState.daysInMonth, 0),
        dailyEfficiency: List.filled(habitState.daysInMonth, 0.0),
        totalChecks: 0,
        totalCapacity: 0,
        monthlyProgress: 0.0,
        successRate: 0.0,
        currentStreak: 0,
        firstEmptyIndex: 0,
      );
    }

    final dailyTotals = calculateDailyTotals(habits: activeHabits);
    final habitProgressScores = activeHabits
        .map((habit) => habit.getCappedProgress(totalDays: habitState.daysInMonth))
        .toList();

    return DailyStats.calculate(
      daysElapsedMask: habitState.daysElapsedMask,
      dailyTotals: dailyTotals,
      activeHabitCount: activeHabits.length,
      habitProgressScores: habitProgressScores,
    );
  }

  static int getTotalGoalsDefined({required List<Habit> habits, required int totalDays}) {
    int total = 0;
    for (final habit in habits) {
      if (!habit.isActive) continue;
      
      if (habit.targetGoal != null && habit.targetGoal! > 0) {
        total += habit.targetGoal!;
      } else {
        total += totalDays;
      }
    }
    return total;
  }

  static int getTotalHabitsExecuted({required List<Habit> habits}) {
    return habits
        .where((habit) => habit.isActive)
        .fold(0, (sum, habit) => sum + habit.totalCompletions);
  }

  static List<Habit> resizeHabitsForMonth({
    required List<Habit> habits,
    required int newDaysInMonth,
  }) {
    return habits.map((habit) {
      final currentLength = habit.dailyLogs.length;
      
      if (currentLength == newDaysInMonth) {
        return habit;
      }

      final newLogs = List<bool>.filled(newDaysInMonth, false);
      
      // Copy existing logs to the new array
      final copyLength = min(currentLength, newDaysInMonth);
      for (int i = 0; i < copyLength; i++) {
        newLogs[i] = habit.dailyLogs[i];
      }

      return habit.copyWith(dailyLogs: newLogs);
    }).toList();
  }

  static String exportGraphData({required List<int> dailyTotals}) {
    return dailyTotals.join(',');
  }

  static bool normalizeInput(String? input) {
    if (input == null || input.trim().isEmpty) return false;
    
    final normalized = input.trim().toUpperCase();
    return normalized == 'X' || normalized == 'TRUE' || normalized == '1';
  }

  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'habit_${timestamp}_$random';
  }

  static Map<String, dynamic> exportData({
    required HabitState habitState,
    required List<Habit> habits,
    required DailyStats stats,
  }) {
    return {
      'meta': {
        'year': habitState.year,
        'month': habitState.month,
        'totalGoals': getTotalGoalsDefined(habits: habits, totalDays: habitState.daysInMonth),
        'exportDate': DateTime.now().toIso8601String(),
      },
      'habits': habits.map((habit) => habit.toJson()).toList(),
      'dailyStats': stats.toJson(),
      'habitState': habitState.toJson(),
    };
  }

  static List<String> getAvailableMonths() {
    return [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
  }

  static List<int> getAvailableYears({int range = 5}) {
    final currentYear = DateTime.now().year;
    return List.generate(range * 2 + 1, (index) => currentYear - range + index);
  }
}
