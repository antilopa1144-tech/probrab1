// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/canonical_bridge.dart';
import '../usecases/foundation_slab_canonical_adapter.dart';

/// Калькулятор монолитной плиты V2.
final slabFoundationCalculatorV2 = CalculatorDefinitionV2(
  id: 'foundation_slab',
  titleKey: calculatorTitleKey('foundation_slab'),
  descriptionKey: calculatorDescriptionKey('foundation_slab'),
  category: CalculatorCategory.exterior,
  subCategoryKey: 'subcategory.slab',
  iconName: 'foundation',
  accentColor: kCalculatorAccentColor,
  complexity: 3,
  popularity: 85,
  tags: ['фундамент', 'плита', 'монолит', 'бетон', 'foundation', 'slab'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'length',
      labelKey: 'input.length',
      hintKey: 'input.foundationSlabLength.hint',
      unitType: UnitType.meters,
      defaultValue: 10.0,
      minValue: 1.0,
      maxValue: 50.0,
      required: true,
      step: 0.5,
      iconName: 'straighten',
      order: 1,
    ),
    CalculatorField(
      key: 'width',
      labelKey: 'input.width',
      hintKey: 'input.foundationSlabWidth.hint',
      unitType: UnitType.meters,
      defaultValue: 6.0,
      minValue: 1.0,
      maxValue: 50.0,
      required: true,
      step: 0.5,
      iconName: 'straighten',
      order: 2,
    ),
    CalculatorField(
      key: 'thickness',
      labelKey: 'input.foundationSlabThickness',
      hintKey: 'input.foundationSlabThickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 200.0,
      minValue: 150.0,
      maxValue: 300.0,
      required: true,
      step: 10.0,
      iconName: 'height',
      order: 3,
    ),
    CalculatorField(
      key: 'rebarDiam',
      labelKey: 'input.rebarDiameter',
      hintKey: 'input.rebarDiameter.hint',
      unitType: UnitType.millimeters,
      defaultValue: 12.0,
      minValue: 10.0,
      maxValue: 16.0,
      required: true,
      step: 2.0,
      iconName: 'grid_on',
      group: 'materials',
      order: 4,
    ),
    CalculatorField(
      key: 'rebarStep',
      labelKey: 'input.rebarStep',
      hintKey: 'input.rebarStep.hint',
      unitType: UnitType.millimeters,
      defaultValue: 200.0,
      minValue: 150.0,
      maxValue: 250.0,
      required: true,
      step: 50.0,
      iconName: 'grid_4x4',
      group: 'materials',
      order: 5,
    ),
    CalculatorField(
      key: 'sandLayerMm',
      labelKey: 'input.sandLayerThickness',
      hintKey: 'input.sandLayerThickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 100.0,
      minValue: 0.0,
      maxValue: 500.0,
      required: true,
      step: 10.0,
      iconName: 'layers',
      group: 'preparation',
      order: 6,
    ),
    CalculatorField(
      key: 'gravelLayerMm',
      labelKey: 'input.gravelLayerThickness',
      hintKey: 'input.gravelLayerThickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 150.0,
      minValue: 0.0,
      maxValue: 500.0,
      required: true,
      step: 10.0,
      iconName: 'layers',
      group: 'preparation',
      order: 7,
    ),
    CalculatorField(
      key: 'insulationThickness',
      labelKey: 'input.insulationThickness',
      hintKey: 'input.insulationThickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 150.0,
      required: false,
      step: 50.0,
      iconName: 'layers',
      group: 'materials',
      order: 8,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.foundation.slab.before.min_thickness',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.foundation.slab.before.preparation',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.foundation.slab.before.waterproofing',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.foundation.slab.after.reinforcement',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.foundation.slab.after.insulation',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        fieldKey: 'insulationThickness',
        value: 0,
      ),
    ),
  ],

  // UseCase для расчёта
  useCase: CanonicalBridgeUseCase(calculateCanonicalFoundationSlab),
);
