/// Категории констант для группировки и организации
enum ConstantCategory {
  /// Коэффициенты и множители
  coefficients,

  /// Формулы и параметры расчета
  formulas,

  /// Запасы материалов (проценты)
  margins,

  /// Параметры материалов
  materials,

  /// Размеры и длины
  measurements,

  /// Мощности (Вт, кВт)
  power,

  /// Упаковка материалов
  packaging,

  /// Преобразования единиц измерения
  conversion,
}

/// Одна константа с метаданными
///
/// Представляет набор связанных значений для одного аспекта калькулятора.
/// Например, константа "room_power" может содержать значения мощности
/// для разных типов помещений (ванная, кухня, комната и т.д.).
class CalculatorConstant {
  /// Уникальный ключ константы (например, "room_power", "cable_lengths")
  final String key;

  /// Категория для группировки констант
  final ConstantCategory category;

  /// Описание константы на русском
  final String description;

  /// Единица измерения (опционально)
  /// Примеры: "watt_per_m2", "kg_per_m3", "percent", "meters"
  final String? unit;

  /// Значения константы в виде Map
  /// Ключ - название значения, значение - числовое или строковое
  ///
  /// Пример:
  /// ```dart
  /// {
  ///   "bathroom": 180.0,
  ///   "living_room": 150.0,
  ///   "kitchen": 130.0
  /// }
  /// ```
  final Map<String, dynamic> values;

  const CalculatorConstant({
    required this.key,
    required this.category,
    required this.description,
    this.unit,
    required this.values,
  });

  /// Создать константу из JSON
  factory CalculatorConstant.fromJson(String key, Map<String, dynamic> json) {
    return CalculatorConstant(
      key: key,
      category: ConstantCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ConstantCategory.coefficients,
      ),
      description: json['description'] as String? ?? '',
      unit: json['unit'] as String?,
      values: Map<String, dynamic>.from(json['values'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category.name,
      'description': description,
      if (unit != null) 'unit': unit,
      'values': values,
    };
  }

  /// Получить числовое значение по ключу
  double? getDouble(String valueKey) {
    final value = values[valueKey];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  /// Получить целочисленное значение по ключу
  int? getInt(String valueKey) {
    final value = values[valueKey];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return null;
  }

  /// Получить строковое значение по ключу
  String? getString(String valueKey) {
    final value = values[valueKey];
    return value?.toString();
  }

  @override
  String toString() {
    return 'CalculatorConstant(key: $key, category: ${category.name}, values: ${values.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalculatorConstant &&
        other.key == key &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(key, category);
}

/// Набор констант для одного калькулятора
///
/// Представляет все константы, необходимые для работы конкретного калькулятора.
/// Загружается из JSON файла или Firebase Remote Config.
class CalculatorConstants {
  /// ID калькулятора (например, "warmfloor", "electrical", "tile")
  final String calculatorId;

  /// Версия констант (семантическое версионирование)
  final String version;

  /// Дата последнего обновления констант
  final DateTime lastUpdated;

  /// Map констант по ключам для O(1) доступа
  final Map<String, CalculatorConstant> constants;

  const CalculatorConstants({
    required this.calculatorId,
    required this.version,
    required this.lastUpdated,
    required this.constants,
  });

  /// Создать набор констант из JSON
  factory CalculatorConstants.fromJson(Map<String, dynamic> json) {
    final constantsMap = <String, CalculatorConstant>{};

    final constantsJson = json['constants'] as Map<String, dynamic>? ?? {};
    for (final entry in constantsJson.entries) {
      final key = entry.key;
      final constData = entry.value as Map<String, dynamic>;
      constantsMap[key] = CalculatorConstant.fromJson(key, constData);
    }

    return CalculatorConstants(
      calculatorId: json['calculator_id'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '1.0.0',
      lastUpdated: DateTime.tryParse(json['last_updated'] as String? ?? '') ?? DateTime.now(),
      constants: constantsMap,
    );
  }

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() {
    final constantsJson = <String, dynamic>{};

    for (final entry in constants.entries) {
      constantsJson[entry.key] = entry.value.toJson();
    }

    return {
      'calculator_id': calculatorId,
      'version': version,
      'last_updated': lastUpdated.toIso8601String(),
      'constants': constantsJson,
    };
  }

  /// Получить константу по ключу
  CalculatorConstant? get(String key) {
    return constants[key];
  }

  /// Получить числовое значение константы
  ///
  /// Использование:
  /// ```dart
  /// final power = constants.getDouble('room_power', 'bathroom', defaultValue: 180.0);
  /// ```
  double getDouble(
    String constantKey,
    String valueKey, {
    required double defaultValue,
  }) {
    final constant = constants[constantKey];
    if (constant == null) return defaultValue;
    return constant.getDouble(valueKey) ?? defaultValue;
  }

  /// Получить целочисленное значение константы
  int getInt(
    String constantKey,
    String valueKey, {
    required int defaultValue,
  }) {
    final constant = constants[constantKey];
    if (constant == null) return defaultValue;
    return constant.getInt(valueKey) ?? defaultValue;
  }

  /// Получить Map значений из константы
  Map<String, dynamic> getMap(String constantKey) {
    final constant = constants[constantKey];
    return constant?.values ?? {};
  }

  /// Проверить наличие константы
  bool has(String constantKey) {
    return constants.containsKey(constantKey);
  }

  @override
  String toString() {
    return 'CalculatorConstants(id: $calculatorId, version: $version, constants: ${constants.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalculatorConstants &&
        other.calculatorId == calculatorId &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(calculatorId, version);
}
