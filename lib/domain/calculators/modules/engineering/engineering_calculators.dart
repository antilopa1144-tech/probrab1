import '../../definitions.dart';
import '../../../usecases/calculate_electrics.dart';
import '../../../usecases/calculate_plumbing.dart';
import '../../../usecases/calculate_heating.dart';
import '../../../usecases/calculate_ventilation.dart';

/// Калькуляторы для инженерных работ
///
/// Содержит калькуляторы для расчёта материалов на инженерные системы:
/// - Электрика (проводка, розетки, выключатели)
/// - Сантехника (трубы, фитинги, сантехприборы)
/// - Отопление (радиаторы, трубы, мощность)
/// - Вентиляция (воздуховоды, решётки, вентиляторы)
final List<CalculatorDefinition> engineeringCalculators = [
  CalculatorDefinition(
    id: 'engineering_electrics',
    titleKey: 'calculator.electrics',
    category: 'Инженерные работы',
    subCategory: 'Электрика',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 5.0,
        maxValue: 1000.0,
      ),
      const InputFieldDefinition(
        key: 'rooms',
        labelKey: 'input.rooms',
        defaultValue: 1.0,
        minValue: 1.0,
        maxValue: 50.0,
      ),
      const InputFieldDefinition(
        key: 'sockets',
        labelKey: 'input.sockets',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 200.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'switches',
        labelKey: 'input.switches',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'rooms': 'result.rooms',
      'sockets': 'result.sockets',
      'switches': 'result.switches',
      'wireLength': 'result.wire',
      'cableChannelLength': 'result.cableChannel',
      'circuitBreakers': 'result.breakers',
      'junctionBoxes': 'result.boxes',
    },
    tips: const [
      'Работы должен выполнять квалифицированный электрик.',
      'Используйте кабель сечением не менее 2.5 мм² для розеток.',
      'Установите УЗО для защиты от утечек тока.',
      'Проверьте все соединения перед включением.',
    ],
    useCase: CalculateElectrics(),
  ),
  CalculatorDefinition(
    id: 'engineering_plumbing',
    titleKey: 'calculator.plumbing',
    category: 'Инженерные работы',
    subCategory: 'Сантехника',
    fields: [
      const InputFieldDefinition(
        key: 'rooms',
        labelKey: 'input.rooms',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
        key: 'points',
        labelKey: 'input.points',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'pipeLength',
        labelKey: 'input.pipeLength',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'rooms': 'result.rooms',
      'points': 'result.points',
      'pipeLength': 'result.pipeLength',
      'fittingsNeeded': 'result.fittings',
      'tapsNeeded': 'result.taps',
      'mixersNeeded': 'result.mixers',
      'toiletsNeeded': 'result.toilets',
      'sinksNeeded': 'result.sinks',
      'showersNeeded': 'result.showers',
    },
    tips: const [
      'Используйте качественные фитинги для надёжности.',
      'Проверьте все соединения на герметичность.',
      'Установите запорные краны на каждую точку.',
      'Работы должен выполнять квалифицированный сантехник.',
    ],
    useCase: CalculatePlumbing(),
  ),
  CalculatorDefinition(
    id: 'engineering_heating',
    titleKey: 'calculator.heating',
    category: 'Инженерные работы',
    subCategory: 'Отопление',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 10.0,
        maxValue: 1000.0,
      ),
      const InputFieldDefinition(
        key: 'rooms',
        labelKey: 'input.rooms',
        defaultValue: 1.0,
        minValue: 1.0,
        maxValue: 50.0,
      ),
      const InputFieldDefinition(
        key: 'ceilingHeight',
        labelKey: 'input.ceilingHeight',
        defaultValue: 2.5,
        minValue: 2.2,
        maxValue: 5.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'volume': 'result.volume',
      'totalPower': 'result.power',
      'totalSections': 'result.sections',
      'pipeLength': 'result.pipeLength',
      'fittingsNeeded': 'result.fittings',
      'valvesNeeded': 'result.valves',
      'thermostatsNeeded': 'result.thermostats',
    },
    tips: const [
      'Расчёт мощности: 100 Вт на м² для средней полосы.',
      'Установите терморегуляторы для экономии.',
      'Используйте балансировочные краны.',
      'Работы должен выполнять квалифицированный специалист.',
    ],
    useCase: CalculateHeating(),
  ),
  CalculatorDefinition(
    id: 'engineering_ventilation',
    titleKey: 'calculator.ventilation',
    category: 'Инженерные работы',
    subCategory: 'Вентиляция',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'rooms',
        labelKey: 'input.rooms',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
        key: 'ceilingHeight',
        labelKey: 'input.ceilingHeight',
        defaultValue: 2.5,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'volume': 'result.volume',
      'airExchange': 'result.power',
      'ductsNeeded': 'result.boxes',
      'grillesNeeded': 'result.boxes',
      'fansNeeded': 'result.boxes',
      'ductLength': 'result.pipeLength',
    },
    tips: const [
      'Воздухообмен: минимум 3 м³/ч на м².',
      'Устанавливайте решётки вверху для вытяжки, внизу для притока.',
      'Проверьте тягу перед монтажом вентиляторов.',
    ],
    useCase: CalculateVentilation(),
  ),
];
