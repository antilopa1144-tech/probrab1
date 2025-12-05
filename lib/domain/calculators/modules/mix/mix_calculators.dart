import '../../definitions.dart';
import '../../../usecases/calculate_putty.dart';
import '../../../usecases/calculate_primer.dart';
import '../../../usecases/calculate_tile_glue.dart';
import '../../../usecases/calculate_plaster.dart';

/// Калькуляторы для строительных смесей
///
/// Содержит калькуляторы для расчёта материалов на смеси и ровнители:
/// - Шпаклёвка (стартовая и финишная)
/// - Грунтовка (глубокого проникновения)
/// - Плиточный клей
/// - Штукатурка (гипсовая и цементная)
final List<CalculatorDefinition> mixCalculators = [
  CalculatorDefinition(
    id: 'mixes_putty',
    titleKey: 'calculator.putty',
    category: 'Внутренняя отделка',
    subCategory: 'Ровнители / смеси',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 2.0,
      ),
      const InputFieldDefinition(
        key: 'type',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'puttyNeeded': 'result.putty',
      'primerNeeded': 'result.primer',
      'layers': 'result.layers',
      'spatulasNeeded': 'result.spatulas',
    },
    tips: const [
      'Стартовая шпаклёвка для выравнивания, финишная для гладкости.',
      'Наносите тонкими слоями.',
      'Шлифуйте между слоями.',
    ],
    useCase: CalculatePutty(),
  ),
  CalculatorDefinition(
    id: 'mixes_primer',
    titleKey: 'calculator.primer',
    category: 'Внутренняя отделка',
    subCategory: 'Ровнители / смеси',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
        key: 'type',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'primerNeeded': 'result.primer',
      'layers': 'result.layers',
      'rollersNeeded': 'result.rollers',
      'traysNeeded': 'result.trays',
    },
    tips: const [
      'Грунтовка улучшает адгезию материалов.',
      'Грунтовка глубокого проникновения для пористых поверхностей.',
      'Наносите равномерным слоем.',
    ],
    useCase: CalculatePrimer(),
  ),
  CalculatorDefinition(
    id: 'mixes_tile_glue',
    titleKey: 'calculator.tileGlue',
    category: 'Внутренняя отделка',
    subCategory: 'Ровнители / смеси',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'tileSize',
        labelKey: 'input.tileSize',
        defaultValue: 30.0,
      ),
      const InputFieldDefinition(
        key: 'layerThickness',
        labelKey: 'input.layerThickness',
        defaultValue: 5.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'glueNeeded': 'result.glue',
      'consumptionPerM2': 'result.consumption',
      'spatulasNeeded': 'result.spatulas',
    },
    tips: const [
      'Расход зависит от размера плитки и толщины слоя.',
      'Используйте зубчатый шпатель.',
      'Наносите клей на основание и плитку.',
    ],
    useCase: CalculateTileGlue(),
  ),
  CalculatorDefinition(
    id: 'mixes_plaster',
    titleKey: 'calculator.plaster',
    category: 'Внутренняя отделка',
    subCategory: 'Ровнители / смеси',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 10.0,
      ),
      const InputFieldDefinition(
        key: 'type',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'plasterNeeded': 'result.plaster',
      'primerNeeded': 'result.primer',
      'thickness': 'result.thickness',
      'beaconsNeeded': 'result.beacons',
    },
    tips: const [
      'Гипсовая штукатурка для внутренних работ.',
      'Цементная для влажных помещений и фасадов.',
      'Используйте маяки для ровной поверхности.',
    ],
    useCase: CalculatePlaster(),
  ),
];
