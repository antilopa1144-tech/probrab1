import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

double _input(
  SpecReader spec,
  Map<String, double> inputs,
  String key,
  double fallback,
  double min,
  double max,
) {
  final value = inputs[key] ?? spec.inputDefault(key, fallback);
  return value.clamp(min, max).toDouble();
}

double _withReserve(double exactNeed, double reservePercent) =>
    exactNeed * (1 + reservePercent / 100);

int _roundUpUnits(double exactNeed, double unitSize) {
  if (exactNeed <= 0 || unitSize <= 0) return 0;
  return (exactNeed / unitSize - 1e-9).ceil();
}

class _PackagedMaterial {
  final CanonicalMaterialResult material;
  final int packageCount;

  const _PackagedMaterial(this.material, this.packageCount);
}

_PackagedMaterial? _packagedMaterial({
  required String name,
  required String category,
  required double exactNeed,
  required double reservePercent,
  required double packageSize,
  required String unit,
  required String packageUnit,
}) {
  if (exactNeed <= 0 || packageSize <= 0) return null;
  final planned = _withReserve(exactNeed, reservePercent);
  final packageCount = _roundUpUnits(planned, packageSize);
  return _PackagedMaterial(
    CanonicalMaterialResult(
      name: name,
      quantity: roundValue(exactNeed, 3),
      unit: unit,
      withReserve: roundValue(planned, 3),
      purchaseQty: roundValue(packageCount * packageSize, 3),
      category: category,
      packageInfo: {
        'count': packageCount,
        'size': packageSize,
        'packageUnit': packageUnit,
      },
    ),
    packageCount,
  );
}

_PackagedMaterial? _longStockMaterial({
  required int projectPieces,
  required double blankLengthM,
  required double reservePercent,
  required double stockLengthM,
}) {
  if (projectPieces <= 0 || blankLengthM <= 0 || stockLengthM < blankLengthM) {
    return null;
  }
  final plannedPieces =
      (_withReserve(projectPieces.toDouble(), reservePercent) - 1e-9).ceil();
  final blanksPerStock = (stockLengthM / blankLengthM + 1e-9).floor();
  if (blanksPerStock <= 0) return null;
  final stockPieces = _roundUpUnits(
    plannedPieces.toDouble(),
    blanksPerStock.toDouble(),
  );
  return _PackagedMaterial(
    CanonicalMaterialResult(
      name: 'Косоур/тетива — одна проектная позиция',
      quantity: roundValue(projectPieces * blankLengthM, 3),
      unit: 'м',
      withReserve: roundValue(plannedPieces * blankLengthM, 3),
      purchaseQty: roundValue(stockPieces * stockLengthM, 3),
      category: 'Несущие элементы по проекту',
      packageInfo: {
        'count': stockPieces,
        'size': stockLengthM,
        'packageUnit': 'заготовок',
      },
    ),
    stockPieces,
  );
}

Map<String, CanonicalScenarioResult> _treadScenarios(
  int treadCount,
  double reservePercent,
  double packageSize,
) {
  final reserves = <String, double>{
    'MIN': 0,
    'REC': reservePercent,
    'MAX': reservePercent,
  };
  return reserves.map((scenario, reserve) {
    final exactNeed = _withReserve(treadCount.toDouble(), reserve);
    final packagesCount = _roundUpUnits(exactNeed, packageSize);
    final purchaseQuantity = packagesCount * packageSize;
    return MapEntry(
      scenario,
      CanonicalScenarioResult(
        exactNeed: roundValue(exactNeed, 6),
        purchaseQuantity: roundValue(purchaseQuantity, 6),
        leftover: roundValue(purchaseQuantity - exactNeed, 6),
        assumptions: [
          'primary_material:tread_blanks',
          'reserve_percent:$reserve',
          scenario == 'MAX' ? 'no_hidden_max_reserve' : 'explicit_scenario',
        ],
        keyFactors: {'field_multiplier': 1, 'reserve_percent': reserve},
        buyPlan: CanonicalBuyPlan(
          packageLabel: 'tread-package-$packageSize',
          packageSize: packageSize,
          packagesCount: packagesCount,
          unit: 'шт',
        ),
      ),
    );
  });
}

