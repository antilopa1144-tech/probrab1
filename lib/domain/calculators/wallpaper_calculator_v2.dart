// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_wallpaper.dart';

/// Калькулятор обоев V2 с поддержкой гибридного ввода.
final wallpaperCalculatorV2 = CalculatorDefinitionV2(
  id: 'walls_wallpaper',
  titleKey: calculatorTitleKey('walls_wallpaper'),
  descriptionKey: calculatorDescriptionKey('walls_wallpaper'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.walls',
  iconName: 'wallpaper',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 100,
  tags: ['обои', 'стены', 'отделка', 'wallpaper', 'walls', 'decoration'],

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
      key: 'wallHeight',
      labelKey: 'input.wallHeight',
      hintKey: 'input.wallHeight.hint',
      unitType: UnitType.meters,
      defaultValue: 2.5,
      minValue: 2.0,
      maxValue: 5.0,
      required: true,
      step: 0.1,
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
      order: 4,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),
    const CalculatorField(
      key: 'wallHeight',
      labelKey: 'input.wallHeight',
      hintKey: 'input.wallHeight.hint',
      unitType: UnitType.meters,
      defaultValue: 2.5,
      minValue: 2.0,
      maxValue: 5.0,
      required: true,
      step: 0.1,
      iconName: 'height',
      order: 5,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),

    // --- Общие поля (материал рулона) ---
    const CalculatorField(
      key: 'rollWidth',
      labelKey: 'input.rollWidth',
      hintKey: 'input.rollWidth.hint',
      unitType: UnitType.meters,
      defaultValue: 0.53,
      minValue: 0.5,
      maxValue: 1.2,
      required: true,
      step: 0.01,
      iconName: 'straighten',
      order: 10,
    ),
    const CalculatorField(
      key: 'rollLength',
      labelKey: 'input.rollLength',
      hintKey: 'input.rollLength.hint',
      unitType: UnitType.meters,
      defaultValue: 10.05,
      minValue: 5.0,
      maxValue: 50.0,
      required: true,
      step: 0.1,
      iconName: 'straighten',
      order: 11,
    ),
    const CalculatorField(
      key: 'rapport',
      labelKey: 'input.rapport',
      hintKey: 'input.rapport.hint',
      unitType: UnitType.centimeters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      step: 5.0,
      iconName: 'layers',
      order: 12,
    ),

    // --- Группа "Проёмы" (дополнительно) ---
    const CalculatorField(
      key: 'windowsArea',
      labelKey: 'input.windows_area',
      hintKey: 'input.windows_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
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
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 50.0,
      required: false,
      step: 0.1,
      iconName: 'door_front',
      group: 'openings',
      order: 21,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.wallpaper.before.measure',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.wallpaper.before.rapport',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.wallpaper.before.margin',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.wallpaper.after.level',
    ),
    CalculatorHint(type: HintType.tip, messageKey: 'hint.wallpaper.after.glue'),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.wallpaper.after.installation',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateWallpaper(),
);
