import '../models/canonical_calculator_contract.dart';

const PlasterCanonicalSpec plasterCanonicalSpecV1 = PlasterCanonicalSpec(
  calculatorId: 'plaster',
  formulaVersion: 'plaster-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 50),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 1, max: 50),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.7, min: 2, max: 5),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 50, min: 0.1, max: 100000),
    CanonicalInputField(key: 'openingsArea', unit: 'm2', defaultValue: 5, min: 0, max: 500),
    CanonicalInputField(key: 'plasterType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 15, min: 5, max: 100),
    CanonicalInputField(key: 'bagWeight', unit: 'kg', defaultValue: 30, min: 25, max: 40),
    CanonicalInputField(key: 'substrateType', defaultValue: 1, min: 1, max: 5),
    CanonicalInputField(key: 'wallEvenness', defaultValue: 1, min: 1, max: 3),
  ],
  enabledFactors: [
    'surface_quality',
    'geometry_complexity',
    'installation_method',
    'worker_skill',
    'waste_factor',
    'logistics_buffer',
    'packaging_rounding',
  ],
  plasterTypes: [
    PlasterTypeSpec(id: 0, key: 'gypsum', label: 'Гипсовая штукатурка', baseKgPerM2Per10Mm: 8.5, defaultBagWeight: 30, allowedBagWeights: [25, 30, 40]),
    PlasterTypeSpec(id: 1, key: 'cement', label: 'Цементная штукатурка', baseKgPerM2Per10Mm: 17, defaultBagWeight: 25, allowedBagWeights: [25, 30, 40]),
    PlasterTypeSpec(id: 2, key: 'cement_lime', label: 'Цементно-известковая штукатурка', baseKgPerM2Per10Mm: 13, defaultBagWeight: 25, allowedBagWeights: [25, 30, 40]),
  ],
  substrateTypes: [
    PlasterSubstrateSpec(id: 1, key: 'concrete', label: 'Бетон', multiplier: 1.0, primerType: 2),
    PlasterSubstrateSpec(id: 2, key: 'new_brick', label: 'Новый кирпич', multiplier: 1.15, primerType: 1),
    PlasterSubstrateSpec(id: 3, key: 'old_brick', label: 'Старый кирпич', multiplier: 1.3, primerType: 1),
    PlasterSubstrateSpec(id: 4, key: 'gas_block', label: 'Газоблок', multiplier: 1.25, primerType: 1),
    PlasterSubstrateSpec(id: 5, key: 'foam_concrete', label: 'Пенобетон', multiplier: 1.2, primerType: 1),
  ],
  wallEvennessProfiles: [
    PlasterEvennessSpec(id: 1, key: 'even', label: 'Ровные стены', multiplier: 1.0),
    PlasterEvennessSpec(id: 2, key: 'uneven', label: 'Неровные стены', multiplier: 1.15),
    PlasterEvennessSpec(id: 3, key: 'very_uneven', label: 'Очень неровные стены', multiplier: 1.3),
  ],
  packagingRules: PlasterPackagingRules(unit: 'кг'),
  materialRules: PlasterMaterialRules(
    reserveFactor: 1.1,
    deepPrimerLitersPerM2: 0.1,
    contactPrimerKgPerM2: 0.3,
    primerPackageSize: 5,
    beaconsAreaM2PerPiece: 2.5,
    beaconThinSizeMm: 6,
    beaconStandardSizeMm: 10,
    thinBeaconThresholdMm: 15,
    meshOverlapFactor: 1.1,
    ruleSizeM: 1.5,
    ruleCount: 1,
    spatulasCount: 1,
    bucketsCount: 2,
    mixerCount: 1,
    glovesPairs: 3,
    cornerProfileLengthM: 3,
    cornerProfileCount: 4,
  ),
  warningRules: PlasterWarningRules(
    gypsumTwoLayerThresholdMm: 20,
    meshThresholdMm: 30,
    smallAreaThresholdM2: 5,
    thickLayerWarningThresholdMm: 40,
    obryzgTipSubstrateIds: [3],
    obryzgTipEvennessIds: [3],
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'surface_quality': {'MIN': 0.99, 'REC': 1.0, 'MAX': 1.05},
  'geometry_complexity': {'MIN': 0.99, 'REC': 1.0, 'MAX': 1.06},
  'installation_method': {'MIN': 0.99, 'REC': 1.0, 'MAX': 1.04},
  'worker_skill': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.03},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'logistics_buffer': {'MIN': 1.0, 'REC': 1.0, 'MAX': 1.04},
  'packaging_rounding': {'MIN': 1.0, 'REC': 1.0, 'MAX': 1.02},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

bool hasCanonicalPlasterInputs(Map<String, double> inputs) {
  if (inputs.containsKey('inputMode') || inputs.containsKey('length') || inputs.containsKey('width') || inputs.containsKey('height')) {
    return true;
  }
  return inputs.containsKey('plasterType') || inputs.containsKey('bagWeight');
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(PlasterCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _resolveWork(PlasterCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  final openingsArea = (inputs['openingsArea'] ?? _defaultFor(spec, 'openingsArea', 5)).clamp(0, 500).toDouble();

  if (inputMode == 0) {
    final length = (inputs['length'] ?? _defaultFor(spec, 'length', 5)).clamp(1, 50).toDouble();
    final width = (inputs['width'] ?? _defaultFor(spec, 'width', 4)).clamp(1, 50).toDouble();
    final height = (inputs['height'] ?? _defaultFor(spec, 'height', 2.7)).clamp(2, 5).toDouble();
    final wallArea = 2 * (length + width) * height;
    return {
      'wallArea': _roundValue(wallArea, 3),
      'netArea': _roundValue((wallArea - openingsArea).clamp(0, double.infinity).toDouble(), 3),
      'inputMode': 0.0,
      'roomHeight': _roundValue(height, 3),
    };
  }

  final wallArea = (inputs['area'] ?? _defaultFor(spec, 'area', 50)).clamp(0.1, 100000).toDouble();
  return {
    'wallArea': _roundValue(wallArea, 3),
    'netArea': _roundValue((wallArea - openingsArea).clamp(0, double.infinity).toDouble(), 3),
    'inputMode': 1.0,
    'roomHeight': _roundValue(_defaultFor(spec, 'height', 2.7), 3),
  };
}

PlasterTypeSpec _resolvePlasterType(PlasterCanonicalSpec spec, Map<String, double> inputs) {
  final typeId = (inputs['plasterType'] ?? _defaultFor(spec, 'plasterType', 0)).round().clamp(0, 2);
  return spec.plasterTypes.firstWhere((item) => item.id == typeId, orElse: () => spec.plasterTypes.first);
}

PlasterSubstrateSpec _resolveSubstrate(PlasterCanonicalSpec spec, Map<String, double> inputs) {
  final substrateId = (inputs['substrateType'] ?? _defaultFor(spec, 'substrateType', 1)).round().clamp(1, 5);
  return spec.substrateTypes.firstWhere((item) => item.id == substrateId, orElse: () => spec.substrateTypes.first);
}

PlasterEvennessSpec _resolveEvenness(PlasterCanonicalSpec spec, Map<String, double> inputs) {
  final evennessId = (inputs['wallEvenness'] ?? _defaultFor(spec, 'wallEvenness', 1)).round().clamp(1, 3);
  return spec.wallEvennessProfiles.firstWhere((item) => item.id == evennessId, orElse: () => spec.wallEvennessProfiles.first);
}

double _resolveThickness(PlasterCanonicalSpec spec, Map<String, double> inputs) {
  return (inputs['thickness'] ?? _defaultFor(spec, 'thickness', 15)).clamp(5, 100).toDouble();
}

double _resolveBagWeight(PlasterCanonicalSpec spec, PlasterTypeSpec plasterType, Map<String, double> inputs) {
  final requested = (inputs['bagWeight'] ?? plasterType.defaultBagWeight).toDouble();
  if (plasterType.allowedBagWeights.contains(requested)) return requested;
  return plasterType.defaultBagWeight;
}

Map<String, double> _keyFactors(PlasterCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(PlasterCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalPlaster(
  Map<String, double> inputs, {
  PlasterCanonicalSpec spec = plasterCanonicalSpecV1,
}) {
  final work = _resolveWork(spec, inputs);
  final plasterType = _resolvePlasterType(spec, inputs);
  final substrate = _resolveSubstrate(spec, inputs);
  final evenness = _resolveEvenness(spec, inputs);
  final thickness = _resolveThickness(spec, inputs);
  final bagWeight = _resolveBagWeight(spec, plasterType, inputs);
  final netArea = work['netArea']!;
  final wallArea = work['wallArea']!;
  final consumptionKgPerM2Mm =
      (plasterType.baseKgPerM2Per10Mm / 10) * substrate.multiplier * evenness.multiplier * spec.materialRules.reserveFactor;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(netArea * thickness * consumptionKgPerM2Mm * multiplier, 6);
    final packagesCount = exactNeed > 0 ? (exactNeed / bagWeight).ceil() : 0;
    final purchaseQuantity = _roundValue(packagesCount * bagWeight, 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'plaster:${plasterType.key}',
        'substrate:${substrate.key}',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'plaster-bag-${bagWeight.toInt()}${spec.packagingRules.unit}',
        packageSize: bagWeight,
        packagesCount: packagesCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final totalKg = _roundValue(recScenario.exactNeed, 3);
  final primerRate = substrate.primerType == 2 ? spec.materialRules.contactPrimerKgPerM2 : spec.materialRules.deepPrimerLitersPerM2;
  final primerNeed = (netArea * primerRate * spec.materialRules.reserveFactor).ceil().toDouble();
  final primerPackages = primerNeed > 0 ? (primerNeed / spec.materialRules.primerPackageSize).ceil() : 0;
  final meshArea = thickness > spec.warningRules.meshThresholdMm
      ? _roundValue(netArea * spec.materialRules.meshOverlapFactor, 3)
      : 0.0;
  final beacons = netArea > 0 ? (netArea / spec.materialRules.beaconsAreaM2PerPiece).ceil().clamp(2, 100000) : 0;
  final beaconSize = thickness < spec.materialRules.thinBeaconThresholdMm
      ? spec.materialRules.beaconThinSizeMm
      : spec.materialRules.beaconStandardSizeMm;
  final cornerProfiles = (work['inputMode'] ?? 1) == 0
      ? ((work['roomHeight']! * spec.materialRules.cornerProfileCount / spec.materialRules.cornerProfileLengthM) * spec.materialRules.reserveFactor).ceil()
      : 0;

  final warnings = <String>[];
  if (plasterType.id == 0 && thickness > spec.warningRules.gypsumTwoLayerThresholdMm) {
    warnings.add('Гипсовую штукатурку толщиной > 20 мм наносят в 2 слоя с армирующей сеткой');
  }
  if (thickness > spec.warningRules.meshThresholdMm) {
    warnings.add('При толщине > 30 мм обязательно армирование стекловолоконной сеткой');
  }
  if (netArea < spec.warningRules.smallAreaThresholdM2) {
    warnings.add('Маленькая площадь — лучше использовать готовую шпаклёвку из ведра');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: '${plasterType.label} (мешки ${bagWeight.toInt()} кг)',
        quantity: _roundValue(totalKg / bagWeight, 3),
        unit: 'мешков',
        withReserve: recScenario.buyPlan.packagesCount.toDouble(),
        purchaseQty: recScenario.buyPlan.packagesCount,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: substrate.primerType == 2
            ? 'Грунтовка бетоноконтакт (${spec.materialRules.primerPackageSize.toInt()} кг)'
            : 'Грунтовка (${spec.materialRules.primerPackageSize.toInt()} л)',
        quantity: primerNeed,
        unit: substrate.primerType == 2 ? 'кг' : 'л',
        withReserve: (primerPackages * spec.materialRules.primerPackageSize).toDouble(),
        purchaseQty: primerPackages,
        category: 'Подготовка',
      ),
      if (meshArea > 0)
        CanonicalMaterialResult(
          name: 'Стеклосетка армировочная (50x50 мм)',
          quantity: meshArea,
          unit: 'м²',
          withReserve: meshArea.ceil().toDouble(),
          purchaseQty: meshArea.ceil(),
          category: 'Армирование',
        ),
      CanonicalMaterialResult(
        name: 'Маяки штукатурные ($beaconSize мм)',
        quantity: beacons.toDouble(),
        unit: 'шт',
        withReserve: beacons.toDouble(),
        purchaseQty: beacons,
        category: 'Вспомогательное',
      ),
      CanonicalMaterialResult(
        name: 'Правило алюминиевое (${spec.materialRules.ruleSizeM} м)',
        quantity: spec.materialRules.ruleCount.toDouble(),
        unit: 'шт',
        withReserve: spec.materialRules.ruleCount.toDouble(),
        purchaseQty: spec.materialRules.ruleCount,
        category: 'Инструмент',
      ),
      if (cornerProfiles > 0)
        CanonicalMaterialResult(
          name: 'Угловой профиль перфорированный 25x25 мм (3 м)',
          quantity: cornerProfiles.toDouble(),
          unit: 'шт',
          withReserve: cornerProfiles.toDouble(),
          purchaseQty: cornerProfiles,
          category: 'Вспомогательное',
        ),
    ],
    totals: {
      'wallArea': _roundValue(wallArea, 3),
      'netArea': _roundValue(netArea, 3),
      'thickness': _roundValue(thickness, 3),
      'totalKg': totalKg,
      'plasterType': plasterType.id.toDouble(),
      'substrateType': substrate.id.toDouble(),
      'wallEvenness': evenness.id.toDouble(),
      'bagWeight': bagWeight,
      'primerNeed': primerNeed,
      'primerType': substrate.primerType.toDouble(),
      'meshArea': meshArea,
      'beacons': beacons.toDouble(),
      'beaconSize': beaconSize.toDouble(),
      'ruleSize': spec.materialRules.ruleSizeM,
      'warningThickLayer': thickness > spec.warningRules.thickLayerWarningThresholdMm ? 1.0 : 0.0,
      'tipObryzg': spec.warningRules.obryzgTipSubstrateIds.contains(substrate.id) && spec.warningRules.obryzgTipEvennessIds.contains(evenness.id) ? 1.0 : 0.0,
      'minExactNeedKg': scenarios['MIN']!.exactNeed,
      'recExactNeedKg': recScenario.exactNeed,
      'maxExactNeedKg': scenarios['MAX']!.exactNeed,
      'minPurchaseKg': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseKg': recScenario.purchaseQuantity,
      'maxPurchaseKg': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}


