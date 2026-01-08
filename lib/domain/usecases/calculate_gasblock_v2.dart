import 'dart:math' as math;

import '../../data/models/price_item.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор газобетонных блоков (domain layer)
///
/// Входные параметры:
/// - inputMode: 0 = по площади, 1 = по размерам (default: 1)
/// - area: площадь стены м² (для режима 0, default: 15)
/// - length: длина стены м (для режима 1, default: 6)
/// - height: высота стены м (default: 2.7)
/// - openingsArea: площадь проёмов м² (default: 0)
/// - wallType: 0 = перегородка, 1 = несущая (default: 0)
/// - blockMaterial: 0 = газобетон, 1 = пенобетон (default: 0)
/// - blockLength: длина блока см (default: 60)
/// - blockHeight: высота блока см (default: 30)
/// - blockThickness: толщина блока мм (default: 100)
/// - masonryMix: 0 = клей, 1 = раствор (default: 0)
/// - reserve: запас % (default: 5)
/// - useReinforcement: 0/1 (default: 1)
/// - usePrimer: 0/1 (default: 1)
/// - usePlaster: 0/1 (default: 1)
/// - useMesh: 0/1 (default: 1)
/// - useLintels: 0/1 (default: 0)
/// - lintelsCount: количество перемычек (default: 0)
///
/// Выходные параметры:
/// - grossArea: общая площадь стены м²
/// - netArea: площадь кладки без проёмов м²
/// - blocksCount: количество блоков шт
/// - volume: объём кладки м³
/// - glueKg: клей кг (если masonryMix=0)
/// - glueBags: клей мешки 25кг
/// - mortarM3: раствор м³ (если masonryMix=1)
/// - reinforcementLength: арматура м
/// - primerLiters: грунтовка л
/// - plasterKg: штукатурка кг
/// - meshArea: сетка м²
/// - lintelsCount: перемычки шт
class CalculateGasblockV2 extends BaseCalculator {
  // Glue constants
  static const double glueKgPerM3 = 25.0;
  static const double glueMarginFactor = 1.1;
  static const int glueBagSizeKg = 25;

  // Mortar constants
  static const double mortarM3PerM3 = 0.2;
  static const double mortarMarginFactor = 1.1;

  // Primer constants
  static const double primerPerLayer = 0.2;
  static const int primerLayers = 2;

  // Plaster constants
  static const double plasterPerLayer = 10.0;
  static const int plasterLayers = 2;

  // Reinforcement constants
  static const int partitionReinforcementStepRows = 3;
  static const int bearingReinforcementStepRows = 2;
  static const int rodsPerRow = 2;

  // Mesh constants
  static const int meshSides = 2;
  static const double meshMarginFactor = 1.05;

  // Thickness options
  static const List<int> partitionThicknesses = [75, 100, 150];
  static const List<int> bearingThicknesses = [200, 250, 300, 400];

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Input mode: 0 = by area, 1 = by dimensions
    final inputMode = getInput(inputs, 'inputMode', defaultValue: 1.0, minValue: 0.0, maxValue: 1.0).round();

    // Dimensions
    final area = getInput(inputs, 'area', defaultValue: 15.0, minValue: 1.0, maxValue: 1000.0);
    final length = getInput(inputs, 'length', defaultValue: 6.0, minValue: 0.5, maxValue: 200.0);
    final height = getInput(inputs, 'height', defaultValue: 2.7, minValue: 2.0, maxValue: 6.0);
    final openingsArea = getInput(inputs, 'openingsArea', defaultValue: 0.0, minValue: 0.0, maxValue: 500.0);

    // Wall and block settings
    final wallType = getInput(inputs, 'wallType', defaultValue: 0.0, minValue: 0.0, maxValue: 1.0).round();
    final blockMaterial = getInput(inputs, 'blockMaterial', defaultValue: 0.0, minValue: 0.0, maxValue: 1.0).round();
    final blockLengthCm = getInput(inputs, 'blockLength', defaultValue: 60.0, minValue: 50.0, maxValue: 70.0);
    final blockHeightCm = getInput(inputs, 'blockHeight', defaultValue: 30.0, minValue: 20.0, maxValue: 35.0);
    final blockThicknessMm = getInput(inputs, 'blockThickness', defaultValue: 100.0, minValue: 75.0, maxValue: 400.0).round();
    final masonryMix = getInput(inputs, 'masonryMix', defaultValue: 0.0, minValue: 0.0, maxValue: 1.0).round();
    final reserve = getInput(inputs, 'reserve', defaultValue: 5.0, minValue: 0.0, maxValue: 15.0);

    // Additional materials flags
    final useReinforcement = getInput(inputs, 'useReinforcement', defaultValue: 1.0, minValue: 0.0, maxValue: 1.0) >= 0.5;
    final usePrimer = getInput(inputs, 'usePrimer', defaultValue: 1.0, minValue: 0.0, maxValue: 1.0) >= 0.5;
    final usePlaster = getInput(inputs, 'usePlaster', defaultValue: 1.0, minValue: 0.0, maxValue: 1.0) >= 0.5;
    final useMesh = getInput(inputs, 'useMesh', defaultValue: 1.0, minValue: 0.0, maxValue: 1.0) >= 0.5;
    final useLintels = getInput(inputs, 'useLintels', defaultValue: 0.0, minValue: 0.0, maxValue: 1.0) >= 0.5;
    final lintelsCount = getInput(inputs, 'lintelsCount', defaultValue: 0.0, minValue: 0.0, maxValue: 20.0).round();

    // Calculate areas
    final grossArea = inputMode == 0 ? area : length * height;
    final openings = math.min(openingsArea, grossArea);
    final netArea = math.max(0.0, grossArea - openings);

