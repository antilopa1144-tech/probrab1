import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

double _allowedValue(double value, List<dynamic> allowed, double fallback) {
  return allowed.map((item) => (item as num).toDouble()).contains(value)
      ? value
      : fallback;
}

double _roundUpToStep(double value, double step) {
  if (value <= 0) return 0;
  return roundValue((value / step).ceil() * step, 6);
}

Map<String, dynamic> _pickPackage(
  double exactNeed,
  double stepSize,
  String unit,
) {
  final count = exactNeed > 0 ? (exactNeed / stepSize).ceil() : 0;
  final purchase = roundValue(count * stepSize, 6);
  return {
    'size': stepSize,
    'count': count,
    'purchase': purchase,
    'leftover': roundValue(purchase - exactNeed, 6),
    'label': 'foundation-slab-$stepSize$unit',
  };
}

CanonicalCalculatorContractResult calculateCanonicalFoundationSlab(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(foundationSlabSpecData);

  final length = (inputs['length'] ?? defaultFor(spec, 'length', 10))
      .clamp(1, 50)
      .toDouble();
  final width = (inputs['width'] ?? defaultFor(spec, 'width', 6))
      .clamp(1, 50)
      .toDouble();
  final thickness = (inputs['thickness'] ?? defaultFor(spec, 'thickness', 200))
      .clamp(100, 500)
      .toDouble();
  final concreteReservePercent =
      (inputs['concreteReservePercent'] ??
              defaultFor(spec, 'concreteReservePercent', 5))
          .clamp(0, 20)
          .toDouble();
  final readyMixOrderStepM3 = _allowedValue(
    inputs['readyMixOrderStepM3'] ??
        defaultFor(spec, 'readyMixOrderStepM3', 0.1),
    spec.packagingRule<List>('allowed_ready_mix_order_steps_m3'),
    0.1,
  );
  final deliveryAllowanceM3 =
      (inputs['deliveryAllowanceM3'] ??
              defaultFor(spec, 'deliveryAllowanceM3', 0))
          .clamp(0, 5)
          .toDouble();
  final gridLayers = (inputs['gridLayers'] ?? defaultFor(spec, 'gridLayers', 2))
      .round()
      .clamp(1, 2);
  final rebarDiam = _allowedValue(
    (inputs['rebarDiam'] ?? defaultFor(spec, 'rebarDiam', 12)).roundToDouble(),
    spec.materialRule<List>('allowed_rebar_diameters_mm'),
    12,
  ).round();
  final rebarStep = (inputs['rebarStep'] ?? defaultFor(spec, 'rebarStep', 200))
      .clamp(100, 500)
      .toDouble();
  final edgeCoverMm =
      (inputs['edgeCoverMm'] ?? defaultFor(spec, 'edgeCoverMm', 50))
          .clamp(0, 150)
          .toDouble();
  final rebarReservePercent =
      (inputs['rebarReservePercent'] ??
              defaultFor(spec, 'rebarReservePercent', 10))
          .clamp(0, 30)
          .toDouble();
  final rodLengthM = _allowedValue(
    inputs['rodLengthM'] ?? defaultFor(spec, 'rodLengthM', 11.7),
    spec.packagingRule<List>('allowed_rod_lengths_m'),
    11.7,
  );
  final tieSharePercent =
      (inputs['tieSharePercent'] ?? defaultFor(spec, 'tieSharePercent', 100))
          .clamp(0, 100)
          .toDouble();
  final wireLengthPerTieM =
      (inputs['wireLengthPerTieM'] ??
              defaultFor(spec, 'wireLengthPerTieM', 0.3))
          .clamp(0.1, 1)
          .toDouble();
  final wireReservePercent =
      (inputs['wireReservePercent'] ??
              defaultFor(spec, 'wireReservePercent', 10))
          .clamp(0, 50)
          .toDouble();
  final wirePackageKg = _allowedValue(
    inputs['wirePackageKg'] ?? defaultFor(spec, 'wirePackageKg', 1),
    spec.packagingRule<List>('allowed_wire_packages_kg'),
    1,
  );
  final formworkHeightMm =
      (inputs['formworkHeightMm'] ?? defaultFor(spec, 'formworkHeightMm', 200))
          .clamp(0, 1000)
          .toDouble();
  final formworkReservePercent =
      (inputs['formworkReservePercent'] ??
              defaultFor(spec, 'formworkReservePercent', 10))
          .clamp(0, 30)
          .toDouble();
  final sandLayerMm =
      (inputs['sandLayerMm'] ?? defaultFor(spec, 'sandLayerMm', 100))
          .clamp(0, 500)
          .toDouble();
  final sandOrderExtraPercent =
      (inputs['sandOrderExtraPercent'] ??
              defaultFor(spec, 'sandOrderExtraPercent', 0))
          .clamp(0, 50)
          .toDouble();
  final gravelLayerMm =
      (inputs['gravelLayerMm'] ?? defaultFor(spec, 'gravelLayerMm', 150))
          .clamp(0, 500)
          .toDouble();
  final gravelOrderExtraPercent =
      (inputs['gravelOrderExtraPercent'] ??
              defaultFor(spec, 'gravelOrderExtraPercent', 0))
          .clamp(0, 50)
          .toDouble();
  final aggregateOrderStepM3 = _allowedValue(
    inputs['aggregateOrderStepM3'] ??
        defaultFor(spec, 'aggregateOrderStepM3', 0.1),
    spec.packagingRule<List>('allowed_aggregate_order_steps_m3'),
    0.1,
  );
  final includeGeotextile =
      (inputs['includeGeotextile'] ?? defaultFor(spec, 'includeGeotextile', 1))
          .round() ==
      1;
  final geotextileReservePercent =
      (inputs['geotextileReservePercent'] ??
              defaultFor(spec, 'geotextileReservePercent', 20))
          .clamp(0, 50)
          .toDouble();
  final geotextileRollAreaM2 =
      (inputs['geotextileRollAreaM2'] ??
              defaultFor(spec, 'geotextileRollAreaM2', 50))
          .clamp(10, 500)
          .toDouble();
  final insulationThickness =
      (inputs['insulationThickness'] ??
              defaultFor(spec, 'insulationThickness', 0))
          .clamp(0, 200)
          .toDouble();
  final insulationReservePercent =
      (inputs['insulationReservePercent'] ??
              defaultFor(spec, 'insulationReservePercent', 5))
          .clamp(0, 30)
          .toDouble();
  final eppsBoardAreaM2 =
      (inputs['eppsBoardAreaM2'] ?? defaultFor(spec, 'eppsBoardAreaM2', 0.72))
          .clamp(0.2, 3)
          .toDouble();

  final area = roundValue(length * width, 6);
  final perimeter = roundValue(2 * (length + width), 6);
  final concreteExactM3 = roundValue(area * thickness / 1000, 6);
  final maxReserveFloor =
      ((spec.raw['scenario_policy']
                      as Map<String, dynamic>?)?['max_reserve_floor_percent']
                  as num? ??
              10)
          .toDouble();
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final reservePercent = switch (scenarioName) {
      'MIN' => 0.0,
      'MAX' =>
        concreteReservePercent > maxReserveFloor
            ? concreteReservePercent
            : maxReserveFloor,
      _ => concreteReservePercent,
    };
    final exactNeed = roundValue(
      concreteExactM3 * (1 + reservePercent / 100) + deliveryAllowanceM3,
      6,
    );
    final package = _pickPackage(
      exactNeed,
      readyMixOrderStepM3,
      spec.packagingRule<String>('unit'),
    );
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'reserve_percent:$reservePercent',
        'delivery_allowance_m3:$deliveryAllowanceM3',
        'grid_layers:$gridLayers',
        'rebar_diameter_mm:$rebarDiam',
        'rebar_step_mm:$rebarStep',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        'reserve_percent': reservePercent,
        'field_multiplier': roundValue(1 + reservePercent / 100, 6),
        'ready_mix_order_step_m3': readyMixOrderStepM3,
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: package['label'] as String,
        packageSize: package['size'] as double,
        packagesCount: package['count'] as int,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final clearLengthM = (length - 2 * edgeCoverMm / 1000)
      .clamp(0, 50)
      .toDouble();
  final clearWidthM = (width - 2 * edgeCoverMm / 1000).clamp(0, 50).toDouble();
  final rebarStepM = rebarStep / 1000;
  final barsAlongLength = (clearWidthM / rebarStepM).ceil() + 1;
  final barsAlongWidth = (clearLengthM / rebarStepM).ceil() + 1;
  final exactRebarLengthM = roundValue(
    gridLayers *
        (barsAlongLength * clearLengthM + barsAlongWidth * clearWidthM),
    6,
  );
  final planningRebarLengthM = roundValue(
    exactRebarLengthM * (1 + rebarReservePercent / 100),
    6,
  );
  final rebarRods = (planningRebarLengthM / rodLengthM).ceil();
  final purchaseRebarLengthM = roundValue(rebarRods * rodLengthM, 6);
  final weightPerMeter =
      (spec.materialRule<Map>('weight_per_meter')['$rebarDiam'] as num?)
          ?.toDouble() ??
      0.888;
  final exactRebarWeightKg = roundValue(exactRebarLengthM * weightPerMeter, 6);
  final planningRebarWeightKg = roundValue(
    planningRebarLengthM * weightPerMeter,
    6,
  );
  final purchaseRebarWeightKg = roundValue(
    purchaseRebarLengthM * weightPerMeter,
    6,
  );

  final intersections = barsAlongLength * barsAlongWidth * gridLayers;
  final tieCount = (intersections * tieSharePercent / 100).ceil();
  final wireExactLengthM = roundValue(tieCount * wireLengthPerTieM, 6);
  final wireExactKg = roundValue(
    wireExactLengthM *
        spec.materialRule<num>('wire_mass_per_meter_kg').toDouble(),
    6,
  );
  final wirePlanningKg = roundValue(
    wireExactKg * (1 + wireReservePercent / 100),
    6,
  );
  final wirePackages = wirePlanningKg > 0
      ? (wirePlanningKg / wirePackageKg).ceil()
      : 0;
  final wirePurchaseKg = roundValue(wirePackages * wirePackageKg, 6);

  final formworkExactM2 = roundValue(perimeter * formworkHeightMm / 1000, 6);
  final formworkPlanningM2 = roundValue(
    formworkExactM2 * (1 + formworkReservePercent / 100),
    6,
  );
  final geotextileExactM2 = includeGeotextile ? area : 0.0;
  final geotextilePlanningM2 = roundValue(
    geotextileExactM2 * (1 + geotextileReservePercent / 100),
    6,
  );
  final geotextileRolls = geotextilePlanningM2 > 0
      ? (geotextilePlanningM2 / geotextileRollAreaM2).ceil()
      : 0;
  final geotextilePurchaseM2 = roundValue(
    geotextileRolls * geotextileRollAreaM2,
    6,
  );

  final sandExactM3 = roundValue(area * sandLayerMm / 1000, 6);
  final sandPlanningM3 = roundValue(
    sandExactM3 * (1 + sandOrderExtraPercent / 100),
    6,
  );
  final sandPurchaseM3 = _roundUpToStep(sandPlanningM3, aggregateOrderStepM3);
  final gravelExactM3 = roundValue(area * gravelLayerMm / 1000, 6);
  final gravelPlanningM3 = roundValue(
    gravelExactM3 * (1 + gravelOrderExtraPercent / 100),
    6,
  );
  final gravelPurchaseM3 = _roundUpToStep(
    gravelPlanningM3,
    aggregateOrderStepM3,
  );

  final eppsExactM2 = insulationThickness > 0 ? area : 0.0;
  final eppsPlanningM2 = roundValue(
    eppsExactM2 * (1 + insulationReservePercent / 100),
    6,
  );
  final eppsBoards = eppsPlanningM2 > 0
      ? (eppsPlanningM2 / eppsBoardAreaM2).ceil()
      : 0;
  final eppsPurchaseM2 = roundValue(eppsBoards * eppsBoardAreaM2, 6);
  final recScenario = scenarios['REC']!;

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Товарный бетон — класс по проекту',
      quantity: roundValue(concreteExactM3, 3),
      unit: 'м³',
      withReserve: roundValue(recScenario.exactNeed, 3),
      purchaseQty: roundValue(recScenario.purchaseQuantity, 3),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Арматура сеток ∅$rebarDiam мм — класс по проекту',
      quantity: roundValue(exactRebarLengthM, 3),
      unit: 'пог. м',
      withReserve: roundValue(planningRebarLengthM, 3),
      purchaseQty: roundValue(purchaseRebarLengthM, 3),
      packageInfo: {
        'count': rebarRods,
        'size': rodLengthM,
        'packageUnit': 'прутков',
      },
      category: 'Армирование',
    ),
  ];

  if (wireExactKg > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Проволока вязальная отожжённая ∅1,2 мм',
        quantity: roundValue(wireExactKg, 3),
        unit: 'кг',
        withReserve: roundValue(wirePlanningKg, 3),
        purchaseQty: roundValue(wirePurchaseKg, 3),
        packageInfo: {
          'count': wirePackages,
          'size': wirePackageKg,
          'packageUnit': 'упаковок',
        },
        category: 'Армирование',
      ),
    );
  }
  if (formworkExactM2 > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Опалубка — площадь щитов к подготовке',
        quantity: roundValue(formworkExactM2, 3),
        unit: 'м²',
        withReserve: roundValue(formworkPlanningM2, 3),
        purchaseQty: roundValue(formworkPlanningM2, 3),
        category: 'Опалубка',
      ),
    );
  }
  if (geotextileExactM2 > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Геотекстиль — тип и плотность по проекту',
        quantity: roundValue(geotextileExactM2, 3),
        unit: 'м²',
        withReserve: roundValue(geotextilePlanningM2, 3),
        purchaseQty: roundValue(geotextilePurchaseM2, 3),
        packageInfo: {
          'count': geotextileRolls,
          'size': geotextileRollAreaM2,
          'packageUnit': 'рулонов',
        },
        category: 'Подготовка',
      ),
    );
  }
  if (gravelExactM3 > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Щебень для проектного слоя подготовки',
        quantity: roundValue(gravelExactM3, 3),
        unit: 'м³',
        withReserve: roundValue(gravelPlanningM3, 3),
        purchaseQty: roundValue(gravelPurchaseM3, 3),
        category: 'Подготовка',
      ),
    );
  }
  if (sandExactM3 > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Песок для проектного слоя подготовки',
        quantity: roundValue(sandExactM3, 3),
        unit: 'м³',
        withReserve: roundValue(sandPlanningM3, 3),
        purchaseQty: roundValue(sandPurchaseM3, 3),
        category: 'Подготовка',
      ),
    );
  }
  if (insulationThickness > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'ЭППС под плитой $insulationThickness мм — марка по проекту',
        quantity: roundValue(eppsExactM2, 3),
        unit: 'м²',
        withReserve: roundValue(eppsPlanningM2, 3),
        purchaseQty: roundValue(eppsPurchaseM2, 3),
        packageInfo: {
          'count': eppsBoards,
          'size': eppsBoardAreaM2,
          'packageUnit': 'плит',
        },
        category: 'Утепление',
      ),
    );
  }

  final warnings = <String>[
    'Калькулятор считает материалы по готовым размерам и проектной схеме. Он не выбирает тип фундамента, толщину плиты, бетон, армирование или состав подготовки.',
  ];
  if (thickness <= spec.warningRule<num>('thin_slab_threshold_mm').toDouble()) {
    warnings.add(
      'Введена небольшая толщина плиты. Её допустимость подтверждает конструктор по нагрузкам, грунтам и расчётной схеме.',
    );
  }
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add(
      'Большая площадь плиты: проверьте проектные швы, непрерывность бетонирования, подачу смеси и рабочую документацию.',
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
      'perimeter': roundValue(perimeter, 3),
      'thickness': roundValue(thickness, 3),
      'concreteM3': roundValue(concreteExactM3, 3),
      'concreteReservePercent': roundValue(concreteReservePercent, 3),
      'readyMixOrderStepM3': readyMixOrderStepM3,
      'deliveryAllowanceM3': roundValue(deliveryAllowanceM3, 3),
      'gridLayers': gridLayers.toDouble(),
      'rebarDiam': rebarDiam.toDouble(),
      'rebarStep': roundValue(rebarStep, 3),
      'edgeCoverMm': roundValue(edgeCoverMm, 3),
      'barsAlongLength': barsAlongLength.toDouble(),
      'barsAlongWidth': barsAlongWidth.toDouble(),
      'intersections': intersections.toDouble(),
      'tieCount': tieCount.toDouble(),
      'rebarReservePercent': roundValue(rebarReservePercent, 3),
      'rodLengthM': rodLengthM,
      'totalBarLen': roundValue(exactRebarLengthM, 3),
      'rebarPlanningLengthM': roundValue(planningRebarLengthM, 3),
      'rebarPurchaseLengthM': roundValue(purchaseRebarLengthM, 3),
      'rebarRods': rebarRods.toDouble(),
      'rebarKg': roundValue(exactRebarWeightKg, 3),
      'rebarPlanningKg': roundValue(planningRebarWeightKg, 3),
      'rebarPurchaseKg': roundValue(purchaseRebarWeightKg, 3),
      'tieSharePercent': roundValue(tieSharePercent, 3),
      'wireLengthPerTieM': roundValue(wireLengthPerTieM, 3),
      'wireExactLengthM': roundValue(wireExactLengthM, 3),
      'wireKg': roundValue(wireExactKg, 3),
      'wirePlanningKg': roundValue(wirePlanningKg, 3),
      'wirePurchaseKg': roundValue(wirePurchaseKg, 3),
      'wirePackages': wirePackages.toDouble(),
      'wirePackageKg': wirePackageKg,
      'formworkHeightMm': roundValue(formworkHeightMm, 3),
      'formworkArea': roundValue(formworkExactM2, 3),
      'formworkPlanningArea': roundValue(formworkPlanningM2, 3),
      'formworkReservePercent': roundValue(formworkReservePercent, 3),
      'includeGeotextile': includeGeotextile ? 1 : 0,
      'geotextile': roundValue(geotextileExactM2, 3),
      'geotextilePlanningM2': roundValue(geotextilePlanningM2, 3),
      'geotextilePurchaseM2': roundValue(geotextilePurchaseM2, 3),
      'geotextileRolls': geotextileRolls.toDouble(),
      'geotextileReservePercent': roundValue(geotextileReservePercent, 3),
      'geotextileRollAreaM2': roundValue(geotextileRollAreaM2, 3),
      'sandLayerMm': roundValue(sandLayerMm, 3),
      'sand': roundValue(sandExactM3, 3),
      'sandPlanningM3': roundValue(sandPlanningM3, 3),
      'sandPurchaseM3': roundValue(sandPurchaseM3, 3),
      'sandOrderExtraPercent': roundValue(sandOrderExtraPercent, 3),
      'gravelLayerMm': roundValue(gravelLayerMm, 3),
      'gravel': roundValue(gravelExactM3, 3),
      'gravelPlanningM3': roundValue(gravelPlanningM3, 3),
      'gravelPurchaseM3': roundValue(gravelPurchaseM3, 3),
      'gravelOrderExtraPercent': roundValue(gravelOrderExtraPercent, 3),
      'aggregateOrderStepM3': aggregateOrderStepM3,
      'insulationThickness': roundValue(insulationThickness, 3),
      'insulationReservePercent': roundValue(insulationReservePercent, 3),
      'eppsBoardAreaM2': roundValue(eppsBoardAreaM2, 3),
      'eppsPlates': eppsBoards.toDouble(),
      'eppsPurchaseM2': roundValue(eppsPurchaseM2, 3),
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
