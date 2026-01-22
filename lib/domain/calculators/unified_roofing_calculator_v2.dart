import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_unified_roofing.dart';
import 'calculator_constants.dart';

/// V2 Definition для единого калькулятора кровли
///
/// Объединяет все типы кровельных материалов:
/// - Металлочерепица
/// - Мягкая кровля
/// - Профнастил
/// - Ондулин
/// - Шифер
/// - Керамическая черепица
final unifiedRoofingCalculatorV2 = CalculatorDefinitionV2(
  id: 'roofing_unified',
  titleKey: 'calculator.roofing_unified.title',
  descriptionKey: 'calculator.roofing_unified.description',
  category: CalculatorCategory.exterior,
  subCategoryKey: 'subcategory.roofing',
  fields: [
    const CalculatorField(
      key: 'roofingType',
      labelKey: 'input.roofingType',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 0,
      required: true,
      order: 1,
      options: [
        FieldOption(value: 0, labelKey: 'input.roofingType.metalTile'),
        FieldOption(value: 1, labelKey: 'input.roofingType.softRoofing'),
        FieldOption(value: 2, labelKey: 'input.roofingType.profiledSheet'),
        FieldOption(value: 3, labelKey: 'input.roofingType.ondulin'),
        FieldOption(value: 4, labelKey: 'input.roofingType.slate'),
        FieldOption(value: 5, labelKey: 'input.roofingType.ceramicTile'),
      ],
    ),
    const CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      unitType: UnitType.squareMeters,
      inputType: FieldInputType.number,
      defaultValue: 100.0,
      minValue: 10.0,
      maxValue: 1000.0,
      required: true,
      order: 2,
    ),
    const CalculatorField(
      key: 'slope',
      labelKey: 'input.slope',
      unitType: UnitType.degrees,
      inputType: FieldInputType.number,
      defaultValue: 30.0,
      minValue: 5.0,
      maxValue: 60.0,
      required: true,
      order: 3,
    ),
    const CalculatorField(
      key: 'ridgeLength',
      labelKey: 'input.ridgeLength',
      unitType: UnitType.meters,
      inputType: FieldInputType.number,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      order: 4,
    ),
    const CalculatorField(
      key: 'valleyLength',
      labelKey: 'input.valleyLength',
      unitType: UnitType.meters,
      inputType: FieldInputType.number,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      order: 5,
    ),
    const CalculatorField(
      key: 'sheetWidth',
      labelKey: 'input.sheetWidth',
      unitType: UnitType.meters,
      inputType: FieldInputType.number,
      defaultValue: 1.18,
      minValue: 0.5,
      maxValue: 2.0,
      required: false,
      order: 6,
    ),
    const CalculatorField(
      key: 'sheetLength',
      labelKey: 'input.sheetLength',
      unitType: UnitType.meters,
      inputType: FieldInputType.number,
      defaultValue: 2.5,
      minValue: 1.0,
      maxValue: 12.0,
      required: false,
      order: 7,
    ),
  ],
  beforeHints: [
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.roofing.uchityvayte_uklon_kryshi_pri',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.roofing.ne_zabudte_pro_gidroizolyatsiyu',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.roofing.ukladyvayte_listy_s_nahlestom',
    ),
  ],
  afterHints: [
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.roofing.ispolzuyte_spetsialnye_samorezy_s',
    ),
  ],
  useCase: CalculateUnifiedRoofing(),
  accentColor: kCalculatorAccentColor,
  complexity: 3,
  popularity: 15,
  tags: [
    'roofing',
    'roofing_unified',
    'roof',
    'tag.krovlya',
    'tag.naruzhnaya_otdelka',
  ],
);
