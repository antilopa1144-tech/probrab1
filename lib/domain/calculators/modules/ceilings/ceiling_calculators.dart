import '../../definitions.dart';
import '../../../usecases/calculate_ceiling_paint.dart';
import '../../../usecases/calculate_stretch_ceiling.dart';
import '../../../usecases/calculate_gkl_ceiling.dart';
import '../../../usecases/calculate_rail_ceiling.dart';
import '../../../usecases/calculate_cassette_ceiling.dart';
import '../../../usecases/calculate_ceiling_tiles.dart';
import '../../../usecases/calculate_ceiling_insulation.dart';

/// Калькуляторы для потолков
///
/// Содержит калькуляторы для расчёта материалов на отделку потолков:
/// - Покраска потолка
/// - Натяжные потолки
/// - Потолки из ГКЛ (гипсокартон)
/// - Реечные потолки
/// - Кассетные потолки
/// - Потолочная плитка
/// - Утепление потолка
final List<CalculatorDefinition> ceilingCalculators = [
  CalculatorDefinition(
    id: 'ceilings_paint',
    titleKey: 'calculator.ceilingPaint',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 2.0,
      ),
      InputFieldDefinition(
        key: 'consumption',
        labelKey: 'input.consumption',
        defaultValue: 0.12,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'paintNeeded': 'result.paint',
      'primerNeeded': 'result.primer',
      'layers': 'result.layers',
    },
    tips: const [
      'Используйте валик с длинным ворсом для потолка.',
      'Красьте перпендикулярно окну для равномерного покрытия.',
      'Не забудьте защитить стены и пол плёнкой.',
    ],
    useCase: CalculateCeilingPaint(),
  ),
  CalculatorDefinition(
    id: 'ceilings_stretch',
    titleKey: 'calculator.stretchCeiling',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'corners',
        labelKey: 'input.corners',
        defaultValue: 4.0,
      ),
      InputFieldDefinition(
        key: 'fixtures',
        labelKey: 'input.fixtures',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'canvasArea': 'result.canvas',
      'baguetteLength': 'result.baguette',
      'cornersNeeded': 'result.corners',
      'fixtures': 'result.fixtures',
    },
    tips: const [
      'Монтаж выполняют специалисты с опытом.',
      'Заранее определите места для светильников.',
      'Учитывайте высоту потолка — натяжной потолок опускает его на 3–5 см.',
    ],
    useCase: CalculateStretchCeiling(),
  ),
  CalculatorDefinition(
    id: 'ceilings_gkl',
    titleKey: 'calculator.gklCeiling',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'ceilingHeight',
        labelKey: 'input.ceilingHeight',
        defaultValue: 2.5,
      ),
      InputFieldDefinition(
        key: 'dropHeight',
        labelKey: 'input.dropHeight',
        defaultValue: 0.1,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'sheetsNeeded': 'result.sheets',
      'guideLength': 'result.guide',
      'ceilingProfileLength': 'result.ceilingProfile',
      'hangersNeeded': 'result.hangers',
      'screwsNeeded': 'result.screws',
      'puttyNeeded': 'result.putty',
    },
    tips: const [
      'Шаг подвесов — 60 см для надёжности.',
      'Проверьте уровень всех профилей.',
      'Используйте армирующую ленту на стыках листов.',
    ],
    useCase: CalculateGklCeiling(),
  ),
  CalculatorDefinition(
    id: 'ceilings_rail',
    titleKey: 'calculator.railCeiling',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'railWidth',
        labelKey: 'input.railWidth',
        defaultValue: 10.0,
      ),
      InputFieldDefinition(
        key: 'railLength',
        labelKey: 'input.railLength',
        defaultValue: 300.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'railsNeeded': 'result.rails',
      'guideLength': 'result.guide',
      'hangersNeeded': 'result.hangers',
      'cornerLength': 'result.corner',
    },
    tips: const [
      'Монтируйте рейки перпендикулярно направляющим.',
      'Оставляйте зазор для вентиляции.',
      'Используйте уровень для контроля плоскости.',
    ],
    useCase: CalculateRailCeiling(),
  ),
  CalculatorDefinition(
    id: 'ceilings_cassette',
    titleKey: 'calculator.cassetteCeiling',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'cassetteSize',
        labelKey: 'input.tileSize',
        defaultValue: 60.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'cassettesNeeded': 'result.panels',
      'guideLength': 'result.guide',
      'hangersNeeded': 'result.hangers',
    },
    tips: const [
      'Кассеты легко заменяются при повреждении.',
      'Обеспечьте доступ к коммуникациям над потолком.',
      'Используйте уровень для монтажа направляющих.',
    ],
    useCase: CalculateCassetteCeiling(),
  ),
  CalculatorDefinition(
    id: 'ceilings_tiles',
    titleKey: 'calculator.ceilingTiles',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'tileSize',
        labelKey: 'input.tileSize',
        defaultValue: 50.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'tilesNeeded': 'result.tiles',
      'glueNeeded': 'result.glue',
      'primerNeeded': 'result.primer',
    },
    tips: const [
      'Проверьте ровность потолка перед укладкой.',
      'Используйте специальный клей для потолочной плитки.',
      'Начинайте укладку от центра комнаты.',
    ],
    useCase: CalculateCeilingTiles(),
  ),
  CalculatorDefinition(
    id: 'ceilings_insulation',
    titleKey: 'calculator.ceilingInsulation',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'insulationThickness',
        labelKey: 'input.insulationThickness',
        defaultValue: 100.0,
      ),
      InputFieldDefinition(
        key: 'insulationType',
        labelKey: 'input.insulationType',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'volume': 'result.volume',
      'sheetsNeeded': 'result.sheets',
      'vaporBarrierArea': 'result.vaporBarrier',
      'fastenersNeeded': 'result.fasteners',
    },
    tips: const [
      'Используйте пароизоляцию с внутренней стороны.',
      'Не сжимайте утеплитель при укладке.',
      'Обеспечьте вентиляцию подкровельного пространства.',
    ],
    useCase: CalculateCeilingInsulation(),
  ),
];
