import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

// ─── Balcony spec classes ───

// ─── Factor table ───

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
};

const Map<int, String> _finishLabels = {
  0: 'Вагонка',
  1: 'ПВХ-панели',
  2: 'Имитация бруса',
  3: 'МДФ-панели',
};

const Map<int, String> _insulationLabels = {
  0: 'Без утепления',
  1: 'ПСБ (пенопласт)',
  2: 'Пенофол',
  3: 'ПСБ + пенофол',
};

// ─── Helpers ───

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalBalcony(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(balconySpecData);

  final length = (inputs['length'] ?? defaultFor(spec, 'length', 3)).clamp(1, 10).toDouble();
  final width = (inputs['width'] ?? defaultFor(spec, 'width', 1.2)).clamp(0.6, 3).toDouble();
  final height = (inputs['height'] ?? defaultFor(spec, 'height', 2.5)).clamp(2, 3).toDouble();
  final finishType = (inputs['finishType'] ?? defaultFor(spec, 'finishType', 0)).round().clamp(0, 3);
  final insulationType = (inputs['insulationType'] ?? defaultFor(spec, 'insulationType', 0)).round().clamp(0, 3);

  final panelArea = (spec.materialRule<Map>('panel_areas')['$finishType'] as num?)?.toDouble() ?? 0.288;
  final floorArea = roundValue(length * width, 6);
  final wallArea = roundValue((2 * width + 2 * length) * height, 6);
  final ceilingArea = roundValue(length * width, 6);
  final totalFinishArea = roundValue(wallArea + ceilingArea, 6);

  final insPlates = insulationType > 0
      ? (totalFinishArea * spec.materialRule<num>('insulation_reserve').toDouble() / spec.materialRule<num>('insulation_plate').toDouble()).ceil()
      : 0;
  final panelCount = (totalFinishArea * spec.materialRule<num>('finish_reserve').toDouble() / panelArea).ceil();
  final battenRows = (totalFinishArea / spec.materialRule<num>('batten_pitch').toDouble()).ceil();
  final klaymerCount = (panelCount * spec.materialRule<num>('klaymer_per_panel').toDouble() * spec.materialRule<num>('klaymer_reserve').toDouble()).ceil();

  // Scenarios
  final baseExactNeed = panelCount;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseExactNeed * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel = 'balcony-panel-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'finish:$finishType',
        'insulation:$insulationType',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
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

  // Warnings
  final warnings = <String>[];
  if (floorArea > spec.warningRule<num>('large_balcony_area_threshold_m2').toDouble()) {
    warnings.add('Большая площадь балкона — рекомендуется профессиональный расчёт нагрузки на плиту');
  }
  if (insulationType == spec.warningRule<num>('uninsulated_warning_threshold').toDouble()) {
    warnings.add('Без утепления — на балконе будет значительный перепад температур');
  }

  // Materials
  final finishLabel = _finishLabels[finishType] ?? 'Вагонка';
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: finishLabel,
      quantity: panelCount.toDouble(),
      unit: 'шт',
      withReserve: panelCount.toDouble(),
      purchaseQty: panelCount.toDouble(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Обрешётка (брусок 20×40)',
      quantity: battenRows.toDouble(),
      unit: 'шт',
      withReserve: battenRows.toDouble(),
      purchaseQty: battenRows.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Кляймеры',
      quantity: klaymerCount.toDouble(),
      unit: 'шт',
      withReserve: klaymerCount.toDouble(),
      purchaseQty: klaymerCount.toDouble(),
      category: 'Крепёж',
    ),
  ];

  if (insulationType > 0) {
    final insulationLabel = _insulationLabels[insulationType] ?? 'Утеплитель';
    materials.add(CanonicalMaterialResult(
      name: insulationLabel,
      quantity: insPlates.toDouble(),
      unit: 'шт',
      withReserve: insPlates.toDouble(),
      purchaseQty: insPlates.toDouble(),
      category: 'Утепление',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': roundValue(length, 3),
      'width': roundValue(width, 3),
      'height': roundValue(height, 3),
      'finishType': finishType.toDouble(),
      'insulationType': insulationType.toDouble(),
      'floorArea': roundValue(floorArea, 3),
      'wallArea': roundValue(wallArea, 3),
      'ceilingArea': roundValue(ceilingArea, 3),
      'totalFinishArea': roundValue(totalFinishArea, 3),
      'panelArea': roundValue(panelArea, 6),
      'panelCount': panelCount.toDouble(),
      'insPlates': insPlates.toDouble(),
      'battenRows': battenRows.toDouble(),
      'klaymerCount': klaymerCount.toDouble(),
      'minExactNeedPanels': scenarios['MIN']!.exactNeed,
      'recExactNeedPanels': recScenario.exactNeed,
      'maxExactNeedPanels': scenarios['MAX']!.exactNeed,
      'minPurchasePanels': scenarios['MIN']!.purchaseQuantity,
      'recPurchasePanels': recScenario.purchaseQuantity,
      'maxPurchasePanels': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
