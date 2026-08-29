import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */

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

double _basementAllowedValue(
  double value,
  List<dynamic> allowed,
  double fallback,
) {
  return allowed.map((item) => (item as num).toDouble()).contains(value)
      ? value
      : fallback;
}

double _basementRoundUpToStep(double value, double step) {
  if (value <= 0) return 0;
  return roundValue((value / step - 1e-9).ceil() * step, 6);
}

bool _basementIncludesWalls(int scope) => scope == 1 || scope == 3;
bool _basementIncludesFloor(int scope) => scope == 2 || scope == 3;

Map<String, double> _normalizeBasementV2Inputs(Map<String, double> inputs) {
  final hasV2Inputs =
      inputs.containsKey('floorLength') ||
      inputs.containsKey('floorConcreteReservePercent') ||
      inputs.containsKey('floorRebarProjectKg') ||
      inputs.containsKey('wallFormworkMode') ||
      inputs.containsKey('waterproofScope') ||
      inputs.containsKey('insulationScope');
  if (hasV2Inputs) return Map<String, double>.from(inputs);

  final normalized = Map<String, double>.from(inputs);
  final length = (inputs['length'] ?? 8).toDouble();
  final width = (inputs['width'] ?? 6).toDouble();
  final wallThickness = (inputs['wallThickness'] ?? 200).toDouble();
  final floorThickness = (inputs['floorThickness'] ?? 150).toDouble();
  normalized
    ..['length'] = length
    ..['width'] = width
    ..['depth'] = (inputs['depth'] ?? 2.5).toDouble()
    ..['wallThickness'] = wallThickness <= 2
        ? wallThickness * 1000
        : wallThickness
    ..['wallOpeningsAreaM2'] = 0
    ..['floorLength'] = length
    ..['floorWidth'] = width
    ..['floorThickness'] = floorThickness <= 2
        ? floorThickness * 1000
        : floorThickness
    ..['floorConcreteReservePercent'] = 5
    ..['wallConcreteReservePercent'] = 5
    ..['readyMixOrderStepM3'] = 0.1
    ..['floorDeliveryAllowanceM3'] = 0
    ..['wallDeliveryAllowanceM3'] = 0
    ..['floorRebarProjectKg'] = 0
    ..['wallRebarProjectKg'] = 0
    ..['rebarReservePercent'] = 0
    ..['rebarOrderStepKg'] = 1
    ..['wallFormworkMode'] = 0
    ..['formworkReservePercent'] = 10
    ..['formworkSheetAreaM2'] = 2.88
    ..['waterproofScope'] = (inputs['needWaterproof'] ?? 0) > 0 ? 3 : 0
    ..['waterproofSystem'] = 1
    ..['waterproofWallHeightM'] = (inputs['depth'] ?? 2.5).toDouble()
    ..['waterproofReservePercent'] = 15
    ..['waterproofConsumptionKgM2'] = 0
    ..['waterproofPackageKg'] = 0
    ..['waterproofLayers'] = 1
    ..['waterproofRollAreaM2'] = 0
    ..['insulationScope'] = (inputs['needInsulation'] ?? 0) > 0 ? 3 : 0
    ..['insulationWallHeightM'] = (inputs['depth'] ?? 2.5).toDouble()
    ..['insulationLayers'] = 1
    ..['insulationReservePercent'] = 5
    ..['insulationBoardAreaM2'] = 0.72;
  return normalized;
}

