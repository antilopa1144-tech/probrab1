/// Описывает связь между калькуляторами.
///
/// Позволяет передать результаты одного калькулятора
/// как входные данные другого (связанного) калькулятора.
///
/// Пример: Плитка → Затирка (передать площадь, размер плитки, ширину шва)
class CalculatorLink {
  /// ID целевого калькулятора
  final String targetId;

  /// Ключ локализации для кнопки
  final String labelKey;

  /// Имя иконки Material
  final String? iconName;

  /// Маппинг: ключ источника → ключ цели
  ///
  /// Значение ищется сначала в results, затем в inputs (fallback).
  /// Пример: `{'totalArea': 'area', 'tileSize': 'tileSize'}`
  final Map<String, String> inputMapping;

  /// Фиксированные значения для целевого калькулятора.
  ///
  /// Пример: `{'inputMode': 1.0}` — переключить в режим "по площади"
  final Map<String, double> staticInputs;

  /// Показывать ссылку только если этот ключ есть в results и > 0
  final String? showIfResultKey;

  const CalculatorLink({
    required this.targetId,
    required this.labelKey,
    this.iconName,
    required this.inputMapping,
    this.staticInputs = const {},
    this.showIfResultKey,
  });

  /// Собрать входные данные для целевого калькулятора.
  ///
  /// Приоритет: results → inputs (fallback) → staticInputs (override)
  Map<String, double> buildTargetInputs(
    Map<String, double> results,
    Map<String, double> inputs,
  ) {
    final targetInputs = <String, double>{};

    for (final entry in inputMapping.entries) {
      final sourceKey = entry.key;
      final targetKey = entry.value;

      if (results.containsKey(sourceKey)) {
        targetInputs[targetKey] = results[sourceKey]!;
      } else if (inputs.containsKey(sourceKey)) {
        targetInputs[targetKey] = inputs[sourceKey]!;
      }
    }

    // staticInputs перезаписывают маппированные значения
    targetInputs.addAll(staticInputs);

    return targetInputs;
  }

  /// Должна ли ссылка отображаться на основе результатов
  bool shouldShow(Map<String, double> results) {
    if (showIfResultKey == null) return true;
    final value = results[showIfResultKey];
    return value != null && value > 0;
  }
}
