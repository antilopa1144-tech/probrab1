import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_sheeting_osb_plywood.dart';
import 'calculator_constants.dart';

final sheetingOsbPlywoodCalculatorV2 = CalculatorDefinitionV2(
  id: 'sheeting_osb_plywood',
  titleKey: 'calculator.sheeting_osb_plywood.title',
  descriptionKey: 'calculator.sheeting_osb_plywood.description',
  category: CalculatorCategory.interior,
  subCategory: 'ОСБ/фанера',
  tags: ['осб', 'фанера', 'лист', 'sheets', 'osb', 'plywood'],
  accentColor: kCalculatorAccentColor,
  useCase: CalculateSheetingOsbPlywood(),
  fields: const [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      required: true,
      minValue: 0.1,
      maxValue: 10000.0,
    ),
    CalculatorField(
      key: 'sheetLength',
      labelKey: 'input.sheetLength',
      hintKey: 'input.sheetLength.hint',
      unitType: UnitType.meters,
      defaultValue: 2.5,
      required: false,
    ),
    CalculatorField(
      key: 'sheetWidth',
      labelKey: 'input.sheetWidth',
      hintKey: 'input.sheetWidth.hint',
      unitType: UnitType.meters,
      defaultValue: 1.25,
      required: false,
    ),
    CalculatorField(
      key: 'screwsPerM2',
      labelKey: 'input.screwsPerM2',
      hintKey: 'input.screwsPerM2.hint',
      unitType: UnitType.pieces,
      defaultValue: 20.0,
      required: false,
    ),
    CalculatorField(
      key: 'reserve',
      labelKey: 'input.reserve',
      unitType: UnitType.percent,
      defaultValue: 10.0,
      required: false,
    ),
  ],
  beforeHints: const [
    CalculatorHint(
      type: HintType.tip,
      messageKey:
          'Для пола шаг саморезов обычно 150–200 мм по краям и 200–300 мм по полю листа.',
    ),
  ],
);
