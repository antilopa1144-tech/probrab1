// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_laminate.dart';

/// Калькулятор ламината V2.
final laminateCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_laminate',
  titleKey: calculatorTitleKey('floors_laminate'),
  descriptionKey: calculatorDescriptionKey('floors_laminate'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.floors',
  iconName: 'flooring',
  accentColor: kCalculatorAccentColor,
  complexity: 1,
  popularity: 90,
  tags: ['ламинат', 'полы', 'напольное покрытие', 'laminate', 'flooring'],

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
      minValue: 1.0,
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

    // --- Периметр для плинтуса ---
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

    // --- Группа "Материал" ---
    const CalculatorField(
      key: 'laminateClass',
      labelKey: 'input.laminateClass',
      hintKey: 'input.laminateClass.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 32,
      required: true,
      iconName: 'star',
      group: 'material',
      order: 10,
      options: [
        FieldOption(value: 31, labelKey: 'input.laminateClass.31'),
        FieldOption(value: 32, labelKey: 'input.laminateClass.32'),
        FieldOption(value: 33, labelKey: 'input.laminateClass.33'),
        FieldOption(value: 34, labelKey: 'input.laminateClass.34'),
      ],
    ),
    const CalculatorField(
      key: 'laminateThickness',
      labelKey: 'input.laminateThickness',
      hintKey: 'input.laminateThickness.hint',
      unitType: UnitType.millimeters,
      inputType: FieldInputType.select,
      defaultValue: 8,
      required: true,
      iconName: 'height',
      group: 'material',
      order: 11,
      options: [
        FieldOption(value: 6, labelKey: 'input.laminateThickness.6mm'),
        FieldOption(value: 7, labelKey: 'input.laminateThickness.7mm'),
        FieldOption(value: 8, labelKey: 'input.laminateThickness.8mm'),
        FieldOption(value: 10, labelKey: 'input.laminateThickness.10mm'),
        FieldOption(value: 12, labelKey: 'input.laminateThickness.12mm'),
        FieldOption(value: 14, labelKey: 'input.laminateThickness.14mm'),
      ],
    ),
    CalculatorField(
      key: 'packArea',
      labelKey: 'input.packArea',
      hintKey: 'input.packArea.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 2.0,
      minValue: 0.5,
      maxValue: 3.0,
      required: true,
      step: 0.1,
      iconName: 'inventory',
      group: 'material',
      order: 11,
    ),

    // --- Группа "Дополнительно" ---
    const CalculatorField(
      key: 'reserve',
      labelKey: 'input.reserve',
      hintKey: 'input.reserve.hint',
      unitType: UnitType.percent,
      inputType: FieldInputType.slider,
      defaultValue: 7,
      minValue: 5,
      maxValue: 15,
      step: 1,
      iconName: 'add_shopping_cart',
      group: 'advanced',
      order: 20,
    ),
    const CalculatorField(
      key: 'underlayType',
      labelKey: 'input.underlayType',
      hintKey: 'input.underlayType.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 3,
      required: true,
      iconName: 'layers',
      group: 'advanced',
      order: 21,
      options: [
        FieldOption(value: 2, labelKey: 'input.underlayType.2mm'),
        FieldOption(value: 3, labelKey: 'input.underlayType.3mm'),
        FieldOption(value: 5, labelKey: 'input.underlayType.5mm'),
      ],
    ),
    const CalculatorField(
      key: 'doorThresholds',
      labelKey: 'input.doorThresholds',
      hintKey: 'input.doorThresholds.hint',
      unitType: UnitType.pieces,
      defaultValue: 1,
      minValue: 0,
      maxValue: 10,
      required: false,
      step: 1,
      iconName: 'door_front',
      group: 'advanced',
      order: 22,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.laminate.before.measure',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.laminate.before.underlay',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.laminate.before.level',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.laminate.after.wedges',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.laminate.after.acclimatization',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.laminate.after.installation',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateLaminate(),
);
