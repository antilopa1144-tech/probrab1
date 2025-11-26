/// Шаг в плане работ.
class WorkflowStep {
  final String id;
  final String title;
  final String description;
  final String category;
  final int order;
  final List<String> prerequisites; // ID предыдущих шагов
  final int estimatedDays;
  final List<String> requiredMaterials;
  final List<String> requiredTools;
  final List<String> checklist;
  final bool isCritical; // Критический путь

  const WorkflowStep({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.order,
    this.prerequisites = const [],
    this.estimatedDays = 1,
    this.requiredMaterials = const [],
    this.requiredTools = const [],
    this.checklist = const [],
    this.isCritical = false,
  });
}

/// План работ для проекта.
class WorkflowPlan {
  final String id;
  final String name;
  final List<WorkflowStep> steps;
  final DateTime createdAt;
  final DateTime? startDate;

  const WorkflowPlan({
    required this.id,
    required this.name,
    required this.steps,
    required this.createdAt,
    this.startDate,
  });

  /// Получить общее количество дней.
  int get totalDays {
    if (steps.isEmpty) return 0;
    
    // Простой расчёт: суммируем дни с учётом параллельных работ
    final criticalPath = _calculateCriticalPath();
    return criticalPath.fold(0, (sum, step) => sum + step.estimatedDays);
  }

  /// Получить критический путь.
  List<WorkflowStep> _calculateCriticalPath() {
    final sorted = List<WorkflowStep>.from(steps)
      ..sort((a, b) => a.order.compareTo(b.order));
    
    final critical = <WorkflowStep>[];
    final completed = <String>{};
    
    for (final step in sorted) {
      if (step.prerequisites.every((prereq) => completed.contains(prereq))) {
        if (step.isCritical) {
          critical.add(step);
        }
        completed.add(step.id);
      }
    }
    
    return critical;
  }

  /// Получить следующие доступные шаги.
  List<WorkflowStep> getAvailableSteps(List<String> completedStepIds) {
    return steps.where((step) {
      return !completedStepIds.contains(step.id) &&
          step.prerequisites.every((prereq) => completedStepIds.contains(prereq));
    }).toList();
  }
}

