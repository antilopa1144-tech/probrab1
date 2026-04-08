import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */




bool hasCanonicalBlindAreaInputs(Map<String, double> inputs) {
  return inputs.containsKey('perimeter') ||
      inputs.containsKey('materialType') ||
      inputs.containsKey('withInsulation');
}

Map<String, double> normalizeLegacyBlindAreaInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['perimeter'] = (inputs['perimeter'] ?? 40).toDouble();
  normalized['width'] = (inputs['width'] ?? 1.0).toDouble();
  normalized['thickness'] = (inputs['thickness'] ?? 100).toDouble();
  normalized['materialType'] = (inputs['materialType'] ?? 0).toDouble();
  normalized['withInsulation'] = (inputs['withInsulation'] ?? 0).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalBlindArea(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(blindAreaSpecData);

  final normalized = hasCanonicalBlindAreaInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyBlindAreaInputs(inputs);

  final perimeter = math.max(10.0, math.min(200.0, (normalized['perimeter'] ?? defaultFor(spec, 'perimeter', 40)).toDouble()));
  final width = math.max(0.6, math.min(1.5, (normalized['width'] ?? defaultFor(spec, 'width', 1.0)).toDouble()));
  final thickness = math.max(70.0, math.min(150.0, (normalized['thickness'] ?? defaultFor(spec, 'thickness', 100)).toDouble()));
  final materialType = (normalized['materialType'] ?? defaultFor(spec, 'materialType', 0)).round().clamp(0, 2);
  final withInsulation = math.max(0.0, math.min(100.0, (normalized['withInsulation'] ?? defaultFor(spec, 'withInsulation', 0)).toDouble()));

  // Base geometry
  final area = perimeter * width;

  // Type-specific
  var concreteM3 = 0.0;
  var meshPcs = 0;
  var damperM = 0.0;
  var tileM2 = 0;
  var mixBags = 0;
  var borderPcs = 0;
  var membraneM2 = 0;
  var decorGravelM3 = 0.0;

  if (materialType == 0) {
    // Concrete
    concreteM3 = (area * (thickness / 1000.0) * spec.materialRule<num>('concrete_reserve').toDouble() * 10).ceil() / 10.0;
    meshPcs = thickness >= 100 ? (area * spec.materialRule<num>('mesh_reserve').toDouble()).ceil() : 0;
    damperM = roundValue(perimeter * spec.materialRule<num>('damper_reserve').toDouble(), 2);
  } else if (materialType == 1) {
    // Tile
    tileM2 = (area * spec.materialRule<num>('tile_reserve').toDouble()).ceil();
    mixBags = (area * spec.materialRule<num>('tile_mix_kg_per_m2').toDouble() / 50).ceil();
    borderPcs = (perimeter / spec.materialRule<num>('border_length').toDouble()).ceil();
  } else {
    // Soft membrane
    membraneM2 = (area * spec.materialRule<num>('membrane_reserve').toDouble()).ceil();
    decorGravelM3 = roundValue(area * 0.1, 3);
  }

  // Common layers
  final gravel = roundValue(area * spec.materialRule<num>('gravel_layer').toDouble(), 3);
  final sand = roundValue(area * spec.materialRule<num>('sand_layer').toDouble(), 3);
  final geotextileRolls = (area * 1.15 / spec.materialRule<num>('geotextile_roll').toDouble()).ceil();
  final eppsPlates = withInsulation > 0 ? (area * spec.materialRule<num>('epps_reserve').toDouble() / spec.materialRule<num>('epps_plate').toDouble()).ceil() : 0;

  // Scenarios
  final basePrimary = materialType == 0 ? concreteM3 : materialType == 1 ? tileM2.toDouble() : membraneM2.toDouble();
  final packageLabel = materialType == 0
      ? 'concrete-m3'
      : materialType == 1
          ? 'tile-m2'
          : 'membrane-m2';
  final packageUnit = materialType == 0 ? 'м³' : 'м²';

  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'materialType:$materialType',
        'thickness:${thickness.round()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
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

  // Warnings
  final warnings = <String>[];
  if (width < spec.warningRule<num>('narrow_width_threshold_m').toDouble()) {
    warnings.add('Ширина отмостки менее 0.8 м — может не обеспечить достаточной защиты фундамента');
  }
  if (materialType == 0 && thickness < spec.warningRule<num>('thin_concrete_threshold_mm').toDouble()) {
    warnings.add('Толщина бетона менее 100 мм — рекомендуется армосетка при увеличении толщины');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[];

  if (materialType == 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Бетон (${thickness.round()} мм)',
      quantity: recScenario.exactNeed,
      unit: 'м³',
      withReserve: concreteM3,
      purchaseQty: concreteM3.ceilToDouble(),
      category: 'Бетон',
      packageInfo: {'count': concreteM3.ceil(), 'unitSize': 1.0, 'packageUnit': 'доставок'},
    ));
    if (meshPcs > 0) {
      materials.add(CanonicalMaterialResult(
        name: 'Армосетка',
        quantity: meshPcs.toDouble(),
        unit: 'шт',
        withReserve: meshPcs.toDouble(),
        purchaseQty: meshPcs.toDouble(),
        category: 'Армирование',
      ));
    }
    materials.add(CanonicalMaterialResult(
      name: 'Демпферная лента',
      quantity: damperM,
      unit: 'м',
      withReserve: damperM,
      purchaseQty: damperM.ceil().toDouble(),
      category: 'Расходные',
    ));
  } else if (materialType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Тротуарная плитка',
        quantity: recScenario.exactNeed,
        unit: 'м²',
        withReserve: tileM2.toDouble(),
        purchaseQty: tileM2.toDouble(),
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Смесь для укладки (50 кг)',
        quantity: mixBags.toDouble(),
        unit: 'мешков',
        withReserve: mixBags.toDouble(),
        purchaseQty: mixBags.toDouble(),
        category: 'Смеси',
      ),
      CanonicalMaterialResult(
        name: 'Бордюр (0.5 м)',
        quantity: borderPcs.toDouble(),
        unit: 'шт',
        withReserve: borderPcs.toDouble(),
        purchaseQty: borderPcs.toDouble(),
        category: 'Покрытие',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Профилированная мембрана',
        quantity: recScenario.exactNeed,
        unit: 'м²',
        withReserve: membraneM2.toDouble(),
        purchaseQty: membraneM2.toDouble(),
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Декоративный щебень',
        quantity: decorGravelM3,
        unit: 'м³',
        withReserve: decorGravelM3,
        purchaseQty: (decorGravelM3 * 10).ceil().toDouble(),
        category: 'Покрытие',
      ),
    ]);
  }

  // Common materials
  materials.addAll([
    CanonicalMaterialResult(
      name: 'Щебень (подушка)',
      quantity: gravel,
      unit: 'м³',
      withReserve: gravel,
      purchaseQty: (gravel * 10).ceil().toDouble(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Песок (подушка)',
      quantity: sand,
      unit: 'м³',
      withReserve: sand,
      purchaseQty: (sand * 10).ceil().toDouble(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Геотекстиль (${spec.materialRule<num>('geotextile_roll').toDouble().round()} м²)',
      quantity: geotextileRolls.toDouble(),
      unit: 'рулонов',
      withReserve: geotextileRolls.toDouble(),
      purchaseQty: geotextileRolls.toDouble(),
      category: 'Подготовка',
    ),
  ]);

  if (eppsPlates > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'ЭППС утеплитель (${withInsulation.round()} мм)',
      quantity: eppsPlates.toDouble(),
      unit: 'шт',
      withReserve: eppsPlates.toDouble(),
      purchaseQty: eppsPlates.toDouble(),
      category: 'Утепление',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'perimeter': roundValue(perimeter, 3),
      'width': roundValue(width, 3),
      'area': roundValue(area, 3),
      'thickness': thickness,
      'materialType': materialType.toDouble(),
      'withInsulation': withInsulation,
      'concreteM3': concreteM3,
      'meshPcs': meshPcs.toDouble(),
      'damperM': damperM,
      'tileM2': tileM2.toDouble(),
      'mixBags': mixBags.toDouble(),
      'borderPcs': borderPcs.toDouble(),
      'membraneM2': membraneM2.toDouble(),
      'decorGravelM3': decorGravelM3,
      'gravel': gravel,
      'sand': sand,
      'geotextileRolls': geotextileRolls.toDouble(),
      'eppsPlates': eppsPlates.toDouble(),
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
