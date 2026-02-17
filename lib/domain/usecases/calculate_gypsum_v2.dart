import '../../data/models/price_item.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор гипсокартонных конструкций (domain layer)
///
/// Входные параметры:
/// - inputMode: 0 = по площади, 1 = по размерам комнаты (default: 0)
/// - area: площадь м² (для режима 0, default: 20)
/// - length: длина комнаты м (default: 4)
/// - width: ширина комнаты м (default: 3)
/// - height: высота комнаты м (default: 2.7)
/// - constructionType: 0 = облицовка стен, 1 = перегородка, 2 = потолок (default: 0)
/// - gklType: 0 = стандартный, 1 = влагостойкий, 2 = огнестойкий (default: 0)
/// - thickness: 0 = 9.5 мм, 1 = 12.5 мм (default: 1)
/// - sheetSize: 0 = 2000x1200, 1 = 2500x1200, 2 = 2700x1200, 3 = 3000x1200 (default: 1)
/// - layers: 1 или 2 (default: 1)
/// - useInsulation: 0/1 (default: 0)
///
/// Выходные параметры:
/// - calculatedArea: расчётная площадь м²
/// - gklSheets: количество листов ГКЛ
/// - sheetArea: площадь одного листа м²
/// - pnPieces: профиль ПН шт
/// - pnMeters: профиль ПН м
/// - ppPieces: профиль ПП шт
/// - ppMeters: профиль ПП м
/// - screwsTN25: саморезы TN 25 мм шт
/// - screwsTN35: саморезы TN 35 мм шт (для 2 слоя)
/// - screwsLN: саморезы LN шт
/// - dowels: дюбели шт
/// - suspensions: подвесы шт
/// - connectors: соединители шт
/// - insulationArea: утеплитель м²
/// - sealingTape: уплотнительная лента м
/// - armatureTape: армирующая лента м
/// - fillerKg: шпаклёвка кг
/// - primerLiters: грунтовка л
/// - sheetWeight: вес одного листа кг
/// - totalWeight: общий вес ГКЛ кг
class CalculateGypsumV2 extends BaseCalculator {
  // Sheet sizes (area in m²)
  static const Map<int, double> sheetAreas = {
    0: 2.4,   // 2000x1200
    1: 3.0,   // 2500x1200
    2: 3.24,  // 2700x1200
    3: 3.6,   // 3000x1200
  };

  // Sheet weights by thickness and size (kg)
  // thickness: 0 = 9.5mm, 1 = 12.5mm
  // size: 0 = 2000x1200, 1 = 2500x1200, 2 = 2700x1200, 3 = 3000x1200
  static const Map<int, Map<int, double>> sheetWeights = {
    0: {0: 18.0, 1: 22.5, 2: 24.3, 3: 27.0},   // 9.5mm (~7.5 кг/м²)
    1: {0: 23.0, 1: 29.0, 2: 31.3, 3: 34.7},   // 12.5mm (~9.6 кг/м²)
  };

  // GKL multipliers
  static const double gklBaseMultiplier = 1.05;
  static const double gklPartitionMultiplier = 2.0;

  // Profile standard length
  static const double profileLength = 3.0;

  // Wall lining constants (облицовка стен)
  static const double wallLiningPnMeters = 0.8;
  static const double wallLiningPpMeters = 2.0;
  static const double wallLiningSuspensions = 1.3;
  static const double wallLiningDowels = 1.6;
  static const int wallLiningScrewsTN25 = 34;
  static const int wallLiningScrewsLN = 4;
  static const double wallLiningSealingTape = 0.8;

  // Partition constants (перегородки)
  static const double partitionPnMeters = 0.7;
  static const double partitionPpMeters = 2.0;
  static const double partitionDowels = 1.5;
  static const int partitionScrewsTN25 = 50;
  static const int partitionScrewsLN = 4;
  static const double partitionSealingTape = 1.2;

  // Ceiling constants (потолки)
  static const double ceilingPnMeters = 0.4;
  static const double ceilingPpMeters = 3.3;
  static const double ceilingSuspensions = 0.7;
  static const double ceilingConnectors = 2.4;
  static const int ceilingDowelsPerSuspension = 2;
  static const int ceilingScrewsTN25 = 23;
  static const int ceilingScrewsLN = 7;

