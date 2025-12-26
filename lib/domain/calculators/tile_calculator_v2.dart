// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_tile.dart';

/// Калькулятор плитки V2.
final tileCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_tile',
  titleKey: calculatorTitleKey('floors_tile'),
  descriptionKey: calculatorDescriptionKey('floors_tile'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.floors',
  iconName: 'grid_view',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 95,
  tags: ['плитка', 'полы', 'кафель', 'tile', 'flooring', 'ceramic'],

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

    // --- Группа "По площади" ---
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0.5,
      maxValue: 500.0,
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

    // --- Группа "Размер плитки" ---
    const CalculatorField(
      key: 'tileSize',
      labelKey: 'input.tileSize',
      hintKey: 'input.tileSize.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 60,
      required: true,
      iconName: 'grid_view',
      group: 'tile',
      order: 10,
      options: [
        FieldOption(value: 20, labelKey: 'input.tileSize.20x20'),
        FieldOption(value: 30, labelKey: 'input.tileSize.30x30'),
        FieldOption(value: 40, labelKey: 'input.tileSize.40x40'),
        FieldOption(value: 60, labelKey: 'input.tileSize.60x60'),
        FieldOption(value: 80, labelKey: 'input.tileSize.80x80'),
        FieldOption(value: 120, labelKey: 'input.tileSize.120x60'),
        FieldOption(value: 0, labelKey: 'input.tileSize.custom'),
      ],
    ),
    const CalculatorField(
      key: 'tileWidth',
      labelKey: 'input.tileWidth',
      hintKey: 'input.tileWidth.hint',
      unitType: UnitType.centimeters,
      defaultValue: 60.0,
      minValue: 1.0,
      maxValue: 200.0,
      required: true,
      step: 1.0,
      iconName: 'width_normal',
      group: 'tile',
      order: 11,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'tileSize',
        value: 0,
      ),
    ),
    const CalculatorField(
      key: 'tileHeight',
      labelKey: 'input.tileHeight',
      hintKey: 'input.tileHeight.hint',
      unitType: UnitType.centimeters,
      defaultValue: 60.0,
      minValue: 1.0,
      maxValue: 200.0,
      required: true,
      step: 1.0,
      iconName: 'height',
      group: 'tile',
      order: 12,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'tileSize',
        value: 0,
      ),
    ),

    // --- Группа "Дополнительно" ---
    const CalculatorField(
      key: 'reserve',
      labelKey: 'input.reserve',
      hintKey: 'input.reserve.hint',
      unitType: UnitType.percent,
      inputType: FieldInputType.slider,
      defaultValue: 10,
      minValue: 5,
      maxValue: 20,
      step: 1,
      iconName: 'add_shopping_cart',
      group: 'advanced',
      order: 20,
    ),
    CalculatorField(
      key: 'jointWidth',
      labelKey: 'input.jointWidth',
      hintKey: 'input.jointWidth.hint',
      unitType: UnitType.millimeters,
      defaultValue: 3.0,
      minValue: 1.0,
      maxValue: 10.0,
      required: false,
      step: 0.5,
      iconName: 'border_style',
      group: 'advanced',
      order: 21,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(type: HintType.info, messageKey: 'hint.tile.before.measure'),
    CalculatorHint(type: HintType.tip, messageKey: 'hint.tile.before.level'),
    CalculatorHint(type: HintType.tip, messageKey: 'hint.tile.before.crosses'),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(type: HintType.tip, messageKey: 'hint.tile.after.grout'),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.tile.after.adhesive',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.tile.after.installation',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateTile(),
);
