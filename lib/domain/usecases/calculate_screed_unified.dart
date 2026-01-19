import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Тип материала для стяжки
enum ScreedMaterialType {
  /// Готовая сухая смесь (ЦПС М300 или М150)
  readyMix,

  /// Самозамес: цемент + песок
  selfMix,
}

/// Объединённый калькулятор стяжки пола.
///
/// Поддерживает:
/// - 3 типа стяжки: цементно-песчаная, полусухая, бетонная
/// - 2 способа: готовая сухая смесь (ЦПС) или самозамес (цемент + песок)
/// - 2 режима ввода площади: вручную или по размерам комнаты
/// - Расчёт армирующей сетки, демпферной ленты, маяков, плёнки
/// - Расчёт стоимости с учётом текущих цен
///
/// Поля:
/// - inputMode: режим ввода (0 = по площади, 1 = по комнате)
/// - area: площадь (м²) — для режима 0
/// - roomWidth, roomLength: размеры комнаты (м) — для режима 1
/// - thickness: толщина слоя (мм), 30-150
/// - screedType: тип стяжки (0=ЦПС, 1=полусухая, 2=бетонная)
/// - materialType: способ (0=готовая смесь, 1=самозамес)
/// - mixGrade: марка смеси (0=М300, 1=М150) — только для готовой смеси
/// - bagWeight: вес мешка (кг) — только для готовой смеси
/// - needMesh: нужна ли армирующая сетка (0/1)
/// - needFilm: нужна ли плёнка ПЭ (0/1)
/// - needTape: нужна ли демпферная лента (0/1)
/// - needBeacons: нужны ли маяки (0/1)
class CalculateScreedUnified extends BaseCalculator {
  // ==========================================================================
  // Константы для самозамеса (цемент + песок)
  // ==========================================================================

  /// Расход цемента по типу стяжки (кг/м³)
  static const Map<int, double> cementPerCbm = {
    0: 400.0, // Цементно-песчаная М150 (пропорция 1:3)
    1: 350.0, // Полусухая (меньше воды)
    2: 300.0, // Бетон М200 (с добавлением щебня)
  };

  /// Расход песка по типу стяжки (кг/м³)
  static const Map<int, double> sandPerCbm = {
    0: 1200.0, // ЦПС 1:3
    1: 1050.0, // Полусухая
    2: 900.0, // Бетон (часть заменяется щебнем)
  };

  /// Расход щебня для бетонной стяжки (кг/м³)
  static const double gravelPerCbm = 900.0;

  /// Вес стандартного мешка цемента (кг)
  static const double cementBagWeight = 50.0;

  /// Плотность песка (кг/м³)
  static const double sandDensity = 1500.0;

  // ==========================================================================
  // Константы для готовой сухой смеси (ЦПС)
  // ==========================================================================

  /// Расход сухой смеси (кг/м²/мм толщины)
  static const Map<int, double> mixConsumption = {
    0: 2.0, // М300 Пескобетон: ~20-22 кг на 1 см
    1: 1.8, // М150 Универсальная: ~18 кг на 1 см
  };

  // ==========================================================================
  // Константы для дополнительных материалов
  // ==========================================================================

  /// Запас на армирующую сетку (%)
  static const double meshMargin = 10.0;

  /// Запас на плёнку ПЭ (%)
  static const double filmMargin = 15.0;

  /// Шаг установки маяков (м²/шт)
  static const double beaconStep = 1.5;

  /// Минимальная безопасная толщина стяжки (мм)
  static const double minSafeThickness = 30.0;

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

    // --- Параметры стяжки ---
    final screedType = getIntInput(inputs, 'screedType', defaultValue: 0, minValue: 0, maxValue: 2);
    final materialType = getIntInput(inputs, 'materialType', defaultValue: 0, minValue: 0, maxValue: 1);
    final thickness = getInput(inputs, 'thickness', defaultValue: 50.0, minValue: 10.0, maxValue: 200.0);

    // --- Опции ---
    final needMesh = getIntInput(inputs, 'needMesh', defaultValue: 1) == 1;
    final needFilm = getIntInput(inputs, 'needFilm', defaultValue: 1) == 1;
    final needTape = getIntInput(inputs, 'needTape', defaultValue: 1) == 1;
    final needBeacons = getIntInput(inputs, 'needBeacons', defaultValue: 1) == 1;

    // --- Объём стяжки ---
    final volume = calculateVolume(area, thickness);

    // --- Расчёт основных материалов ---
    double cementKg = 0;
    int cementBags = 0;
    double sandKg = 0;
    double sandCbm = 0;
    double gravelKg = 0;
    double gravelCbm = 0;
    double mixWeightKg = 0;
    int mixBags = 0;

