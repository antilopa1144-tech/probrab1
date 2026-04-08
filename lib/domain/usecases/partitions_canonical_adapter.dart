import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


CanonicalCalculatorContractResult calculateCanonicalPartitions(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(partitionsSpecData);

  final length = math.max(1.0, math.min(50.0, inputs['length'] ?? defaultFor(spec, 'length', 5)));
  final height = math.max(2.0, math.min(4.0, inputs['height'] ?? defaultFor(spec, 'height', 2.7)));
  final thickness = math.max(75.0, math.min(200.0, (inputs['thickness'] ?? defaultFor(spec, 'thickness', 100)).roundToDouble()));
  final blockType = (inputs['blockType'] ?? defaultFor(spec, 'blockType', 0)).round().clamp(0, 2);

  // Wall area
  final wallArea = length * height;

  // Block dimensions
  final dimsMap = spec.materialRule<Map>('block_dims')['$blockType'] as Map? ?? spec.materialRule<Map>('block_dims')['0'] as Map? ?? {'lengthMm': 625, 'heightMm': 250};
  final blockArea = (((dimsMap['lengthMm'] as num?)?.toDouble() ?? 625) / 1000) * (((dimsMap['heightMm'] as num?)?.toDouble() ?? 250) / 1000);
  final blocks = (wallArea / blockArea * spec.materialRule<num>('block_reserve').toDouble()).ceil();

  // Glue / gypsum
  final glueRate = (spec.materialRule<Map>('glue_rate')['$blockType'] as num?)?.toDouble() ?? 0;
  final glueBags = blockType != 2
      ? (wallArea * glueRate / spec.materialRule<num>('glue_bag').toDouble()).ceil()
      : 0;
  final gypsumBags = blockType == 2
      ? (wallArea * spec.materialRule<num>('gypsum_milk_rate').toDouble() / spec.materialRule<num>('gypsum_bag').toDouble()).ceil()
      : 0;

  // Reinforcing mesh
  final armRows = (height / spec.materialRule<num>('mesh_interval').toDouble()).ceil();
  final meshLen = length * armRows * spec.materialRule<num>('mesh_reserve').toDouble();
  final meshRolls = (meshLen / spec.materialRule<num>('mesh_roll').toDouble()).ceil();

  // Foam
  final foamBottles = ((length + height * 2) / spec.materialRule<num>('foam_per_perim').toDouble()).ceil();

  // Primer (both sides)
  final primer = (wallArea * 2 * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can').toDouble()).ceil();

  // Sealing tape
  final sealTape = ((length * 2 + height * 2) * spec.materialRule<num>('seal_tape_reserve').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(blocks * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    const packageLabel = 'partition-block';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'blockType:$blockType',
        'thickness:${thickness.toInt()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (height > spec.warningRule<num>('high_wall_threshold_m').toDouble()) {
    warnings.add('Высота перегородки более 3.5 м — рекомендуется усиленное армирование');
  }
  if (blockType == 2 && thickness > 100) {
    warnings.add('Гипсовые ПГП толще 100 мм — проверьте наличие нужного размера');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Блоки перегородочные',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Основное',
    ),
  ];

  if (glueBags > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Клей для блоков 25кг',
      quantity: glueBags.toDouble(),
      unit: 'мешков',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags.toDouble(),
      category: 'Кладка',
    ));
  }

  if (gypsumBags > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Гипсовое молочко 20кг',
      quantity: gypsumBags.toDouble(),
      unit: 'мешков',
      withReserve: gypsumBags.toDouble(),
      purchaseQty: gypsumBags.toDouble(),
      category: 'Кладка',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Армирующая сетка (рулон ${spec.materialRule<num>('mesh_roll').toInt()} м)',
      quantity: meshRolls.toDouble(),
      unit: 'рулонов',
      withReserve: meshRolls.toDouble(),
      purchaseQty: meshRolls.toDouble(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Монтажная пена 750мл',
      quantity: foamBottles.toDouble(),
      unit: 'шт',
      withReserve: foamBottles.toDouble(),
      purchaseQty: foamBottles.toDouble(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра ${spec.materialRule<num>('primer_can').toInt()} л)',
      quantity: primer.toDouble(),
      unit: 'канистр',
      withReserve: primer.toDouble(),
      purchaseQty: primer.toDouble(),
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Уплотнительная лента',
      quantity: sealTape.toDouble(),
      unit: 'м',
      withReserve: sealTape.toDouble(),
      purchaseQty: sealTape.toDouble(),
      category: 'Монтаж',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': roundValue(length, 3),
      'height': roundValue(height, 3),
      'thickness': thickness,
      'blockType': blockType.toDouble(),
      'wallArea': roundValue(wallArea, 3),
      'blockArea': roundValue(blockArea, 6),
      'blocks': blocks.toDouble(),
      'glueBags': glueBags.toDouble(),
      'gypsumBags': gypsumBags.toDouble(),
      'armRows': armRows.toDouble(),
      'meshLen': roundValue(meshLen, 3),
      'meshRolls': meshRolls.toDouble(),
      'foamBottles': foamBottles.toDouble(),
      'primer': primer.toDouble(),
      'sealTape': sealTape.toDouble(),
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
