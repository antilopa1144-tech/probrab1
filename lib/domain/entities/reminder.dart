/// Напоминание о важном событии.
class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime scheduledDate;
  final ReminderType type;
  final String? relatedCalculationId;
  final String? relatedProjectId;
  final bool isCompleted;
  final DateTime? completedAt;

  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.type,
    this.relatedCalculationId,
    this.relatedProjectId,
    this.isCompleted = false,
    this.completedAt,
  });

  /// Проверить, просрочено ли напоминание.
  bool get isOverdue {
    return !isCompleted && scheduledDate.isBefore(DateTime.now());
  }

  /// Проверить, скоро ли наступит (в течение 24 часов).
  bool get isUpcoming {
    if (isCompleted) return false;
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);
    return difference.inHours >= 0 && difference.inHours <= 24;
  }
}

enum ReminderType {
  materialPurchase, // закупка материалов
  workStart, // начало работ
  qualityCheck, // проверка качества
  nextStep, // следующий этап
  deadline, // дедлайн
  custom, // пользовательское
}

/// Шаблон напоминания.
class ReminderTemplate {
  final String workType;
  final ReminderType type;
  final String title;
  final String description;
  final int daysBefore; // за сколько дней до события

  const ReminderTemplate({
    required this.workType,
    required this.type,
    required this.title,
    required this.description,
    required this.daysBefore,
  });

  /// Создать напоминание из шаблона.
  Reminder createReminder({
    required String id,
    required DateTime eventDate,
    String? calculationId,
    String? projectId,
  }) {
    final scheduledDate = eventDate.subtract(Duration(days: daysBefore));
    
    return Reminder(
      id: id,
      title: title,
      description: description,
      scheduledDate: scheduledDate,
      type: type,
      relatedCalculationId: calculationId,
      relatedProjectId: projectId,
    );
  }
}