    if (materialType == 0) {
      // Готовая сухая смесь (ЦПС)
      final mixGrade = getIntInput(inputs, 'mixGrade', defaultValue: 0, minValue: 0, maxValue: 1);
      final bagWeight = getInput(inputs, 'bagWeight', defaultValue: 40.0, minValue: 25.0, maxValue: 50.0);

      final consumption = mixConsumption[mixGrade] ?? 2.0;
      mixWeightKg = area * thickness * consumption;
      mixBags = ceilToInt(mixWeightKg / bagWeight);
    } else {
      // Самозамес (цемент + песок)
      cementKg = volume * (cementPerCbm[screedType] ?? 400.0);
      sandKg = volume * (sandPerCbm[screedType] ?? 1200.0);
      cementBags = ceilToInt(cementKg / cementBagWeight);
      sandCbm = sandKg / sandDensity;

      // Для бетонной стяжки добавляем щебень
      if (screedType == 2) {
        gravelKg = volume * gravelPerCbm;
        gravelCbm = gravelKg / 1400; // Плотность щебня ~1400 кг/м³
      }
    }

    // --- Армирующая сетка ---
    final meshArea = needMesh ? addMargin(area, meshMargin) : 0.0;

    // --- Плёнка ПЭ ---
    final filmArea = needFilm ? addMargin(area, filmMargin) : 0.0;

    // --- Демпферная лента ---
    final tapeMeters = needTape ? perimeter : 0.0;

    // --- Маяки ---
    final beaconsNeeded = needBeacons ? ceilToInt(area / beaconStep) : 0;

    // --- Предупреждение о толщине ---
    final thicknessWarning = thickness < minSafeThickness ? 1.0 : 0.0;

    // --- Расчёт стоимости ---
    final costs = <double?>[];

    if (materialType == 0) {
      // Готовая смесь
      final mixGrade = getIntInput(inputs, 'mixGrade', defaultValue: 0);
      final mixSku = mixGrade == 0 ? 'dsp_m300' : 'dsp_m150';
      final mixPrice = findPrice(priceList, [mixSku, 'cement_sand_mix', 'dry_mix']);
      costs.add(calculateCost(mixBags.toDouble(), mixPrice?.price));
    } else {
      // Самозамес
      final cementPrice = findPrice(priceList, ['cement', 'cement_bag', 'cement_m400', 'цемент']);
      final sandPrice = findPrice(priceList, ['sand', 'sand_construction', 'песок']);
      costs.add(calculateCost(cementBags.toDouble(), cementPrice?.price));
      costs.add(calculateCost(sandCbm, sandPrice?.price));

      if (screedType == 2) {
        final gravelPrice = findPrice(priceList, ['gravel', 'crushed_stone', 'щебень']);
        costs.add(calculateCost(gravelCbm, gravelPrice?.price));
      }
    }

    // Дополнительные материалы
    if (needMesh) {
      final meshPrice = findPrice(priceList, ['mesh', 'armature_mesh', 'mesh_reinforcing', 'сетка']);
      costs.add(calculateCost(meshArea, meshPrice?.price));
    }

    if (needFilm) {
      final filmPrice = findPrice(priceList, ['film', 'pe_film', 'плёнка']);
      costs.add(calculateCost(filmArea, filmPrice?.price));
    }

    if (needTape) {
      final tapePrice = findPrice(priceList, ['tape_damper', 'damper_tape', 'демпферная_лента']);
      costs.add(calculateCost(tapeMeters, tapePrice?.price));
    }

    if (needBeacons) {
      final beaconPrice = findPrice(priceList, ['beacon', 'beacon_metal', 'profile_beacon', 'маяк']);
      costs.add(calculateCost(beaconsNeeded.toDouble(), beaconPrice?.price));
    }

    return createResult(
      values: {
        // Основные результаты
        'area': area,
        'perimeter': perimeter,
        'thickness': thickness,
        'volume': volume,
        'screedType': screedType.toDouble(),
        'materialType': materialType.toDouble(),

        // Для готовой смеси
        'mixWeightKg': mixWeightKg,
        'mixWeightTonnes': mixWeightKg / 1000,
        'mixBags': mixBags.toDouble(),

        // Для самозамеса
        'cementKg': cementKg,
        'cementBags': cementBags.toDouble(),
        'sandKg': sandKg,
        'sandCbm': sandCbm,
        'gravelKg': gravelKg,
        'gravelCbm': gravelCbm,

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
      },
      totalPrice: sumCosts(costs),
    );
  }
}
