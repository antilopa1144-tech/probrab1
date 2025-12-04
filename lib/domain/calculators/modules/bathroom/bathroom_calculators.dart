import '../../definitions.dart';
import '../../../usecases/calculate_bathroom_tile.dart';
import '../../../usecases/calculate_waterproofing.dart';

/// Калькуляторы для ванной комнаты и санузла
///
/// Содержит калькуляторы для расчёта материалов на отделку ванной:
/// - Плитка для ванной (стены и пол)
/// - Гидроизоляция (защита от влаги)
final List<CalculatorDefinition> bathroomCalculators = [
  CalculatorDefinition(
    id: 'bathroom_tile',
    titleKey: 'calculator.bathroomTile',
    category: 'Внутренняя отделка',
    subCategory: 'Ванная / туалет',
    fields: [
      const InputFieldDefinition(
        key: 'wallArea',
        labelKey: 'input.wallArea',
        minValue: 0.0,
        maxValue: 100.0,
      ),
      const InputFieldDefinition(
        key: 'floorArea',
        labelKey: 'input.floorArea',
        minValue: 0.0,
        maxValue: 50.0,
      ),
      const InputFieldDefinition(
        key: 'tileWidth',
        labelKey: 'input.tileWidth',
        defaultValue: 30.0,
        minValue: 10.0,
        maxValue: 120.0,
      ),
      const InputFieldDefinition(
        key: 'tileHeight',
        labelKey: 'input.tileHeight',
        defaultValue: 30.0,
        minValue: 10.0,
        maxValue: 120.0,
      ),
      const InputFieldDefinition(
        key: 'jointWidth',
        labelKey: 'input.jointWidth',
        defaultValue: 3.0,
        minValue: 1.0,
        maxValue: 10.0,
      ),
    ],
    resultLabels: {
      'wallArea': 'result.wallArea',
      'floorArea': 'result.floorArea',
      'totalTiles': 'result.tiles',
      'groutNeeded': 'result.grout',
      'glueNeeded': 'result.glue',
      'crossesNeeded': 'result.crosses',
      'waterproofingArea': 'result.waterproofing',
    },
    tips: const [
      'Используйте влагостойкий клей и затирку.',
      'Гидроизоляция обязательна для пола и нижней части стен.',
      'Проверьте ровность основания перед укладкой.',
      'Используйте крестики для равномерного шва.',
    ],
    useCase: CalculateBathroomTile(),
  ),
  CalculatorDefinition(
    id: 'bathroom_waterproof',
    titleKey: 'calculator.waterproofing',
    category: 'Внутренняя отделка',
    subCategory: 'Ванная / туалет',
    fields: [
      const InputFieldDefinition(
        key: 'floorArea',
        labelKey: 'input.floorArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'wallHeight',
        labelKey: 'input.wallHeight',
        defaultValue: 0.3,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'floorArea': 'result.floorArea',
      'wallArea': 'result.wallArea',
      'totalArea': 'result.totalArea',
      'materialNeeded': 'result.material',
      'primerNeeded': 'result.primer',
      'tapeLength': 'result.tape',
    },
    tips: const [
      'Гидроизоляция обязательна для пола и стен на высоту 30 см.',
      'Используйте армирующую ленту для углов и стыков.',
      'Наносите материал в два слоя перпендикулярно.',
      'Проверьте целостность покрытия перед укладкой плитки.',
    ],
    useCase: CalculateWaterproofing(),
  ),
];
