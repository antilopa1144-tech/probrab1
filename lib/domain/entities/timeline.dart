import 'workflow_step.dart';

/// Временная линия проекта.
class Timeline {
  final String projectId;
  final List<TimelineEvent> events;
  final DateTime startDate;
  final DateTime? endDate;

  const Timeline({
    required this.projectId,
    required this.events,
    required this.startDate,
    this.endDate,
  });

  /// Создать временную линию из плана работ.
  factory Timeline.fromWorkflowPlan(WorkflowPlan plan, DateTime startDate) {
    final events = <TimelineEvent>[];
    var currentDate = startDate;
    final completed = <String>{};
    
    // Сортируем шаги по порядку
    final sortedSteps = List<WorkflowStep>.from(plan.steps)
      ..sort((a, b) => a.order.compareTo(b.order));
    
    for (final step in sortedSteps) {
      // Проверяем зависимости
      if (step.prerequisites.every((prereq) => completed.contains(prereq))) {
        final event = TimelineEvent(
          stepId: step.id,
          title: step.title,
          startDate: currentDate,
          endDate: currentDate.add(Duration(days: step.estimatedDays)),
          isCritical: step.isCritical,
        );
        
        events.add(event);
        completed.add(step.id);
        
        // Следующий шаг начинается после завершения текущего
        currentDate = event.endDate;
      }
    }
    
    final endDate = events.isNotEmpty ? events.last.endDate : null;
    
    return Timeline(
      projectId: plan.id,
      events: events,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Получить критический путь.
  List<TimelineEvent> getCriticalPath() {
    return events.where((e) => e.isCritical).toList();
  }

  /// Получить общую длительность в днях.
  int getTotalDays() {
    if (endDate == null) return 0;
    return endDate!.difference(startDate).inDays;
  }
}

/// Событие на временной линии.
class TimelineEvent {
  final String stepId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCritical;
  final bool isCompleted;
  final String? notes;

  const TimelineEvent({
    required this.stepId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.isCritical,
    this.isCompleted = false,
    this.notes,
  });

  /// Получить длительность в днях.
  int get durationDays {
    return endDate.difference(startDate).inDays;
  }
}

