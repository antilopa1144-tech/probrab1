// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_wallpaper.dart';

/// Калькулятор обоев V2.
final wallpaperCalculatorV2 = CalculatorDefinitionV2(
  id: 'walls_wallpaper',
  titleKey: calculatorTitleKey('walls_wallpaper'),
  descriptionKey: calculatorDescriptionKey('walls_wallpaper'),
  category: CalculatorCategory.interior,
  subCategory: 'Стены',
  iconName: 'wallpaper',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 100,
  tags: ['обои', 'стены', 'отделка', 'wallpaper', 'walls', 'decoration'],

  // Поля ввода
  fields: [
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
      order: 1,
    ),
    CalculatorField(
      key: 'rollWidth',
      labelKey: 'input.rollWidth',
      hintKey: 'input.rollWidth.hint',
      unitType: UnitType.meters,
      defaultValue: 0.53,
      minValue: 0.5,
      maxValue: 1.2,
      required: true,
      step: 0.01,
      iconName: 'width_normal',
      group: 'roll',
      order: 2,
    ),
    CalculatorField(
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
      group: 'roll',
      order: 3,
    ),
    CalculatorField(
      key: 'rapport',
      labelKey: 'input.rapport',
      hintKey: 'input.rapport.hint',
      unitType: UnitType.centimeters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      step: 5.0,
      iconName: 'repeat',
      group: 'roll',
      order: 4,
    ),
    CalculatorField(
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
    ),
    CalculatorField(
      key: 'windowsArea',
      labelKey: 'input.windowsArea',
      hintKey: 'input.windowsArea.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      step: 0.1,
      iconName: 'window',
      group: 'openings',
      order: 6,
    ),
    CalculatorField(
      key: 'doorsArea',
      labelKey: 'input.doorsArea',
      hintKey: 'input.doorsArea.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 50.0,
      required: false,
      step: 0.1,
      iconName: 'door_front',
      group: 'openings',
      order: 7,
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