    // Block dimensions in meters
    final blockLengthM = blockLengthCm / 100;
    final blockHeightM = blockHeightCm / 100;
    final blockThicknessM = blockThicknessMm / 1000;

    // Block face area (visible side)
    final blockFaceArea = blockLengthM * blockHeightM;

    // Calculate blocks count
    final reserveFactor = 1 + reserve / 100;
    final blocksCount = netArea > 0 && blockFaceArea > 0
        ? (netArea / blockFaceArea * reserveFactor).ceil()
        : 0;

    // Volume of masonry
    final volume = netArea * blockThicknessM;

    // Glue or mortar
    double glueKg = 0;
    int glueBags = 0;
    double mortarM3 = 0;
    if (masonryMix == 0) {
      // Glue
      glueKg = volume * glueKgPerM3 * glueMarginFactor;
      glueBags = (glueKg / glueBagSizeKg).ceil();
    } else {
      // Mortar
      mortarM3 = volume * mortarM3PerM3 * mortarMarginFactor;
    }

    // Reinforcement calculation
    double reinforcementLength = 0;
    if (useReinforcement && netArea > 0) {
      final rows = blockHeightM > 0 ? (height / blockHeightM).ceil() : 0;
      final reinforcementStep = wallType == 0
          ? partitionReinforcementStepRows
          : bearingReinforcementStepRows;
      final reinforcementRows = reinforcementStep > 0
          ? (rows / reinforcementStep).ceil()
          : 0;
      final wallLength = inputMode == 1
          ? length
          : (height > 0 ? netArea / height : 0.0);
      reinforcementLength = reinforcementRows * wallLength * rodsPerRow;
    }

    // Primer
    final primerLiters = usePrimer
        ? netArea * primerPerLayer * primerLayers
        : 0.0;

    // Plaster
    final plasterKg = usePlaster
        ? netArea * plasterPerLayer * plasterLayers
        : 0.0;

    // Mesh (both sides)
    final meshArea = useMesh
        ? netArea * meshSides * meshMarginFactor
        : 0.0;

    // Lintels
    final finalLintelsCount = useLintels ? lintelsCount : 0;

    // Build output values
    final values = <String, double>{
      'inputMode': inputMode.toDouble(),
      'area': area,
      'length': length,
      'height': height,
      'openingsArea': openingsArea,
      'wallType': wallType.toDouble(),
      'blockMaterial': blockMaterial.toDouble(),
      'blockLength': blockLengthCm,
      'blockHeight': blockHeightCm,
      'blockThickness': blockThicknessMm.toDouble(),
      'masonryMix': masonryMix.toDouble(),
      'reserve': reserve,
      'useReinforcement': useReinforcement ? 1.0 : 0.0,
      'usePrimer': usePrimer ? 1.0 : 0.0,
      'usePlaster': usePlaster ? 1.0 : 0.0,
      'useMesh': useMesh ? 1.0 : 0.0,
      'useLintels': useLintels ? 1.0 : 0.0,
      'lintelsCount': finalLintelsCount.toDouble(),
      'grossArea': grossArea,
      'netArea': netArea,
      'blockFaceArea': blockFaceArea,
      'blocksCount': blocksCount.toDouble(),
      'volume': volume,
      'glueKg': glueKg,
      'glueBags': glueBags.toDouble(),
      'mortarM3': mortarM3,
      'reinforcementLength': reinforcementLength,
      'primerLiters': primerLiters,
      'plasterKg': plasterKg,
      'meshArea': meshArea,
    };

    // Calculate total price if prices available
    double? totalPrice;
    if (priceList.isNotEmpty) {
      double total = 0;

      // Blocks
      final blockPriceItem = findPrice(priceList, ['gasblock', 'gas_block']);
      if (blockPriceItem != null) {
        total += blocksCount * blockPriceItem.price;
      }

      // Glue
      if (masonryMix == 0) {
        final gluePriceItem = findPrice(priceList, ['glue', 'block_glue']);
        if (gluePriceItem != null) {
          total += glueBags * gluePriceItem.price;
        }
      } else {
        final mortarPriceItem = findPrice(priceList, ['mortar', 'cement_mortar']);
        if (mortarPriceItem != null) {
          total += mortarM3 * mortarPriceItem.price;
        }
      }

      // Reinforcement
      if (useReinforcement) {
        final reinforcementPriceItem = findPrice(priceList, ['reinforcement', 'rebar']);
        if (reinforcementPriceItem != null) {
          total += reinforcementLength * reinforcementPriceItem.price;
        }
      }

      // Primer
      if (usePrimer) {
        final primerPriceItem = findPrice(priceList, ['primer', 'deep_primer']);
        if (primerPriceItem != null) {
          total += primerLiters * primerPriceItem.price;
        }
      }

      // Plaster
      if (usePlaster) {
        final plasterPriceItem = findPrice(priceList, ['plaster', 'gypsum_plaster']);
        if (plasterPriceItem != null) {
          total += plasterKg * plasterPriceItem.price;
        }
      }

      // Mesh
      if (useMesh) {
        final meshPriceItem = findPrice(priceList, ['mesh', 'reinforcement_mesh']);
        if (meshPriceItem != null) {
          total += meshArea * meshPriceItem.price;
        }
      }

      // Lintels
      if (useLintels && finalLintelsCount > 0) {
        final lintelPriceItem = findPrice(priceList, ['lintel', 'door_lintel']);
        if (lintelPriceItem != null) {
          total += finalLintelsCount * lintelPriceItem.price;
        }
      }

      if (total > 0) totalPrice = total;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
