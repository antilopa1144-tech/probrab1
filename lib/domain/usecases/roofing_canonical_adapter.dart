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

double _planningQuantity(double exactNeed, double reservePercent) =>
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

Map<String, CanonicalScenarioResult> _primaryScenarios(
  double cleanUnits,
  double recReservePercent,
  double maxReserveFloorPercent,
  String packageLabel,
  String packageUnit,
) {
  final reserves = <String, double>{
    'MIN': 0,
    'REC': recReservePercent,
    'MAX': math.max(recReservePercent, maxReserveFloorPercent),
  };
  return reserves.map((scenario, reservePercent) {
    final exactNeed = _planningQuantity(cleanUnits, reservePercent);
    final purchaseQuantity = _roundUpUnits(exactNeed, 1);
    return MapEntry(
      scenario,
      CanonicalScenarioResult(
        exactNeed: roundValue(exactNeed, 6),
        purchaseQuantity: purchaseQuantity.toDouble(),
        leftover: roundValue(purchaseQuantity - exactNeed, 6),
        assumptions: [
          'primary_material:roof_covering',
          'reserve_percent:$reservePercent',
        ],
        keyFactors: {'field_multiplier': 1, 'reserve_percent': reservePercent},
        buyPlan: CanonicalBuyPlan(
          packageLabel: packageLabel,
          packageSize: 1,
          packagesCount: purchaseQuantity,
          unit: packageUnit,
        ),
      ),
    );
  });
}

String _roofingTypeLabel(SpecReader spec, int roofingType) {
  final normative = spec.raw['normative_formula'] as Map<String, dynamic>?;
  final types = normative?['roofing_types'] as List<dynamic>? ?? const [];
  for (final item in types) {
    final data = item as Map<String, dynamic>;
    if ((data['id'] as num?)?.toInt() == roofingType) {
      return data['label'] as String? ?? 'Кровельное покрытие';
    }
  }
  return 'Кровельное покрытие';
}

String _primaryPackageUnit(SpecReader spec, int roofingType) {
  final materialRules = spec.raw['material_rules'] as Map<String, dynamic>?;
  final units =
      materialRules?['primary_package_units'] as Map<String, dynamic>?;
  return units?['$roofingType'] as String? ?? 'единиц';
}