CanonicalCalculatorContractResult calculateCanonicalBasement(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(basementSpecData);
  final values = _normalizeBasementV2Inputs(inputs);

  double read(String key, double fallback, double min, double max) =>
      (values[key] ?? defaultFor(spec, key, fallback))
          .clamp(min, max)
          .toDouble();

  final length = read('length', 8, 3, 30);
  final width = read('width', 6, 3, 20);
  final depth = read('depth', 2.5, 1.5, 5);
  final wallThickness = read('wallThickness', 200, 100, 1000);
  final wallThicknessM = wallThickness / 1000;
  final requestedOpeningsAreaM2 = read('wallOpeningsAreaM2', 0, 0, 200);
  final floorLength = read('floorLength', 8, 3, 35);
  final floorWidth = read('floorWidth', 6, 3, 25);
  final floorThickness = read('floorThickness', 150, 100, 1000);
  final floorConcreteReservePercent = read(
    'floorConcreteReservePercent',
    5,
    0,
    20,
  );
  final wallConcreteReservePercent = read(
    'wallConcreteReservePercent',
    5,
    0,
    20,
  );
  final readyMixOrderStepM3 = _basementAllowedValue(
    values['readyMixOrderStepM3'] ??
        defaultFor(spec, 'readyMixOrderStepM3', 0.1),
    spec.packagingRule<List>('allowed_ready_mix_order_steps_m3'),
    0.1,
  );
  final floorDeliveryAllowanceM3 = read('floorDeliveryAllowanceM3', 0, 0, 5);
  final wallDeliveryAllowanceM3 = read('wallDeliveryAllowanceM3', 0, 0, 5);
  final floorRebarProjectKg = read('floorRebarProjectKg', 0, 0, 100000);
  final wallRebarProjectKg = read('wallRebarProjectKg', 0, 0, 100000);
  final rebarReservePercent = read('rebarReservePercent', 0, 0, 30);
  final rebarOrderStepKg = _basementAllowedValue(
    values['rebarOrderStepKg'] ?? defaultFor(spec, 'rebarOrderStepKg', 1),
    spec.packagingRule<List>('allowed_rebar_order_steps_kg'),
    1,
  );
  final wallFormworkMode = read('wallFormworkMode', 0, 0, 3).round();
  final formworkReservePercent = read('formworkReservePercent', 10, 0, 30);
  final formworkSheetAreaM2 = read('formworkSheetAreaM2', 2.88, 0.1, 20);
  final waterproofScope = read('waterproofScope', 0, 0, 3).round();
  final waterproofSystem = read('waterproofSystem', 1, 1, 2).round();
  final requestedWaterproofWallHeightM = read(
    'waterproofWallHeightM',
    2.5,
    0,
    5,
  );
  final waterproofWallHeightM = math.min(requestedWaterproofWallHeightM, depth);
  final waterproofReservePercent = read('waterproofReservePercent', 15, 0, 50);
  final waterproofConsumptionKgM2 = read('waterproofConsumptionKgM2', 0, 0, 20);
  final waterproofPackageKg = read('waterproofPackageKg', 0, 0, 200);
  final waterproofLayers = read('waterproofLayers', 1, 1, 5).round();
  final waterproofRollAreaM2 = read('waterproofRollAreaM2', 0, 0, 200);
  final insulationScope = read('insulationScope', 0, 0, 3).round();
  final requestedInsulationWallHeightM = read(
    'insulationWallHeightM',
    2.5,
    0,
    5,
  );
  final insulationWallHeightM = math.min(requestedInsulationWallHeightM, depth);
  final insulationLayers = read('insulationLayers', 1, 1, 5).round();
  final insulationReservePercent = read('insulationReservePercent', 5, 0, 30);
  final insulationBoardAreaM2 = read('insulationBoardAreaM2', 0.72, 0.1, 5);

  final outerPlanArea = length * width;
  final innerLength = math.max(0.0, length - 2 * wallThicknessM);
  final innerWidth = math.max(0.0, width - 2 * wallThicknessM);
  final innerPlanArea = innerLength * innerWidth;
  final outerWallPerimeter = 2 * (length + width);
  final innerWallPerimeter = 2 * (innerLength + innerWidth);
  final grossWallVolume = (outerPlanArea - innerPlanArea) * depth;
  final outerWallAreaGross = outerWallPerimeter * depth;
  final innerWallAreaGross = innerWallPerimeter * depth;
  final maxOpeningsAreaM2 = wallThicknessM > 0
      ? math.min(
          math.min(outerWallAreaGross, innerWallAreaGross),
          grossWallVolume / wallThicknessM,
        )
      : 0.0;
  final wallOpeningsAreaM2 = math.min(
    requestedOpeningsAreaM2,
    maxOpeningsAreaM2,
  );
  final openingsVolume = wallOpeningsAreaM2 * wallThicknessM;
  final wallVolume = math.max(0.0, grossWallVolume - openingsVolume);
  final outerWallArea = math.max(0.0, outerWallAreaGross - wallOpeningsAreaM2);
  final innerWallArea = math.max(0.0, innerWallAreaGross - wallOpeningsAreaM2);
  final floorArea = floorLength * floorWidth;
  final floorVolume = floorArea * floorThickness / 1000;
  final cleanConcreteM3 = floorVolume + wallVolume;

  final maxReserveFloor =
      ((spec.raw['scenario_policy']
                      as Map<String, dynamic>?)?['max_reserve_floor_percent']
                  as num? ??
              10)
          .toDouble();
  final concreteParts = <String, Map<String, double>>{};
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final floorReserve = switch (scenarioName) {
      'MIN' => 0.0,
      'MAX' => math.max(floorConcreteReservePercent, maxReserveFloor),
      _ => floorConcreteReservePercent,
    };
    final wallReserve = switch (scenarioName) {
      'MIN' => 0.0,
      'MAX' => math.max(wallConcreteReservePercent, maxReserveFloor),
      _ => wallConcreteReservePercent,
    };
    final floorNeedM3 =
        floorVolume * (1 + floorReserve / 100) + floorDeliveryAllowanceM3;
    final wallNeedM3 =
        wallVolume * (1 + wallReserve / 100) + wallDeliveryAllowanceM3;
    final floorPurchaseM3 = _basementRoundUpToStep(
      floorNeedM3,
      readyMixOrderStepM3,
    );
    final wallPurchaseM3 = _basementRoundUpToStep(
      wallNeedM3,
      readyMixOrderStepM3,
    );
    final exactNeed = roundValue(floorNeedM3 + wallNeedM3, 6);
    final purchaseQuantity = roundValue(floorPurchaseM3 + wallPurchaseM3, 6);
    concreteParts[scenarioName] = {
      'floorNeedM3': floorNeedM3,
      'wallNeedM3': wallNeedM3,
      'floorPurchaseM3': floorPurchaseM3,
      'wallPurchaseM3': wallPurchaseM3,
    };
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'dimension_reference:outer_wall_contour',
        'concrete_orders:floor_and_walls_separate',
        'floor_reserve_percent:$floorReserve',
        'wall_reserve_percent:$wallReserve',
        'ready_mix_order_step_m3:$readyMixOrderStepM3',
      ],
      keyFactors: {
        'floor_reserve_percent': floorReserve,
        'wall_reserve_percent': wallReserve,
        'field_multiplier': 1,
        'ready_mix_order_step_m3': readyMixOrderStepM3,
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'separate-ready-mix-orders-${readyMixOrderStepM3}m3',
        packageSize: readyMixOrderStepM3,
        packagesCount: (purchaseQuantity / readyMixOrderStepM3).round(),
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recParts = concreteParts['REC']!;
  final floorRebarPlanningKg =
      floorRebarProjectKg * (1 + rebarReservePercent / 100);
  final wallRebarPlanningKg =
      wallRebarProjectKg * (1 + rebarReservePercent / 100);
  final floorRebarPurchaseKg = _basementRoundUpToStep(
    floorRebarPlanningKg,
    rebarOrderStepKg,
  );
  final wallRebarPurchaseKg = _basementRoundUpToStep(
    wallRebarPlanningKg,
    rebarOrderStepKg,
  );
  final formworkExactAreaM2 = switch (wallFormworkMode) {
    1 => outerWallArea,
    2 => innerWallArea,
    3 => outerWallArea + innerWallArea,
    _ => 0.0,
  };
  final formworkPlanningAreaM2 =
      formworkExactAreaM2 * (1 + formworkReservePercent / 100);
  final formworkSheets = formworkExactAreaM2 > 0
      ? (formworkPlanningAreaM2 / formworkSheetAreaM2).ceil()
      : 0;
  final formworkPurchaseAreaM2 = formworkSheets * formworkSheetAreaM2;

  final waterproofWallAreaM2 = _basementIncludesWalls(waterproofScope)
      ? outerWallPerimeter * waterproofWallHeightM
      : 0.0;
  final waterproofFloorAreaM2 = _basementIncludesFloor(waterproofScope)
      ? floorArea
      : 0.0;
  final waterproofBaseAreaM2 = waterproofWallAreaM2 + waterproofFloorAreaM2;
  final waterproofMassExactKg = waterproofSystem == 1
      ? waterproofBaseAreaM2 * waterproofConsumptionKgM2
      : 0.0;
  final waterproofMassPlanningKg =
      waterproofMassExactKg * (1 + waterproofReservePercent / 100);
  final waterproofPackages =
      waterproofScope > 0 &&
          waterproofSystem == 1 &&
          waterproofMassExactKg > 0 &&
          waterproofPackageKg > 0
      ? (waterproofMassPlanningKg / waterproofPackageKg).ceil()
      : 0;
  final waterproofMassPurchaseKg = waterproofPackages * waterproofPackageKg;
  final waterproofRollExactAreaM2 = waterproofSystem == 2
      ? waterproofBaseAreaM2 * waterproofLayers
      : 0.0;
  final waterproofRollPlanningAreaM2 =
      waterproofRollExactAreaM2 * (1 + waterproofReservePercent / 100);
  final waterproofRolls =
      waterproofScope > 0 &&
          waterproofSystem == 2 &&
          waterproofRollExactAreaM2 > 0 &&
          waterproofRollAreaM2 > 0
      ? (waterproofRollPlanningAreaM2 / waterproofRollAreaM2).ceil()
      : 0;
  final waterproofRollPurchaseAreaM2 = waterproofRolls * waterproofRollAreaM2;

  final insulationWallAreaM2 = _basementIncludesWalls(insulationScope)
      ? outerWallPerimeter * insulationWallHeightM
      : 0.0;
  final insulationFloorAreaM2 = _basementIncludesFloor(insulationScope)
      ? floorArea
      : 0.0;
  final insulationBaseAreaM2 = insulationWallAreaM2 + insulationFloorAreaM2;
  final insulationExactAreaM2 = insulationBaseAreaM2 * insulationLayers;
  final insulationPlanningAreaM2 =
      insulationExactAreaM2 * (1 + insulationReservePercent / 100);
  final insulationBoards = insulationExactAreaM2 > 0
      ? (insulationPlanningAreaM2 / insulationBoardAreaM2).ceil()
      : 0;
  final insulationPurchaseAreaM2 = insulationBoards * insulationBoardAreaM2;

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Товарный бетон для плиты пола — класс по проекту',
      quantity: roundValue(floorVolume, 3),
      unit: 'м³',
      withReserve: roundValue(recParts['floorNeedM3']!, 3),
      purchaseQty: roundValue(recParts['floorPurchaseM3']!, 3),
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Товарный бетон для наружных стен — класс по проекту',
      quantity: roundValue(wallVolume, 3),
      unit: 'м³',
      withReserve: roundValue(recParts['wallNeedM3']!, 3),
      purchaseQty: roundValue(recParts['wallPurchaseM3']!, 3),
      category: 'Бетон',
    ),
  ];

  void addMaterial({
    required String name,
    required double quantity,
    required String unit,
    required double withReserve,
    required double purchaseQty,
    required String category,
    Map<String, dynamic>? packageInfo,
  }) {
    materials.add(
      CanonicalMaterialResult(
        name: name,
        quantity: roundValue(quantity, 3),
        unit: unit,
        withReserve: roundValue(withReserve, 3),
        purchaseQty: roundValue(purchaseQty, 3),
        category: category,
        packageInfo: packageInfo,
      ),
    );
  }

  if (floorRebarProjectKg > 0) {
    addMaterial(
      name: 'Арматура плиты пола — масса из проектной ведомости',
      quantity: floorRebarProjectKg,
      unit: 'кг',
      withReserve: floorRebarPlanningKg,
      purchaseQty: floorRebarPurchaseKg,
      category: 'Армирование',
    );
  }
  if (wallRebarProjectKg > 0) {
    addMaterial(
      name: 'Арматура стен — масса из проектной ведомости',
      quantity: wallRebarProjectKg,
      unit: 'кг',
      withReserve: wallRebarPlanningKg,
      purchaseQty: wallRebarPurchaseKg,
      category: 'Армирование',
    );
  }
  if (formworkExactAreaM2 > 0) {
    addMaterial(
      name: 'Щиты или листы опалубки стен',
      quantity: formworkExactAreaM2,
      unit: 'м²',
      withReserve: formworkPlanningAreaM2,
      purchaseQty: formworkPurchaseAreaM2,
      category: 'Опалубка',
      packageInfo: {
        'count': formworkSheets,
        'size': formworkSheetAreaM2,
        'packageUnit': 'листов/щитов',
      },
    );
  }
  if (waterproofScope > 0 && waterproofSystem == 1 && waterproofPackages > 0) {
    addMaterial(
      name: 'Гидроизоляционный состав — выбранная система',
      quantity: waterproofMassExactKg,
      unit: 'кг',
      withReserve: waterproofMassPlanningKg,
      purchaseQty: waterproofMassPurchaseKg,
      category: 'Гидроизоляция',
      packageInfo: {
        'count': waterproofPackages,
        'size': waterproofPackageKg,
        'packageUnit': 'упаковок',
      },
    );
  }
  if (waterproofScope > 0 && waterproofSystem == 2 && waterproofRolls > 0) {
    addMaterial(
      name: 'Рулонная гидроизоляция — выбранная система',
      quantity: waterproofRollExactAreaM2,
      unit: 'м²',
      withReserve: waterproofRollPlanningAreaM2,
      purchaseQty: waterproofRollPurchaseAreaM2,
      category: 'Гидроизоляция',
      packageInfo: {
        'count': waterproofRolls,
        'size': waterproofRollAreaM2,
        'packageUnit': 'рулонов',
      },
    );
  }
  if (insulationExactAreaM2 > 0) {
    addMaterial(
      name: 'Плитный утеплитель — тип и толщина по проекту',
      quantity: insulationExactAreaM2,
      unit: 'м²',
      withReserve: insulationPlanningAreaM2,
      purchaseQty: insulationPurchaseAreaM2,
      category: 'Утепление',
      packageInfo: {
        'count': insulationBoards,
        'size': insulationBoardAreaM2,
        'packageUnit': 'плит',
      },
    );
  }

  final warnings = <String>[
    'Калькулятор не проектирует подвал: тип основания, толщину стен и плиты, класс бетона, армирование, трещиностойкость и защиту от воды назначают по геологии и расчёту',
    'Дренаж, вентиляция, земляные работы, обратная засыпка, швы, вводы и узлы примыкания не рассчитываются — для них нужна отдельная проектная схема',
  ];
  if (floorRebarProjectKg <= 0 && wallRebarProjectKg <= 0) {
    warnings.add(
      'Арматура не добавлена автоматически: перенесите массы из проектной ведомости или рассчитайте стержни по рабочей схеме в отдельном калькуляторе арматуры',
    );
  }
  if (scenarios['REC']!.purchaseQuantity >=
      spec.warningRule<double>('large_order_threshold_m3', 20)) {
    warnings.add(
      'Крупный заказ бетона: подтвердите раздельные графики заливки пола и стен, шаг поставщика, насос, подъезд и остаток смеси в линии подачи',
    );
  }
  if (requestedOpeningsAreaM2 > wallOpeningsAreaM2) {
    warnings.add(
      'Площадь проёмов ограничена доступной геометрией стен; проверьте проектные размеры',
    );
  }
  if (waterproofScope > 0 &&
      waterproofSystem == 1 &&
      (waterproofConsumptionKgM2 <= 0 || waterproofPackageKg <= 0)) {
    warnings.add(
      'Для гидроизоляционного состава заполните расход на весь цикл и массу упаковки',
    );
  }
  if (waterproofScope > 0 &&
      waterproofSystem == 2 &&
      waterproofRollAreaM2 <= 0) {
    warnings.add('Для рулонной гидроизоляции заполните площадь одного рулона');
  }
  if (requestedWaterproofWallHeightM > depth) {
    warnings.add(
      'Высота гидроизоляции ограничена введённой высотой монолитной стены',
    );
  }
  if (requestedInsulationWallHeightM > depth) {
    warnings.add(
      'Высота утепления ограничена введённой высотой монолитной стены',
    );
  }

  final recScenario = scenarios['REC']!;
  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': roundValue(length, 3),
      'width': roundValue(width, 3),
      'depth': roundValue(depth, 3),
      'wallThickness': wallThickness,
      'wallOpeningsAreaM2': roundValue(wallOpeningsAreaM2, 3),
      'requestedOpeningsAreaM2': roundValue(requestedOpeningsAreaM2, 3),
      'floorLength': roundValue(floorLength, 3),
      'floorWidth': roundValue(floorWidth, 3),
      'floorThickness': floorThickness,
      'outerPlanArea': roundValue(outerPlanArea, 3),
      'innerPlanArea': roundValue(innerPlanArea, 3),
      'innerLength': roundValue(innerLength, 3),
      'innerWidth': roundValue(innerWidth, 3),
      'outerWallPerimeter': roundValue(outerWallPerimeter, 3),
      'innerWallPerimeter': roundValue(innerWallPerimeter, 3),
      'outerWallArea': roundValue(outerWallArea, 3),
      'innerWallArea': roundValue(innerWallArea, 3),
      'wallArea': roundValue(outerWallArea, 3),
      'floorArea': roundValue(floorArea, 3),
      'grossWallVolume': roundValue(grossWallVolume, 4),
      'openingsVolume': roundValue(openingsVolume, 4),
      'wallVolume': roundValue(wallVolume, 4),
      'floorVolume': roundValue(floorVolume, 4),
      'cleanConcreteM3': roundValue(cleanConcreteM3, 4),
      'floorConcreteReservePercent': roundValue(floorConcreteReservePercent, 3),
      'wallConcreteReservePercent': roundValue(wallConcreteReservePercent, 3),
      'readyMixOrderStepM3': readyMixOrderStepM3,
      'floorDeliveryAllowanceM3': roundValue(floorDeliveryAllowanceM3, 3),
      'wallDeliveryAllowanceM3': roundValue(wallDeliveryAllowanceM3, 3),
      'floorConcrete': roundValue(recParts['floorPurchaseM3']!, 3),
      'wallConcrete': roundValue(recParts['wallPurchaseM3']!, 3),
      'totalConcrete': roundValue(cleanConcreteM3, 3),
      'concreteVolume': roundValue(recScenario.purchaseQuantity, 3),
      'floorRebarProjectKg': roundValue(floorRebarProjectKg, 3),
      'wallRebarProjectKg': roundValue(wallRebarProjectKg, 3),
      'floorRebarPurchaseKg': roundValue(floorRebarPurchaseKg, 3),
      'wallRebarPurchaseKg': roundValue(wallRebarPurchaseKg, 3),
      'rebarPurchaseKg': roundValue(
        floorRebarPurchaseKg + wallRebarPurchaseKg,
        3,
      ),
      'wallFormworkMode': wallFormworkMode.toDouble(),
      'formworkExactAreaM2': roundValue(formworkExactAreaM2, 3),
      'formworkPlanningAreaM2': roundValue(formworkPlanningAreaM2, 3),
      'formworkSheets': formworkSheets.toDouble(),
      'formworkPurchaseAreaM2': roundValue(formworkPurchaseAreaM2, 3),
      'waterproofScope': waterproofScope.toDouble(),
      'waterproofSystem': waterproofSystem.toDouble(),
      'waterproofArea': roundValue(waterproofBaseAreaM2, 3),
      'waterproofWallAreaM2': roundValue(waterproofWallAreaM2, 3),
      'waterproofFloorAreaM2': roundValue(waterproofFloorAreaM2, 3),
      'waterproofPackages': waterproofPackages.toDouble(),
      'waterproofRolls': waterproofRolls.toDouble(),
      'insulationScope': insulationScope.toDouble(),
      'insulationArea': roundValue(insulationExactAreaM2, 3),
      'insulationBoards': insulationBoards.toDouble(),
      'insulationPurchaseAreaM2': roundValue(insulationPurchaseAreaM2, 3),
      'drainageLength': 0,
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

