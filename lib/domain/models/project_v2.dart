import 'package:isar_community/isar.dart';

part 'project_v2.g.dart';

/// Проект ремонта (улучшенная версия).
@collection
class ProjectV2 {
  /// ID проекта
  Id id = Isar.autoIncrement;

  /// Название проекта
  @Index()
  late String name;

  /// Описание проекта
  String? description;

  /// Дата создания
  @Index()
  late DateTime createdAt;

  /// Дата последнего изменения
  late DateTime updatedAt;

  /// Расчёты в проекте
  final calculations = IsarLinks<ProjectCalculation>();

  /// Общая стоимость проекта (материалы)
  double get totalMaterialCost {
    double total = 0;
    for (final calc in calculations) {
      total += calc.materialCost ?? 0;
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
  }
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

  /// Стоимость материалов
  double? materialCost;

  /// Стоимость работ
  double? laborCost;

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
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
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
