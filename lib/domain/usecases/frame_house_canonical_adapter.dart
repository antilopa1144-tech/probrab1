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

int _roundUpUnits(double exactNeed, double unitSize) {
  if (exactNeed <= 0 || unitSize <= 0) return 0;
  return (exactNeed / unitSize - 1e-12).ceil();
}

double _planningQuantity(double exactNeed, double reservePercent) =>
    exactNeed * (1 + reservePercent / 100);

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
  final withReserve = _planningQuantity(exactNeed, reservePercent);
  final packageCount = _roundUpUnits(withReserve, packageSize);
  return _PackagedMaterial(
    CanonicalMaterialResult(
      name: name,
      quantity: roundValue(exactNeed, 3),
      unit: unit,
      withReserve: roundValue(withReserve, 3),
      purchaseQty: roundValue(packageCount * packageSize, 3),
      category: category,
      packageInfo: {
        'count': packageCount,
        'unitSize': packageSize,
        'packageUnit': packageUnit,
      },
    ),
    packageCount,
  );
}

Map<String, CanonicalScenarioResult> _outerSheetScenarios(
  double cleanSheets,
  double recReservePercent,
  double maxReserveFloorPercent,
) {
  final reserves = <String, double>{
    'MIN': 0,
    'REC': recReservePercent,
    'MAX': math.max(recReservePercent, maxReserveFloorPercent),
  };
  return reserves.map((scenario, reservePercent) {
    final exactNeed = _planningQuantity(cleanSheets, reservePercent);
    final purchaseQuantity = (exactNeed - 1e-12).ceil();
    return MapEntry(
      scenario,
      CanonicalScenarioResult(
        exactNeed: roundValue(exactNeed, 6),
        purchaseQuantity: purchaseQuantity.toDouble(),
        leftover: roundValue(purchaseQuantity - exactNeed, 6),
        assumptions: [
          'primary_material:outer_sheet_sheathing',
          'reserve_percent:$reservePercent',
        ],
        keyFactors: {'field_multiplier': 1, 'reserve_percent': reservePercent},
        buyPlan: CanonicalBuyPlan(
          packageLabel: 'outer-sheet',
          packageSize: 1,
          packagesCount: purchaseQuantity,
          unit: 'листов',
        ),
      ),
    );
  });
}

