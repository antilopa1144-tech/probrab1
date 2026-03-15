import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class SewageSeptikTypeSpec {
  final int id;
  final String key;
  final String label;

  const SewageSeptikTypeSpec({
    required this.id,
    required this.key,
    required this.label,
  });
}

class SewageGroundTypeSpec {
  final int id;
  final String key;
  final String label;
  final double gravelM3;

  const SewageGroundTypeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.gravelM3,
  });
}

class SewagePackagingRules {
  final String unit;
  final double packageSize;

  const SewagePackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class SewageMaterialRules {
  final double litersPerPersonPerDay;
  final double reserveDays;
  final double ringVolumeM3;
  final double eurocubeUsableM3;
  final double pipeSectionM;
  final double pipeReserve;
  final int defaultElbows;
  final int defaultTees;
  final Map<int, double> gravelByGround;
  final double geotextileFactor;
  final double sandBackfillFactor;

  const SewageMaterialRules({
    required this.litersPerPersonPerDay,
    required this.reserveDays,
    required this.ringVolumeM3,
    required this.eurocubeUsableM3,
    required this.pipeSectionM,
    required this.pipeReserve,
    required this.defaultElbows,
    required this.defaultTees,
    required this.gravelByGround,
    required this.geotextileFactor,
    required this.sandBackfillFactor,
  });
}

class SewageWarningRules {
  final int bioTreatmentResidentsThreshold;

  const SewageWarningRules({
    required this.bioTreatmentResidentsThreshold,
  });
}

class SewageCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<SewageSeptikTypeSpec> septikTypes;
  final List<SewageGroundTypeSpec> groundTypes;
  final SewagePackagingRules packagingRules;
  final SewageMaterialRules materialRules;
  final SewageWarningRules warningRules;

