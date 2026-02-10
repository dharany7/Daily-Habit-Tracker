import 'package:equatable/equatable.dart';

class HabitState extends Equatable {
  final int year;
  final String month;
  final DateTime startDate;
  final DateTime endDate;
  final int daysInMonth;
  final List<String> dayLabels;
  final List<bool> daysElapsedMask;

  const HabitState({
    required this.year,
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.daysInMonth,
    required this.dayLabels,
    required this.daysElapsedMask,
  });

  factory HabitState.create({required int year, required String month}) {
    final monthIndex = _getMonthIndex(month);
    final startDate = DateTime(year, monthIndex, 1);
    final endDate = DateTime(year, monthIndex + 1, 0);
    final daysInMonth = endDate.day;
    
    final dayLabels = List.generate(daysInMonth, (index) {
      final date = startDate.add(Duration(days: index));
      return _getDayLabel(date.weekday);
    });

    final now = DateTime.now();
    final daysElapsedMask = List.generate(daysInMonth, (index) {
      final date = startDate.add(Duration(days: index));
      return date.isBefore(now) || date.isAtSameMomentAs(now);
    });

    return HabitState(
      year: year,
      month: month,
      startDate: startDate,
      endDate: endDate,
      daysInMonth: daysInMonth,
      dayLabels: dayLabels,
      daysElapsedMask: daysElapsedMask,
    );
  }

  static int _getMonthIndex(String month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months.indexOf(month) + 1;
  }

  static String _getDayLabel(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[weekday - 1];
  }

  int get daysElapsed {
    return daysElapsedMask.where((mask) => mask).length;
  }

  bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  HabitState copyWith({
    int? year,
    String? month,
    DateTime? startDate,
    DateTime? endDate,
    int? daysInMonth,
    List<String>? dayLabels,
    List<bool>? daysElapsedMask,
  }) {
    return HabitState(
      year: year ?? this.year,
      month: month ?? this.month,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      daysInMonth: daysInMonth ?? this.daysInMonth,
      dayLabels: dayLabels ?? this.dayLabels,
      daysElapsedMask: daysElapsedMask ?? this.daysElapsedMask,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'daysInMonth': daysInMonth,
      'dayLabels': dayLabels,
      'daysElapsedMask': daysElapsedMask,
    };
  }

  factory HabitState.fromJson(Map<String, dynamic> json) {
    return HabitState(
      year: json['year'],
      month: json['month'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      daysInMonth: json['daysInMonth'],
      dayLabels: List<String>.from(json['dayLabels']),
      daysElapsedMask: List<bool>.from(json['daysElapsedMask']),
    );
  }

  @override
  List<Object?> get props => [
        year,
        month,
        startDate,
        endDate,
        daysInMonth,
        dayLabels,
        daysElapsedMask,
      ];
}