CanonicalCalculatorContractResult calculateCanonicalStairs(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(stairsSpecData);
  double read(String key, double fallback, double min, double max) =>
      _input(spec, inputs, key, fallback, min, max);

  final geometryMode = read('geometryMode', 0, 0, 1).round();
  final floorRiseM = read('floorRiseM', 2.8, 1, 6);
  final targetRiserHeightMm = read('targetRiserHeightMm', 175, 100, 250);
  final projectRiserCount = read('projectRiserCount', 16, 1, 50).round();
  final treadDepthMm = read('treadDepthMm', 280, 100, 500);
  final topFloorActsAsTread = read('topFloorActsAsTread', 1, 0, 1).round();
  final stairWidthM = read('stairWidthM', 1, 0.5, 3);
  final openingLengthM = read('openingLengthM', 0, 0, 20);
  final floorStructureThicknessM = read('floorStructureThicknessM', 0.3, 0, 2);

  final materialRules =
      spec.raw['material_rules'] as Map<String, dynamic>? ?? const {};
  final geometryModeCodes =
      materialRules['geometry_mode_codes'] as Map<String, dynamic>? ?? const {};
  final targetModeCode =
      (geometryModeCodes['target_riser_height'] as num?)?.toInt() ?? 0;
  final riserCount = geometryMode == targetModeCode
      ? math.max(1, (floorRiseM / (targetRiserHeightMm / 1000)).round())
      : projectRiserCount;
  final actualRiserHeightMm = floorRiseM * 1000 / riserCount;
  final treadCount = math.max(0, riserCount - topFloorActsAsTread);
  final straightRunM = treadCount * (treadDepthMm / 1000);
  final inclineLengthM = math.sqrt(
    floorRiseM * floorRiseM + straightRunM * straightRunM,
  );
  final angleDeg = straightRunM > 0
      ? math.atan2(floorRiseM, straightRunM) * 180 / math.pi
      : 90.0;
  final comfortStepMm = 2 * actualRiserHeightMm + treadDepthMm;
  final headroomEstimateAvailable = openingLengthM > 0 && straightRunM > 0;
  final estimatedHeadroomM = headroomEstimateAvailable
      ? math
            .max(
              0.0,
              floorRiseM * math.min(openingLengthM / straightRunM, 1) -
                  floorStructureThicknessM,
            )
            .toDouble()
      : 0.0;

  final includeTreadBlanks = read('includeTreadBlanks', 1, 0, 1).round();
  final treadReservePercent = read('treadReservePercent', 0, 0, 50);
  final treadsPerPackagePcs = read('treadsPerPackagePcs', 1, 0, 1000);
  final riserProjectPcs = read('riserProjectPcs', 0, 0, 1000).round();
  final riserReservePercent = read('riserReservePercent', 0, 0, 50);
  final risersPerPackagePcs = read('risersPerPackagePcs', 1, 0, 1000);
  final stringerProjectPcs = read('stringerProjectPcs', 0, 0, 100).round();
  final stringerBlankLengthM = read('stringerBlankLengthM', 0, 0, 30);
  final stringerReservePercent = read('stringerReservePercent', 0, 0, 50);
  final stringerStockLengthM = read('stringerStockLengthM', 0, 0, 30);
  final concreteProjectM3 = read('concreteProjectM3', 0, 0, 100);
  final concreteReservePercent = read('concreteReservePercent', 5, 0, 30);
  final concreteOrderStepM3 = read('concreteOrderStepM3', 0.1, 0, 10);
  final rebarProjectKg = read('rebarProjectKg', 0, 0, 100000);
  final rebarReservePercent = read('rebarReservePercent', 5, 0, 30);
  final rebarPackageKg = read('rebarPackageKg', 1, 0, 10000);
  final handrailProjectM = read('handrailProjectM', 0, 0, 1000);
  final handrailReservePercent = read('handrailReservePercent', 5, 0, 30);
  final handrailStockLengthM = read('handrailStockLengthM', 0, 0, 30);
  final railingInfillProjectPcs = read(
    'railingInfillProjectPcs',
    0,
    0,
    10000,
  ).round();
  final railingInfillReservePercent = read(
    'railingInfillReservePercent',
    0,
    0,
    30,
  );
  final railingInfillPackagePcs = read('railingInfillPackagePcs', 1, 0, 10000);
  final fastenersProjectPcs = read(
    'fastenersProjectPcs',
    0,
    0,
    1000000,
  ).round();
  final fastenersReservePercent = read('fastenersReservePercent', 5, 0, 30);
  final fastenersPackagePcs = read('fastenersPackagePcs', 0, 0, 100000);
  final landingFinishProjectM2 = read('landingFinishProjectM2', 0, 0, 1000);
  final landingFinishReservePercent = read(
    'landingFinishReservePercent',
    10,
    0,
    50,
  );
  final landingFinishPackageM2 = read('landingFinishPackageM2', 0, 0, 1000);

  final countPackageUnit = spec.packagingRule<String>('count_package_unit');
  final stockPieceUnit = spec.packagingRule<String>('stock_piece_unit');
  final concreteOrderUnit = spec.packagingRule<String>('concrete_order_unit');
  final materialCandidates = <_PackagedMaterial?>[
    includeTreadBlanks == 1
        ? _packagedMaterial(
            name: 'Чистовые заготовки ступеней по геометрии',
            category: 'Ступени',
            exactNeed: treadCount.toDouble(),
            reservePercent: treadReservePercent,
            packageSize: treadsPerPackagePcs,
            unit: 'шт',
            packageUnit: countPackageUnit,
          )
        : null,
    _packagedMaterial(
      name: 'Подступенки из проектной ведомости',
      category: 'Ступени',
      exactNeed: riserProjectPcs.toDouble(),
      reservePercent: riserReservePercent,
      packageSize: risersPerPackagePcs,
      unit: 'шт',
      packageUnit: countPackageUnit,
    ),
    _longStockMaterial(
      projectPieces: stringerProjectPcs,
      blankLengthM: stringerBlankLengthM,
      reservePercent: stringerReservePercent,
      stockLengthM: stringerStockLengthM,
    ),
    _packagedMaterial(
      name: 'Бетон из проектной ведомости',
      category: 'Монолит по проекту',
      exactNeed: concreteProjectM3,
      reservePercent: concreteReservePercent,
      packageSize: concreteOrderStepM3,
      unit: 'м³',
      packageUnit: concreteOrderUnit,
    ),
    _packagedMaterial(
      name: 'Арматура по проектной массе',
      category: 'Монолит по проекту',
      exactNeed: rebarProjectKg,
      reservePercent: rebarReservePercent,
      packageSize: rebarPackageKg,
      unit: 'кг',
      packageUnit: 'пакетов',
    ),
    _packagedMaterial(
      name: 'Поручень — одна проектная позиция',
      category: 'Ограждение по проекту',
      exactNeed: handrailProjectM,
      reservePercent: handrailReservePercent,
      packageSize: handrailStockLengthM,
      unit: 'м',
      packageUnit: stockPieceUnit,
    ),
    _packagedMaterial(
      name: 'Стойки/заполнение ограждения из ведомости',
      category: 'Ограждение по проекту',
      exactNeed: railingInfillProjectPcs.toDouble(),
      reservePercent: railingInfillReservePercent,
      packageSize: railingInfillPackagePcs,
      unit: 'шт',
      packageUnit: countPackageUnit,
    ),
    _packagedMaterial(
      name: 'Крепёж и анкеры из проектной ведомости',
      category: 'Крепёж по проекту',
      exactNeed: fastenersProjectPcs.toDouble(),
      reservePercent: fastenersReservePercent,
      packageSize: fastenersPackagePcs,
      unit: 'шт',
      packageUnit: countPackageUnit,
    ),
    _packagedMaterial(
      name: 'Покрытие площадок из проектной ведомости',
      category: 'Площадки по проекту',
      exactNeed: landingFinishProjectM2,
      reservePercent: landingFinishReservePercent,
      packageSize: landingFinishPackageM2,
      unit: 'м²',
      packageUnit: countPackageUnit,
    ),
  ];
  final materials = materialCandidates
      .whereType<_PackagedMaterial>()
      .map((entry) => entry.material)
      .toList(growable: false);
  final scenarioTreadCount = includeTreadBlanks == 1 ? treadCount : 0;
  final scenarios = _treadScenarios(
    scenarioTreadCount,
    treadReservePercent,
    treadsPerPackagePcs,
  );

  final warnings = <String>[
    'Это геометрия одного прямого марша и закупка по проектной ведомости: несущие элементы, узлы, площадки, повороты, армирование, анкеры и ограждения здесь не проектируются',
  ];
  if (geometryMode == targetModeCode) {
    warnings.add(
      'Число подъёмов подобрано по целевой высоте подступенка; перед закупкой зафиксируйте его в проекте и проверьте все чистовые отметки',
    );
  }
  final comfortMin = spec.warningRule<num>('comfort_step_min_mm').toDouble();
  final comfortMax = spec.warningRule<num>('comfort_step_max_mm').toDouble();
  if (comfortStepMm < comfortMin || comfortStepMm > comfortMax) {
    warnings.add(
      'Связка размеров требует проверки эргономики: 2h + b = ${roundValue(comfortStepMm, 1)} мм',
    );
  }
  final steepAngle = spec
      .warningRule<num>('steep_angle_attention_deg')
      .toDouble();
  if (angleDeg > steepAngle) {
    warnings.add(
      'Получен крутой марш ${roundValue(angleDeg, 1)}°; допустимость зависит от назначения лестницы и проектных требований',
    );
  }
  final headroomAttention = spec
      .warningRule<num>('headroom_attention_m')
      .toDouble();
  if (headroomEstimateAvailable && estimatedHeadroomM < headroomAttention) {
    warnings.add(
      'Оценочный габарит прохода ${roundValue(estimatedHeadroomM, 3)} м меньше контрольного ориентира $headroomAttention м — нужен разрез проекта',
    );
  }
  if (stringerProjectPcs > 0 &&
      (stringerBlankLengthM <= 0 || stringerStockLengthM <= 0)) {
    warnings.add(
      'Количество косоуров/тетив задано, но длина проектной детали или покупной заготовки не заполнена',
    );
  } else if (stringerProjectPcs > 0 &&
      stringerStockLengthM < stringerBlankLengthM) {
    warnings.add(
      'Покупная заготовка короче проектной детали; составной косоур/тетива без отдельного проектного узла не рассчитан',
    );
  }
  final missingPackages = <(double, double, String)>[
    (
      includeTreadBlanks == 1 ? treadCount.toDouble() : 0,
      treadsPerPackagePcs,
      'Ступени включены, но количество в упаковке не заполнено',
    ),
    (
      riserProjectPcs.toDouble(),
      risersPerPackagePcs,
      'Подступенки заданы, но количество в упаковке не заполнено',
    ),
    (
      concreteProjectM3,
      concreteOrderStepM3,
      'Объём бетона задан, но шаг заказа не заполнен',
    ),
    (
      rebarProjectKg,
      rebarPackageKg,
      'Масса арматуры задана, но закупочный шаг не заполнен',
    ),
    (
      handrailProjectM,
      handrailStockLengthM,
      'Длина поручня задана, но длина покупной заготовки не заполнена',
    ),
    (
      railingInfillProjectPcs.toDouble(),
      railingInfillPackagePcs,
      'Стойки/заполнение заданы, но количество в упаковке не заполнено',
    ),
    (
      fastenersProjectPcs.toDouble(),
      fastenersPackagePcs,
      'Крепёж задан, но количество в упаковке не заполнено',
    ),
    (
      landingFinishProjectM2,
      landingFinishPackageM2,
      'Покрытие площадки задано, но площадь упаковки не заполнена',
    ),
  ];
  for (final (projectQuantity, packageSize, warning) in missingPackages) {
    if (projectQuantity > 0 && packageSize <= 0) warnings.add(warning);
  }
  if (materials.isEmpty) {
    warnings.add('Не рассчитана ни одна закупочная позиция');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'geometryMode': geometryMode.toDouble(),
      'floorRiseM': roundValue(floorRiseM, 3),
      'targetRiserHeightMm': roundValue(targetRiserHeightMm, 3),
      'projectRiserCount': projectRiserCount.toDouble(),
      'riserCount': riserCount.toDouble(),
      'actualRiserHeightMm': roundValue(actualRiserHeightMm, 3),
      'treadCount': treadCount.toDouble(),
      'treadDepthMm': roundValue(treadDepthMm, 3),
      'topFloorActsAsTread': topFloorActsAsTread.toDouble(),
      'stairWidthM': roundValue(stairWidthM, 3),
      'straightRunM': roundValue(straightRunM, 3),
      'inclineLengthM': roundValue(inclineLengthM, 3),
      'angleDeg': roundValue(angleDeg, 3),
      'comfortStepMm': roundValue(comfortStepMm, 3),
      'openingLengthM': roundValue(openingLengthM, 3),
      'floorStructureThicknessM': roundValue(floorStructureThicknessM, 3),
      'headroomEstimateAvailable': headroomEstimateAvailable ? 1 : 0,
      'estimatedHeadroomM': roundValue(estimatedHeadroomM, 3),
      'treadPackages': (materialCandidates[0]?.packageCount ?? 0).toDouble(),
      'riserPackages': (materialCandidates[1]?.packageCount ?? 0).toDouble(),
      'stringerStockPieces': (materialCandidates[2]?.packageCount ?? 0)
          .toDouble(),
      'concreteOrders': (materialCandidates[3]?.packageCount ?? 0).toDouble(),
      'rebarPackages': (materialCandidates[4]?.packageCount ?? 0).toDouble(),
      'handrailStockPieces': (materialCandidates[5]?.packageCount ?? 0)
          .toDouble(),
      'railingInfillPackages': (materialCandidates[6]?.packageCount ?? 0)
          .toDouble(),
      'fastenerPackages': (materialCandidates[7]?.packageCount ?? 0).toDouble(),
      'landingFinishPackages': (materialCandidates[8]?.packageCount ?? 0)
          .toDouble(),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': scenarios['REC']!.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'recPurchase': scenarios['REC']!.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
