import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
// ─── Foundation Slab spec classes ───

// ─── Factor table ───

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
};

// ─── Helpers ───

Map<String, dynamic> _pickPackage(
  double exactNeed,
  double stepSize,
  String unit,
) {
  final count = exactNeed > 0 ? (exactNeed / stepSize).ceil() : 0;
  final purchase = roundValue(count * stepSize, 6);
  final leftover = roundValue(purchase - exactNeed, 6);
  return {
    'size': stepSize,
    'count': count,
    'purchase': purchase,
    'leftover': leftover,
    'label': 'foundation-slab-$stepSize$unit',
  };
}

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalFoundationSlab(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(foundationSlabSpecData);

  final areaInput = math
      .max(10, inputs['area'] ?? defaultFor(spec, 'area', 60))
      .toDouble()
      .clamp(10, 500)
      .toDouble();
  final thickness = (inputs['thickness'] ?? defaultFor(spec, 'thickness', 200))
      .clamp(150, 300)
      .toDouble();
  final rebarDiam = (inputs['rebarDiam'] ?? defaultFor(spec, 'rebarDiam', 12))
      .round()
      .clamp(10, 16);
  final rebarStep = (inputs['rebarStep'] ?? defaultFor(spec, 'rebarStep', 200))
      .clamp(150, 250)
      .toDouble();
  final sandLayerMm =
      (inputs['sandLayerMm'] ?? defaultFor(spec, 'sandLayerMm', 100))
          .clamp(0, 500)
          .toDouble();
  final gravelLayerMm =
      (inputs['gravelLayerMm'] ?? defaultFor(spec, 'gravelLayerMm', 150))
          .clamp(0, 500)
          .toDouble();
  final insulationThickness =
      (inputs['insulationThickness'] ??
              defaultFor(spec, 'insulationThickness', 0))
          .clamp(0, 150)
          .toDouble();

  final weightPerMeter =
      (spec.materialRule<Map>('weight_per_meter')['$rebarDiam'] as num?)
          ?.toDouble() ??
      0.888;
  final lengthInput = (inputs['length'] ?? 0).clamp(0, 50).toDouble();
  final widthInput = (inputs['width'] ?? 0).clamp(0, 50).toDouble();
  final useRect = lengthInput > 0 && widthInput > 0;
  final length = useRect ? lengthInput : math.sqrt(areaInput);
  final width = useRect ? widthInput : math.sqrt(areaInput);
  final area = useRect ? roundValue(length * width, 6) : areaInput;
  final side = math.sqrt(area);
  final perimeter = useRect ? 2 * (length + width) : side * 4;
  final concreteM3 = roundValue(area * (thickness / 1000), 6);
  final stepM = rebarStep / 1000;
  final barsAlongLength = (width / stepM).ceil() + 1;
  final barsAlongWidth = (length / stepM).ceil() + 1;
  final barsPerDir = barsAlongLength;
  final totalBarLen = (barsAlongLength * length + barsAlongWidth * width) * 2;
  final rebarKg = roundValue(totalBarLen * weightPerMeter, 6);
  final wireKg = roundValue(
    barsAlongLength *
        barsAlongWidth *
        2 *
        spec.materialRule<num>('wire_length_per_joint_m').toDouble() *
        spec.materialRule<num>('wire_mass_per_meter_kg').toDouble(),
    6,
  );
  final formworkArea = roundValue(
    perimeter *
        (thickness / 1000) *
        spec.materialRule<num>('formwork_reserve').toDouble(),
    6,
  );
  final geotextile = roundValue(
    area * spec.materialRule<num>('geotextile_reserve').toDouble(),
    6,
  );
  final gravel = roundValue(area * (gravelLayerMm / 1000), 6);
  final sand = roundValue(area * (sandLayerMm / 1000), 6);
  final eppsPlates = insulationThickness > 0
      ? (area *
                spec.materialRule<num>('insulation_reserve').toDouble() /
                spec.materialRule<num>('epps_plate_m2').toDouble())
            .ceil()
      : 0;

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      _factorTable,
      scenarioName,
    );
    final exactNeed = roundValue(concreteM3 * multiplier, 6);
    final package = _pickPackage(
      exactNeed,
      spec.packagingRule<num>('volume_step_m3').toDouble(),
      spec.packagingRule<String>('unit'),
    );

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'rebarDiam:$rebarDiam',
        'rebarStep:${rebarStep.toInt()}',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: package['label'] as String,
        packageSize: package['size'] as double,
        packagesCount: package['count'] as int,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (thickness <= spec.warningRule<num>('thin_slab_threshold_mm').toDouble()) {
    warnings.add(
      'Толщина плиты должна быть подтверждена расчётом конструктора по нагрузкам и основанию',
    );
  }
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add(
      'Большая площадь плиты — рекомендуется профессиональный расчёт нагрузок',
    );
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Товарный бетон — класс по проекту',
      quantity: roundValue(concreteM3, 3),
      unit: 'м³',
      withReserve: roundValue(concreteM3, 3),
      purchaseQty: ((concreteM3 * 10).ceil() / 10).toDouble(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Арматура рифлёная ∅$rebarDiam мм для двух сеток',
      quantity: roundValue(rebarKg, 3),
      unit: 'кг',
      withReserve: rebarKg.ceil().toDouble(),
      purchaseQty: rebarKg.ceil().toDouble(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Проволока вязальная отожжённая ∅1,2 мм',
      quantity: roundValue(wireKg, 3),
      unit: 'кг',
      withReserve: wireKg.ceil().toDouble(),
      purchaseQty: wireKg.ceil().toDouble(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Опалубка — материал для щитов',
      quantity: roundValue(formworkArea, 3),
      unit: 'м²',
      withReserve: formworkArea.ceil().toDouble(),
      purchaseQty: formworkArea.ceil().toDouble(),
      category: 'Опалубка',
    ),
    CanonicalMaterialResult(
      name: 'Геотекстиль нетканый иглопробивной, 200–300 г/м²',
      quantity: roundValue(geotextile, 3),
      unit: 'м²',
      withReserve: geotextile.ceil().toDouble(),
      purchaseQty: geotextile.ceil().toDouble(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Щебень для подушки, фракция 20–40 мм',
      quantity: roundValue(gravel, 3),
      unit: 'м³',
      withReserve: roundValue(gravel, 3),
      purchaseQty: gravel.ceil().toDouble(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Песок для подушки, средней или крупной фракции',
      quantity: roundValue(sand, 3),
      unit: 'м³',
      withReserve: roundValue(sand, 3),
      purchaseQty: sand.ceil().toDouble(),
      category: 'Подготовка',
    ),
  ];

  if (insulationThickness > 0) {
    materials.add(
      CanonicalMaterialResult(
        name:
            'Экструдированный пенополистирол (ЭППС) для фундамента 1200×600×$insulationThickness мм',
        quantity: eppsPlates.toDouble(),
        unit: 'шт',
        withReserve: eppsPlates.toDouble(),
        purchaseQty: eppsPlates.toDouble(),
        category: 'Утепление',
      ),
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'length': roundValue(length, 3),
      'width': roundValue(width, 3),
      'thickness': roundValue(thickness, 3),
      'rebarDiam': rebarDiam.toDouble(),
      'rebarStep': roundValue(rebarStep, 3),
      'sandLayerMm': roundValue(sandLayerMm, 3),
      'gravelLayerMm': roundValue(gravelLayerMm, 3),
      'insulationThickness': roundValue(insulationThickness, 3),
      'side': roundValue(side, 3),
      'perimeter': roundValue(perimeter, 3),
      'concreteM3': roundValue(concreteM3, 3),
      'barsPerDir': barsPerDir.toDouble(),
      'barsAlongLength': barsAlongLength.toDouble(),
      'barsAlongWidth': barsAlongWidth.toDouble(),
      'totalBarLen': roundValue(totalBarLen, 3),
      'rebarKg': roundValue(rebarKg, 3),
      'wireKg': roundValue(wireKg, 3),
      'formworkArea': roundValue(formworkArea, 3),
      'geotextile': roundValue(geotextile, 3),
      'gravel': roundValue(gravel, 3),
      'sand': roundValue(sand, 3),
      'eppsPlates': eppsPlates.toDouble(),
      'minExactNeedM3': scenarios['MIN']!.exactNeed,
      'recExactNeedM3': recScenario.exactNeed,
      'maxExactNeedM3': scenarios['MAX']!.exactNeed,
      'minPurchaseM3': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseM3': recScenario.purchaseQuantity,
      'maxPurchaseM3': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
