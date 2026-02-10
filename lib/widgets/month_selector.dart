import 'package:flutter/material.dart';
import '../services/habit_service.dart';

class MonthSelector extends StatelessWidget {
  final int currentYear;
  final String currentMonth;
  final Function(int year, String month) onMonthChanged;

  const MonthSelector({
    super.key,
    required this.currentYear,
    required this.currentMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              // Mobile layout with prominent date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Month',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentMonth $currentYear',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showMonthPicker(context),
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Change Month', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // Desktop layout
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '$currentMonth $currentYear',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showMonthPicker(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MonthPickerDialog(
        currentYear: currentYear,
        currentMonth: currentMonth,
        onMonthChanged: onMonthChanged,
      ),
    );
  }
}

class MonthPickerDialog extends StatefulWidget {
  final int currentYear;
  final String currentMonth;
  final Function(int year, String month) onMonthChanged;

  const MonthPickerDialog({
    super.key,
    required this.currentYear,
    required this.currentMonth,
    required this.onMonthChanged,
  });

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int selectedYear;
  late String selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.currentYear;
    selectedMonth = widget.currentMonth;
  }

  @override
  Widget build(BuildContext context) {
    final months = HabitService.getAvailableMonths();
    final years = HabitService.getAvailableYears();

    return AlertDialog(
      title: const Text('Select Month'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year selector
            DropdownButtonFormField<int>(
              initialValue: selectedYear,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text('$year'),
                );
              }).toList(),
              onChanged: (year) {
                if (year != null) {
                  setState(() {
                    selectedYear = year;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Month selector
            DropdownButtonFormField<String>(
              initialValue: selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Month',
                border: OutlineInputBorder(),
              ),
              items: months.map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (month) {
                if (month != null) {
                  setState(() {
                    selectedMonth = month;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onMonthChanged(selectedYear, selectedMonth);
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
