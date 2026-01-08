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
class CalculateGypsumV2 extends BaseCalculator {
  // Sheet sizes (area in m²)
  static const Map<int, double> sheetAreas = {
    0: 2.4,   // 2000x1200
    1: 3.0,   // 2500x1200
    2: 3.24,  // 2700x1200
    3: 3.6,   // 3000x1200
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
  static const double fillerStandard = 0.3;
  static const double fillerPartition = 0.6;
  static const double primerPerSqm = 0.1;

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
    final sheetSizeIndex = getInput(inputs, 'sheetSize', defaultValue: 1.0, minValue: 0.0, maxValue: 3.0).round();
    final layers = getInput(inputs, 'layers', defaultValue: 1.0, minValue: 1.0, maxValue: 2.0).round();
    final useInsulation = getInput(inputs, 'useInsulation', defaultValue: 0.0, minValue: 0.0, maxValue: 1.0) >= 0.5;

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

    switch (constructionType) {
      case 0: // Wall lining
        pnMeters = calculatedArea * wallLiningPnMeters;
        ppMeters = calculatedArea * wallLiningPpMeters;
        pnPieces = (pnMeters / profileLength).ceil();
        ppPieces = (ppMeters / profileLength).ceil();
        suspensions = (calculatedArea * wallLiningSuspensions).ceil();
        dowels = (calculatedArea * wallLiningDowels).ceil();
        screwsTN25 = (calculatedArea * wallLiningScrewsTN25).ceil();
        screwsLN = (calculatedArea * wallLiningScrewsLN).ceil();
        sealingTape = calculatedArea * wallLiningSealingTape;
        break;
      case 1: // Partition
        pnMeters = calculatedArea * partitionPnMeters;
        ppMeters = calculatedArea * partitionPpMeters;
        pnPieces = (pnMeters / profileLength).ceil();
        ppPieces = (ppMeters / profileLength).ceil();
        dowels = (calculatedArea * partitionDowels).ceil();
        screwsTN25 = (calculatedArea * partitionScrewsTN25).ceil();
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
        screwsTN25 = (calculatedArea * ceilingScrewsTN25).ceil();
        screwsLN = (calculatedArea * ceilingScrewsLN).ceil();
        break;
    }

    // Second layer screws
    if (layers == 2) {
      final multiplier = constructionType == 1 ? secondLayerPartitionMultiplier : 1;
      screwsTN35 = (calculatedArea * secondLayerScrewsTN35 * multiplier).ceil();
    }

    // Materials
    final insulationArea = useInsulation ? calculatedArea * insulationMargin : 0.0;
    final armatureTape = calculatedArea * armatureTapePerSqm;
    final fillerKg = calculatedArea * (constructionType == 1 ? fillerPartition : fillerStandard) * layers;
    final primerLiters = calculatedArea * primerPerSqm;

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
