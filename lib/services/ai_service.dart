import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/habit.dart';
import '../models/habit_state.dart';
import '../models/daily_stats.dart';

class AIService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  Future<void> initialize(String apiKey) async {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize AI service: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  Future<String> generateHabitSuggestions({
    required List<Habit> existingHabits,
    required String userPreferences,
  }) async {
    if (!_isInitialized) {
      throw Exception('AI service not initialized');
    }

    final existingHabitsText = existingHabits
        .where((h) => h.isActive)
        .map((h) => '- ${h.name}')
        .join('\n');

    final prompt = '''
Based on the user's current habits and preferences, suggest 5 new habits they could add to their routine.

Current habits:
$existingHabitsText

User preferences: $userPreferences

Please provide:
1. A diverse mix of habits (health, productivity, personal growth, etc.)
2. Habits that complement their current routine
3. Both daily and goal-based options
4. Brief explanation for each suggestion

Format your response as a numbered list with each habit name and a short description.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No suggestions available';
    } catch (e) {
      throw Exception('Failed to generate suggestions: $e');
    }
  }

  Future<String> generateProgressInsight({
    required HabitState habitState,
    required List<Habit> habits,
    required DailyStats stats,
  }) async {
    if (!_isInitialized) {
      throw Exception('AI service not initialized');
    }

    final activeHabits = habits.where((h) => h.isActive).toList();
    final habitsText = activeHabits.map((habit) {
      final progress = habit.getCappedProgress(totalDays: habitState.daysInMonth);
      return '- ${habit.name}: ${(progress * 100).toStringAsFixed(1)}% complete (${habit.totalCompletions} checks)';
    }).join('\n');

    final prompt = '''
Analyze the user's habit tracking progress for ${habitState.month} ${habitState.year} and provide motivational insights and actionable advice.

Current Progress:
- Monthly Progress: ${(stats.monthlyProgress * 100).toStringAsFixed(1)}%
- Success Rate: ${(stats.successRate * 100).toStringAsFixed(1)}%
- Current Streak: ${stats.currentStreak} days
- Active Habits: ${activeHabits.length}

Individual Habits:
$habitsText

Please provide:
1. A motivational summary of their progress
2. Recognition of what they're doing well
3. 1-2 specific, actionable suggestions for improvement
4. Encouragement for maintaining momentum

Keep the tone supportive and encouraging. Be specific about their actual data.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No insights available';
    } catch (e) {
      throw Exception('Failed to generate insights: $e');
    }
  }

  Future<String> generateWeeklyPlan({
    required List<Habit> habits,
    required List<int> recentDailyTotals,
  }) async {
    if (!_isInitialized) {
      throw Exception('AI service not initialized');
    }

    final activeHabits = habits.where((h) => h.isActive).toList();
    final recentPerformance = recentDailyTotals.take(7).toList();
    final averageDaily = recentPerformance.isEmpty 
        ? 0.0 
        : recentPerformance.reduce((a, b) => a + b) / recentPerformance.length;

    final habitsText = activeHabits.map((habit) {
      return '- ${habit.name} (Goal: ${habit.targetGoal ?? 'Daily'})';
    }).join('\n');

    final prompt = '''
Create a focused weekly plan to help the user improve their habit consistency.

Current Situation:
- Active Habits: ${activeHabits.length}
- Recent daily average: ${averageDaily.toStringAsFixed(1)} habits per day
- Recent performance: $recentPerformance

Habits:
$habitsText

Please provide:
1. A realistic daily target for the upcoming week
2. 2-3 specific focus areas for improvement
3. A simple strategy to stay on track
4. A motivational quote for the week

Keep it practical and encouraging. The plan should feel achievable, not overwhelming.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No plan available';
    } catch (e) {
      throw Exception('Failed to generate weekly plan: $e');
    }
  }

  Future<String> answerHabitQuestion({
    required String question,
    required List<Habit> habits,
  }) async {
    if (!_isInitialized) {
      throw Exception('AI service not initialized');
    }

    final habitsText = habits
        .where((h) => h.isActive)
        .map((h) => '- ${h.name} (Goal: ${h.targetGoal ?? 'Daily'}, Progress: ${(h.getCappedProgress(totalDays: 31) * 100).toStringAsFixed(1)}%)')
        .join('\n');

    final prompt = '''
The user has a question about their habit tracking routine. Answer it helpfully based on their current habits and progress.

Current Habits:
$habitsText

User Question: $question

Please provide:
1. A direct answer to their question
2. Specific advice related to their actual habits
3. Actionable suggestions if relevant
4. Keep it concise and practical

Focus on habit science, motivation, and practical strategies.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'I cannot answer that question right now.';
    } catch (e) {
      throw Exception('Failed to answer question: $e');
    }
  }

  void dispose() {
    // Clean up any resources if needed
    _isInitialized = false;
  }
}