  const SewageCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.septikTypes,
    required this.groundTypes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const SewageCanonicalSpec sewageCanonicalSpecV1 = SewageCanonicalSpec(
  calculatorId: 'sewage',
  formulaVersion: 'sewage-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'residents', defaultValue: 4, min: 1, max: 20),
    CanonicalInputField(key: 'septikType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'chambersCount', defaultValue: 2, min: 1, max: 3),
    CanonicalInputField(key: 'pipeLength', unit: 'm', defaultValue: 10, min: 1, max: 50),
    CanonicalInputField(key: 'groundType', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  septikTypes: [
    SewageSeptikTypeSpec(id: 0, key: 'concrete_rings', label: 'Бетонные кольца'),
    SewageSeptikTypeSpec(id: 1, key: 'plastic', label: 'Пластиковый септик'),
    SewageSeptikTypeSpec(id: 2, key: 'eurocubes', label: 'Еврокубы'),
  ],
  groundTypes: [
    SewageGroundTypeSpec(id: 0, key: 'sand', label: 'Песок', gravelM3: 0),
    SewageGroundTypeSpec(id: 1, key: 'loam', label: 'Суглинок', gravelM3: 2),
    SewageGroundTypeSpec(id: 2, key: 'clay', label: 'Глина', gravelM3: 4),
  ],
  packagingRules: SewagePackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: SewageMaterialRules(
    litersPerPersonPerDay: 200,
    reserveDays: 3,
    ringVolumeM3: 0.71,
    eurocubeUsableM3: 0.8,
    pipeSectionM: 3,
    pipeReserve: 1.05,
    defaultElbows: 3,
    defaultTees: 2,
    gravelByGround: {0: 0, 1: 2, 2: 4},
    geotextileFactor: 2,
    sandBackfillFactor: 0.5,
  ),
  warningRules: SewageWarningRules(
    bioTreatmentResidentsThreshold: 10,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.05},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(SewageCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(SewageCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(SewageCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalSewage(
  Map<String, double> inputs, {
  SewageCanonicalSpec spec = sewageCanonicalSpecV1,
}) {
  final residents = (inputs['residents'] ?? _defaultFor(spec, 'residents', 4)).round().clamp(1, 20);
  final septikType = (inputs['septikType'] ?? _defaultFor(spec, 'septikType', 0)).round().clamp(0, 2);
  final chambersCount = (inputs['chambersCount'] ?? _defaultFor(spec, 'chambersCount', 2)).round().clamp(1, 3);
  final pipeLength = (inputs['pipeLength'] ?? _defaultFor(spec, 'pipeLength', 10)).clamp(1.0, 50.0);
  final groundType = (inputs['groundType'] ?? _defaultFor(spec, 'groundType', 0)).round().clamp(0, 2);

  /* ─── volume calculation ─── */
  final dailyVolumeLiters = residents * spec.materialRules.litersPerPersonPerDay;
  final totalVolumeLiters = dailyVolumeLiters * spec.materialRules.reserveDays;
  final totalVolume = totalVolumeLiters / 1000;
  final volumePerChamber = totalVolume / chambersCount;

  /* ─── type-specific ─── */
  final materials = <CanonicalMaterialResult>[];
  double basePrimary;

  int totalRings = 0;
  int ringsPerChamber = 0;
  int bottomPlates = 0;
  int topPlates = 0;
  int covers = 0;
  int sealingRings = 0;
  int septicCount = 0;
  int sandBackfill = 0;
  int eurocubes = 0;

  if (septikType == 0) {
    // Concrete rings KS 10-9
    ringsPerChamber = (volumePerChamber / spec.materialRules.ringVolumeM3).ceil();
    totalRings = ringsPerChamber * chambersCount;
    bottomPlates = chambersCount;
    topPlates = chambersCount;
    covers = chambersCount;
    sealingRings = totalRings;
    basePrimary = totalRings.toDouble();

    materials.addAll([
      CanonicalMaterialResult(
        name: 'Кольца ЖБ КС 10-9',
        quantity: totalRings.toDouble(),
        unit: 'шт',
        withReserve: totalRings.toDouble(),
        purchaseQty: totalRings,
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Днища ПН-10',
        quantity: bottomPlates.toDouble(),
        unit: 'шт',
        withReserve: bottomPlates.toDouble(),
        purchaseQty: bottomPlates,
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Плиты перекрытия ПП-10',
        quantity: topPlates.toDouble(),
        unit: 'шт',
        withReserve: topPlates.toDouble(),
        purchaseQty: topPlates,
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Люки чугунные',
        quantity: covers.toDouble(),
        unit: 'шт',
        withReserve: covers.toDouble(),
        purchaseQty: covers,
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Кольца уплотнительные',
        quantity: sealingRings.toDouble(),
        unit: 'шт',
        withReserve: sealingRings.toDouble(),
        purchaseQty: sealingRings,
        category: 'Герметизация',
      ),
    ]);
  } else if (septikType == 1) {
    // Plastic septic
    septicCount = 1;
    sandBackfill = (totalVolume * spec.materialRules.sandBackfillFactor).ceil();
    basePrimary = septicCount.toDouble();

    materials.addAll([
      CanonicalMaterialResult(
        name: 'Септик пластиковый',
        quantity: septicCount.toDouble(),
        unit: 'шт',
        withReserve: septicCount.toDouble(),
        purchaseQty: septicCount,
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Песок для обсыпки',
        quantity: sandBackfill.toDouble(),
        unit: 'м\u00b3',
        withReserve: sandBackfill.toDouble(),
        purchaseQty: sandBackfill,
        category: 'Обсыпка',
      ),
    ]);
  } else {
    // Eurocubes
    eurocubes = (totalVolume / spec.materialRules.eurocubeUsableM3).ceil();
    basePrimary = eurocubes.toDouble();

    materials.add(CanonicalMaterialResult(
      name: 'Еврокубы',
      quantity: eurocubes.toDouble(),
      unit: 'шт',
      withReserve: eurocubes.toDouble(),
      purchaseQty: eurocubes,
      category: 'Ёмкость',
    ));
  }

  /* ─── common materials ─── */
  final pipeSections = (pipeLength * spec.materialRules.pipeReserve / spec.materialRules.pipeSectionM).ceil();
  final elbows = spec.materialRules.defaultElbows;
  final tees = spec.materialRules.defaultTees;
  final gravel = (spec.materialRules.gravelByGround[groundType] ?? 0).round();
  final geotextile = groundType >= 1 ? (totalVolume * spec.materialRules.geotextileFactor).ceil() : 0;

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Труба ПВХ \u00f8110 (секции 3 м)',
      quantity: pipeSections.toDouble(),
      unit: 'шт',
      withReserve: pipeSections.toDouble(),
      purchaseQty: pipeSections,
      category: 'Трубопровод',
    ),
    CanonicalMaterialResult(
      name: 'Отводы (колена)',
      quantity: elbows.toDouble(),
      unit: 'шт',
      withReserve: elbows.toDouble(),
      purchaseQty: elbows,
      category: 'Фасонные',
    ),
    CanonicalMaterialResult(
      name: 'Тройники',
      quantity: tees.toDouble(),
      unit: 'шт',
      withReserve: tees.toDouble(),
      purchaseQty: tees,
      category: 'Фасонные',
    ),
  ]);

  if (gravel > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Щебень фракция 20-40',
      quantity: gravel.toDouble(),
      unit: 'м\u00b3',
      withReserve: gravel.toDouble(),
      purchaseQty: gravel,
      category: 'Дренаж',
    ));
  }

  if (geotextile > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Геотекстиль',
      quantity: geotextile.toDouble(),
      unit: 'м\u00b2',
      withReserve: geotextile.toDouble(),
      purchaseQty: geotextile,
      category: 'Дренаж',
    ));
  }

