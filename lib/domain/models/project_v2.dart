import 'package:isar_community/isar.dart';

part 'project_v2.g.dart';

/// Проект ремонта (улучшенная версия с Dashboard).
@collection
class ProjectV2 {
  /// ID проекта
  Id id = Isar.autoIncrement;

  /// Название проекта
  @Index()
  late String name;

  /// Описание проекта
  String? description;

  /// Адрес объекта
  String? address;

  /// URL изображения проекта
  String? thumbnailUrl;

  /// Дата создания
  @Index()
  late DateTime createdAt;

  /// Дата последнего изменения
  late DateTime updatedAt;

  /// Дедлайн проекта
  DateTime? deadline;

  /// Общий бюджет проекта
  late double budgetTotal;

  /// Потраченный бюджет
  late double budgetSpent;

  /// Всего задач в проекте
  late int tasksTotal;

  /// Выполненных задач
  late int tasksCompleted;

  /// Расчёты в проекте
  final calculations = IsarLinks<ProjectCalculation>();

  /// Общая стоимость проекта (материалы) - uses effectiveMaterialCost
  double get totalMaterialCost {
    double total = 0;
    for (final calc in calculations) {
      total += calc.effectiveMaterialCost; // CHANGED: Use new getter
    }
    return total;
  }

  /// Общая стоимость работ
  double get totalLaborCost {
    double total = 0;
    for (final calc in calculations) {
      total += calc.laborCost ?? 0;
    }
    return total;
  }

  /// Общая стоимость проекта
  double get totalCost => totalMaterialCost + totalLaborCost;

  /// Get all materials across all calculations in project (NEW)
  @ignore
  List<ProjectMaterial> get allMaterials {
    final materials = <ProjectMaterial>[];
    for (final calc in calculations) {
      materials.addAll(calc.materials);
    }
    return materials;
  }

  /// Get shopping list (unpurchased materials) (NEW)
  @ignore
  List<ProjectMaterial> get shoppingList {
    return allMaterials.where((m) => !m.purchased).toList();
  }

  /// Get total cost of unpurchased materials (NEW)
  @ignore
  double get remainingMaterialCost {
    return shoppingList.fold<double>(
      0,
      (sum, material) => sum + material.totalCost,
    );
  }

  /// Избранный проект
  late bool isFavorite;

  /// Теги проекта
  late List<String> tags;

  /// Цвет проекта (для визуального различия)
  int? color;

  /// Статус проекта
  @Enumerated(EnumType.name)
  late ProjectStatus status;

  /// Заметки
  String? notes;

  ProjectV2() {
    name = '';
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    isFavorite = false;
    tags = [];
    status = ProjectStatus.planning;
    budgetTotal = 0;
    budgetSpent = 0;
    tasksTotal = 0;
    tasksCompleted = 0;
  }

  // ─────────────────────────────────────────────────────────────────
  // Вычисляемые геттеры для Dashboard
  // ─────────────────────────────────────────────────────────────────

  /// Прогресс проекта (0.0 - 1.0)
  /// Рассчитывается по задачам или материалам
  @ignore
  double get progress {
    if (tasksTotal > 0) {
      return tasksCompleted / tasksTotal;
    }
    // Fallback: считаем по купленным материалам
    final materials = allMaterials;
    if (materials.isNotEmpty) {
      final purchased = materials.where((m) => m.purchased).length;
      return purchased / materials.length;
    }
    return 0;
  }

  /// Процент прогресса (0 - 100)
  @ignore
  int get progressPercent => (progress * 100).round();

  /// Превышен ли бюджет
  @ignore
  bool get isOverBudget => budgetTotal > 0 && budgetSpent > budgetTotal;

  /// Процент использования бюджета
  @ignore
  double get budgetUtilization {
    if (budgetTotal <= 0) return 0;
    return budgetSpent / budgetTotal;
  }

  /// Осталось дней до дедлайна
  @ignore
  int get daysLeft {
    if (deadline == null) return -1;
    return deadline!.difference(DateTime.now()).inDays;
  }

  /// Дедлайн близко (менее 7 дней)
  @ignore
  bool get isDeadlineClose {
    final days = daysLeft;
    return days >= 0 && days <= 7;
  }

