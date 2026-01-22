// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../../core/enums/field_input_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_warm_floor.dart';

/// Калькулятор тёплого пола V2.
final warmFloorCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_warm',
  titleKey: calculatorTitleKey('floors_warm'),
  descriptionKey: calculatorDescriptionKey('floors_warm'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.heating',
  iconName: 'radiator',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 90,
  tags: ['тёплый пол', 'отопление', 'электричество', 'heating', 'floor'],

  // Поля ввода
  fields: [
    // --- Переключатель режима ввода ---
    const CalculatorField(
      key: 'inputMode',
      labelKey: 'input.mode',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 1,
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
      unitType: UnitType.meters,
      defaultValue: 5.0,
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
      unitType: UnitType.meters,
      defaultValue: 4.0,
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
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 20.0,
      minValue: 1.0,
      maxValue: 200.0,
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

    // --- Периметр для демпферной ленты ---
    const CalculatorField(
      key: 'perimeter',
      labelKey: 'input.perimeter',
      hintKey: 'input.perimeter.hint',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0,
      maxValue: 500,
      required: false,
      step: 0.5,
      iconName: 'border_outer',
      order: 4,
    ),

    // --- Группа "Система" ---
    const CalculatorField(
      key: 'roomType',
      labelKey: 'input.roomType',
      hintKey: 'input.roomType.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 2,
      required: true,
      iconName: 'meeting_room',
      group: 'system',
      order: 10,
      options: [
        FieldOption(value: 1, labelKey: 'input.roomType.bathroom'),
        FieldOption(value: 2, labelKey: 'input.roomType.living'),
        FieldOption(value: 3, labelKey: 'input.roomType.kitchen'),
        FieldOption(value: 4, labelKey: 'input.roomType.balcony'),
        FieldOption(value: 0, labelKey: 'input.roomType.custom'),
      ],
    ),
    CalculatorField(
      key: 'power',
      labelKey: 'input.power',
      hintKey: 'input.power.hint',
      unitType: UnitType.pieces,
      defaultValue: 150.0,
      minValue: 80.0,
      maxValue: 200.0,
      required: true,
      step: 10.0,
      iconName: 'bolt',
      group: 'system',
      order: 11,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'roomType',
        value: 0,
      ),
    ),
    CalculatorField(
      key: 'type',
      labelKey: 'input.type',
      hintKey: 'input.type.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 2.0,
      required: true,
      iconName: 'category',
      group: 'system',
      order: 12,
      options: [
        FieldOption(value: 1.0, labelKey: 'input.type.cable'),
        FieldOption(value: 2.0, labelKey: 'input.type.mat'),
      ],
    ),
    CalculatorField(
      key: 'thermostats',
      labelKey: 'input.thermostats',
      hintKey: 'input.thermostats.hint',
      unitType: UnitType.pieces,
      defaultValue: 1,
      minValue: 1,
      maxValue: 10,
      required: true,
      step: 1,
      iconName: 'settings',
      group: 'system',
      order: 13,
    ),

    // --- Группа "Дополнительно" ---
    const CalculatorField(
      key: 'usefulAreaPercent',
      labelKey: 'input.usefulAreaPercent',
      hintKey: 'input.usefulAreaPercent.hint',
      unitType: UnitType.percent,
      inputType: FieldInputType.slider,
      defaultValue: 70,
      minValue: 50,
      maxValue: 90,
      step: 5,
      iconName: 'dashboard',
      group: 'advanced',
      order: 20,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.warm_floor.before.power',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.warm_floor.before.area',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.warm_floor.before.installation',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.warm_floor.after.thermostat',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.warm_floor.after.electricity',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateWarmFloor(),
);
