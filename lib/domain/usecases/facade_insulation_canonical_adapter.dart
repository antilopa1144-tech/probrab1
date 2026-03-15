import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class FacadeInsulationPackagingRules {
  final String unit;
  final double packageSize;

  const FacadeInsulationPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class FacadeInsulationMaterialRules {
  final double plateM2;
  final double plateReserve;
  final Map<int, double> glueKgPerM2;
  final double glueBag;
  final Map<int, double> dowelsPerM2;
  final double dowelReserve;
  final double meshReserve;
  final double meshRoll;
  final double armorKgPerM2;
  final double armorBag;
  final double primerLPerM2;
  final double primerCanL;
  final double primerReserve;
  final Map<int, double> decorConsumption;
  final double decorBag;
  final double starterLength;
  final double starterReserve;

  const FacadeInsulationMaterialRules({
    required this.plateM2,
    required this.plateReserve,
    required this.glueKgPerM2,
    required this.glueBag,
    required this.dowelsPerM2,
    required this.dowelReserve,
    required this.meshReserve,
    required this.meshRoll,
    required this.armorKgPerM2,
    required this.armorBag,
    required this.primerLPerM2,
    required this.primerCanL,
    required this.primerReserve,
    required this.decorConsumption,
    required this.decorBag,
    required this.starterLength,
    required this.starterReserve,
  });
}

class FacadeInsulationWarningRules {
  final double thickInsulationThresholdMm;
  final bool eppsAdhesionWarning;

  const FacadeInsulationWarningRules({
    required this.thickInsulationThresholdMm,
    required this.eppsAdhesionWarning,
  });
}

class FacadeInsulationCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final FacadeInsulationPackagingRules packagingRules;
  final FacadeInsulationMaterialRules materialRules;
  final FacadeInsulationWarningRules warningRules;

  const FacadeInsulationCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const FacadeInsulationCanonicalSpec facadeInsulationCanonicalSpecV1 = FacadeInsulationCanonicalSpec(
  calculatorId: 'facade-insulation',
  formulaVersion: 'facade-insulation-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm\u00b2', defaultValue: 100, min: 10, max: 2000),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 100, min: 50, max: 200),
    CanonicalInputField(key: 'insulationType', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'finishType', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: FacadeInsulationPackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: FacadeInsulationMaterialRules(
    plateM2: 0.72,
    plateReserve: 1.05,
    glueKgPerM2: {0: 4, 1: 5},
    glueBag: 25,
    dowelsPerM2: {0: 6, 1: 4},
    dowelReserve: 1.05,
    meshReserve: 1.15,
    meshRoll: 50,
    armorKgPerM2: 4,
    armorBag: 25,
    primerLPerM2: 0.25,
    primerCanL: 10,
    primerReserve: 1.1,
    decorConsumption: {0: 3.5, 1: 4.5, 2: 2.5},
    decorBag: 25,
    starterLength: 2,
    starterReserve: 1.05,
  ),
  warningRules: FacadeInsulationWarningRules(
    thickInsulationThresholdMm: 150,
    eppsAdhesionWarning: true,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
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

double _defaultFor(FacadeInsulationCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(FacadeInsulationCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(FacadeInsulationCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalFacadeInsulation(
  Map<String, double> inputs, {
  FacadeInsulationCanonicalSpec spec = facadeInsulationCanonicalSpecV1,
}) {
  final area = math.max(10.0, math.min(2000.0, inputs['area'] ?? _defaultFor(spec, 'area', 100)));
  final thickness = math.max(50.0, math.min(200.0, (inputs['thickness'] ?? _defaultFor(spec, 'thickness', 100)).roundToDouble()));
  final insulationType = (inputs['insulationType'] ?? _defaultFor(spec, 'insulationType', 0)).round().clamp(0, 1);
  final finishType = (inputs['finishType'] ?? _defaultFor(spec, 'finishType', 0)).round().clamp(0, 2);

  // Plates
  final plates = (area * spec.materialRules.plateReserve / spec.materialRules.plateM2).ceil();

  // Glue
  final glueRate = spec.materialRules.glueKgPerM2[insulationType] ?? spec.materialRules.glueKgPerM2[0]!;
  final glueBags = (area * glueRate / spec.materialRules.glueBag).ceil();

  // Dowels
  final dowelsPerM2 = spec.materialRules.dowelsPerM2[insulationType] ?? spec.materialRules.dowelsPerM2[0]!;
  final dowels = (area * dowelsPerM2 * spec.materialRules.dowelReserve).ceil();

  // Mesh
  final meshRolls = (area * spec.materialRules.meshReserve / spec.materialRules.meshRoll).ceil();

  // Armor
  final armorBags = (area * spec.materialRules.armorKgPerM2 / spec.materialRules.armorBag).ceil();

  // Primer
  final primerCans = (area * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / spec.materialRules.primerCanL).ceil();

  // Decorative finish
  final decorConsumption = spec.materialRules.decorConsumption[finishType] ?? spec.materialRules.decorConsumption[0]!;
  final decorBags = (area * decorConsumption / spec.materialRules.decorBag).ceil();

  // Starter profile
  final starterPcs = (math.sqrt(area) * 4 * spec.materialRules.starterReserve / spec.materialRules.starterLength).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(plates * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    const packageLabel = 'insulation-plate';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'insulationType:$insulationType',
        'finishType:$finishType',
        'thickness:${thickness.toInt()}',
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

  final insulationLabel = insulationType == 0 ? 'Минеральная вата' : 'ЭППС';
  final finishLabels = <int, String>{
    0: 'Декоративная штукатурка \u00abкороед\u00bb',
    1: 'Декоративная штукатурка \u00abшуба\u00bb',
    2: 'Тонкослойная штукатурка',
  };

  final warnings = <String>[];
  if (thickness >= spec.warningRules.thickInsulationThresholdMm) {
    warnings.add('Толстый утеплитель — рекомендуется двухслойная укладка');
  }
  if (insulationType == 1 && finishType != 2) {
    warnings.add('ЭППС — обязательна обработка поверхности для адгезии штукатурки');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '$insulationLabel (плиты ${spec.materialRules.plateM2} м\u00b2)',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Утепление',
    ),
    CanonicalMaterialResult(
      name: 'Клей для утеплителя 25кг',
      quantity: glueBags.toDouble(),
      unit: 'мешков',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags,
      category: 'Клей',
    ),
    CanonicalMaterialResult(
      name: 'Тарельчатые дюбели',
      quantity: dowels.toDouble(),
      unit: 'шт',
      withReserve: dowels.toDouble(),
      purchaseQty: dowels,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Армирующая сетка (${spec.materialRules.meshRoll.toInt()} м\u00b2)',
      quantity: meshRolls.toDouble(),
      unit: 'рулонов',
      withReserve: meshRolls.toDouble(),
      purchaseQty: meshRolls,
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Армирующая шпаклёвка 25кг',
      quantity: armorBags.toDouble(),
      unit: 'мешков',
      withReserve: armorBags.toDouble(),
      purchaseQty: armorBags,
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра ${spec.materialRules.primerCanL.toInt()} л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: '${finishLabels[finishType]} 25кг',
      quantity: decorBags.toDouble(),
      unit: 'мешков',
      withReserve: decorBags.toDouble(),
      purchaseQty: decorBags,
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Стартовый профиль (${spec.materialRules.starterLength.toInt()} м)',
      quantity: starterPcs.toDouble(),
      unit: 'шт',
      withReserve: starterPcs.toDouble(),
      purchaseQty: starterPcs,
      category: 'Профиль',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
      'thickness': thickness,
      'insulationType': insulationType.toDouble(),
      'finishType': finishType.toDouble(),
      'plates': plates.toDouble(),
      'glueBags': glueBags.toDouble(),
      'dowels': dowels.toDouble(),
      'meshRolls': meshRolls.toDouble(),
      'armorBags': armorBags.toDouble(),
      'primerCans': primerCans.toDouble(),
      'decorBags': decorBags.toDouble(),
      'starterPcs': starterPcs.toDouble(),
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
