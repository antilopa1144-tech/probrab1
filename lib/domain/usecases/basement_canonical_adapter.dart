import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */


const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const Map<int, String> _waterproofLabels = {
  0: 'Обмазочная (мастика)',
  1: 'Рулонная (наплавляемая)',
  2: 'Проникающая',
};


bool hasCanonicalBasementInputs(Map<String, double> inputs) {
  return inputs.containsKey('depth') ||
      inputs.containsKey('wallThickness') ||
      inputs.containsKey('waterproofType');
}

Map<String, double> normalizeLegacyBasementInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['length'] = (inputs['length'] ?? 8).toDouble();
  normalized['width'] = (inputs['width'] ?? 6).toDouble();
  normalized['depth'] = (inputs['depth'] ?? 2.5).toDouble();
  normalized['wallThickness'] = (inputs['wallThickness'] ?? 200).toDouble();
  normalized['floorThickness'] = (inputs['floorThickness'] ?? 150).toDouble();
  normalized['waterproofType'] = (inputs['waterproofType'] ?? 0).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalBasement(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(basementSpecData);

  final normalized = hasCanonicalBasementInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyBasementInputs(inputs);

  final length = math.max(3.0, math.min(30.0, (normalized['length'] ?? defaultFor(spec, 'length', 8)).toDouble()));
  final width = math.max(3.0, math.min(20.0, (normalized['width'] ?? defaultFor(spec, 'width', 6)).toDouble()));
  final depth = math.max(1.5, math.min(4.0, (normalized['depth'] ?? defaultFor(spec, 'depth', 2.5)).toDouble()));
  final wallThickness = math.max(150.0, math.min(300.0, (normalized['wallThickness'] ?? defaultFor(spec, 'wallThickness', 200)).toDouble()));
  final floorThickness = math.max(100.0, math.min(200.0, (normalized['floorThickness'] ?? defaultFor(spec, 'floorThickness', 150)).toDouble()));
  final waterproofType = (normalized['waterproofType'] ?? defaultFor(spec, 'waterproofType', 0)).round().clamp(0, 2);

  // Geometry
  final floorArea = length * width;
  final wallPerim = 2.0 * (length + width);
  final wallArea = wallPerim * depth;
  final floorVol = floorArea * (floorThickness / 1000.0);
  final wallVol = wallArea * (wallThickness / 1000.0);

  // Concrete
  final floorConcrete = (floorVol * 1.05 * 10).ceil() / 10.0;
  final wallConcrete = (wallVol * 1.03 * 10).ceil() / 10.0;

  // Rebar
  final floorRebar = roundValue(floorArea * spec.materialRule<num>('floor_rebar_kg_per_m2').toDouble(), 2);
  final wallRebar = roundValue(wallArea * spec.materialRule<num>('wall_rebar_kg_per_m2').toDouble(), 2);
  final wire = ((floorRebar + wallRebar) * spec.materialRule<num>('wire_ratio').toDouble()).ceil();

  // Formwork
  final formwork = (wallArea * 2 * spec.materialRule<num>('formwork_reserve').toDouble() / spec.materialRule<num>('formwork_sheet_m2').toDouble()).ceil();

  // Ventilation
  final ventCount = math.max(spec.materialRule<num>('min_vents').toDouble(), (floorArea / spec.materialRule<num>('vent_per_area').toDouble()).ceil());

  // Waterproofing
  final totalWpArea = wallArea + floorArea;
  var masticKg = 0.0;
  var rollCount = 0;
  var penKg = 0.0;

  if (waterproofType == 0) {
    masticKg = roundValue(totalWpArea * spec.materialRule<num>('mastic_layers').toDouble() * spec.materialRule<num>('mastic_kg_per_m2').toDouble(), 2);
  } else if (waterproofType == 1) {
    final rollArea = totalWpArea * spec.materialRule<num>('roll_reserve').toDouble();
    rollCount = (rollArea / spec.materialRule<num>('roll_m2').toDouble() * 2).ceil();
  } else {
    penKg = roundValue(totalWpArea * spec.materialRule<num>('pen_kg_per_m2').toDouble() * spec.materialRule<num>('pen_reserve').toDouble(), 2);
  }

  // Scenarios
  final totalConcrete = roundValue(floorConcrete + wallConcrete, 3);
  final basePrimary = totalConcrete;
  const packageLabel = 'concrete-m3';
  const packageUnit = 'м³';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'waterproofType:$waterproofType',
        'wallThickness:${wallThickness.round()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
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
  if (depth > spec.warningRule<num>('deep_basement_threshold_m').toDouble()) {
    warnings.add('Глубина подвала более 3 м — требуется проект и расчёт несущей способности');
  }
  if (wallThickness < spec.warningRule<num>('thin_wall_threshold_mm').toDouble()) {
    warnings.add('Толщина стен менее 200 мм — допустима только для неглубоких погребов');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Бетон на пол (${floorThickness.round()} мм)',
      quantity: floorConcrete,
      unit: 'м³',
      withReserve: floorConcrete,
      purchaseQty: (floorConcrete * 10).ceil(),
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Бетон на стены (${wallThickness.round()} мм)',
      quantity: wallConcrete,
      unit: 'м³',
      withReserve: wallConcrete,
      purchaseQty: (wallConcrete * 10).ceil(),
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Арматура на пол',
      quantity: floorRebar,
      unit: 'кг',
      withReserve: floorRebar,
      purchaseQty: floorRebar.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Арматура на стены',
      quantity: wallRebar,
      unit: 'кг',
      withReserve: wallRebar,
      purchaseQty: wallRebar.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Вязальная проволока',
      quantity: wire.toDouble(),
      unit: 'кг',
      withReserve: wire.toDouble(),
      purchaseQty: wire.toInt(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Опалубка (${spec.materialRule<num>('formwork_sheet_m2').toDouble()} м²/лист)',
      quantity: formwork.toDouble(),
      unit: 'листов',
      withReserve: formwork.toDouble(),
      purchaseQty: formwork.toInt(),
      category: 'Опалубка',
    ),
    CanonicalMaterialResult(
      name: 'Продухи (вент. отверстия)',
      quantity: ventCount.toDouble(),
      unit: 'шт',
      withReserve: ventCount.toDouble(),
      purchaseQty: ventCount.toInt(),
      category: 'Вентиляция',
    ),
  ];

  // Waterproofing materials
  if (waterproofType == 0) {
    materials.add(CanonicalMaterialResult(
      name: '${_waterproofLabels[0]}',
      quantity: masticKg,
      unit: 'кг',
      withReserve: masticKg,
      purchaseQty: masticKg.ceil(),
      category: 'Гидроизоляция',
    ));
  } else if (waterproofType == 1) {
    materials.add(CanonicalMaterialResult(
      name: '${_waterproofLabels[1]} (${spec.materialRule<num>('roll_m2').toDouble().round()} м²/рулон)',
      quantity: rollCount.toDouble(),
      unit: 'рулонов',
      withReserve: rollCount.toDouble(),
      purchaseQty: rollCount.toInt(),
      category: 'Гидроизоляция',
    ));
  } else {
    materials.add(CanonicalMaterialResult(
      name: '${_waterproofLabels[2]}',
      quantity: penKg,
      unit: 'кг',
      withReserve: penKg,
      purchaseQty: penKg.ceil(),
      category: 'Гидроизоляция',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': roundValue(length, 3),
      'width': roundValue(width, 3),
      'depth': roundValue(depth, 3),
      'wallThickness': wallThickness,
      'floorThickness': floorThickness,
      'waterproofType': waterproofType.toDouble(),
      'floorArea': roundValue(floorArea, 3),
      'wallPerim': roundValue(wallPerim, 3),
      'wallArea': roundValue(wallArea, 3),
      'floorVol': roundValue(floorVol, 4),
      'wallVol': roundValue(wallVol, 4),
      'floorConcrete': floorConcrete,
      'wallConcrete': wallConcrete,
      'totalConcrete': totalConcrete,
      'floorRebar': floorRebar,
      'wallRebar': wallRebar,
      'wire': wire.toDouble(),
      'formwork': formwork.toDouble(),
      'ventCount': ventCount.toDouble(),
      'masticKg': masticKg,
      'rollCount': rollCount.toDouble(),
      'penKg': penKg,
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