  /// Дедлайн просрочен
  @ignore
  bool get isDeadlineOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Есть проблемы (статус problem, превышен бюджет или просрочен дедлайн)
  @ignore
  bool get hasProblems {
    return status == ProjectStatus.problem ||
        status == ProjectStatus.cancelled ||
        isOverBudget ||
        isDeadlineOverdue;
  }

  /// Требует внимания (близкий дедлайн или бюджет > 90%)
  @ignore
  bool get needsAttention {
    return isDeadlineClose || (budgetUtilization > 0.9 && !isOverBudget);
  }

  /// Оставшийся бюджет
  @ignore
  double get budgetRemaining => budgetTotal - budgetSpent;
}

/// Статус проекта
enum ProjectStatus {
  /// Планирование
  planning,

  /// В работе
  inProgress,

  /// На паузе
  onHold,

  /// Завершён
  completed,

  /// Отменён
  cancelled,

  /// Проблема (требует внимания)
  problem,
}

/// Расчёт в проекте.
@collection
class ProjectCalculation {
  /// ID расчёта
  Id id = Isar.autoIncrement;

  /// ID калькулятора
  @Index()
  late String calculatorId;

  /// Название расчёта
  late String name;

  /// Входные данные (как список пар ключ-значение)
  late List<KeyValuePair> inputs;

  /// Результаты расчёта (как список пар ключ-значение)
  late List<KeyValuePair> results;

  /// Стоимость материалов (aggregate cost)
  double? materialCost;

  /// Стоимость работ
  double? laborCost;

  /// Детальный список материалов (NEW)
  late List<ProjectMaterial> materials;

  /// Дата создания
  late DateTime createdAt;

  /// Дата последнего изменения
  late DateTime updatedAt;

  /// Заметки к расчёту
  String? notes;

  /// Ссылка на проект
  @Backlink(to: 'calculations')
  final project = IsarLink<ProjectV2>();

  ProjectCalculation() {
    calculatorId = '';
    name = '';
    inputs = [];
    results = [];
    materials = []; // Initialize empty materials list
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Get total cost from detailed materials
  @ignore
  double get detailedMaterialCost {
    return materials.fold<double>(
      0,
      (sum, material) => sum + material.totalCost,
    );
  }

  /// Get effective material cost (prefer detailed, fallback to aggregate)
  @ignore
  double get effectiveMaterialCost {
    if (materials.isNotEmpty) {
      return detailedMaterialCost;
    }
    return materialCost ?? 0;
  }

  /// Получить входные данные как Map
  @ignore
  Map<String, double> get inputsMap {
    return {for (final pair in inputs) pair.key: pair.value};
  }

  /// Установить входные данные из Map
  void setInputsFromMap(Map<String, double> map) {
    inputs = map.entries
        .map((e) => KeyValuePair()
          ..key = e.key
          ..value = e.value)
        .toList();
  }

  /// Получить результаты как Map
  @ignore
  Map<String, double> get resultsMap {
    return {for (final pair in results) pair.key: pair.value};
  }

  /// Установить результаты из Map
  void setResultsFromMap(Map<String, double> map) {
    results = map.entries
        .map((e) => KeyValuePair()
          ..key = e.key
          ..value = e.value)
        .toList();
  }
}

/// Пара ключ-значение для хранения в Isar.
@embedded
class KeyValuePair {
  late String key;
  late double value;

  KeyValuePair() {
    key = '';
    value = 0;
  }
}

/// Материал проекта с ценой.
@embedded
class ProjectMaterial {
  /// Название материала
  late String name;

  /// SKU материала (для связи с прайс-листом)
  String? sku;

  /// Количество
  late double quantity;

  /// Единица измерения
  late String unit;

  /// Цена за единицу
  late double pricePerUnit;

  /// Общая стоимость
  @ignore
  double get totalCost => quantity * pricePerUnit;

  /// ID калькулятора, который добавил этот материал
  String? calculatorId;

  /// Приоритет закупки (1-5)
  late int priority;

  /// Куплен ли материал
  late bool purchased;

  /// Дата покупки
  DateTime? purchasedAt;

  ProjectMaterial() {
    name = '';
    quantity = 0;
    unit = '';
    pricePerUnit = 0;
    priority = 3;
    purchased = false;
  }
}
