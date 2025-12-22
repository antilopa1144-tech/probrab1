// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_self_leveling_floor.dart';

/// Калькулятор наливного пола V2 с гибридным режимом ввода.
///
/// Согласно спецификации:
/// - Логика: Площадь × Толщина (мм) × Расход (~1.6 кг/мм)
/// - Вывод: Общий вес в кг и количество мешков (20/25кг)
/// - Дополнительно: Грунтовка (литры), Демпферная лента (периметр)
final selfLevelingFloorCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_self_leveling',
  titleKey: calculatorTitleKey('floors_self_leveling'),
  descriptionKey: calculatorDescriptionKey('floors_self_leveling'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.floors',
  iconName: 'grid_on',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 75,
  tags: ['наливной пол', 'полы', 'стяжка', 'self-leveling', 'floor', 'screed'],

  // Поля ввода
  fields: [
    // --- Переключатель режима ввода ---
    const CalculatorField(
      key: 'inputMode',
      labelKey: 'input.mode',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.mode.by_dimensions'),
        FieldOption(value: 1, labelKey: 'input.mode.by_area'),
      ],
      order: 0,
    ),

    // --- Группа "По размерам" ---
    const CalculatorField(
      key: 'length',
      labelKey: 'input.length',
      hintKey: 'input.length.hint',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 100,
      required: true,
      step: 0.1,
      iconName: 'straighten',
      group: 'dimensions',
      order: 1,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 0,
      ),
    ),
    const CalculatorField(
      key: 'width',
      labelKey: 'input.width',
      hintKey: 'input.width.hint',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 100,
      required: true,
      step: 0.1,
      iconName: 'straighten',
      group: 'dimensions',
      order: 2,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 0,
      ),
    ),

    // --- Группа "По площади" ---
    const CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0.5,
      maxValue: 1000,
      required: true,
      step: 0.5,
      iconName: 'square_foot',
      order: 3,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),

    // --- Общие поля ---
    const CalculatorField(
      key: 'thickness',
      labelKey: 'input.thickness',
      hintKey: 'input.thickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 10,
      minValue: 3,
      maxValue: 100,
      required: true,
      step: 1,
      iconName: 'layers',
      order: 10,
    ),
    const CalculatorField(
      key: 'consumption',
      labelKey: 'input.consumption',
      hintKey: 'input.consumption.hint',
      unitType: UnitType.kilograms,
      defaultValue: 1.6,
      minValue: 1.3,
      maxValue: 2.0,
      required: false,
      step: 0.1,
      iconName: 'opacity',
      group: 'advanced',
      order: 20,
    ),
    const CalculatorField(
      key: 'bagWeight',
      labelKey: 'input.bag_weight',
      hintKey: 'input.bag_weight.hint',
      unitType: UnitType.kilograms,
      inputType: FieldInputType.select,
      defaultValue: 25,
      options: [
        FieldOption(value: 20, labelKey: 'input.bag_weight.20kg'),
        FieldOption(value: 25, labelKey: 'input.bag_weight.25kg'),
      ],
      group: 'advanced',
      order: 21,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    const CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.self_leveling.before.measure',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.self_leveling.before.level',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.self_leveling.before.primer',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    const CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.self_leveling.after.mixing',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.self_leveling.after.temperature',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.self_leveling.after.drying',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateSelfLevelingFloor(),
);