  // Second layer constants
  static const int secondLayerScrewsTN35 = 17;
  static const int secondLayerPartitionMultiplier = 2;

  // Materials
  static const double insulationMargin = 1.05;
  static const double armatureTapePerSqm = 1.2;
  // Шпаклёвка: Knauf Fugen ~0.8 кг/м² (заделка швов + финиш), перегородка ×2 стороны
  static const double fillerStandard = 0.8;
  static const double fillerPartition = 1.5; // 0.8 × 2 стороны - 0.1 (нет стыков у стены)
  // Грунтовка: 0.15 л/м² одна сторона, перегородка ×2 стороны
  static const double primerPerSqm = 0.15;
  static const double primerPartitionPerSqm = 0.3;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Input mode: 0 = by area, 1 = by room dimensions
    final inputMode = getInput(inputs, 'inputMode', defaultValue: 0.0, minValue: 0.0, maxValue: 1.0).round();

    // Dimensions
    final area = getInput(inputs, 'area', defaultValue: 20.0, minValue: 1.0, maxValue: 500.0);
    final length = getInput(inputs, 'length', defaultValue: 4.0, minValue: 1.0, maxValue: 20.0);
    final width = getInput(inputs, 'width', defaultValue: 3.0, minValue: 1.0, maxValue: 20.0);
    final height = getInput(inputs, 'height', defaultValue: 2.7, minValue: 2.0, maxValue: 5.0);

    // Construction settings
    final constructionType = getInput(inputs, 'constructionType', defaultValue: 0.0, minValue: 0.0, maxValue: 2.0).round();
    final gklType = getInput(inputs, 'gklType', defaultValue: 0.0, minValue: 0.0, maxValue: 2.0).round();
    final thickness = getInput(inputs, 'thickness', defaultValue: 1.0, minValue: 0.0, maxValue: 1.0).round(); // 0 = 9.5mm, 1 = 12.5mm
    final sheetSizeIndex = getInput(inputs, 'sheetSize', defaultValue: 1.0, minValue: 0.0, maxValue: 3.0).round();
    final layers = getInput(inputs, 'layers', defaultValue: 1.0, minValue: 1.0, maxValue: 2.0).round();
    final useInsulation = getInput(inputs, 'useInsulation', defaultValue: 0.0, minValue: 0.0, maxValue: 1.0) >= 0.5;

    // Форма стен: 1=прямоугольная, 2=Г-образная, 3=сложная (много углов)
    final wallShape = getIntInput(inputs, 'wallShape', defaultValue: 1, minValue: 1, maxValue: 3);

    // Множитель профиля для сложных стен (больше подрезок и стыков)
    final double wallShapeProfileMultiplier = switch (wallShape) {
      2 => 1.10,  // Г-образная — +10% профиля на внутренние углы
      3 => 1.20,  // Сложная — +20% на подрезки
      _ => 1.0,   // Прямоугольная
    };

    // Calculate area based on input mode
    double calculatedArea;
    if (inputMode == 0) {
      calculatedArea = area;
    } else {
      // Calculate based on construction type
      switch (constructionType) {
        case 0: // Wall lining - perimeter × height
          calculatedArea = (length + width) * 2 * height;
          break;
        case 1: // Partition - length × height
          calculatedArea = length * height;
          break;
        case 2: // Ceiling - length × width
          calculatedArea = length * width;
          break;
        default:
          calculatedArea = area;
      }
    }

    // Sheet area
    final sheetArea = sheetAreas[sheetSizeIndex] ?? 3.0;

    // GKL sheets calculation
    double gklMultiplier = gklBaseMultiplier;
    if (constructionType == 1) {
      // Partition - double sided
      gklMultiplier *= gklPartitionMultiplier;
    }
    final gklArea = calculatedArea * layers * gklMultiplier;
    final gklSheets = (gklArea / sheetArea).ceil();

