import '../../definitions.dart';
import '../../../usecases/calculate_roofing_metal.dart';
import '../../../usecases/calculate_soft_roofing.dart';
import '../../../usecases/calculate_gutters.dart';

/// Калькуляторы для кровли
///
/// Содержит калькуляторы для расчёта материалов на кровельные работы:
/// - Металлическая кровля (профнастил, металлочерепица)
/// - Мягкая кровля (битумная черепица)
/// - Водосточные системы (желоба и водостоки)
final List<CalculatorDefinition> roofingCalculators = [
  CalculatorDefinition(
    id: 'roofing_metal',
    titleKey: 'calculator.metalRoofing',
    category: 'Наружная отделка',
    subCategory: 'Кровля',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 10.0,
        maxValue: 1000.0,
      ),
      InputFieldDefinition(
        key: 'slope',
        labelKey: 'input.slope',
        defaultValue: 30.0,
        minValue: 5.0,
        maxValue: 60.0,
      ),
      InputFieldDefinition(
        key: 'sheetWidth',
        labelKey: 'input.sheetWidth',
        defaultValue: 1.18,
        minValue: 0.5,
        maxValue: 2.0,
      ),
      InputFieldDefinition(
        key: 'sheetLength',
        labelKey: 'input.sheetLength',
        defaultValue: 2.5,
        minValue: 1.0,
        maxValue: 8.0,
      ),
      InputFieldDefinition(
        key: 'ridgeLength',
        labelKey: 'input.ridgeLength',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'valleyLength',
        labelKey: 'input.valleyLength',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'endLength',
        labelKey: 'input.endLength',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'realArea': 'result.realArea',
      'sheetsNeeded': 'result.sheets',
      'ridgeLength': 'result.ridge',
      'valleyLength': 'result.valley',
      'eaveLength': 'result.eave',
      'endLength': 'result.end',
      'screwsNeeded': 'result.screws',
      'waterproofingArea': 'result.waterproofing',
    },
    tips: const [
      'Учитывайте уклон крыши при расчёте площади.',
      'Используйте специальные саморезы с уплотнителями.',
      'Укладывайте листы с нахлёстом 15-20 см.',
      'Не забудьте про гидроизоляцию под кровлей.',
    ],
    useCase: CalculateRoofingMetal(),
  ),
  CalculatorDefinition(
    id: 'roofing_soft',
    titleKey: 'calculator.softRoofing',
    category: 'Наружная отделка',
    subCategory: 'Кровля',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'slope',
        labelKey: 'input.slope',
        defaultValue: 30.0,
      ),
      InputFieldDefinition(
        key: 'ridgeLength',
        labelKey: 'input.ridgeLength',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'valleyLength',
        labelKey: 'input.valleyLength',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'realArea': 'result.realArea',
      'packsNeeded': 'result.packs',
      'underlaymentArea': 'result.underlayment',
      'ridgeStripLength': 'result.ridge',
      'valleyCarpetLength': 'result.valley',
      'nailsNeeded': 'result.nails',
      'masticNeeded': 'result.mastic',
      'deckingArea': 'result.decking',
      'dripEdgeLength': 'result.dripEdge',
      'ventilationsNeeded': 'result.ventilation',
    },
    tips: const [
      'Битумная черепица подходит для крыш с уклоном от 12°.',
      'Обязательно используйте подкладочный ковёр.',
      'Монтаж при температуре выше +5°C.',
      'Укладывайте снизу вверх с перекрытием.',
    ],
    useCase: CalculateSoftRoofing(),
  ),
  CalculatorDefinition(
    id: 'roofing_gutters',
    titleKey: 'calculator.gutters',
    category: 'Наружная отделка',
    subCategory: 'Кровля',
    fields: const [
      InputFieldDefinition(
        key: 'roofLength',
        labelKey: 'input.roofLength',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'roofArea',
        labelKey: 'input.roofArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'gutterLength',
        labelKey: 'input.gutterLength',
        defaultValue: 3.0,
      ),
    ],
    resultLabels: const {
      'gutterLength': 'result.guide',
      'downpipeLength': 'result.pipeLength',
      'gutterBrackets': 'result.fasteners',
      'pipeBrackets': 'result.fasteners',
      'corners': 'result.corners',
      'endCaps': 'result.corners',
      'funnels': 'result.boxes',
      'elbows': 'result.fittings',
    },
    tips: const [
      'Устанавливайте желоба с уклоном 3-5 мм на 1 м.',
      'Кронштейны монтируются через каждые 50-60 см.',
      'На каждые 10 м² крыши — 1 водосточная труба.',
      'Используйте герметик для соединений.',
    ],
    useCase: CalculateGutters(),
  ),
];
