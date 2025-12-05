import '../../definitions.dart';
import '../../../usecases/calculate_siding.dart';
import '../../../usecases/calculate_facade_panels.dart';
import '../../../usecases/calculate_wood_facade.dart';
import '../../../usecases/calculate_brick_facing.dart';
import '../../../usecases/calculate_wet_facade.dart';

/// Калькуляторы для наружной отделки
///
/// Содержит калькуляторы для расчёта материалов на наружную отделку:
/// - Сайдинг
/// - Фасадные панели
/// - Деревянный фасад
/// - Облицовочный кирпич
/// - Мокрый фасад
final List<CalculatorDefinition> exteriorCalculators = [
  CalculatorDefinition(
    id: 'exterior_siding',
    titleKey: 'calculator.siding',
    category: 'Наружная отделка',
    subCategory: 'Сайдинг',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 10.0,
        maxValue: 1000.0,
      ),
      const InputFieldDefinition(
        key: 'panelWidth',
        labelKey: 'input.panelWidth',
        defaultValue: 20.0,
        minValue: 10.0,
        maxValue: 50.0,
      ),
      const InputFieldDefinition(
        key: 'panelLength',
        labelKey: 'input.panelLength',
        defaultValue: 300.0,
        minValue: 200.0,
        maxValue: 600.0,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 200.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'corners',
        labelKey: 'input.corners',
        defaultValue: 4.0,
        minValue: 4.0,
        maxValue: 20.0,
      ),
      const InputFieldDefinition(
        key: 'soffitLength',
        labelKey: 'input.soffitLength',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'panelsNeeded': 'result.panels',
      'jProfileLength': 'result.jProfile',
      'cornerLength': 'result.corners',
      'startStripLength': 'result.startStrip',
      'finishStripLength': 'result.finishStrip',
      'soffitLength': 'result.soffit',
      'screwsNeeded': 'result.screws',
    },
    tips: const [
      'Не забудьте J-профиль, углы, стартовую и финишную планку.',
      'Оставляйте температурные зазоры (5-10 мм) для расширения материала.',
      'Монтируйте сайдинг снизу вверх, начиная со стартовой планки.',
      'Используйте саморезы с пресс-шайбой, не затягивайте их до упора.',
    ],
    useCase: CalculateSiding(),
  ),
  CalculatorDefinition(
    id: 'exterior_facade_panels',
    titleKey: 'calculator.facadePanels',
    category: 'Наружная отделка',
    subCategory: 'Фасадные панели',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'panelWidth',
        labelKey: 'input.panelWidth',
        defaultValue: 50.0,
      ),
      const InputFieldDefinition(
        key: 'panelHeight',
        labelKey: 'input.panelHeight',
        defaultValue: 100.0,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'panelsNeeded': 'result.panels',
      'fastenersNeeded': 'result.fasteners',
      'cornersLength': 'result.corners',
      'startStripLength': 'result.startStrip',
    },
    tips: const [
      'Фасадные панели долговечны и не требуют ухода.',
      'Используйте качественные крепления.',
      'Оставляйте зазор для температурного расширения.',
    ],
    useCase: CalculateFacadePanels(),
  ),
  CalculatorDefinition(
    id: 'exterior_wood',
    titleKey: 'calculator.woodFacade',
    category: 'Наружная отделка',
    subCategory: 'Дерево',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'boardWidth',
        labelKey: 'input.boardWidth',
        defaultValue: 14.0,
      ),
      const InputFieldDefinition(
        key: 'boardLength',
        labelKey: 'input.boardLength',
        defaultValue: 3.0,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'boardsNeeded': 'result.boards',
      'cornersLength': 'result.corners',
      'finishNeeded': 'result.finish',
      'fastenersNeeded': 'result.fasteners',
    },
    tips: const [
      'Используйте защитные составы для дерева.',
      'Обрабатывайте торцы досок.',
      'Оставляйте зазор для вентиляции.',
    ],
    useCase: CalculateWoodFacade(),
  ),
  CalculatorDefinition(
    id: 'exterior_brick',
    titleKey: 'calculator.brickFacing',
    category: 'Наружная отделка',
    subCategory: 'Облицовочный кирпич',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 0.5,
      ),
      const InputFieldDefinition(
        key: 'windowsArea',
        labelKey: 'input.windowsArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'doorsArea',
        labelKey: 'input.doorsArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'wallHeight',
        labelKey: 'input.wallHeight',
        defaultValue: 2.5,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'usefulArea': 'result.usefulArea',
      'bricksNeeded': 'result.bricks',
      'mortarVolume': 'result.mortar',
      'cementNeeded': 'result.cement',
      'sandNeeded': 'result.sand',
      'reinforcementLength': 'result.reinforcement',
    },
    tips: const [
      'Используйте облицовочный кирпич с правильной геометрией.',
      'Армируйте через каждые 5 рядов.',
      'Проверяйте вертикальность каждого ряда.',
      'Защитите кладку от дождя во время работ.',
    ],
    useCase: CalculateBrickFacing(),
  ),
  CalculatorDefinition(
    id: 'exterior_wet_facade',
    titleKey: 'calculator.wetFacade',
    category: 'Наружная отделка',
    subCategory: 'Мокрый фасад',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'insulationThickness',
        labelKey: 'input.insulationThickness',
        defaultValue: 100.0,
      ),
      const InputFieldDefinition(
        key: 'insulationType',
        labelKey: 'input.insulationType',
        defaultValue: 2.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'insulationVolume': 'result.insulationVolume',
      'sheetsNeeded': 'result.sheets',
      'glueNeeded': 'result.glue',
      'fastenersNeeded': 'result.fasteners',
      'meshArea': 'result.mesh',
      'plasterNeeded': 'result.plaster',
      'primerNeeded': 'result.primer',
      'finishNeeded': 'result.finish',
    },
    tips: const [
      'Работы выполняйте при температуре выше +5°C.',
      'Используйте армирующую сетку для прочности.',
      'Наносите штукатурку в два слоя.',
      'Защитите фасад от дождя во время работ.',
    ],
    useCase: CalculateWetFacade(),
  ),
];
