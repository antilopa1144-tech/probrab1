import '../../definitions.dart';
import '../../../usecases/calculate_strip_foundation.dart';
import '../../../usecases/calculate_slab.dart';
import '../../../usecases/calculate_basement.dart';
import '../../../usecases/calculate_blind_area.dart';

/// Калькуляторы для фундаментов
///
/// Включает расчёты для различных типов фундаментов:
/// - Ленточный фундамент
/// - Монолитная плита
/// - Цокольный этаж
/// - Отмостка
final List<CalculatorDefinition> foundationCalculators = [
  // Ленточный фундамент
  CalculatorDefinition(
    id: 'calculator.stripTitle',
    titleKey: 'calculator.stripTitle',
    category: 'Фундамент',
    subCategory: 'Ленточный фундамент',
    fields: [
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        minValue: 4.0,
        maxValue: 500.0,
      ),
      InputFieldDefinition(
        key: 'width',
        labelKey: 'input.width',
        minValue: 0.2,
        maxValue: 2.0,
        defaultValue: 0.4,
      ),
      InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        minValue: 0.3,
        maxValue: 3.0,
        defaultValue: 0.8,
      ),
    ],
    resultLabels: {
      'concreteVolume': 'result.volume',
      'rebarWeight': 'result.rebar',
    },
    tips: const [
      'Снимите плодородный слой и утрамбуйте основание перед заливкой.',
      'Используйте песчано-щебёночную подушку не менее 200 мм.',
      'Контролируйте диагонали опалубки — от этого зависит геометрия стен.',
      'Заранее подготовьте закладные гильзы для инженерных коммуникаций.',
    ],
    useCase: CalculateStripFoundation(),
  ),

  // Монолитная плита
  CalculatorDefinition(
    id: 'foundation_slab',
    titleKey: 'calculator.slab',
    category: 'Фундамент',
    subCategory: 'Монолитная плита',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 0.2,
      ),
      InputFieldDefinition(
        key: 'insulation',
        labelKey: 'input.insulationThickness',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'thickness': 'result.thickness',
      'concreteVolume': 'result.volume',
      'rebarWeight': 'result.rebar',
      'sandVolume': 'result.sand',
      'gravelVolume': 'result.gravel',
      'waterproofingArea': 'result.waterproofing',
      'insulationVolume': 'result.insulation',
      'formworkArea': 'result.formwork',
      'wireNeeded': 'result.wire',
      'plasticizerNeeded': 'result.plasticizer',
    },
    tips: const [
      'Плита толщиной минимум 200 мм для жилого дома.',
      'Обязательна песчано-гравийная подготовка.',
      'Гидроизоляция снизу и по периметру.',
      'Армирование двумя сетками в верхней и нижней зонах.',
      'Утеплитель (ЭППС) под плитой для теплого пола.',
    ],
    useCase: CalculateSlab(),
  ),

  // Цокольный этаж
  CalculatorDefinition(
    id: 'foundation_basement',
    titleKey: 'calculator.basement',
    category: 'Фундамент',
    subCategory: 'Цокольный этаж',
    fields: [
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 2.5,
      ),
      InputFieldDefinition(
        key: 'wallThickness',
        labelKey: 'input.wallThickness',
        defaultValue: 0.4,
      ),
      InputFieldDefinition(
        key: 'floorArea',
        labelKey: 'input.floorArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'floorThickness',
        labelKey: 'input.floorThickness',
        defaultValue: 0.15,
      ),
    ],
    resultLabels: {
      'concreteVolume': 'result.volume',
      'rebarWeight': 'result.rebar',
      'waterproofingArea': 'result.waterproofing',
      'insulationArea': 'result.insulation',
    },
    tips: const [
      'Гидроизоляция по всей площади контакта с грунтом.',
      'Утепление наружное (ЭППС) минимум 100 мм.',
      'Армирование стен вертикальными и горизонтальными сетками.',
      'Вентиляция обязательна для предотвращения сырости.',
    ],
    useCase: CalculateBasement(),
  ),

  // Отмостка
  CalculatorDefinition(
    id: 'foundation_blind_area',
    titleKey: 'calculator.blindArea',
    category: 'Фундамент',
    subCategory: 'Отмостка',
    fields: [
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'width',
        labelKey: 'input.width',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 0.1,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'concreteVolume': 'result.volume',
      'sandVolume': 'result.sand',
      'gravelVolume': 'result.gravel',
    },
    tips: const [
      'Минимальная ширина 60 см, рекомендуемая 1 м.',
      'Уклон от дома 1-2 см на метр.',
      'Песчано-гравийная подушка 15-20 см.',
      'Компенсационный шов между отмосткой и цоколем.',
    ],
    useCase: CalculateBlindArea(),
  ),
];
