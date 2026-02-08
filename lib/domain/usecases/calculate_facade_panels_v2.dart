import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Характеристики типа фасадных панелей.
class _PanelSpec {
  /// Площадь одной панели/элемента (м²)
  final double unitArea;

  /// Запас на подрезку (%)
  final double wastePercent;

  /// Шаг обрешётки (м). 0 = обрешётка не нужна (клеевой монтаж)
  final double profileStep;

  const _PanelSpec({
    required this.unitArea,
    required this.wastePercent,
    required this.profileStep,
  });
}

/// Калькулятор фасадных панелей V2.
///
/// Входные параметры:
/// - wallLength: периметр дома (м), 10-200, по умолчанию 40
/// - wallHeight: высота стен (м), 2-10, по умолчанию 3
/// - openingsArea: площадь проёмов (м²), 0-50, по умолчанию 10
/// - panelType: тип панелей (0-6), по умолчанию 0
/// - needInsulation: утепление (0/1), по умолчанию 1
/// - needProfile: обрешётка (0/1), по умолчанию 1
///
/// Типы панелей:
/// 0 = Виниловый сайдинг (3660×230 мм ≈ 0.84 м²)
/// 1 = Металлосайдинг (3000×270 мм ≈ 0.81 м²)
/// 2 = Фиброцементный сайдинг (3600×190 мм ≈ 0.68 м²)
/// 3 = Блок-хаус деревянный (3000×140 мм ≈ 0.42 м²)
/// 4 = Фасадные термопанели (1000×500 мм = 0.50 м²)
/// 5 = Профлист стеновой С-8 (2000×1150 мм ≈ 2.30 м²)
/// 6 = HPL-панели (1300×3050 мм ≈ 3.97 м²)
///
/// Выходные значения:
/// - wallArea: площадь стен (м²)
/// - panelsArea: площадь панелей с запасом (м²)
/// - panelsCount: количество панелей (шт)
/// - profileLength: длина профиля (м.п.)
/// - insulationArea: площадь утеплителя (м²)
/// - cornersCount: количество угловых элементов (шт)
/// - startersCount: количество стартовых планок (шт)
class CalculateFacadePanelsV2 extends BaseCalculator {
  // Характеристики по типу панелей (российский рынок)
  static const List<_PanelSpec> _specs = [
    // 0: Виниловый сайдинг — Grand Line, Döcke, FineBer
    // 3660×230 мм (рабочая ширина), лёгкий, запас 10%, обрешётка 400 мм
    _PanelSpec(unitArea: 0.84, wastePercent: 10, profileStep: 0.4),

    // 1: Металлосайдинг — стальной, МЕТАЛЛ ПРОФИЛЬ, Grand Line
    // 3000×270 мм (рабочая), прочный, запас 7%, обрешётка 400 мм
    _PanelSpec(unitArea: 0.81, wastePercent: 7, profileStep: 0.4),

    // 2: Фиброцементный сайдинг — Cedral, Eternit
    // 3600×190 мм, тяжёлый, хрупкий, запас 12%, обрешётка 600 мм
    _PanelSpec(unitArea: 0.68, wastePercent: 12, profileStep: 0.6),

    // 3: Блок-хаус деревянный — натуральная древесина
    // 3000×140 мм (рабочая), естественные потери, запас 15%, обрешётка 500 мм
    _PanelSpec(unitArea: 0.42, wastePercent: 15, profileStep: 0.5),

    // 4: Фасадные термопанели — клинкер/пенополистирол
    // 1000×500 мм, клеевой монтаж, запас 5%, обрешётка не нужна
    _PanelSpec(unitArea: 0.50, wastePercent: 5, profileStep: 0),

    // 5: Профлист стеновой С-8/С-10 — МЕТАЛЛ ПРОФИЛЬ
    // 2000×1150 мм (рабочая), минимум отходов, запас 8%, обрешётка 600 мм
    _PanelSpec(unitArea: 2.30, wastePercent: 8, profileStep: 0.6),

    // 6: HPL-панели — композитные, вентфасад
    // 1300×3050 мм, дорогие, точный раскрой, запас 10%, обрешётка 600 мм
    _PanelSpec(unitArea: 3.97, wastePercent: 10, profileStep: 0.6),
  ];

