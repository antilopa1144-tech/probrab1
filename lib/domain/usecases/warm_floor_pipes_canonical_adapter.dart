import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class WarmFloorPipesPipeTypeSpec {
  final int id;
  final String key;
  final String label;

  const WarmFloorPipesPipeTypeSpec({
    required this.id,
    required this.key,
    required this.label,
  });
}

class WarmFloorPipesPackagingRules {
  final String unit;
  final double coilLengthM;

  const WarmFloorPipesPackagingRules({
    required this.unit,
    required this.coilLengthM,
  });
}

class WarmFloorPipesMaterialRules {
  final double furnitureReduction;
  final double collectorAdditionM;
  final double maxCircuitM;
  final double pipeReserve;
  final double pipeCoilM;
  final double eppsSheetM2;
  final double eppsReserve;
  final double damperTapeRollM;
  final double damperReserve;
  final double anchorStepM;
  final double anchorReserve;
  final int anchorPack;
  final double screedThicknessM;
  final double screedDensity;
  final double screedBagKg;

  const WarmFloorPipesMaterialRules({
    required this.furnitureReduction,
    required this.collectorAdditionM,
    required this.maxCircuitM,
    required this.pipeReserve,
    required this.pipeCoilM,
    required this.eppsSheetM2,
    required this.eppsReserve,
    required this.damperTapeRollM,
    required this.damperReserve,
    required this.anchorStepM,
    required this.anchorReserve,
    required this.anchorPack,
    required this.screedThicknessM,
    required this.screedDensity,
    required this.screedBagKg,
  });
}

class WarmFloorPipesWarningRules {
  final double multipleCircuitsPipeThresholdM;
  final double professionalHeatLossAreaThresholdM2;

  const WarmFloorPipesWarningRules({
    required this.multipleCircuitsPipeThresholdM,
    required this.professionalHeatLossAreaThresholdM2,
  });
}

class WarmFloorPipesCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<WarmFloorPipesPipeTypeSpec> pipeTypes;
  final List<int> allowedPipeStepsMm;
  final WarmFloorPipesPackagingRules packagingRules;
  final WarmFloorPipesMaterialRules materialRules;
  final WarmFloorPipesWarningRules warningRules;

  const WarmFloorPipesCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.pipeTypes,
    required this.allowedPipeStepsMm,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const WarmFloorPipesCanonicalSpec warmFloorPipesCanonicalSpecV1 = WarmFloorPipesCanonicalSpec(
  calculatorId: 'warm-floor-pipes',
  formulaVersion: 'warm-floor-pipes-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 30),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 1, max: 30),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 20, min: 1, max: 300),
    CanonicalInputField(key: 'pipeStep', unit: 'mm', defaultValue: 200, min: 100, max: 300),
    CanonicalInputField(key: 'pipeType', defaultValue: 0, min: 0, max: 3),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  pipeTypes: [
    WarmFloorPipesPipeTypeSpec(id: 0, key: 'pex_a', label: 'PEX-a'),
    WarmFloorPipesPipeTypeSpec(id: 1, key: 'pex_b', label: 'PEX-b'),
    WarmFloorPipesPipeTypeSpec(id: 2, key: 'pe_rt', label: 'PE-RT'),
    WarmFloorPipesPipeTypeSpec(id: 3, key: 'metalplastic', label: 'Металлопластик'),
  ],
  allowedPipeStepsMm: [100, 150, 200, 250, 300],
  packagingRules: WarmFloorPipesPackagingRules(
    unit: 'м',
    coilLengthM: 200,
  ),
  materialRules: WarmFloorPipesMaterialRules(
    furnitureReduction: 0.85,
    collectorAdditionM: 3,
    maxCircuitM: 80,
    pipeReserve: 1.05,
    pipeCoilM: 200,
    eppsSheetM2: 0.72,
    eppsReserve: 1.05,
    damperTapeRollM: 25,
    damperReserve: 1.05,
    anchorStepM: 0.3,
    anchorReserve: 1.05,
    anchorPack: 100,
    screedThicknessM: 0.05,
    screedDensity: 1500,
    screedBagKg: 25,
  ),
  warningRules: WarmFloorPipesWarningRules(
    multipleCircuitsPipeThresholdM: 80,
    professionalHeatLossAreaThresholdM2: 40,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _pipeTypeLabels = {
  0: 'PEX-a',
  1: 'PEX-b',
  2: 'PE-RT',
  3: 'Металлопластик',
};

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(WarmFloorPipesCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _resolveArea(WarmFloorPipesCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = (inputs['length'] ?? _defaultFor(spec, 'length', 5)).clamp(1.0, 30.0);
    final width = (inputs['width'] ?? _defaultFor(spec, 'width', 4)).clamp(1.0, 30.0);
    return {
      'inputMode': 0.0,
      'area': _roundValue(length * width, 3),
      'perimeter': _roundValue(2 * (length + width), 3),
      'length': length,
      'width': width,
    };
  }
  final area = (inputs['area'] ?? _defaultFor(spec, 'area', 20)).clamp(1.0, 300.0);
  return {
    'inputMode': 1.0,
    'area': _roundValue(area, 3),
    'perimeter': _roundValue(math.sqrt(area) * 4, 3),
    'length': 0.0,
    'width': 0.0,
  };
}

Map<String, double> _keyFactors(WarmFloorPipesCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(WarmFloorPipesCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalWarmFloorPipes(
  Map<String, double> inputs, {
  WarmFloorPipesCanonicalSpec spec = warmFloorPipesCanonicalSpecV1,
}) {
  final areaInfo = _resolveArea(spec, inputs);
  final area = areaInfo['area']!;
  final perimeter = areaInfo['perimeter']!;

  final pipeStep = (inputs['pipeStep'] ?? _defaultFor(spec, 'pipeStep', 200)).clamp(100.0, 300.0);
  final pipeType = (inputs['pipeType'] ?? _defaultFor(spec, 'pipeType', 0)).round().clamp(0, 3);

  /* ─── core formulas ─── */
  final usefulArea = _roundValue(area * spec.materialRules.furnitureReduction, 3);
  final pipeStepM = pipeStep / 1000;
  final pipeLength = _roundValue(usefulArea / pipeStepM + spec.materialRules.collectorAdditionM, 3);
  final circuits = math.max(1, (pipeLength / spec.materialRules.maxCircuitM).ceil());
  final totalPipe = _roundValue(pipeLength * spec.materialRules.pipeReserve, 3);
  final coils = (totalPipe / spec.materialRules.pipeCoilM).ceil();

  /* ─── ancillary materials ─── */
  final eppsSheets = (area * spec.materialRules.eppsReserve / spec.materialRules.eppsSheetM2).ceil();
  final damperTapeRolls = (perimeter * spec.materialRules.damperReserve / spec.materialRules.damperTapeRollM).ceil();
  final anchorTotal = (totalPipe / spec.materialRules.anchorStepM * spec.materialRules.anchorReserve).ceil();
  final anchorPacks = (anchorTotal / spec.materialRules.anchorPack).ceil();
  final screedBags = (area * spec.materialRules.screedThicknessM * spec.materialRules.screedDensity / spec.materialRules.screedBagKg).ceil();

  /* ─── scenarios ─── */
  final basePrimary = totalPipe;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packageSize = spec.materialRules.pipeCoilM;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'pipe-coil-${packageSize.toInt()}m';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'pipeType:$pipeType',
        'pipeStep:${pipeStep.toInt()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ─── materials list ─── */
  final pipeTypeLabel = _pipeTypeLabels[pipeType] ?? 'PEX-a';
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Труба $pipeTypeLabel (бухты ${spec.materialRules.pipeCoilM.toInt()} м)',
      quantity: _roundValue(totalPipe, 3),
      unit: 'м',
      withReserve: (coils * spec.materialRules.pipeCoilM),
      purchaseQty: coils,
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Утеплитель ЭППС (листы 1200×600)',
      quantity: eppsSheets.toDouble(),
      unit: 'листов',
      withReserve: eppsSheets.toDouble(),
      purchaseQty: eppsSheets,
      category: 'Утепление',
    ),
    CanonicalMaterialResult(
      name: 'Демпферная лента (рулоны)',
      quantity: damperTapeRolls.toDouble(),
      unit: 'рулонов',
      withReserve: damperTapeRolls.toDouble(),
      purchaseQty: damperTapeRolls,
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Якорные клипсы (упаковки по 100 шт)',
      quantity: anchorTotal.toDouble(),
      unit: 'шт',
      withReserve: (anchorPacks * spec.materialRules.anchorPack).toDouble(),
      purchaseQty: anchorPacks,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Коллектор ($circuits контуров)',
      quantity: 1,
      unit: 'шт',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Управление',
    ),
    CanonicalMaterialResult(
      name: 'Стяжка полусухая (мешки 25 кг)',
      quantity: _roundValue(area * spec.materialRules.screedThicknessM * spec.materialRules.screedDensity, 3),
      unit: 'кг',
      withReserve: (screedBags * spec.materialRules.screedBagKg),
      purchaseQty: screedBags,
      category: 'Основное',
    ),
  ];

  /* ─── warnings ─── */
  final warnings = <String>[];
  if (pipeLength > spec.warningRules.multipleCircuitsPipeThresholdM) {
    warnings.add('Длина трубы более 80 м — рекомендуется несколько контуров');
  }
  if (area > spec.warningRules.professionalHeatLossAreaThresholdM2) {
    warnings.add('Площадь более 40 м² — рекомендуется профессиональный расчёт теплопотерь');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'inputMode': areaInfo['inputMode']!,
      'area': area,
      'perimeter': perimeter,
      'length': areaInfo['length']!,
      'width': areaInfo['width']!,
      'pipeStep': pipeStep,
      'pipeType': pipeType.toDouble(),
      'usefulArea': usefulArea,
      'pipeStepM': _roundValue(pipeStepM, 4),
      'pipeLength': _roundValue(pipeLength, 3),
      'circuits': circuits.toDouble(),
      'totalPipe': totalPipe,
      'coils': coils.toDouble(),
      'eppsSheets': eppsSheets.toDouble(),
      'damperTapeRolls': damperTapeRolls.toDouble(),
      'anchorTotal': anchorTotal.toDouble(),
      'anchorPacks': anchorPacks.toDouble(),
      'screedBags': screedBags.toDouble(),
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
