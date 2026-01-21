import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Тип сухой смеси для стяжки
enum ScreedMixType {
  /// ЦПС - цементно-песчаная смесь (мелкая фракция)
  cps,

  /// Пескобетон (крупная фракция с гравием)
  peskobeton,
}

/// Марки ЦПС
enum CpsMarka {
  /// М100 — для выравнивания, под плитку (расход ~15 кг/м²/см)
  m100,

  /// М150 — универсальная, стяжка до 50 мм (расход ~17 кг/м²/см)
  m150,

  /// М200 — высокопрочная, стяжка 50-100 мм (расход ~18 кг/м²/см)
  m200,
}

/// Марки Пескобетона
enum PeskobetonMarka {
  /// М200 — для стяжки в жилых помещениях (расход ~19 кг/м²/см)
  m200,

  /// М300 — стандарт, для стяжки и заливки (расход ~20 кг/м²/см)
  m300,

  /// М400 — высокопрочный, для гаражей и складов (расход ~22 кг/м²/см)
  m400,
}

/// Калькулятор стяжки пола (ЦПС / Пескобетон).
///
/// Рассчитывает количество сухой смеси для стяжки пола по СП 29.13330.2011.
///
/// ## Поддерживаемые типы смесей:
///
/// **ЦПС (цементно-песчаная смесь):**
/// - М100 — выравнивание, расход 15 кг/м²/см
/// - М150 — универсальная, расход 17 кг/м²/см
/// - М200 — высокопрочная, расход 18 кг/м²/см
///
/// **Пескобетон:**
/// - М200 — жилые помещения, расход 19 кг/м²/см
/// - М300 — стандарт, расход 20 кг/м²/см
/// - М400 — высокопрочный, расход 22 кг/м²/см
///
/// ## Входные параметры:
/// - inputMode: режим ввода (0 = по площади, 1 = по комнате)
/// - area: площадь (м²) — для режима 0
/// - roomWidth, roomLength: размеры комнаты (м) — для режима 1
/// - thickness: толщина слоя (мм), 10-150
/// - mixType: тип смеси (0=ЦПС, 1=Пескобетон)
/// - cpsMarka: марка ЦПС (0=М100, 1=М150, 2=М200)
/// - peskobetonMarka: марка Пескобетона (0=М200, 1=М300, 2=М400)
/// - bagWeight: вес мешка (кг)
/// - needMesh, needFilm, needTape, needBeacons: опции (0/1)
class CalculateScreedUnified extends BaseCalculator {
  // ==========================================================================
  // Расход сухой смеси по СП 29.13330.2011 (кг на м² при толщине 10 мм)
  // ==========================================================================

  /// Расход ЦПС по маркам (кг/м²/см)
  static const Map<int, double> cpsConsumption = {
    0: 15.0, // М100 — выравнивание
    1: 17.0, // М150 — универсальная
    2: 18.0, // М200 — высокопрочная
  };

  /// Расход Пескобетона по маркам (кг/м²/см)
  static const Map<int, double> peskobetonConsumption = {
    0: 19.0, // М200 — жилые
    1: 20.0, // М300 — стандарт
    2: 22.0, // М400 — высокопрочный
  };

  /// Рекомендуемые марки по толщине стяжки
  static String getRecommendedMarka(int mixType, double thickness) {
    if (mixType == 0) {
      // ЦПС
      if (thickness <= 30) return 'М100';
      if (thickness <= 50) return 'М150';
      return 'М200';
    } else {
      // Пескобетон
      if (thickness <= 40) return 'М200';
      if (thickness <= 80) return 'М300';
      return 'М400';
    }
  }

  // ==========================================================================
  // Константы для дополнительных материалов
  // ==========================================================================

  /// Запас на армирующую сетку (%)
  static const double meshMargin = 10.0;

  /// Запас на плёнку ПЭ (%)
  static const double filmMargin = 15.0;

  /// Шаг установки маяков (м²/шт) — примерно 1 маяк на 1.5 м²
  static const double beaconStep = 1.5;

  /// Минимальная безопасная толщина стяжки (мм) по СП
  static const double minSafeThickness = 30.0;

  /// Рекомендуемая минимальная толщина для ЦПС (мм)
  static const double minCpsThickness = 20.0;

  /// Рекомендуемая минимальная толщина для Пескобетона (мм)
  static const double minPeskobetonThickness = 30.0;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode'] ?? 0;
    final area = inputs['area'] ?? 0;
    final roomWidth = inputs['roomWidth'];
    final roomLength = inputs['roomLength'];

    if (inputMode == 0 && area <= 0) {
      return 'Площадь должна быть больше нуля';
    }

    if (inputMode == 1 && (roomWidth == null || roomLength == null)) {
      return 'Необходимо указать размеры комнаты';
    }

    final thickness = inputs['thickness'] ?? 50;
    if (thickness < 10 || thickness > 200) {
      return 'Толщина слоя должна быть от 10 до 200 мм';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // --- Режим ввода площади ---
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0);

    // Вычисляем площадь и периметр
    double area;
    double perimeter;

