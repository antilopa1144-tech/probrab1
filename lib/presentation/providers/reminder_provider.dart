import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/reminder.dart';
import '../../core/errors/error_handler.dart';

/// Провайдер для управления напоминаниями.
class ReminderNotifier extends StateNotifier<List<Reminder>> {
  ReminderNotifier() : super([]) {
    _loadReminders();
  }

  static const String _key = 'reminders';

  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json != null) {
        try {
          final list = jsonDecode(json) as List;
          state = list.map((e) => _reminderFromJson(e)).toList();
        } catch (e, stackTrace) {
          ErrorHandler.logError(e, stackTrace, 'ReminderNotifier._loadReminders (parse)');
          state = [];
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'ReminderNotifier._loadReminders');
      state = [];
    }
  }

  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(state.map((r) => r.toJson()).toList());
      await prefs.setString(_key, json);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'ReminderNotifier._saveReminders');
      // Не меняем состояние при ошибке сохранения
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    state = [...state, reminder];
    await _saveReminders();
  }

  Future<void> updateReminder(String id, Reminder updated) async {
    state = state.map((r) => r.id == id ? updated : r).toList();
    await _saveReminders();
  }

  Future<void> completeReminder(String id) async {
    state = state.map((r) => r.id == id 
        ? Reminder(
            id: r.id,
            title: r.title,
            description: r.description,
            scheduledDate: r.scheduledDate,
            type: r.type,
            relatedCalculationId: r.relatedCalculationId,
            relatedProjectId: r.relatedProjectId,
            isCompleted: true,
            completedAt: DateTime.now(),
          )
        : r).toList();
    await _saveReminders();
  }

  Future<void> deleteReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _saveReminders();
  }

  List<Reminder> getUpcoming() {
    return state.where((r) => r.isUpcoming && !r.isCompleted).toList();
  }

  List<Reminder> getOverdue() {
    return state.where((r) => r.isOverdue).toList();
  }
}

final reminderProvider = 
    StateNotifierProvider<ReminderNotifier, List<Reminder>>(
  (ref) => ReminderNotifier(),
);

// Вспомогательная функция для десериализации
Reminder _reminderFromJson(Map<String, dynamic> json) {
  return Reminder(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    scheduledDate: DateTime.parse(json['scheduledDate']),
    type: ReminderType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => ReminderType.custom,
    ),
    relatedCalculationId: json['relatedCalculationId'],
    relatedProjectId: json['relatedProjectId'],
    isCompleted: json['isCompleted'] ?? false,
    completedAt: json['completedAt'] != null 
        ? DateTime.parse(json['completedAt'])
        : null,
  );
}

// Расширение для сериализации
extension ReminderJson on Reminder {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledDate': scheduledDate.toIso8601String(),
      'type': type.toString(),
      'relatedCalculationId': relatedCalculationId,
      'relatedProjectId': relatedProjectId,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  static Reminder fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      scheduledDate: DateTime.parse(json['scheduledDate']),
      type: ReminderType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ReminderType.custom,
      ),
      relatedCalculationId: json['relatedCalculationId'],
      relatedProjectId: json['relatedProjectId'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

