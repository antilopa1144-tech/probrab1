// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_wall_paint.dart';

/// Обновлённое определение калькулятора краски с поддержкой гибридного ввода и запаса.
final paintCalculatorV2 = CalculatorDefinitionV2(
  id: 'wall_paint',
  titleKey: calculatorTitleKey('wall_paint'),
  descriptionKey: calculatorDescriptionKey('wall_paint'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.paint',
  iconName: 'format_paint',
  accentColor: kCalculatorAccentColor,
  complexity: 1,
  popularity: 100,
  tags: ['краска', 'стены', 'отделка', 'paint', 'walls'],

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
    const CalculatorField(
      key: 'height',
      labelKey: 'input.height',
      unitType: UnitType.meters,
      defaultValue: 2.5,
      minValue: 0.1,
      maxValue: 10,
      required: true,
      step: 0.05,
      iconName: 'height',
      group: 'dimensions',
      order: 3,
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
      minValue: 0.1,
      maxValue: 1000,
      required: true,
      step: 0.5,
      iconName: 'square_foot',
      order: 4,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),
    const CalculatorField(
      key: 'perimeter',
      labelKey: 'input.perimeter',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 500,
      required: true,
      step: 0.1,
      iconName: 'zoom_out_map',
      order: 5,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),

    // --- Общие поля ---
    const CalculatorField(
      key: 'layers',
      labelKey: 'input.layers',
      hintKey: 'input.layers.hint',
      unitType: UnitType.pieces,
      defaultValue: 2,
      minValue: 1,
      maxValue: 5,
      required: true,
      step: 1,
      iconName: 'layers',
      order: 10,
    ),
    const CalculatorField(
      key: 'reserve',
      labelKey: 'input.reserve',
      unitType: UnitType.percent,
      inputType: FieldInputType.slider,
      defaultValue: 5, // 5% по умолчанию для краски
      minValue: 0,
      maxValue: 25,
      step: 1,
      iconName: 'add_shopping_cart',
      order: 11,
    ),
    
    // --- Группа "Проёмы" (дополнительно) ---
    const CalculatorField(
      key: 'windowsArea',
      labelKey: 'input.windows_area',
      hintKey: 'input.windows_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0,
      maxValue: 100,
      required: false,
      step: 0.1,
      iconName: 'window',
      group: 'openings',
      order: 20,
    ),
    const CalculatorField(
      key: 'doorsArea',
      labelKey: 'input.doors_area',
      hintKey: 'input.doors_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0,
      maxValue: 50,
      required: false,
      step: 0.1,
      iconName: 'door_front',
      group: 'openings',
      order: 21,
    ),
    
    // --- Группа "Расход" (дополнительно) ---
    const CalculatorField(
      key: 'consumption',
      labelKey: 'input.consumption',
      hintKey: 'input.consumption.hint',
      unitType: UnitType.litersPerSqm,
      defaultValue: 0.12, // Средний расход по новым данным
      minValue: 0.08,
      maxValue: 0.25,
      required: false,
      step: 0.01,
      iconName: 'opacity',
      group: 'advanced',
      order: 30,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    const CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.paint.before.measure',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.paint.before.primer',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.paint.large_area',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        fieldKey: 'area',
        value: 100,
      ),
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.paint.after.apply',
    ),
    const CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.paint.after.ventilation',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.paint.high_consumption',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        resultKey: 'paintNeededLiters', // Используем новый ключ
        value: 50,
      ),
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateWallPaint(),
);
