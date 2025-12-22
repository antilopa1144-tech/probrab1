// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_ceiling_paint.dart';

final ceilingsPaintCalculatorV2 = CalculatorDefinitionV2(
  id: 'ceilings_paint',
  titleKey: calculatorTitleKey('ceilings_paint'),
  descriptionKey: calculatorDescriptionKey('ceilings_paint'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.paint',
  iconName: 'format_paint',
  accentColor: kCalculatorAccentColor,
  fields: const [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 500,
      required: true,
      step: 0.1,
    ),
    CalculatorField(
      key: 'layers',
      labelKey: 'input.layers',
      hintKey: 'input.layers.hint',
      unitType: UnitType.pieces,
      defaultValue: 2,
      minValue: 1,
      maxValue: 4,
      required: true,
      step: 1,
    ),
    CalculatorField(
      key: 'consumption',
      labelKey: 'input.consumption',
      hintKey: 'input.consumption.hint',
      unitType: UnitType.litersPerSqm,
      defaultValue: 0.12,
      minValue: 0.05,
      maxValue: 0.2,
      required: false,
      step: 0.01,
    ),
    CalculatorField(
      key: 'perimeter',
      labelKey: 'input.perimeter',
      hintKey: 'input.perimeter.hint',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0,
      maxValue: 200,
      required: false,
      step: 0.1,
    ),
  ],
  useCase: CalculateCeilingPaint(),
);
