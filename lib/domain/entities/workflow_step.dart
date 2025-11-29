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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'order': order,
      'prerequisites': prerequisites,
      'estimatedDays': estimatedDays,
      'requiredMaterials': requiredMaterials,
      'requiredTools': requiredTools,
      'checklist': checklist,
      'isCritical': isCritical,
    };
  }

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      order: json['order'] as int,
      prerequisites: (json['prerequisites'] as List?)?.cast<String>() ?? [],
      estimatedDays: json['estimatedDays'] as int? ?? 1,
      requiredMaterials: (json['requiredMaterials'] as List?)?.cast<String>() ?? [],
      requiredTools: (json['requiredTools'] as List?)?.cast<String>() ?? [],
      checklist: (json['checklist'] as List?)?.cast<String>() ?? [],
      isCritical: json['isCritical'] as bool? ?? false,
    );
  }
}

/// План работ для проекта.
class WorkflowPlan {
  final String id;
  final String name;
  final List<WorkflowStep> steps;
  final DateTime createdAt;
  final DateTime? startDate;
  final List<String> completedSteps;

  const WorkflowPlan({
    required this.id,
    required this.name,
    required this.steps,
    required this.createdAt,
    this.startDate,
    this.completedSteps = const [],
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

  /// Создать копию с изменениями.
  WorkflowPlan copyWith({
    String? id,
    String? name,
    List<WorkflowStep>? steps,
    DateTime? createdAt,
    DateTime? startDate,
    List<String>? completedSteps,
  }) {
    return WorkflowPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'steps': steps.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'completedSteps': completedSteps,
    };
  }

  factory WorkflowPlan.fromJson(Map<String, dynamic> json) {
    return WorkflowPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      steps: (json['steps'] as List)
          .map((s) => WorkflowStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String)
          : null,
      completedSteps: (json['completedSteps'] as List?)?.cast<String>() ?? [],
    );
  }
}