// Retained only for reading historical v1 tests while the public route below
// uses the audited v2 contract.
// ignore: unused_element
CanonicalCalculatorContractResult _calculateCanonicalBasementV1(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(basementSpecData);

  final normalized = hasCanonicalBasementInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyBasementInputs(inputs);

  final length = math.max(
    3.0,
    math.min(
      30.0,
      (normalized['length'] ?? defaultFor(spec, 'length', 8)).toDouble(),
    ),
  );
  final width = math.max(
    3.0,
    math.min(
      20.0,
      (normalized['width'] ?? defaultFor(spec, 'width', 6)).toDouble(),
    ),
  );
  final depth = math.max(
    1.5,
    math.min(
      4.0,
      (normalized['depth'] ?? defaultFor(spec, 'depth', 2.5)).toDouble(),
    ),
  );
  final wallThickness = math.max(
    150.0,
    math.min(
      300.0,
      (normalized['wallThickness'] ?? defaultFor(spec, 'wallThickness', 200))
          .toDouble(),
    ),
  );
  final floorThickness = math.max(
    100.0,
    math.min(
      200.0,
      (normalized['floorThickness'] ?? defaultFor(spec, 'floorThickness', 150))
          .toDouble(),
    ),
  );
  final waterproofType =
      (normalized['waterproofType'] ?? defaultFor(spec, 'waterproofType', 0))
          .round()
          .clamp(0, 2);

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
  final floorRebar = roundValue(
    floorArea * spec.materialRule<num>('floor_rebar_kg_per_m2').toDouble(),
    2,
  );
  final wallRebar = roundValue(
    wallArea * spec.materialRule<num>('wall_rebar_kg_per_m2').toDouble(),
    2,
  );
  final wire =
      ((floorRebar + wallRebar) *
              spec.materialRule<num>('wire_ratio').toDouble())
          .ceil();

  // Formwork
  final formwork =
      (wallArea *
              2 *
              spec.materialRule<num>('formwork_reserve').toDouble() /
              spec.materialRule<num>('formwork_sheet_m2').toDouble())
          .ceil();

  // Ventilation
  final ventCount = math.max(
    spec.materialRule<num>('min_vents').toDouble(),
    (floorArea / spec.materialRule<num>('vent_per_area').toDouble()).ceil(),
  );

  // Waterproofing
  final totalWpArea = wallArea + floorArea;
  var masticKg = 0.0;
  var rollCount = 0;
  var penKg = 0.0;

  if (waterproofType == 0) {
    masticKg = roundValue(
      totalWpArea *
          spec.materialRule<num>('mastic_layers').toDouble() *
          spec.materialRule<num>('mastic_kg_per_m2').toDouble(),
      2,
    );
  } else if (waterproofType == 1) {
    final rollArea =
        totalWpArea * spec.materialRule<num>('roll_reserve').toDouble();
    rollCount = (rollArea / spec.materialRule<num>('roll_m2').toDouble() * 2)
        .ceil();
  } else {
    penKg = roundValue(
      totalWpArea *
          spec.materialRule<num>('pen_kg_per_m2').toDouble() *
          spec.materialRule<num>('pen_reserve').toDouble(),
      2,
    );
  }

  // Scenarios
  final totalConcrete = roundValue(floorConcrete + wallConcrete, 3);
  final basePrimary = totalConcrete;
  const packageLabel = 'concrete-m3';
  const packageUnit = 'м³';

  final scenarios = <String, CanonicalScenarioResult>{};
  final accuracyMode = parseAccuracyMode(inputs);
  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(basePrimary * accuracyMult * multiplier, 6);
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
        ...buildKeyFactors(
          spec.enabledFactors,
          defaultFactorTable,
          scenarioName,
        ),
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
    warnings.add(
      'Глубина подвала более 3 м — требуется проект и расчёт несущей способности',
    );
  }
  if (wallThickness <
      spec.warningRule<num>('thin_wall_threshold_mm').toDouble()) {
    warnings.add(
      'Толщина стен менее 200 мм — допустима только для неглубоких погребов',
    );
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Бетон на пол (${floorThickness.round()} мм)',
      quantity: floorConcrete,
      unit: 'м³',
      withReserve: floorConcrete,
      purchaseQty: floorConcrete,
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Бетон на стены (${wallThickness.round()} мм)',
      quantity: wallConcrete,
      unit: 'м³',
      withReserve: wallConcrete,
      purchaseQty: wallConcrete,
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Арматура на пол',
      quantity: floorRebar,
      unit: 'кг',
      withReserve: floorRebar,
      purchaseQty: floorRebar.ceil().toDouble(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Арматура на стены',
      quantity: wallRebar,
      unit: 'кг',
      withReserve: wallRebar,
      purchaseQty: wallRebar.ceil().toDouble(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Вязальная проволока',
      quantity: wire.toDouble(),
      unit: 'кг',
      withReserve: wire.toDouble(),
      purchaseQty: wire.toDouble(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name:
          'Опалубка (${spec.materialRule<num>('formwork_sheet_m2').toDouble()} м²/лист)',
      quantity: formwork.toDouble(),
      unit: 'листов',
      withReserve: formwork.toDouble(),
      purchaseQty: formwork.toDouble(),
      category: 'Опалубка',
    ),
    CanonicalMaterialResult(
      name: 'Продухи (вент. отверстия)',
      quantity: ventCount.toDouble(),
      unit: 'шт',
      withReserve: ventCount.toDouble(),
      purchaseQty: ventCount.toDouble(),
      category: 'Вентиляция',
    ),
  ];

  // Waterproofing materials
  if (waterproofType == 0) {
    materials.add(
      CanonicalMaterialResult(
        name: '${_waterproofLabels[0]}',
        quantity: masticKg,
        unit: 'кг',
        withReserve: masticKg,
        purchaseQty: masticKg.ceil().toDouble(),
        category: 'Гидроизоляция',
      ),
    );
  } else if (waterproofType == 1) {
    materials.add(
      CanonicalMaterialResult(
        name:
            '${_waterproofLabels[1]} (${spec.materialRule<num>('roll_m2').toDouble().round()} м²/рулон)',
        quantity: rollCount.toDouble(),
        unit: 'рулонов',
        withReserve: rollCount.toDouble(),
        purchaseQty: rollCount.toDouble(),
        category: 'Гидроизоляция',
      ),
    );
  } else {
    materials.add(
      CanonicalMaterialResult(
        name: '${_waterproofLabels[2]}',
        quantity: penKg,
        unit: 'кг',
        withReserve: penKg,
        purchaseQty: penKg.ceil().toDouble(),
        category: 'Гидроизоляция',
      ),
    );
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
