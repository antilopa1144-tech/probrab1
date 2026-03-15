/// Данные для экспорта проекта.
class ExportData {
  /// Название проекта
  final String projectName;

  /// Описание проекта
  final String? projectDescription;

  /// Дата создания
  final DateTime createdAt;

  /// Список расчётов
  final List<ExportCalculation> calculations;

  /// Общая стоимость материалов
  final double totalMaterialCost;

  /// Общая стоимость работ
  final double totalLaborCost;

  /// Общая стоимость
  final double totalCost;

  /// Дополнительные заметки
  final String? notes;

  const ExportData({
    required this.projectName,
    this.projectDescription,
    required this.createdAt,
    required this.calculations,
    required this.totalMaterialCost,
    required this.totalLaborCost,
    required this.totalCost,
    this.notes,
  });
}

/// Данные расчёта для экспорта.
class ExportCalculation {
  /// Название калькулятора
  final String calculatorName;

  /// Входные параметры
  final Map<String, double> inputs;

  /// Результаты
  final Map<String, double> results;

  /// Стоимость материалов
  final double? materialCost;

  /// Стоимость работ
  final double? laborCost;

  /// Заметки
  final String? notes;

  const ExportCalculation({
    required this.calculatorName,
    required this.inputs,
    required this.results,
    this.materialCost,
    this.laborCost,
    this.notes,
  });
}
