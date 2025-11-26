import '../../data/models/calculation.dart';

/// Полный проект с несколькими расчётами.
class Project {
  final String id;
  final String name;
  final String description;
  final String objectType; // дом, квартира, гараж
  final List<String> calculationIds; // ID сохранённых расчётов
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? completionDate;
  final double totalBudget;
  final double spentAmount;
  final Map<String, dynamic> metadata; // дополнительные данные

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.objectType,
    this.calculationIds = const [],
    required this.createdAt,
    this.startDate,
    this.completionDate,
    this.totalBudget = 0,
    this.spentAmount = 0,
    this.metadata = const {},
  });

  /// Создать проект из расчётов.
  factory Project.fromCalculations({
    required String id,
    required String name,
    required String description,
    required String objectType,
    required List<Calculation> calculations,
  }) {
    final totalBudget = calculations.fold<double>(
      0,
      (sum, calc) => sum + calc.totalCost,
    );
    
    return Project(
      id: id,
      name: name,
      description: description,
      objectType: objectType,
      calculationIds: calculations.map((c) => c.id.toString()).toList(),
      createdAt: DateTime.now(),
      totalBudget: totalBudget,
    );
  }

  /// Получить прогресс проекта (0-100%).
  double getProgress() {
    if (completionDate != null) return 100.0;
    if (startDate == null) return 0.0;
    
    // Простой расчёт: можно улучшить
    return 50.0; // заглушка
  }

  /// Получить оставшийся бюджет.
  double getRemainingBudget() {
    return totalBudget - spentAmount;
  }
}

