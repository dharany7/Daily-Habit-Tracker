import 'package:equatable/equatable.dart';

class Habit extends Equatable {
  final String id;
  final String name;
  final int? targetGoal;
  final List<bool> dailyLogs;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Habit({
    required this.id,
    required this.name,
    this.targetGoal,
    required this.dailyLogs,
    required this.createdAt,
    this.updatedAt,
  });

  factory Habit.empty({
    required String id,
    required String name,
    int? targetGoal,
    required int daysInMonth,
  }) {
    return Habit(
      id: id,
      name: name,
      targetGoal: targetGoal,
      dailyLogs: List<bool>.filled(daysInMonth, false),
      createdAt: DateTime.now(),
    );
  }

  Habit copyWith({
    String? id,
    String? name,
    int? targetGoal,
    List<bool>? dailyLogs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      targetGoal: targetGoal ?? this.targetGoal,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isActive => name.isNotEmpty;

  int get totalCompletions {
    return dailyLogs.where((log) => log).length;
  }

  double calculateProgress({required int totalDays}) {
    if (!isActive) return 0.0;
    
    final denominator = targetGoal != null && targetGoal! > 0 
        ? targetGoal! 
        : totalDays;
    
    if (denominator == 0) return 0.0;
    
    return totalCompletions / denominator;
  }

  double getCappedProgress({required int totalDays}) {
    final rawProgress = calculateProgress(totalDays: totalDays);
    return rawProgress.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetGoal': targetGoal,
      'dailyLogs': dailyLogs,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      targetGoal: json['targetGoal'],
      dailyLogs: List<bool>.from(json['dailyLogs']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        targetGoal,
        dailyLogs,
        createdAt,
        updatedAt,
      ];
}