    // Profile and fasteners calculation based on construction type
    double pnMeters = 0;
    double ppMeters = 0;
    int pnPieces = 0;
    int ppPieces = 0;
    int screwsTN25 = 0;
    int screwsTN35 = 0;
    int screwsLN = 0;
    int dowels = 0;
    int suspensions = 0;
    int connectors = 0;
    double sealingTape = 0;

    // Calculate base screw count based on construction type
    int baseScrewCount = 0;
    switch (constructionType) {
      case 0: // Wall lining
        pnMeters = calculatedArea * wallLiningPnMeters;
        ppMeters = calculatedArea * wallLiningPpMeters;
        pnPieces = (pnMeters / profileLength).ceil();
        ppPieces = (ppMeters / profileLength).ceil();
        suspensions = (calculatedArea * wallLiningSuspensions).ceil();
        dowels = (calculatedArea * wallLiningDowels).ceil();
        baseScrewCount = (calculatedArea * wallLiningScrewsTN25).ceil();
        screwsLN = (calculatedArea * wallLiningScrewsLN).ceil();
        sealingTape = calculatedArea * wallLiningSealingTape;
        break;
      case 1: // Partition
        pnMeters = calculatedArea * partitionPnMeters;
        ppMeters = calculatedArea * partitionPpMeters;
        pnPieces = (pnMeters / profileLength).ceil();
        ppPieces = (ppMeters / profileLength).ceil();
        dowels = (calculatedArea * partitionDowels).ceil();
        baseScrewCount = (calculatedArea * partitionScrewsTN25).ceil();
        screwsLN = (calculatedArea * partitionScrewsLN).ceil();
        sealingTape = calculatedArea * partitionSealingTape;
        break;
      case 2: // Ceiling
        pnMeters = calculatedArea * ceilingPnMeters;
        ppMeters = calculatedArea * ceilingPpMeters;
        pnPieces = (pnMeters / profileLength).ceil();
        ppPieces = (ppMeters / profileLength).ceil();
        suspensions = (calculatedArea * ceilingSuspensions).ceil();
        connectors = (calculatedArea * ceilingConnectors).ceil();
        dowels = suspensions * ceilingDowelsPerSuspension;
        baseScrewCount = (calculatedArea * ceilingScrewsTN25).ceil();
        screwsLN = (calculatedArea * ceilingScrewsLN).ceil();
        break;
    }

    // Применяем множитель формы стен к профилям
    // (для сложных стен больше подрезок, стыков, внутренних углов)
    pnMeters *= wallShapeProfileMultiplier;
    ppMeters *= wallShapeProfileMultiplier;
    pnPieces = (pnMeters / profileLength).ceil();
    ppPieces = (ppMeters / profileLength).ceil();

    // Сращивание профилей при высоте > 3.0м (только для стен и перегородок)
    int profileConnectors = 0;
    if (inputMode == 1 && height > 3.0 && constructionType != 2) {
      // Количество уровней сращивания
      final spliceCount = ((height - 3.0) / 3.0).ceil();
      // Соединители на каждый ПП профиль
      profileConnectors = spliceCount * ppPieces;
    }

    // Assign screws based on thickness:
    // 9.5mm -> TN25 (25mm screws)
    // 12.5mm -> TN35 (35mm screws)
    if (thickness == 0) {
      // 9.5mm sheets use TN25
      screwsTN25 = baseScrewCount;
    } else {
      // 12.5mm sheets use TN35
      screwsTN35 = baseScrewCount;
    }

    // Second layer always uses TN35 (needs to go through 2 sheets)
    if (layers == 2) {
      final multiplier = constructionType == 1 ? secondLayerPartitionMultiplier : 1;
      final secondLayerScrews = (calculatedArea * secondLayerScrewsTN35 * multiplier).ceil();
      screwsTN35 += secondLayerScrews;
    }

    // Materials
    final insulationArea = useInsulation ? calculatedArea * insulationMargin : 0.0;
    final armatureTape = calculatedArea * armatureTapePerSqm;
    final fillerKg = calculatedArea * (constructionType == 1 ? fillerPartition : fillerStandard) * layers;
    final primerLiters = calculatedArea * (constructionType == 1 ? primerPartitionPerSqm : primerPerSqm);