    if (inputMode == 0) {
      // Режим "По площади"
      area = getInput(inputs, 'area', defaultValue: 20.0, minValue: 1.0, maxValue: 500.0);
      perimeter = estimatePerimeter(area);
    } else {
      // Режим "По комнате"
      final roomWidth = getInput(inputs, 'roomWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 30.0);
      final roomLength = getInput(inputs, 'roomLength', defaultValue: 5.0, minValue: 0.5, maxValue: 30.0);
      area = roomWidth * roomLength;
      perimeter = (roomWidth + roomLength) * 2;
    }

    // --- Параметры смеси ---
    final mixType = getIntInput(inputs, 'mixType', defaultValue: 0, minValue: 0, maxValue: 1);
    final thickness = getInput(inputs, 'thickness', defaultValue: 50.0, minValue: 10.0, maxValue: 150.0);
    final bagWeight = getInput(inputs, 'bagWeight', defaultValue: 40.0, minValue: 25.0, maxValue: 50.0);

    // --- Опции ---
    final needMesh = getIntInput(inputs, 'needMesh', defaultValue: 1) == 1;
    final needFilm = getIntInput(inputs, 'needFilm', defaultValue: 1) == 1;
    final needTape = getIntInput(inputs, 'needTape', defaultValue: 1) == 1;
    final needBeacons = getIntInput(inputs, 'needBeacons', defaultValue: 1) == 1;

    // --- Объём стяжки ---
    final volume = calculateVolume(area, thickness);

    // --- Расход смеси ---
    double consumption;
    int marka;

    if (mixType == 0) {
      // ЦПС
      marka = getIntInput(inputs, 'cpsMarka', defaultValue: 1, minValue: 0, maxValue: 2);
      consumption = cpsConsumption[marka] ?? 17.0;
    } else {
      // Пескобетон
      marka = getIntInput(inputs, 'peskobetonMarka', defaultValue: 1, minValue: 0, maxValue: 2);
      consumption = peskobetonConsumption[marka] ?? 20.0;
    }

    // Формула: площадь × толщина(см) × расход(кг/м²/см)
    final thicknessCm = thickness / 10.0;
    final mixWeightKg = area * thicknessCm * consumption;
    final mixBags = ceilToInt(mixWeightKg / bagWeight);

    // --- Армирующая сетка ---
    final meshArea = needMesh ? addMargin(area, meshMargin) : 0.0;

    // --- Плёнка ПЭ ---
    final filmArea = needFilm ? addMargin(area, filmMargin) : 0.0;

    // --- Демпферная лента ---
    final tapeMeters = needTape ? perimeter : 0.0;

    // --- Маяки ---
    final beaconsNeeded = needBeacons ? ceilToInt(area / beaconStep) : 0;

    // --- Предупреждения ---
    final thicknessWarning = thickness < minSafeThickness ? 1.0 : 0.0;

    // Предупреждение о минимальной толщине для типа смеси
    final minThicknessForType = mixType == 0 ? minCpsThickness : minPeskobetonThickness;
    final typeThicknessWarning = thickness < minThicknessForType ? 1.0 : 0.0;

    // --- Расчёт стоимости ---
    final costs = <double?>[];

    // Смесь
    String mixSku;
    if (mixType == 0) {
      mixSku = marka == 0 ? 'cps_m100' : (marka == 1 ? 'cps_m150' : 'cps_m200');
    } else {
      mixSku = marka == 0 ? 'peskobeton_m200' : (marka == 1 ? 'peskobeton_m300' : 'peskobeton_m400');
    }
    final mixPrice = findPrice(priceList, [mixSku, 'dry_mix', 'cement_sand_mix']);
    costs.add(calculateCost(mixBags.toDouble(), mixPrice?.price));

    // Дополнительные материалы
    if (needMesh) {
      final meshPrice = findPrice(priceList, ['mesh', 'armature_mesh', 'mesh_reinforcing']);
      costs.add(calculateCost(meshArea, meshPrice?.price));
    }

    if (needFilm) {
      final filmPrice = findPrice(priceList, ['film', 'pe_film']);
      costs.add(calculateCost(filmArea, filmPrice?.price));
    }

    if (needTape) {
      final tapePrice = findPrice(priceList, ['tape_damper', 'damper_tape']);
      costs.add(calculateCost(tapeMeters, tapePrice?.price));
    }

    if (needBeacons) {
      final beaconPrice = findPrice(priceList, ['beacon', 'beacon_metal', 'profile_beacon']);
      costs.add(calculateCost(beaconsNeeded.toDouble(), beaconPrice?.price));
    }

    return createResult(
      values: {
        // Основные результаты
        'area': area,
        'perimeter': perimeter,
        'thickness': thickness,
        'volume': volume,
        'mixType': mixType.toDouble(),
        'marka': marka.toDouble(),

        // Смесь
        'mixWeightKg': mixWeightKg,
        'mixWeightTonnes': mixWeightKg / 1000,
        'mixBags': mixBags.toDouble(),
        'consumption': consumption,

        // Дополнительные материалы
        'needMesh': needMesh ? 1.0 : 0.0,
        'meshArea': meshArea,
        'needFilm': needFilm ? 1.0 : 0.0,
        'filmArea': filmArea,
        'needTape': needTape ? 1.0 : 0.0,
        'tapeMeters': tapeMeters,
        'needBeacons': needBeacons ? 1.0 : 0.0,
        'beaconsNeeded': beaconsNeeded.toDouble(),

        // Предупреждения
        'thicknessWarning': thicknessWarning,
        'typeThicknessWarning': typeThicknessWarning,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
