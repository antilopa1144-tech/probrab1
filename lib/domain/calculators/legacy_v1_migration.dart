import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import 'calculator_constants.dart';
import 'definitions.dart' as legacy;

/// Конвертация всех V1 калькуляторов в V2-формат.
///
/// Используется для автоматической миграции, чтобы новые экраны и реестр
/// работали только с `CalculatorDefinitionV2`.
List<CalculatorDefinitionV2> buildMigratedCalculators({
  Set<String> skipIds = const {},
  Map<String, CalculatorDefinitionV2> overrides = const {},
}) {
  final migrated = <CalculatorDefinitionV2>[];

  for (final definition in legacy.calculators) {
    if (skipIds.contains(definition.id)) continue;
    if (overrides.containsKey(definition.id)) continue;

    migrated.add(_convert(definition));
  }

  return migrated;
}

CalculatorDefinitionV2 _convert(legacy.CalculatorDefinition legacyDef) {
  final category = _mapCategory(legacyDef.category, legacyDef.subCategory);
  final subCategory = _mapSubCategory(legacyDef);
  final fields = <CalculatorField>[];
  for (var i = 0; i < legacyDef.fields.length; i++) {
    final field = legacyDef.fields[i];
    fields.add(
      CalculatorField(
        key: field.key,
        labelKey: field.labelKey,
        unitType: _mapUnit(field),
        inputType: FieldInputType.number,
        defaultValue: field.defaultValue,
        minValue: field.minValue,
        maxValue: field.maxValue,
        required: field.required,
        order: i + 1,
      ),
    );
  }

  return CalculatorDefinitionV2(
    id: legacyDef.id,
    titleKey: calculatorTitleKey(legacyDef.id),
    descriptionKey: calculatorDescriptionKey(legacyDef.id),
    category: category,
    subCategory: subCategory,
    fields: fields,
    beforeHints: const [],
    afterHints: const [],
    useCase: legacyDef.useCase,
    iconName: null,
    accentColor: kCalculatorAccentColor,
    complexity: _inferComplexity(category, legacyDef.subCategory),
    popularity: 10,
    tags: _buildTags(legacyDef),
  );
}

CalculatorCategory _mapCategory(String category, String subCategory) {
  // Упрощенная двухуровневая система: interior/exterior
  switch (category) {
    case 'Фундамент':
    case 'Наружная отделка':
    case 'Конструкции':
      return CalculatorCategory.exterior;
    case 'Инженерные работы':
    case 'Внутренняя отделка':
      return CalculatorCategory.interior;
    default:
      // По умолчанию внутренняя отделка
      return CalculatorCategory.interior;
  }
}

String _mapSubCategory(legacy.CalculatorDefinition legacyDef) {
  if (legacyDef.subCategory.isNotEmpty) {
    return legacyDef.subCategory;
  }
  final parts = legacyDef.id.split(RegExp(r'[\\._]'));
  if (parts.length > 1) {
    return parts.sublist(1).join('_');
  }
  return legacyDef.id;
}

List<String> _buildTags(legacy.CalculatorDefinition legacyDef) {
  final tags = <String>{
    legacyDef.category,
    legacyDef.subCategory,
    legacyDef.id,
  };
  tags.addAll(legacyDef.id.split(RegExp(r'[._]')));
  return tags.where((t) => t.isNotEmpty).toList();
}

UnitType _mapUnit(legacy.InputFieldDefinition field) {
  final key = field.key.toLowerCase();
  final defaultValue = field.defaultValue;
  final referenceValue = defaultValue != 0
      ? defaultValue
      : (field.maxValue ?? field.minValue ?? 0);

  if (key.contains('area')) return UnitType.squareMeters;
  if (key.contains('volume')) return UnitType.cubicMeters;
  if (key.contains('power'))
    return UnitType.kilograms; // ближайший доступный тип
  if (key.contains('density') || key.contains('weight')) {
    return UnitType.kilograms;
  }
  if (key.contains('consumption')) return UnitType.liters;
  if (key.contains('perimeter') || key.contains('length')) {
    return UnitType.meters;
  }
  if (key.contains('height') || key.contains('width')) {
    if (referenceValue >= 5) return UnitType.centimeters;
    return UnitType.meters;
  }
  if (key.contains('thickness')) {
    if (referenceValue >= 5) return UnitType.millimeters;
    return UnitType.meters;
  }
  if (key.contains('radius') || key.contains('diameter')) {
    return UnitType.meters;
  }
  if (key.contains('rooms') ||
      key.contains('windows') ||
      key.contains('doors') ||
      key.contains('layers') ||
      key.contains('corners') ||
      key.contains('fixtures') ||
      key.contains('sockets') ||
      key.contains('switches') ||
      key.contains('thermostats') ||
      key.contains('gates') ||
      key.contains('wickets') ||
      key.contains('count') ||
      key.contains('pieces') ||
      key.contains('type')) {
    return UnitType.pieces;
  }
  return UnitType.meters;
}

int _inferComplexity(CalculatorCategory category, String subCategory) {
  // Наружная отделка обычно сложнее (фундамент, кровля)
  if (category == CalculatorCategory.exterior) {
    return 3;
  }
  // Внутренняя отделка - средняя сложность
  if (category == CalculatorCategory.interior) {
    return 2;
  }
  return 1;
}