CanonicalCalculatorContractResult calculateCanonicalFrameHouse(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(frameHouseSpecData);
  double read(String key, double fallback, double min, double max) =>
      _input(spec, inputs, key, fallback, min, max);

  final wallLength = read('wallLength', 30, 1, 200);
  final wallHeight = read('wallHeight', 2.7, 1, 8);
  final openingsAreaInput = read('openingsArea', 10, 0, 500);
  final surfaceAreaBasis = read('surfaceAreaBasis', 0, 0, 1).round();
  final grossWallArea = wallLength * wallHeight;
  final openingsArea = math.min(openingsAreaInput, grossWallArea);
  final netWallArea = grossWallArea - openingsArea;
  final selectedSurfaceArea = surfaceAreaBasis == 1
      ? netWallArea
      : grossWallArea;

  final framingProjectLengthM = read('framingProjectLengthM', 0, 0, 100000);
  final framingReservePercent = read('framingReservePercent', 5, 0, 30);
  final framingBoardLengthM = read('framingBoardLengthM', 6, 0.1, 20);

  final outerSheathingEnabled = read('outerSheathingEnabled', 1, 0, 1).round();
  final outerSheetAreaM2 = read('outerSheetAreaM2', 3.125, 0.1, 20);
  final outerSheathingLayers = read('outerSheathingLayers', 1, 1, 4).round();
  final outerSheathingReservePercent = read(
    'outerSheathingReservePercent',
    10,
    0,
    50,
  );

  final innerSheathingEnabled = read('innerSheathingEnabled', 0, 0, 1).round();
  final innerSheetAreaM2 = read('innerSheetAreaM2', 3, 0.1, 20);
  final innerSheathingLayers = read('innerSheathingLayers', 1, 1, 4).round();
  final innerSheathingReservePercent = read(
    'innerSheathingReservePercent',
    10,
    0,
    50,
  );

  final insulationEnabled = read('insulationEnabled', 0, 0, 1).round();
  final insulationPackageAreaM2 = read('insulationPackageAreaM2', 0, 0, 100);
  final insulationLayers = read('insulationLayers', 1, 1, 10).round();
  final insulationReservePercent = read('insulationReservePercent', 5, 0, 30);

  final vaporBarrierEnabled = read('vaporBarrierEnabled', 0, 0, 1).round();
  final vaporRollAreaM2 = read('vaporRollAreaM2', 0, 0, 500);
  final vaporLayers = read('vaporLayers', 1, 1, 5).round();
  final vaporReservePercent = read('vaporReservePercent', 15, 0, 50);

  final windBarrierEnabled = read('windBarrierEnabled', 0, 0, 1).round();
  final windRollAreaM2 = read('windRollAreaM2', 0, 0, 500);
  final windLayers = read('windLayers', 1, 1, 5).round();
  final windReservePercent = read('windReservePercent', 15, 0, 50);

  final tapeProjectM = read('tapeProjectM', 0, 0, 100000);
  final tapeReservePercent = read('tapeReservePercent', 10, 0, 50);
  final tapeRollLengthM = read('tapeRollLengthM', 0, 0, 1000);

  final sheathingFastenersProjectPcs = read(
    'sheathingFastenersProjectPcs',
    0,
    0,
    1000000,
  );
  final sheathingFastenersReservePercent = read(
    'sheathingFastenersReservePercent',
    5,
    0,
    30,
  );
  final sheathingFastenersPackagePcs = read(
    'sheathingFastenersPackagePcs',
    0,
    0,
    100000,
  );
  final framingFastenersProjectPcs = read(
    'framingFastenersProjectPcs',
    0,
    0,
    1000000,
  );
  final framingFastenersReservePercent = read(
    'framingFastenersReservePercent',
    5,
    0,
    30,
  );
  final framingFastenersPackagePcs = read(
    'framingFastenersPackagePcs',
    0,
    0,
    100000,
  );

  final materials = <CanonicalMaterialResult>[];
  final framing = _packagedMaterial(
    name: 'Конструкционная доска — одна позиция из проектной ведомости',
    category: 'Каркас по проекту',
    exactNeed: framingProjectLengthM,
    reservePercent: framingReservePercent,
    packageSize: framingBoardLengthM,
    unit: 'м',
    packageUnit: 'досок',
  );
  if (framing != null) materials.add(framing.material);

  final outerExactAreaM2 = outerSheathingEnabled == 1
      ? selectedSurfaceArea * outerSheathingLayers
      : 0.0;
  final outer = _packagedMaterial(
    name: 'Наружная листовая обшивка по проекту',
    category: 'Обшивка',
    exactNeed: outerExactAreaM2,
    reservePercent: outerSheathingReservePercent,
    packageSize: outerSheetAreaM2,
    unit: 'м²',
    packageUnit: 'листов',
  );
  if (outer != null) materials.add(outer.material);

  final innerExactAreaM2 = innerSheathingEnabled == 1
      ? selectedSurfaceArea * innerSheathingLayers
      : 0.0;
  final inner = _packagedMaterial(
    name: 'Внутренняя листовая обшивка по проекту',
    category: 'Обшивка',
    exactNeed: innerExactAreaM2,
    reservePercent: innerSheathingReservePercent,
    packageSize: innerSheetAreaM2,
    unit: 'м²',
    packageUnit: 'листов',
  );
  if (inner != null) materials.add(inner.material);

  final insulationExactAreaM2 = insulationEnabled == 1
      ? selectedSurfaceArea * insulationLayers
      : 0.0;
  final insulation = _packagedMaterial(
    name: 'Утеплитель принятой проектной толщины',
    category: 'Утепление',
    exactNeed: insulationExactAreaM2,
    reservePercent: insulationReservePercent,
    packageSize: insulationPackageAreaM2,
    unit: 'м²',
    packageUnit: 'упаковок',
  );
  if (insulation != null) materials.add(insulation.material);

  final vaporExactAreaM2 = vaporBarrierEnabled == 1
      ? selectedSurfaceArea * vaporLayers
      : 0.0;
  final vapor = _packagedMaterial(
    name: 'Пароизоляционный слой по проекту',
    category: 'Мембраны',
    exactNeed: vaporExactAreaM2,
    reservePercent: vaporReservePercent,
    packageSize: vaporRollAreaM2,
    unit: 'м²',
    packageUnit: 'рулонов',
  );
  if (vapor != null) materials.add(vapor.material);

  final windExactAreaM2 = windBarrierEnabled == 1
      ? selectedSurfaceArea * windLayers
      : 0.0;
  final wind = _packagedMaterial(
    name: 'Наружная защитная мембрана по проекту',
    category: 'Мембраны',
    exactNeed: windExactAreaM2,
    reservePercent: windReservePercent,
    packageSize: windRollAreaM2,
    unit: 'м²',
    packageUnit: 'рулонов',
  );
  if (wind != null) materials.add(wind.material);

  final tape = _packagedMaterial(
    name: 'Системная лента для стыков и примыканий',
    category: 'Герметизация',
    exactNeed: tapeProjectM,
    reservePercent: tapeReservePercent,
    packageSize: tapeRollLengthM,
    unit: 'м',
    packageUnit: 'рулонов',
  );
  if (tape != null) materials.add(tape.material);

  final sheathingFasteners = _packagedMaterial(
    name: 'Крепёж листовой обшивки из проектной ведомости',
    category: 'Крепёж',
    exactNeed: sheathingFastenersProjectPcs,
    reservePercent: sheathingFastenersReservePercent,
    packageSize: sheathingFastenersPackagePcs,
    unit: 'шт',
    packageUnit: 'упаковок',
  );
  if (sheathingFasteners != null) materials.add(sheathingFasteners.material);

  final framingFasteners = _packagedMaterial(
    name: 'Крепёж соединений каркаса из проектной ведомости',
    category: 'Крепёж',
    exactNeed: framingFastenersProjectPcs,
    reservePercent: framingFastenersReservePercent,
    packageSize: framingFastenersPackagePcs,
    unit: 'шт',
    packageUnit: 'упаковок',
  );
  if (framingFasteners != null) materials.add(framingFasteners.material);

  final cleanOuterSheets = outerSheathingEnabled == 1 && outerSheetAreaM2 > 0
      ? outerExactAreaM2 / outerSheetAreaM2
      : 0.0;
  final scenarioPolicy =
      spec.raw['scenario_policy'] as Map<String, dynamic>? ?? const {};
  final maxReserveFloorPercent =
      (scenarioPolicy['max_reserve_floor_percent'] as num?)?.toDouble() ?? 15;
  final scenarios = _outerSheetScenarios(
    cleanOuterSheets,
    outerSheathingReservePercent,
    maxReserveFloorPercent,
  );

  final warnings = <String>[
    'Это закупочный расчёт по принятому проекту: несущая схема, шаг и сечение стоек, перемычки, укосины, узлы, крепёж и состав стены здесь не проектируются',
  ];
  if (openingsAreaInput > grossWallArea) {
    warnings.add(
      'Площадь проёмов превышает валовую площадь стен и ограничена площадью стен',
    );
  }
  if (framingProjectLengthM <= 0) {
    warnings.add(
      'Пиломатериал каркаса не добавлен: перенесите длину одной позиции из проектной ведомости и повторите расчёт для каждого сечения',
    );
  }
  if (insulationEnabled == 1 && insulationPackageAreaM2 <= 0) {
    warnings.add(
      'Утеплитель включён, но площадь упаковки выбранного товара не заполнена',
    );
  }
  if (vaporBarrierEnabled == 1 && vaporRollAreaM2 <= 0) {
    warnings.add(
      'Пароизоляция включена, но полезная площадь рулона не заполнена',
    );
  }
  if (windBarrierEnabled == 1 && windRollAreaM2 <= 0) {
    warnings.add(
      'Наружная мембрана включена, но полезная площадь рулона не заполнена',
    );
  }
  if (tapeProjectM > 0 && tapeRollLengthM <= 0) {
    warnings.add('Длина ленты задана, но длина одного рулона не заполнена');
  }
  if (sheathingFastenersProjectPcs > 0 && sheathingFastenersPackagePcs <= 0) {
    warnings.add('Крепёж обшивки задан, но количество в упаковке не заполнено');
  }
  if (framingFastenersProjectPcs > 0 && framingFastenersPackagePcs <= 0) {
    warnings.add('Крепёж каркаса задан, но количество в упаковке не заполнено');
  }
  if (materials.isEmpty) {
    warnings.add('Не выбрана ни одна закупочная позиция');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'wallLength': roundValue(wallLength, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'openingsAreaInput': roundValue(openingsAreaInput, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'grossWallArea': roundValue(grossWallArea, 3),
      'netWallArea': roundValue(netWallArea, 3),
      'selectedSurfaceArea': roundValue(selectedSurfaceArea, 3),
      'surfaceAreaBasis': surfaceAreaBasis.toDouble(),
      'framingProjectLengthM': roundValue(framingProjectLengthM, 3),
      'framingPurchaseBoards': (framing?.packageCount ?? 0).toDouble(),
      'framingPurchaseM': framing?.material.purchaseQty ?? 0,
      'outerSheathingEnabled': outerSheathingEnabled.toDouble(),
      'outerExactAreaM2': roundValue(outerExactAreaM2, 3),
      'outerSheets': (outer?.packageCount ?? 0).toDouble(),
      'outerPurchaseAreaM2': outer?.material.purchaseQty ?? 0,
      'innerSheathingEnabled': innerSheathingEnabled.toDouble(),
      'innerExactAreaM2': roundValue(innerExactAreaM2, 3),
      'innerSheets': (inner?.packageCount ?? 0).toDouble(),
      'innerPurchaseAreaM2': inner?.material.purchaseQty ?? 0,
      'insulationEnabled': insulationEnabled.toDouble(),
      'insulationExactAreaM2': roundValue(insulationExactAreaM2, 3),
      'insulationPackages': (insulation?.packageCount ?? 0).toDouble(),
      'vaporBarrierEnabled': vaporBarrierEnabled.toDouble(),
      'vaporRolls': (vapor?.packageCount ?? 0).toDouble(),
      'windBarrierEnabled': windBarrierEnabled.toDouble(),
      'windRolls': (wind?.packageCount ?? 0).toDouble(),
      'tapeRolls': (tape?.packageCount ?? 0).toDouble(),
      'sheathingFastenerPackages': (sheathingFasteners?.packageCount ?? 0)
          .toDouble(),
      'framingFastenerPackages': (framingFasteners?.packageCount ?? 0)
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
