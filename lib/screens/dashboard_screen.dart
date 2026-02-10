import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/auth_provider.dart';
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
  Widget build(BuildContext context) {
    return Consumer2<HabitProvider, AuthProvider>(
      builder: (context, habitProvider, authProvider, child) {
        // Handle user authentication changes
        if (authProvider.isAuthenticated && !habitProvider.hasLoadedUserData && !habitProvider.isLoading) {
          // User just logged in, load their data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            habitProvider.loadUserData();
          });
        }

        // Initialize month if not already done (only after user data is loaded)
        if (habitProvider.habitState == null && authProvider.isAuthenticated && !habitProvider.isLoading && habitProvider.hasLoadedUserData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final now = DateTime.now();
            habitProvider.initializeMonth(
              year: now.year,
              month: _getMonthName(now.month),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Habit Tracker'),
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
                onPressed: () async {
                  final now = DateTime.now();
                  await habitProvider.initializeMonth(
                    year: now.year,
                    month: _getMonthName(now.month),
                  );
                },
                tooltip: 'Refresh',
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value, habitProvider, authProvider),
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
          body: habitProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : habitProvider.error != null
                  ? Center(
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
                            'Error: ${habitProvider.error}',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: habitProvider.clearError,
                            child: const Text('Clear Error'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        final now = DateTime.now();
                        await habitProvider.initializeMonth(
                          year: now.year,
                          month: _getMonthName(now.month),
                        );
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MonthSelector(
                              currentYear: habitProvider.habitState?.year ?? DateTime.now().year,
                              currentMonth: habitProvider.habitState?.month ?? _getMonthName(DateTime.now().month),
                              onMonthChanged: (year, month) async {
                                await habitProvider.initializeMonth(
                                  year: year,
                                  month: month,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: StatsCard(
                                    title: 'Success Rate',
                                    value: '${(habitProvider.successRate * 100).toStringAsFixed(1)}%',
                                    subtitle: 'This month',
                                    icon: Icons.trending_up,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: StatsCard(
                                    title: 'Current Streak',
                                    value: '${habitProvider.currentStreak}',
                                    subtitle: 'Days in a row',
                                    icon: Icons.local_fire_department,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            StatsCard(
                              title: 'Monthly Progress',
                              value: '${(habitProvider.monthlyProgress * 100).toStringAsFixed(1)}%',
                              subtitle: 'Overall completion',
                              icon: Icons.assessment,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Habits',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddHabitDialog(context, habitProvider),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Habit'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            habitProvider.habits.isEmpty
                                ? Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.track_changes,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No habits yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Add your first habit to get started!',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () => _showAddHabitDialog(context, habitProvider),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Your First Habit'),
                                        ),
                                      ],
                                    ),
                                  )
                                : HabitGrid(
                                    habitState: habitProvider.habitState!,
                                    habits: habitProvider.habits,
                                    onToggle: (habitId, dayIndex) {
                                      habitProvider.toggleHabitDay(
                                        habitId: habitId,
                                        dayIndex: dayIndex,
                                      );
                                    },
                                    onDelete: (habitId) {
                                      habitProvider.deleteHabit(habitId: habitId);
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddHabitDialog(context, habitProvider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action, HabitProvider habitProvider, AuthProvider authProvider) {
    switch (action) {
      case 'add_habit':
        _showAddHabitDialog(context, habitProvider);
        break;
      case 'load_sample':
        habitProvider.loadSampleData();
        break;
      case 'export':
        habitProvider.exportData();
        break;
      case 'logout':
        _handleLogout(context, authProvider);
        break;
    }
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) {
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
              authProvider.signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, HabitProvider habitProvider) {
    showDialog(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
