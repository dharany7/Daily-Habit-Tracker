import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_grid.dart';
import '../widgets/stats_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/add_habit_dialog.dart';
import 'ai_insights_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  void _initializeDashboard() {
    final provider = Provider.of<HabitProvider>(context, listen: false);
    final now = DateTime.now();
    provider.initializeMonth(
      year: now.year,
      month: _getMonthName(now.month),
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, User'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AIInsightsScreen(),
                ),
              );
            },
            tooltip: 'AI Insights',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _initializeDashboard(),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_habit',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Add Habit'),
                ),
              ),
              const PopupMenuItem(
                value: 'load_sample',
                child: ListTile(
                  leading: Icon(Icons.dataset),
                  title: Text('Load Sample Data'),
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.clearError,
                    child: const Text('Clear Error'),
                  ),
                ],
              ),
            );
          }

          if (provider.habitState == null) {
            return const Center(
              child: Text('Initializing...'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector
                MonthSelector(
                  currentYear: provider.habitState!.year,
                  currentMonth: provider.habitState!.month,
                  onMonthChanged: (year, month) {
                    provider.initializeMonth(
                      year: year,
                      month: month,
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Total Habits',
                        value: provider.activeHabits.length.toString(),
                        subtitle: 'Active habits',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Completed Today',
                        value: provider.getTodayCompletedCount().toString(),
                        subtitle: 'Habits done today',
                        icon: Icons.today,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Current Streak',
                        value: provider.getCurrentStreak().toString(),
                        subtitle: 'Days in a row',
                        icon: Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Completion Rate',
                        value: '${provider.getCompletionRate().toInt()}%',
                        subtitle: 'Monthly progress',
                        icon: Icons.trending_up,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Habit Grid
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Habit Tracker',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            TextButton.icon(
                              onPressed: () => _showAddHabitDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Habit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (provider.activeHabits.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.checklist,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No habits yet',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first habit to start tracking',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddHabitDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Your First Habit'),
                                ),
                              ],
                            ),
                          )
                        else
                          HabitGrid(
                            habitState: provider.habitState!,
                            habits: provider.activeHabits,
                            onToggle: (habitId, dayIndex) {
                              provider.toggleHabitDay(
                                habitId: habitId,
                                dayIndex: dayIndex,
                              );
                            },
                            onDelete: (habitId) {
                              provider.deleteHabit(habitId: habitId);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _handleMenuAction(String action) {
    final provider = Provider.of<HabitProvider>(context, listen: false);
    
    switch (action) {
      case 'add_habit':
        _showAddHabitDialog(context);
        break;
      case 'load_sample':
        provider.loadSampleData();
        break;
      case 'export':
        provider.exportData();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _showAddHabitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle logout logic here
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
