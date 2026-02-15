import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_state.dart';

class HabitGrid extends StatelessWidget {
  final HabitState habitState;
  final List<Habit> habits;
  final Function(String habitId, int dayIndex) onToggle;
  final Function(String habitId) onDelete;

  const HabitGrid({
    super.key,
    required this.habitState,
    required this.habits,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600; // Mobile breakpoint

    if (isMobile) {
      return _buildMobileLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Mobile header with current date prominently displayed
        _buildMobileHeader(context),

        const SizedBox(height: 16),

        // Mobile habit list with accessible checkboxes
        ...habits.map((habit) => _buildMobileHabitCard(context, habit)),

        const SizedBox(height: 16),

        // Mobile footer stats
        _buildMobileFooterStats(context),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    final today = DateTime.now();
    final todayStr = '${today.day} ${_getMonthName(today.month)} ${today.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Date',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            todayStr,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap on a date to mark progress',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHabitCard(BuildContext context, Habit habit) {
    final progress = habit.getCappedProgress(totalDays: habitState.daysInMonth);
    final todayIndex = DateTime.now().day - 1; // 0-based index

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit name and delete button
            Row(
              children: [
                Expanded(
                  child: Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(context, habit.id),
                  tooltip: 'Delete Habit',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Goal and progress info
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    habit.targetGoal?.toString() ?? 'Daily',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% Complete',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: progress >= 1.0
                            ? Colors.green
                            : progress >= 0.5
                                ? Theme.of(context).colorScheme.primary
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Scrollable interactive date strip

            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: habitState.daysInMonth,
                // Scroll to end to show latest days primarily
                controller: ScrollController(
                  initialScrollOffset:
                      (todayIndex * 40.0).clamp(0.0, double.infinity),
                ),
                itemBuilder: (context, index) {
                  final isCompleted = habit.dailyLogs[index];
                  final dayNum = index + 1;
                  final isToday = index == todayIndex;
                  final isFuture = index > todayIndex;

                  return GestureDetector(
                    onTap: isFuture ? null : () => onToggle(habit.id, index),
                    child: Container(
                      width: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : isFuture
                                ? Colors.grey[200]
                                : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNum',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isCompleted
                                        ? Colors.white
                                        : isFuture
                                            ? Colors.grey[400]
                                            : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFooterStats(BuildContext context) {
    // Calculate daily totals
    final dailyTotals = List<int>.filled(habitState.daysInMonth, 0);
    for (final habit in habits) {
      for (int i = 0; i < habit.dailyLogs.length; i++) {
        if (habit.dailyLogs[i]) {
          dailyTotals[i]++;
        }
      }
    }

    final totalChecks = dailyTotals.reduce((a, b) => a + b);
    final totalPossible = habits.length * habitState.daysElapsed;
    final monthlyProgress =
        totalPossible > 0 ? totalChecks / totalPossible : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMobileStatItem(
                  context,
                  'Total Checks',
                  '$totalChecks',
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildMobileStatItem(
                  context,
                  'Progress',
                  '${(monthlyProgress * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Fixed widths for metadata columns
        const nameWidth = 190.0;
        const goalWidth = 60.0;
        const progressWidth = 80.0;
        const fixedMetadataWidth = nameWidth + goalWidth + progressWidth;

        // Calculate day width
        final remainingWidth = availableWidth - fixedMetadataWidth;
        final daysCount = habitState.daysInMonth;
        var dayWidth = remainingWidth / daysCount;

        // Enforce a minimum day width for usability
        const minDayWidth = 32.0;
        final bool needsScrolling = dayWidth < minDayWidth;

        if (needsScrolling) {
          dayWidth = minDayWidth;
        }

        final content = Column(
          children: [
            // Desktop header row with day numbers and weekday labels
            _buildHeaderRow(context, dayWidth),

            const SizedBox(height: 8),

            // Desktop habit rows
            ...habits.map((habit) => _buildHabitRow(context, habit, dayWidth)),

            const SizedBox(height: 16),

            // Desktop footer stats
            _buildFooterStats(context),
          ],
        );

        if (needsScrolling) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: fixedMetadataWidth + (dayWidth * daysCount),
              child: content,
            ),
          );
        } else {
          return content;
        }
      },
    );
  }

  Widget _buildHeaderRow(BuildContext context, double dayWidth) {
    return Row(
      children: [
        // Habit name column (wider for delete button)
        SizedBox(
          width: 190,
          child: Text(
            'Habit',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        // Goal column
        SizedBox(
          width: 60,
          child: Text(
            'Goal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        // Progress column
        SizedBox(
          width: 80,
          child: Text(
            'Progress',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        // Day columns
        ...List.generate(habitState.daysInMonth, (index) {
          final isToday = _isToday(index, habitState);

          return SizedBox(
            width: dayWidth,
            child: Column(
              children: [
                Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  habitState.dayLabels[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHabitRow(BuildContext context, Habit habit, double dayWidth) {
    final progress = habit.getCappedProgress(totalDays: habitState.daysInMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Habit name with delete button
          SizedBox(
            width: 190,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    habit.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _showDeleteConfirmation(context, habit.id),
                  tooltip: 'Delete Habit',
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // Goal
          SizedBox(
            width: 60,
            child: Text(
              habit.targetGoal?.toString() ?? 'Daily',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),

          // Progress
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progress >= 1.0
                            ? Colors.green
                            : progress >= 0.5
                                ? Colors.orange
                                : Colors.red,
                      ),
                ),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0
                        ? Colors.green
                        : progress >= 0.5
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(habitState.daysInMonth, (index) {
            final isCompleted = habit.dailyLogs[index];
            final isPast = habitState.daysElapsedMask[index];
            final isToday = _isToday(index, habitState);

            return SizedBox(
              width: dayWidth,
              height: 32,
              child: GestureDetector(
                onTap: isPast ? () => onToggle(habit.id, index) : null,
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : isPast
                            ? Colors.grey[200]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2)
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooterStats(BuildContext context) {
    // Calculate daily totals
    final dailyTotals = List<int>.filled(habitState.daysInMonth, 0);
    for (final habit in habits) {
      for (int i = 0; i < habit.dailyLogs.length; i++) {
        if (habit.dailyLogs[i]) {
          dailyTotals[i]++;
        }
      }
    }

    final totalChecks = dailyTotals.reduce((a, b) => a + b);
    final totalPossible = habits.length * habitState.daysElapsed;
    final monthlyProgress =
        totalPossible > 0 ? totalChecks / totalPossible : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Checks',
                  '$totalChecks',
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Monthly Progress',
                  '${(monthlyProgress * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Daily totals mini chart
          Text(
            'Daily Activity',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: Row(
              children: List.generate(habitState.daysInMonth, (index) {
                final value = dailyTotals[index];
                final maxValue = habits.length;
                final height = maxValue > 0 ? (value / maxValue) * 40 : 0.0;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: value > 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isToday(int dayIndex, HabitState habitState) {
    final today = DateTime.now();
    final checkDate = habitState.startDate.add(Duration(days: dayIndex));
    return checkDate.year == today.year &&
        checkDate.month == today.month &&
        checkDate.day == today.day;
  }

  void _showDeleteConfirmation(BuildContext context, String habitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text(
            'Are you sure you want to delete this habit? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete(habitId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
