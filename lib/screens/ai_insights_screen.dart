import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../services/ai_service.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final _questionController = TextEditingController();
  bool _isLoading = false;
  String? _insight;
  String? _suggestions;
  String? _weeklyPlan;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<HabitProvider>();
      final aiService = context.read<AIService>();
      
      // Initialize AI service if needed (you'll need to provide API key)
      // await aiService.initialize('your-gemini-api-key');
      
      if (provider.habitState != null && provider.stats != null) {
        // Generate progress insight
        // _insight = await aiService.generateProgressInsight(
        //   habitState: provider.habitState!,
        //   habits: provider.habits,
        //   stats: provider.stats!,
        // );
        
        // Generate habit suggestions
        // _suggestions = await aiService.generateHabitSuggestions(
        //   existingHabits: provider.habits,
        //   userPreferences: 'I want to improve my health and productivity',
        // );
        
        // Generate weekly plan
        // _weeklyPlan = await aiService.generateWeeklyPlan(
        //   habits: provider.habits,
        //   recentDailyTotals: provider.stats?.dailyTotals ?? [],
        // );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load AI insights: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<HabitProvider>();
      final aiService = context.read<AIService>();
      
      // final answer = await aiService.answerHabitQuestion(
      //   question: question,
      //   habits: provider.habits,
      // );
      
      // Show answer in dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('AI Answer'),
            content: const Text('AI features require Gemini API key. See setup instructions.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get answer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Setup Notice
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'AI Features Setup Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To enable AI insights, add your Gemini API key in the AI service initialization.',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Get API key from Google AI Studio\n'
                      '2. Add it to AIService.initialize() in main.dart\n'
                      '3. Restart the app',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Progress Insight
            _buildInsightCard(
              title: 'Progress Analysis',
              icon: Icons.analytics,
              content: _insight ?? 'AI analysis of your habit progress will appear here.',
              isLoading: _isLoading,
            ),
            
            const SizedBox(height: 16),
            
            // Habit Suggestions
            _buildInsightCard(
              title: 'Habit Suggestions',
              icon: Icons.lightbulb,
              content: _suggestions ?? 'Personalized habit suggestions will appear here.',
              isLoading: _isLoading,
            ),
            
            const SizedBox(height: 16),
            
            // Weekly Plan
            _buildInsightCard(
              title: 'Weekly Plan',
              icon: Icons.calendar_today,
              content: _weeklyPlan ?? 'Your weekly habit plan will appear here.',
              isLoading: _isLoading,
            ),
            
            const SizedBox(height: 24),
            
            // Ask AI Question
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask AI Assistant',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        labelText: 'Your question about habits',
                        hintText: 'e.g., How can I stay motivated?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _askQuestion,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.question_answer),
                        label: Text(_isLoading ? 'Thinking...' : 'Ask AI'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required IconData icon,
    required String content,
    required bool isLoading,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
