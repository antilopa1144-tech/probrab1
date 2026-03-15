import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class WarmFloorHeatingTypeSpec {
  final int id;
  final String key;
  final String label;

  const WarmFloorHeatingTypeSpec({
    required this.id,
    required this.key,
    required this.label,
  });
}

class WarmFloorPackagingRules {
  final String matUnit;
  final String cableUnit;
  final String pipeUnit;

  const WarmFloorPackagingRules({
    required this.matUnit,
    required this.cableUnit,
    required this.pipeUnit,
  });
}

class WarmFloorMaterialRules {
  final double matArea;
  final double cableStepM;
  final double cableReserve;
  final double pipeStepM;
  final double pipeReserve;
  final double substrateReserve;
  final double substrateRollM2;
  final double corrugatedTubeM;
  final double tileAdhesiveKgPerM2;
  final double tileAdhesiveBagKg;
  final double epsSheetM2;
  final double epsReserve;
  final double screedThicknessM;
  final double screedDensity;
  final double screedBagKg;
  final double meshReserve;
  final double mountingTapeRollM;
  final double pipeInsulationReserve;
  final double maxCircuitM;

  const WarmFloorMaterialRules({
    required this.matArea,
    required this.cableStepM,
    required this.cableReserve,
    required this.pipeStepM,
    required this.pipeReserve,
    required this.substrateReserve,
    required this.substrateRollM2,
    required this.corrugatedTubeM,
    required this.tileAdhesiveKgPerM2,
    required this.tileAdhesiveBagKg,
    required this.epsSheetM2,
    required this.epsReserve,
    required this.screedThicknessM,
    required this.screedDensity,
    required this.screedBagKg,
    required this.meshReserve,
    required this.mountingTapeRollM,
    required this.pipeInsulationReserve,
    required this.maxCircuitM,
  });
}

class WarmFloorWarningRules {
  final double separateBreakerKwThreshold;
  final double ineffectiveCoverageRatio;

  const WarmFloorWarningRules({
    required this.separateBreakerKwThreshold,
    required this.ineffectiveCoverageRatio,
  });
}

class WarmFloorCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<WarmFloorHeatingTypeSpec> heatingTypes;
  final WarmFloorPackagingRules packagingRules;
  final WarmFloorMaterialRules materialRules;
  final WarmFloorWarningRules warningRules;

  const WarmFloorCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.heatingTypes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const WarmFloorCanonicalSpec warmFloorCanonicalSpecV1 = WarmFloorCanonicalSpec(
  calculatorId: 'warm-floor',
  formulaVersion: 'warm-floor-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'roomArea', unit: 'm2', defaultValue: 10, min: 1, max: 100),
    CanonicalInputField(key: 'furnitureArea', unit: 'm2', defaultValue: 2, min: 0, max: 50),
    CanonicalInputField(key: 'heatingType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'powerDensity', unit: 'W/m2', defaultValue: 150, min: 100, max: 200),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  heatingTypes: [
    WarmFloorHeatingTypeSpec(id: 0, key: 'mat', label: 'Нагревательный мат'),
    WarmFloorHeatingTypeSpec(id: 1, key: 'cable', label: 'Кабель в стяжку'),
    WarmFloorHeatingTypeSpec(id: 2, key: 'water_pipes', label: 'Водяные трубы'),
  ],
  packagingRules: WarmFloorPackagingRules(
    matUnit: 'шт',
    cableUnit: 'м',
    pipeUnit: 'м',
  ),
  materialRules: WarmFloorMaterialRules(
    matArea: 2.0,
    cableStepM: 0.15,
    cableReserve: 1.05,
    pipeStepM: 0.15,
    pipeReserve: 1.05,
    substrateReserve: 1.1,
    substrateRollM2: 25,
    corrugatedTubeM: 1,
    tileAdhesiveKgPerM2: 5,
    tileAdhesiveBagKg: 25,
    epsSheetM2: 0.72,
    epsReserve: 1.1,
    screedThicknessM: 0.04,
    screedDensity: 2000,
    screedBagKg: 50,
    meshReserve: 1.05,
    mountingTapeRollM: 25,
    pipeInsulationReserve: 1.0,
    maxCircuitM: 80,
  ),
  warningRules: WarmFloorWarningRules(
    separateBreakerKwThreshold: 3.5,
    ineffectiveCoverageRatio: 0.5,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(WarmFloorCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(WarmFloorCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(WarmFloorCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalWarmFloor(
  Map<String, double> inputs, {
  WarmFloorCanonicalSpec spec = warmFloorCanonicalSpecV1,
}) {
  final roomArea = (inputs['roomArea'] ?? _defaultFor(spec, 'roomArea', 10)).clamp(1.0, 100.0);
  final furnitureArea = (inputs['furnitureArea'] ?? _defaultFor(spec, 'furnitureArea', 2)).clamp(0.0, 50.0);
  final heatingType = (inputs['heatingType'] ?? _defaultFor(spec, 'heatingType', 0)).round().clamp(0, 2);
  final powerDensity = (inputs['powerDensity'] ?? _defaultFor(spec, 'powerDensity', 150)).clamp(100.0, 200.0);

  final heatingArea = math.max(0.0, roomArea - furnitureArea);
  final totalPowerW = heatingArea * powerDensity;
  final totalPowerKW = _roundValue(totalPowerW / 1000, 3);

  /* ─── per-type calculations ─── */
  double basePrimary;
  List<CanonicalMaterialResult> materials;

  int mats = 0, cableLength = 0, mountingTapeRolls = 0, epsSheets = 0, screedBags = 0;
  int pipeLength = 0, circuits = 0;
  double pipeInsulation = 0, meshArea = 0;
  int substrateRolls = 0, adhesiveBags = 0;

  if (heatingType == 0) {
    // Mats
    mats = (heatingArea / spec.materialRules.matArea).ceil();
    substrateRolls = (heatingArea * spec.materialRules.substrateReserve / spec.materialRules.substrateRollM2).ceil();
    adhesiveBags = (heatingArea * spec.materialRules.tileAdhesiveKgPerM2 / spec.materialRules.tileAdhesiveBagKg).ceil();

    basePrimary = mats.toDouble();
    materials = [
      CanonicalMaterialResult(
        name: 'Нагревательный мат',
        quantity: mats.toDouble(),
        unit: 'шт',
        withReserve: mats.toDouble(),
        purchaseQty: mats,
        category: 'Основное',
      ),
      const CanonicalMaterialResult(
        name: 'Терморегулятор',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1,
        category: 'Управление',
      ),
      CanonicalMaterialResult(
        name: 'Гофротрубка для датчика',
        quantity: spec.materialRules.corrugatedTubeM,
        unit: 'м',
        withReserve: spec.materialRules.corrugatedTubeM,
        purchaseQty: spec.materialRules.corrugatedTubeM.ceil(),
        category: 'Монтаж',
      ),
      CanonicalMaterialResult(
        name: 'Подложка (рулоны)',
        quantity: substrateRolls.toDouble(),
        unit: 'рулонов',
        withReserve: substrateRolls.toDouble(),
        purchaseQty: substrateRolls,
        category: 'Подготовка',
      ),
      CanonicalMaterialResult(
        name: 'Плиточный клей (мешки 25 кг)',
        quantity: _roundValue(heatingArea * spec.materialRules.tileAdhesiveKgPerM2, 3),
        unit: 'кг',
        withReserve: (adhesiveBags * spec.materialRules.tileAdhesiveBagKg),
        purchaseQty: adhesiveBags,
        category: 'Основное',
      ),
    ];
  } else if (heatingType == 1) {
    // Cable in screed
    cableLength = (heatingArea / spec.materialRules.cableStepM * spec.materialRules.cableReserve).ceil();
    mountingTapeRolls = (cableLength / spec.materialRules.mountingTapeRollM).ceil();
    epsSheets = (heatingArea * spec.materialRules.epsReserve / spec.materialRules.epsSheetM2).ceil();
    screedBags = (heatingArea * spec.materialRules.screedThicknessM * spec.materialRules.screedDensity / spec.materialRules.screedBagKg).ceil();

    basePrimary = cableLength.toDouble();
    materials = [
      CanonicalMaterialResult(
        name: 'Нагревательный кабель',
        quantity: cableLength.toDouble(),
        unit: 'м',
        withReserve: cableLength.toDouble(),
        purchaseQty: cableLength,
        category: 'Основное',
      ),
      const CanonicalMaterialResult(
        name: 'Терморегулятор',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1,
        category: 'Управление',
      ),
      CanonicalMaterialResult(
        name: 'Монтажная лента (рулоны)',
        quantity: mountingTapeRolls.toDouble(),
        unit: 'рулонов',
        withReserve: mountingTapeRolls.toDouble(),
        purchaseQty: mountingTapeRolls,
        category: 'Монтаж',
      ),
      CanonicalMaterialResult(
        name: 'Утеплитель ЕПС (листы 1200×600)',
        quantity: epsSheets.toDouble(),
        unit: 'листов',
        withReserve: epsSheets.toDouble(),
        purchaseQty: epsSheets,
        category: 'Утепление',
      ),
      CanonicalMaterialResult(
        name: 'Стяжка ЦПС (мешки 50 кг)',
        quantity: _roundValue(heatingArea * spec.materialRules.screedThicknessM * spec.materialRules.screedDensity, 3),
        unit: 'кг',
        withReserve: (screedBags * spec.materialRules.screedBagKg),
        purchaseQty: screedBags,
        category: 'Основное',
      ),
    ];
  } else {
    // Water pipes
    pipeLength = (heatingArea / spec.materialRules.pipeStepM * spec.materialRules.pipeReserve).ceil();
    circuits = math.max(1, (pipeLength / spec.materialRules.maxCircuitM).ceil());
    pipeInsulation = pipeLength * spec.materialRules.pipeInsulationReserve;
    meshArea = heatingArea * spec.materialRules.meshReserve;

    basePrimary = pipeLength.toDouble();
    materials = [
      CanonicalMaterialResult(
        name: 'Труба для тёплого пола',
        quantity: pipeLength.toDouble(),
        unit: 'м',
        withReserve: pipeLength.toDouble(),
        purchaseQty: pipeLength,
        category: 'Основное',
      ),
      const CanonicalMaterialResult(
        name: 'Коллектор',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1,
        category: 'Управление',
      ),
      CanonicalMaterialResult(
        name: 'Теплоизоляция трубы',
        quantity: pipeInsulation,
        unit: 'м',
        withReserve: pipeInsulation,
        purchaseQty: pipeInsulation.ceil(),
        category: 'Утепление',
      ),
      CanonicalMaterialResult(
        name: 'Армирующая сетка',
        quantity: _roundValue(meshArea, 3),
        unit: 'м²',
        withReserve: meshArea.ceil().toDouble(),
        purchaseQty: meshArea.ceil(),
        category: 'Армирование',
      ),
    ];
  }

  /* ─── scenarios ─── */
  final scenarios = <String, CanonicalScenarioResult>{};
  final packageLabel = heatingType == 0
      ? 'warm-floor-mat'
      : heatingType == 1
          ? 'warm-floor-cable-m'
          : 'warm-floor-pipe-m';
  final packageUnit = heatingType == 0 ? 'шт' : 'м';

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount.toDouble(), 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'heatingType:$heatingType',
        'powerDensity:$powerDensity',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ─── warnings ─── */
  final warnings = <String>[];
  if (totalPowerKW > spec.warningRules.separateBreakerKwThreshold) {
    warnings.add('Мощность более 3.5 кВт — требуется отдельный автомат');
  }
  if (roomArea > 0 && heatingArea / roomArea < spec.warningRules.ineffectiveCoverageRatio) {
    warnings.add('Обогреваемая площадь менее 50% — неэффективное покрытие');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roomArea': _roundValue(roomArea, 3),
      'furnitureArea': _roundValue(furnitureArea, 3),
      'heatingArea': _roundValue(heatingArea, 3),
      'heatingType': heatingType.toDouble(),
      'powerDensity': powerDensity,
      'totalPowerW': _roundValue(totalPowerW, 3),
      'totalPowerKW': totalPowerKW,
      'thermostat': 1.0,
      'mats': mats.toDouble(),
      'cableLength': cableLength.toDouble(),
      'mountingTapeRolls': mountingTapeRolls.toDouble(),
      'epsSheets': epsSheets.toDouble(),
      'screedBags': screedBags.toDouble(),
      'pipeLength': pipeLength.toDouble(),
      'circuits': circuits.toDouble(),
      'pipeInsulation': pipeInsulation,
      'meshArea': _roundValue(meshArea, 3),
      'substrateRolls': substrateRolls.toDouble(),
      'adhesiveBags': adhesiveBags.toDouble(),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': recScenario.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'recPurchase': recScenario.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