  // Запас на утеплитель
  static const double insulationWastePercent = 5.0;

  // Запас на профиль обрешётки
  static const double profileWastePercent = 10.0;

  // Длина доборных профилей
  static const double cornerProfileLength = 3.0; // м
  static const double starterProfileLength = 3.0; // м

  // Количество внешних углов дома
  static const int externalCorners = 4;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final wallLength = getInput(inputs, 'wallLength',
        defaultValue: 40.0, minValue: 10.0, maxValue: 200.0);
    final wallHeight = getInput(inputs, 'wallHeight',
        defaultValue: 3.0, minValue: 2.0, maxValue: 10.0);
    final openingsArea = getInput(inputs, 'openingsArea',
        defaultValue: 10.0, minValue: 0.0, maxValue: 50.0);
    final panelType = getIntInput(inputs, 'panelType',
        defaultValue: 0, minValue: 0, maxValue: _specs.length - 1);
    final needInsulation = getIntInput(inputs, 'needInsulation',
        defaultValue: 1, minValue: 0, maxValue: 1);
    final needProfile = getIntInput(inputs, 'needProfile',
        defaultValue: 1, minValue: 0, maxValue: 1);

    final spec = _specs[panelType];

    // Площадь стен
    final grossArea = wallLength * wallHeight;
    final wallArea = grossArea - openingsArea;

    // Панели с запасом по типу
    final panelsArea = wallArea * (1 + spec.wastePercent / 100);
    final panelsCount = (panelsArea / spec.unitArea).ceil();

    // Профиль для обрешётки
    double profileLength = 0;
    if (needProfile == 1 && spec.profileStep > 0) {
      final verticals = (wallLength / spec.profileStep).ceil();
      profileLength = verticals * wallHeight * (1 + profileWastePercent / 100);
    }

    // Утеплитель
    final insulationArea = needInsulation == 1
        ? wallArea * (1 + insulationWastePercent / 100)
        : 0.0;

    // Углы: 4 внешних угла × высота / длина профиля
    final cornersCount =
        (externalCorners * wallHeight / cornerProfileLength).ceil();

    // Стартовые планки: периметр / длина профиля
    final startersCount = (wallLength / starterProfileLength).ceil();

    // Расчёт стоимости
    double? totalPrice;

    final panelPrice = findPrice(priceList, ['facade_panel', 'siding']);
    final profilePrice = findPrice(priceList, ['profile', 'metal_profile']);
    final insulationPrice = findPrice(priceList, ['insulation', 'mineral_wool']);
    final cornerPrice = findPrice(priceList, ['corner', 'corner_profile']);
    final starterPrice = findPrice(priceList, ['starter', 'starter_profile']);

    if (panelPrice != null) {
      totalPrice = (totalPrice ?? 0) + panelsArea * panelPrice.price;
    }
    if (needProfile == 1 && profilePrice != null) {
      totalPrice = (totalPrice ?? 0) + profileLength * profilePrice.price;
    }
    if (needInsulation == 1 && insulationPrice != null) {
      totalPrice = (totalPrice ?? 0) + insulationArea * insulationPrice.price;
    }
    if (cornerPrice != null) {
      totalPrice = (totalPrice ?? 0) + cornersCount * cornerPrice.price;
    }
    if (starterPrice != null) {
      totalPrice = (totalPrice ?? 0) + startersCount * starterPrice.price;
    }

    return createResult(
      values: {
        'wallLength': wallLength,
        'wallHeight': wallHeight,
        'openingsArea': openingsArea,
        'panelType': panelType.toDouble(),
        'needInsulation': needInsulation.toDouble(),
        'needProfile': needProfile.toDouble(),
        'grossArea': grossArea,
        'wallArea': wallArea,
        'panelsArea': panelsArea,
        'panelsCount': panelsCount.toDouble(),
        'profileLength': profileLength,
        'insulationArea': insulationArea,
        'cornersCount': cornersCount.toDouble(),
        'startersCount': startersCount.toDouble(),
        'wastePercent': spec.wastePercent,
      },
      totalPrice: totalPrice,
    );
  }
}
