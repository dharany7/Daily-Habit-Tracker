import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  bool _isDailyHabit = true;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Habit'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Habit name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g., Exercise, Read, Meditate',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
                autofocus: true,
              ),
              
              const SizedBox(height: 16),
              
              // Habit type selector
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Daily Habit'),
                      subtitle: const Text('Track every day'),
                      value: true,
                      groupValue: _isDailyHabit,
                      onChanged: (value) {
                        setState(() {
                          _isDailyHabit = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Goal Based'),
                      subtitle: const Text('X times per month'),
                      value: false,
                      groupValue: _isDailyHabit,
                      onChanged: (value) {
                        setState(() {
                          _isDailyHabit = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Goal input (only for goal-based habits)
              if (!_isDailyHabit) ...[
                TextFormField(
                  controller: _goalController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Goal',
                    hintText: 'e.g., 15',
                    border: OutlineInputBorder(),
                    suffixText: 'times',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (!_isDailyHabit) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a goal';
                      }
                      final goal = int.tryParse(value);
                      if (goal == null || goal <= 0) {
                        return 'Please enter a valid positive number';
                      }
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'This habit will be considered complete when you check it off ${_goalController.text.isEmpty ? 'X' : _goalController.text} times this month.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                Text(
                  'This habit will be tracked every day. Perfect for daily routines like flossing, taking vitamins, etc.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addHabit,
          child: const Text('Add Habit'),
        ),
      ],
    );
  }

  void _addHabit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final goal = !_isDailyHabit ? int.tryParse(_goalController.text) : null;

    try {
      final provider = context.read<HabitProvider>();
      await provider.addHabit(
        name: name,
        targetGoal: goal,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add habit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