    // Sheet weight calculation based on thickness and size
    final sheetWeight = sheetWeights[thickness]?[sheetSizeIndex] ?? 29.0;
    final totalWeight = sheetWeight * gklSheets;

    // Build output values
    final values = <String, double>{
      'inputMode': inputMode.toDouble(),
      'area': area,
      'length': length,
      'width': width,
      'height': height,
      'constructionType': constructionType.toDouble(),
      'gklType': gklType.toDouble(),
      'sheetSize': sheetSizeIndex.toDouble(),
      'layers': layers.toDouble(),
      'useInsulation': useInsulation ? 1.0 : 0.0,
      'calculatedArea': calculatedArea,
      'gklSheets': gklSheets.toDouble(),
      'sheetArea': sheetArea,
      'pnPieces': pnPieces.toDouble(),
      'pnMeters': pnMeters,
      'ppPieces': ppPieces.toDouble(),
      'ppMeters': ppMeters,
      'screwsTN25': screwsTN25.toDouble(),
      'screwsTN35': screwsTN35.toDouble(),
      'screwsLN': screwsLN.toDouble(),
      'dowels': dowels.toDouble(),
      'suspensions': suspensions.toDouble(),
      'connectors': connectors.toDouble(),
      'insulationArea': insulationArea,
      'sealingTape': sealingTape,
      'armatureTape': armatureTape,
      'fillerKg': fillerKg,
      'primerLiters': primerLiters,
      'thickness': thickness.toDouble(),
      'sheetWeight': sheetWeight,
      'totalWeight': totalWeight,
      'wallShape': wallShape.toDouble(),
      'profileConnectors': profileConnectors.toDouble(),
      // Flags for conditional hints
      if (inputMode == 1 && height > 3.0 && constructionType != 2) 'warningTallWall': 1.0,
      if (constructionType == 1) 'suggestInsulation': 1.0,
      if (gklType == 1) 'suggestWaterproofing': 1.0,
    };

    // Calculate total price if prices available
    double? totalPrice;
    if (priceList.isNotEmpty) {
      double total = 0;

      // GKL sheets
      final gklPriceItem = findPrice(priceList, ['gkl_sheet', 'gypsum_board']);
      if (gklPriceItem != null) {
        total += gklSheets * gklPriceItem.price;
      }

      // Profiles
      final pnPriceItem = findPrice(priceList, ['profile_pn', 'pn_profile']);
      if (pnPriceItem != null) {
        total += pnPieces * pnPriceItem.price;
      }

      final ppPriceItem = findPrice(priceList, ['profile_pp', 'pp_profile']);
      if (ppPriceItem != null) {
        total += ppPieces * ppPriceItem.price;
      }

      // Screws
      final screws25PriceItem = findPrice(priceList, ['screw_tn25', 'screw_25']);
      if (screws25PriceItem != null) {
        total += screwsTN25 * screws25PriceItem.price;
      }

      if (screwsTN35 > 0) {
        final screws35PriceItem = findPrice(priceList, ['screw_tn35', 'screw_35']);
        if (screws35PriceItem != null) {
          total += screwsTN35 * screws35PriceItem.price;
        }
      }

      // Dowels
      final dowelPriceItem = findPrice(priceList, ['dowel', 'wall_dowel']);
      if (dowelPriceItem != null) {
        total += dowels * dowelPriceItem.price;
      }

      // Insulation
      if (useInsulation) {
        final insulationPriceItem = findPrice(priceList, ['insulation', 'mineral_wool']);
        if (insulationPriceItem != null) {
          total += insulationArea * insulationPriceItem.price;
        }
      }

      // Filler
      final fillerPriceItem = findPrice(priceList, ['filler', 'gypsum_filler']);
      if (fillerPriceItem != null) {
        total += fillerKg * fillerPriceItem.price;
      }

      // Primer
      final primerPriceItem = findPrice(priceList, ['primer', 'deep_primer']);
      if (primerPriceItem != null) {
        total += primerLiters * primerPriceItem.price;
      }

      if (total > 0) totalPrice = total;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