CanonicalCalculatorContractResult calculateCanonicalRoofing(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(roofingSpecData);
  double read(String key, double fallback, double min, double max) =>
      _input(spec, inputs, key, fallback, min, max);

  final roofAreaMode = read('roofAreaMode', 0, 0, 1).round();
  final projectSlopeAreaM2 = read('projectSlopeAreaM2', 100, 1, 10000);
  final planProjectionAreaM2 = read('planProjectionAreaM2', 80, 1, 10000);
  final slopeDeg = read('slopeDeg', 30, 1, 75);
  final slopeFactor = 1 / math.cos(slopeDeg * math.pi / 180);
  final selectedSlopeAreaM2 = roofAreaMode == 1
      ? planProjectionAreaM2 * slopeFactor
      : projectSlopeAreaM2;

  final roofingType = read('roofingType', 0, 0, 5).round();
  final roofingTypeLabel = _roofingTypeLabel(spec, roofingType);
  final primaryPackageUnit = _primaryPackageUnit(spec, roofingType);
  final primaryCoverageM2 = read('primaryCoverageM2', 0, 0, 1000);
  final primaryReservePercent = read('primaryReservePercent', 10, 0, 50);

  final ridgeProjectM = read('ridgeProjectM', 0, 0, 10000);
  final ridgeReservePercent = read('ridgeReservePercent', 5, 0, 30);
  final ridgeElementUsefulLengthM = read(
    'ridgeElementUsefulLengthM',
    0,
    0,
    100,
  );
  final valleyProjectM = read('valleyProjectM', 0, 0, 10000);
  final valleyReservePercent = read('valleyReservePercent', 10, 0, 50);
  final valleyElementUsefulLengthM = read(
    'valleyElementUsefulLengthM',
    0,
    0,
    100,
  );
  final eavesProjectM = read('eavesProjectM', 0, 0, 10000);
  final eavesReservePercent = read('eavesReservePercent', 5, 0, 30);
  final eavesElementUsefulLengthM = read(
    'eavesElementUsefulLengthM',
    0,
    0,
    100,
  );

  final membraneProjectAreaM2 = read('membraneProjectAreaM2', 0, 0, 10000);
  final membraneReservePercent = read('membraneReservePercent', 15, 0, 50);
  final membraneRollCoverageM2 = read('membraneRollCoverageM2', 0, 0, 1000);
  final deckProjectAreaM2 = read('deckProjectAreaM2', 0, 0, 10000);
  final deckReservePercent = read('deckReservePercent', 10, 0, 50);
  final deckSheetAreaM2 = read('deckSheetAreaM2', 0, 0, 100);

  final battenProjectLengthM = read('battenProjectLengthM', 0, 0, 100000);
  final battenReservePercent = read('battenReservePercent', 5, 0, 30);
  final battenBoardLengthM = read('battenBoardLengthM', 0, 0, 20);
  final counterBattenProjectLengthM = read(
    'counterBattenProjectLengthM',
    0,
    0,
    100000,
  );
  final counterBattenReservePercent = read(
    'counterBattenReservePercent',
    5,
    0,
    30,
  );
  final counterBattenBoardLengthM = read('counterBattenBoardLengthM', 0, 0, 20);

  final fastenersProjectPcs = read('fastenersProjectPcs', 0, 0, 1000000);
  final fastenersReservePercent = read('fastenersReservePercent', 5, 0, 30);
  final fastenersPackagePcs = read('fastenersPackagePcs', 0, 0, 100000);
  final snowGuardProjectM = read('snowGuardProjectM', 0, 0, 10000);
  final snowGuardReservePercent = read('snowGuardReservePercent', 5, 0, 30);
  final snowGuardSectionUsefulLengthM = read(
    'snowGuardSectionUsefulLengthM',
    0,
    0,
    100,
  );
  final sealingTapeProjectM = read('sealingTapeProjectM', 0, 0, 100000);
  final sealingTapeReservePercent = read(
    'sealingTapeReservePercent',
    10,
    0,
    50,
  );
  final sealingTapeRollLengthM = read('sealingTapeRollLengthM', 0, 0, 1000);

  final materials = <CanonicalMaterialResult>[];
  final primary = _packagedMaterial(
    name: '$roofingTypeLabel — выбранный товар',
    category: 'Основное покрытие',
    exactNeed: selectedSlopeAreaM2,
    reservePercent: primaryReservePercent,
    packageSize: primaryCoverageM2,
    unit: 'м²',
    packageUnit: primaryPackageUnit,
  );
  if (primary != null) materials.add(primary.material);

  final projectLines = <_PackagedMaterial?>[
    _packagedMaterial(
      name: 'Коньковый элемент из проектной ведомости',
      category: 'Доборные элементы',
      exactNeed: ridgeProjectM,
      reservePercent: ridgeReservePercent,
      packageSize: ridgeElementUsefulLengthM,
      unit: 'м',
      packageUnit: 'шт',
    ),
    _packagedMaterial(
      name: 'Ендовный элемент из проектной ведомости',
      category: 'Доборные элементы',
      exactNeed: valleyProjectM,
      reservePercent: valleyReservePercent,
      packageSize: valleyElementUsefulLengthM,
      unit: 'м',
      packageUnit: 'шт',
    ),
    _packagedMaterial(
      name: 'Карнизная планка из проектной ведомости',
      category: 'Доборные элементы',
      exactNeed: eavesProjectM,
      reservePercent: eavesReservePercent,
      packageSize: eavesElementUsefulLengthM,
      unit: 'м',
      packageUnit: 'шт',
    ),
    _packagedMaterial(
      name: 'Кровельная мембрана по проекту',
      category: 'Изоляция',
      exactNeed: membraneProjectAreaM2,
      reservePercent: membraneReservePercent,
      packageSize: membraneRollCoverageM2,
      unit: 'м²',
      packageUnit: 'рулонов',
    ),
    _packagedMaterial(
      name: 'Сплошное листовое основание по проекту',
      category: 'Основание',
      exactNeed: deckProjectAreaM2,
      reservePercent: deckReservePercent,
      packageSize: deckSheetAreaM2,
      unit: 'м²',
      packageUnit: 'листов',
    ),
    _packagedMaterial(
      name: 'Обрешётка — одна позиция пиломатериала из проекта',
      category: 'Пиломатериал',
      exactNeed: battenProjectLengthM,
      reservePercent: battenReservePercent,
      packageSize: battenBoardLengthM,
      unit: 'м',
      packageUnit: 'досок',
    ),
    _packagedMaterial(
      name: 'Контробрешётка — одна позиция пиломатериала из проекта',
      category: 'Пиломатериал',
      exactNeed: counterBattenProjectLengthM,
      reservePercent: counterBattenReservePercent,
      packageSize: counterBattenBoardLengthM,
      unit: 'м',
      packageUnit: 'брусков',
    ),
    _packagedMaterial(
      name: 'Крепёж из проектной ведомости',
      category: 'Крепёж',
      exactNeed: fastenersProjectPcs,
      reservePercent: fastenersReservePercent,
      packageSize: fastenersPackagePcs,
      unit: 'шт',
      packageUnit: 'упаковок',
    ),
    _packagedMaterial(
      name: 'Снегозадержание из проектной ведомости',
      category: 'Безопасность',
      exactNeed: snowGuardProjectM,
      reservePercent: snowGuardReservePercent,
      packageSize: snowGuardSectionUsefulLengthM,
      unit: 'м',
      packageUnit: 'секций',
    ),
    _packagedMaterial(
      name: 'Системная лента для мембран и примыканий',
      category: 'Герметизация',
      exactNeed: sealingTapeProjectM,
      reservePercent: sealingTapeReservePercent,
      packageSize: sealingTapeRollLengthM,
      unit: 'м',
      packageUnit: 'рулонов',
    ),
  ];
  materials.addAll(
    projectLines.whereType<_PackagedMaterial>().map((e) => e.material),
  );

  final cleanPrimaryUnits = primaryCoverageM2 > 0
      ? selectedSlopeAreaM2 / primaryCoverageM2
      : 0.0;
  final scenarioPolicy =
      spec.raw['scenario_policy'] as Map<String, dynamic>? ?? const {};
  final maxReserveFloorPercent =
      (scenarioPolicy['max_reserve_floor_percent'] as num?)?.toDouble() ?? 15;
  final scenarios = _primaryScenarios(
    cleanPrimaryUnits,
    primaryReservePercent,
    maxReserveFloorPercent,
    'roof-covering-$roofingType',
    primaryPackageUnit,
  );

  final warnings = <String>[
    'Это закупочный расчёт по принятому проекту: стропила, прогоны, обрешётка, кровельный пирог, нагрузки, водоотвод и снегозадержание здесь не проектируются',
  ];
  if (roofAreaMode == 1) {
    warnings.add(
      'Площадь по проекции и уклону допустима только для простой одно- или двухскатной крыши с одинаковым уклоном; для сложной крыши введите сумму площадей скатов из проекта',
    );
  }
  if (primaryCoverageM2 <= 0) {
    warnings.add(
      'Основное покрытие не рассчитано: заполните полезную площадь одной покупной единицы выбранного товара',
    );
  }

  final missingPackageWarnings = <(double, double, String)>[
    (
      ridgeProjectM,
      ridgeElementUsefulLengthM,
      'Длина конька задана, но полезная длина одного конькового элемента не заполнена',
    ),
    (
      valleyProjectM,
      valleyElementUsefulLengthM,
      'Длина ендов задана, но полезная длина одного ендовного элемента не заполнена',
    ),
    (
      eavesProjectM,
      eavesElementUsefulLengthM,
      'Длина карнизов задана, но полезная длина одной планки не заполнена',
    ),
    (
      membraneProjectAreaM2,
      membraneRollCoverageM2,
      'Площадь мембраны задана, но полезная площадь рулона не заполнена',
    ),
    (
      deckProjectAreaM2,
      deckSheetAreaM2,
      'Площадь сплошного основания задана, но площадь одного листа не заполнена',
    ),
    (
      battenProjectLengthM,
      battenBoardLengthM,
      'Длина обрешётки задана, но длина покупной доски не заполнена',
    ),
    (
      counterBattenProjectLengthM,
      counterBattenBoardLengthM,
      'Длина контробрешётки задана, но длина покупного бруска не заполнена',
    ),
    (
      fastenersProjectPcs,
      fastenersPackagePcs,
      'Количество крепежа задано, но количество в упаковке не заполнено',
    ),
    (
      snowGuardProjectM,
      snowGuardSectionUsefulLengthM,
      'Длина снегозадержания задана, но полезная длина одной секции не заполнена',
    ),
    (
      sealingTapeProjectM,
      sealingTapeRollLengthM,
      'Длина ленты задана, но длина одного рулона не заполнена',
    ),
  ];
  for (final (projectQuantity, packageSize, warning)
      in missingPackageWarnings) {
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
      'roofAreaMode': roofAreaMode.toDouble(),
      'projectSlopeAreaM2': roundValue(projectSlopeAreaM2, 3),
      'planProjectionAreaM2': roundValue(planProjectionAreaM2, 3),
      'slopeDeg': roundValue(slopeDeg, 3),
      'slopeFactor': roundValue(slopeFactor, 6),
      'selectedSlopeAreaM2': roundValue(selectedSlopeAreaM2, 3),
      'roofingType': roofingType.toDouble(),
      'primaryCoverageM2': roundValue(primaryCoverageM2, 3),
      'primaryUnits': (primary?.packageCount ?? 0).toDouble(),
      'primaryPurchaseAreaM2': primary?.material.purchaseQty ?? 0,
      'ridgeElements': (projectLines[0]?.packageCount ?? 0).toDouble(),
      'valleyElements': (projectLines[1]?.packageCount ?? 0).toDouble(),
      'eavesElements': (projectLines[2]?.packageCount ?? 0).toDouble(),
      'membraneRolls': (projectLines[3]?.packageCount ?? 0).toDouble(),
      'deckSheets': (projectLines[4]?.packageCount ?? 0).toDouble(),
      'battenBoards': (projectLines[5]?.packageCount ?? 0).toDouble(),
      'counterBattenBoards': (projectLines[6]?.packageCount ?? 0).toDouble(),
      'fastenerPackages': (projectLines[7]?.packageCount ?? 0).toDouble(),
      'snowGuardSections': (projectLines[8]?.packageCount ?? 0).toDouble(),
      'sealingTapeRolls': (projectLines[9]?.packageCount ?? 0).toDouble(),
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