  /* ─── scenarios ─── */
  final scenarios = <String, CanonicalScenarioResult>{};

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
        'septikType:$septikType',
        'chambersCount:$chambersCount',
        'groundType:$groundType',
        'packaging:sewage-unit',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'sewage-unit',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'шт',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ─── warnings ─── */
  final warnings = <String>[];
  if (groundType == 2) {
    warnings.add('Глинистый грунт \u2014 рекомендуется дренажный тоннель');
  }
  if (residents > spec.warningRules.bioTreatmentResidentsThreshold) {
    warnings.add('Более 10 жителей \u2014 рекомендуется станция биологической очистки');
  }
  if (chambersCount == 1) {
    warnings.add('Одна камера \u2014 минимум, рекомендуется 2-3 камеры');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'residents': residents.toDouble(),
      'septikType': septikType.toDouble(),
      'chambersCount': chambersCount.toDouble(),
      'pipeLength': _roundValue(pipeLength, 3),
      'groundType': groundType.toDouble(),
      'dailyVolumeLiters': dailyVolumeLiters,
      'totalVolumeLiters': totalVolumeLiters,
      'totalVolume': _roundValue(totalVolume, 3),
      'volumePerChamber': _roundValue(volumePerChamber, 3),
      'totalRings': totalRings.toDouble(),
      'ringsPerChamber': ringsPerChamber.toDouble(),
      'bottomPlates': bottomPlates.toDouble(),
      'topPlates': topPlates.toDouble(),
      'covers': covers.toDouble(),
      'sealingRings': sealingRings.toDouble(),
      'septicCount': septicCount.toDouble(),
      'sandBackfill': sandBackfill.toDouble(),
      'eurocubes': eurocubes.toDouble(),
      'pipeSections': pipeSections.toDouble(),
      'elbows': elbows.toDouble(),
      'tees': tees.toDouble(),
      'gravel': gravel.toDouble(),
      'geotextile': geotextile.toDouble(),
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
