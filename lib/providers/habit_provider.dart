import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../models/habit_state.dart';
import '../models/daily_stats.dart';
import '../services/habit_service.dart';

class HabitProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  HabitState? _habitState;
  List<Habit> _habits = [];
  DailyStats? _stats;
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedUserData = false; // Flag to prevent multiple loads

  // Getters
  HabitState? get habitState => _habitState;
  List<Habit> get habits => List.unmodifiable(_habits);
  DailyStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoadedUserData => _hasLoadedUserData;

  // Convenience getters
  List<Habit> get activeHabits => _habits.where((habit) => habit.isActive).toList();
  int get activeHabitCount => activeHabits.length;
  double get monthlyProgress => _stats?.monthlyProgress ?? 0.0;
  double get successRate => _stats?.successRate ?? 0.0;
  int get currentStreak => _stats?.currentStreak ?? 0;
  
  // Additional convenience methods
  int getTodayCompletedCount() {
    if (_habitState == null || _habits.isEmpty) return 0;
    final today = DateTime.now().day;
    return _habits.where((habit) => 
      habit.isActive && 
      today <= habit.dailyLogs.length && 
      habit.dailyLogs[today - 1]
    ).length;
  }
  
  int getCurrentStreak() {
    return _stats?.currentStreak ?? 0;
  }
  
  double getCompletionRate() {
    if (_habits.isEmpty) return 0.0;
    int totalPossible = 0;
    int totalCompleted = 0;
    
    for (final habit in _habits) {
      if (!habit.isActive) continue;
      for (int i = 0; i < habit.dailyLogs.length && i < DateTime.now().day; i++) {
        totalPossible++;
        if (habit.dailyLogs[i]) totalCompleted++;
      }
    }
    
    return totalPossible > 0 ? (totalCompleted / totalPossible * 100).roundToDouble() : 0.0;
  }

  Future<void> initializeMonth({required int year, required String month}) async {
    _setLoading(true);
    _clearError();

    try {
      final newHabitState = HabitService.createHabitState(year: year, month: month);
      
      // Resize existing habits if they exist
      if (_habits.isNotEmpty) {
        _habits = HabitService.resizeHabitsForMonth(
          habits: _habits,
          newDaysInMonth: newHabitState.daysInMonth,
        );
      }

      _habitState = newHabitState;
      await _recalculateStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize month: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addHabit({
    required String name,
    int? targetGoal,
  }) async {
    if (_habitState == null) {
      _setError('Please initialize a month first');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final newHabit = HabitService.createHabit(
        name: name,
        targetGoal: targetGoal,
        daysInMonth: _habitState!.daysInMonth,
      );

      _habits.add(newHabit);
      await _recalculateStats();
      await saveUserData(); // Save to Firestore
      notifyListeners();
    } catch (e) {
      _setError('Failed to add habit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateHabit({
    required String habitId,
    String? name,
    int? targetGoal,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final habitIndex = _habits.indexWhere((habit) => habit.id == habitId);
      if (habitIndex == -1) {
        throw Exception('Habit not found');
      }

      final habit = _habits[habitIndex];
      _habits[habitIndex] = habit.copyWith(
        name: name,
        targetGoal: targetGoal,
      );

      await _recalculateStats();
      await saveUserData(); // Save to Firestore
      notifyListeners();
    } catch (e) {
      _setError('Failed to update habit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteHabit({required String habitId}) async {
    _setLoading(true);
    _clearError();

    try {
      _habits.removeWhere((habit) => habit.id == habitId);
      await _recalculateStats();
      await saveUserData(); // Save to Firestore
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete habit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleHabitDay({
    required String habitId,
    required int dayIndex,
  }) async {
    _clearError();

    try {
      final habitIndex = _habits.indexWhere((habit) => habit.id == habitId);
      if (habitIndex == -1) {
        throw Exception('Habit not found');
      }

      final habit = _habits[habitIndex];
      _habits[habitIndex] = HabitService.toggleHabitDay(
        habit: habit,
        dayIndex: dayIndex,
      );

      await _recalculateStats();
      await saveUserData(); // Save to Firestore
      notifyListeners();
    } catch (e) {
      _setError('Failed to toggle habit: $e');
    }
  }

  Future<void> loadSampleData() async {
    if (_habitState == null) {
      _setError('Please initialize a month first');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final sampleHabits = [
        {'name': 'Stretch or do yoga', 'goal': 5},
        {'name': 'Read a book chapter', 'goal': 15},
        {'name': 'Meditate', 'goal': 20},
        {'name': 'Declutter a space', 'goal': 4},
        {'name': 'Exercise', 'goal': 10},
        {'name': 'Drink 8 glasses of water', 'goal': null}, // Daily habit
        {'name': 'Floss', 'goal': null}, // Daily habit
        {'name': 'Volunteer', 'goal': 3},
        {'name': 'Put \$10 to savings', 'goal': 10},
      ];

      _habits.clear();
      for (final habitData in sampleHabits) {
        final habit = HabitService.createHabit(
          name: habitData['name'] as String,
          targetGoal: habitData['goal'] as int?,
          daysInMonth: _habitState!.daysInMonth,
        );
        
        // Add some sample completions
        final updatedLogs = List<bool>.from(habit.dailyLogs);
        for (int i = 0; i < min(22, updatedLogs.length); i++) {
          if (Random().nextDouble() > 0.3) { // 70% chance of completion
            updatedLogs[i] = true;
          }
        }
        
        _habits.add(habit.copyWith(dailyLogs: updatedLogs));
      }

      await _recalculateStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load sample data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> exportData() async {
    if (_habitState == null || _stats == null) {
      _setError('No data to export');
      return;
    }

    try {
      final exportData = HabitService.exportData(
        habitState: _habitState!,
        habits: _habits,
        stats: _stats!,
      );
      
      // In a real app, you would save this to a file or send to a backend
      if (kDebugMode) {
        print('Export data: ${exportData.toString()}');
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to export data: $e');
    }
  }

  String getGraphData() {
    if (_stats == null) return '';
    return HabitService.exportGraphData(dailyTotals: _stats!.dailyTotals);
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // User-specific data management
  void clearUserData() {
    _habitState = null;
    _habits.clear();
    _stats = null;
    _hasLoadedUserData = false; // Reset flag
    _clearError();
    notifyListeners();
  }

  Future<void> loadUserData() async {
    if (_hasLoadedUserData) return; // Prevent multiple loads
    
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('No user logged in');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (!userDoc.exists) {
        _setError('User data not found');
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        _setError('User data is empty');
        return;
      }

      // Load habits data
      final List<dynamic> habitsData = userData['habits'] ?? [];
      _habits.clear();
      
      for (final habitData in habitsData) {
        try {
          final habit = Habit.fromJson(habitData as Map<String, dynamic>);
          _habits.add(habit);
        } catch (e) {
          if (kDebugMode) {
            print('Error loading habit: $e');
          }
        }
      }
      
      _hasLoadedUserData = true; // Mark as loaded
      notifyListeners();
      
    } catch (e) {
      _setError('Failed to load user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveUserData() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('No user logged in');
      return;
    }

    try {
      final habitsData = _habits.map((habit) => habit.toJson()).toList();
      
      await _firestore.collection('users').doc(currentUser.uid).update({
        'habits': habitsData,
        'lastUpdated': FieldValue.serverTimestamp(),
        'stats': {
          'totalHabits': _habits.length,
          'completedToday': getTodayCompletedCount(),
          'streak': currentStreak,
        },
      });
    } catch (e) {
      _setError('Failed to save user data: $e');
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<void> _recalculateStats() async {
    if (_habitState == null) return;
    
    _stats = HabitService.calculateStats(
      habitState: _habitState!,
      habits: _habits,
    );
  }
}
