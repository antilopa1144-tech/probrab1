import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

class _RebarGeometry {
  final double mainExactLength;
  final double secondaryExactLength;
  final int intersections;
  final int barsAlongLength;
  final int barsAlongWidth;
  final int stirrupCount;
  final double stirrupPieceLength;

  const _RebarGeometry({
    required this.mainExactLength,
    required this.secondaryExactLength,
    required this.intersections,
    required this.barsAlongLength,
    required this.barsAlongWidth,
    required this.stirrupCount,
    required this.stirrupPieceLength,
  });
}

class _ScenarioPlan {
  final double reservePercent;
  final double mainPlanningLength;
  final int mainRods;
  final double mainPurchaseLength;
  final double secondaryPlanningLength;
  final int secondaryRods;
  final double secondaryPurchaseLength;

  const _ScenarioPlan({
    required this.reservePercent,
    required this.mainPlanningLength,
    required this.mainRods,
    required this.mainPurchaseLength,
    required this.secondaryPlanningLength,
    required this.secondaryRods,
    required this.secondaryPurchaseLength,
  });

  double get totalPlanningLength =>
      roundValue(mainPlanningLength + secondaryPlanningLength, 6);
  double get totalPurchaseLength =>
      roundValue(mainPurchaseLength + secondaryPurchaseLength, 6);
}

double _allowedPackagingValue(
  SpecReader spec,
  String key,
  double requested,
  double fallback,
) {
  final allowed = spec
      .packagingRule<List>(key)
      .whereType<num>()
      .map((value) => value.toDouble())
      .toList(growable: false);
  return allowed.contains(requested) ? requested : fallback;
}

int _allowedDiameter(SpecReader spec, String key, int requested, int fallback) {
  final allowed = spec
      .materialRule<List>(key)
      .whereType<num>()
      .map((value) => value.toInt())
      .toList(growable: false);
  return allowed.contains(requested) ? requested : fallback;
}

double _weightPerMeter(SpecReader spec, int diameter, double fallback) {
  return (spec.materialRule<Map>('weight_per_meter')[diameter.toString()]
              as num?)
          ?.toDouble() ??
      fallback;
}

_ScenarioPlan _buildPlan(
  _RebarGeometry geometry,
  double reservePercent,
  double rodLength,
) {
  final multiplier = 1 + reservePercent / 100;
  final mainPlanning = roundValue(geometry.mainExactLength * multiplier, 6);
  final mainRods = (mainPlanning / rodLength).ceil();
  final mainPurchase = roundValue(mainRods * rodLength, 6);
  final secondaryPlanning = roundValue(
    geometry.secondaryExactLength * multiplier,
    6,
  );
  final secondaryRods = secondaryPlanning > 0
      ? (secondaryPlanning / rodLength).ceil()
      : 0;
  final secondaryPurchase = roundValue(secondaryRods * rodLength, 6);

  return _ScenarioPlan(
    reservePercent: reservePercent,
    mainPlanningLength: mainPlanning,
    mainRods: mainRods,
    mainPurchaseLength: mainPurchase,
    secondaryPlanningLength: secondaryPlanning,
    secondaryRods: secondaryRods,
    secondaryPurchaseLength: secondaryPurchase,
  );
}

CanonicalCalculatorContractResult calculateCanonicalRebar(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(rebarSpecData);
  final structureType =
      (inputs['structureType'] ?? defaultFor(spec, 'structureType', 0))
          .round()
          .clamp(0, 1);
  final length = (inputs['length'] ?? defaultFor(spec, 'length', 10))
      .clamp(1, 50)
      .toDouble();
  final width = (inputs['width'] ?? defaultFor(spec, 'width', 8))
      .clamp(1, 50)
      .toDouble();
  final gridLayers = (inputs['gridLayers'] ?? defaultFor(spec, 'gridLayers', 2))
      .round()
      .clamp(1, 2);
  final gridStepMm =
      (inputs['gridStepMm'] ?? defaultFor(spec, 'gridStepMm', 200))
          .clamp(100, 500)
          .toDouble();
  final edgeCoverMm =
      (inputs['edgeCoverMm'] ?? defaultFor(spec, 'edgeCoverMm', 50))
          .clamp(0, 150)
          .toDouble();
  final frameLength =
      (inputs['frameLengthM'] ?? defaultFor(spec, 'frameLengthM', 36))
          .clamp(1, 500)
          .toDouble();
  final longitudinalBars =
      (inputs['longitudinalBars'] ?? defaultFor(spec, 'longitudinalBars', 4))
          .round()
          .clamp(2, 16);
  final stirrupWidth =
      (inputs['stirrupWidthMm'] ?? defaultFor(spec, 'stirrupWidthMm', 300))
          .clamp(100, 2000)
          .toDouble();
  final stirrupHeight =
      (inputs['stirrupHeightMm'] ?? defaultFor(spec, 'stirrupHeightMm', 300))
          .clamp(100, 3000)
          .toDouble();
  final stirrupStep =
      (inputs['stirrupStepMm'] ?? defaultFor(spec, 'stirrupStepMm', 400))
          .clamp(100, 1000)
          .toDouble();
  final stirrupHookAllowance =
      (inputs['stirrupHookAllowanceMm'] ??
              defaultFor(spec, 'stirrupHookAllowanceMm', 300))
          .clamp(0, 1500)
          .toDouble();
  final mainDiameter = _allowedDiameter(
    spec,
    'allowed_diameters_mm',
    (inputs['mainDiameter'] ?? defaultFor(spec, 'mainDiameter', 12)).round(),
    12,
  );
  final stirrupDiameter = _allowedDiameter(
    spec,
    'allowed_stirrup_diameters_mm',
    (inputs['stirrupDiameterMm'] ?? defaultFor(spec, 'stirrupDiameterMm', 8))
        .round(),
    8,
  );
  final reserve =
      (inputs['reservePercent'] ?? defaultFor(spec, 'reservePercent', 10))
          .clamp(0, 30)
          .toDouble();
  final rodLength = _allowedPackagingValue(
    spec,
    'allowed_rod_lengths_m',
    inputs['rodLengthM'] ?? defaultFor(spec, 'rodLengthM', 11.7),
    11.7,
  );
  final tieShare =
      (inputs['tieSharePercent'] ?? defaultFor(spec, 'tieSharePercent', 100))
          .clamp(0, 100)
          .toDouble();
  final wireLengthPerTie =
      (inputs['wireLengthPerTieM'] ??
              defaultFor(spec, 'wireLengthPerTieM', 0.3))
          .clamp(0.1, 1)
          .toDouble();
  final wireReserve =
      (inputs['wireReservePercent'] ??
              defaultFor(spec, 'wireReservePercent', 10))
          .clamp(0, 50)
          .toDouble();
  final wirePackage = _allowedPackagingValue(
    spec,
    'allowed_wire_packages_kg',
    inputs['wirePackageKg'] ?? defaultFor(spec, 'wirePackageKg', 1),
    1,
  );

  late final _RebarGeometry geometry;
  if (structureType == 0) {
    final clearLength = math.max(0, length - 2 * edgeCoverMm / 1000).toDouble();
    final clearWidth = math.max(0, width - 2 * edgeCoverMm / 1000).toDouble();
    final stepM = gridStepMm / 1000;
    final barsAlongLength = (clearWidth / stepM).ceil() + 1;
    final barsAlongWidth = (clearLength / stepM).ceil() + 1;
    geometry = _RebarGeometry(
      mainExactLength: roundValue(
        gridLayers *
            (barsAlongLength * clearLength + barsAlongWidth * clearWidth),
        6,
      ),
      secondaryExactLength: 0,
      intersections: barsAlongLength * barsAlongWidth * gridLayers,
      barsAlongLength: barsAlongLength,
      barsAlongWidth: barsAlongWidth,
      stirrupCount: 0,
      stirrupPieceLength: 0,
    );
  } else {
    final stirrupCount = (frameLength / (stirrupStep / 1000)).ceil() + 1;
    final stirrupPieceLength = roundValue(
      2 * (stirrupWidth + stirrupHeight) / 1000 + stirrupHookAllowance / 1000,
      6,
    );
    geometry = _RebarGeometry(
      mainExactLength: roundValue(frameLength * longitudinalBars, 6),
      secondaryExactLength: roundValue(stirrupCount * stirrupPieceLength, 6),
      intersections: stirrupCount * longitudinalBars,
      barsAlongLength: 0,
      barsAlongWidth: 0,
      stirrupCount: stirrupCount,
      stirrupPieceLength: stirrupPieceLength,
    );
  }

  final scenarioPolicy = spec.raw['scenario_policy'] as Map<String, dynamic>;
  final maxReserveFloor =
      (scenarioPolicy['max_reserve_floor_percent'] as num?)?.toDouble() ?? 15;
  final plans = <String, _ScenarioPlan>{
    'MIN': _buildPlan(geometry, 0, rodLength),
    'REC': _buildPlan(geometry, reserve, rodLength),
    'MAX': _buildPlan(
      geometry,
      math.max(reserve, maxReserveFloor).toDouble(),
      rodLength,
    ),
  };
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final plan = plans[scenarioName]!;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: plan.totalPlanningLength,
      purchaseQuantity: plan.totalPurchaseLength,
      leftover: roundValue(
        plan.totalPurchaseLength - plan.totalPlanningLength,
        6,
      ),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'scheme:${structureType == 0 ? 'grid' : 'frame'}',
        'reserve_percent:${plan.reservePercent}',
        'main_diameter_mm:$mainDiameter',
        'rod_length_m:$rodLength',
        'packaging:each_diameter_separately',
      ],
      keyFactors: {
        'reserve_percent': plan.reservePercent,
        'field_multiplier': roundValue(1 + plan.reservePercent / 100, 6),
        'rod_length_m': rodLength,
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'Прутки по $rodLength м — каждый диаметр отдельно',
        packageSize: rodLength,
        packagesCount: plan.mainRods + plan.secondaryRods,
        unit: 'прутков',
      ),
    );
  }

  final recPlan = plans['REC']!;
  final tieCount = (geometry.intersections * tieShare / 100).ceil();
  final wireExactLength = roundValue(tieCount * wireLengthPerTie, 6);
  final wireExactKg = roundValue(
    wireExactLength * spec.materialRule<num>('wire_weight_kg_per_m').toDouble(),
    6,
  );
  final wirePlanningKg = roundValue(wireExactKg * (1 + wireReserve / 100), 6);
  final wirePackages = wirePlanningKg > 0
      ? (wirePlanningKg / wirePackage).ceil()
      : 0;
  final wirePurchaseKg = roundValue(wirePackages * wirePackage, 6);
  final mainWeightPerM = _weightPerMeter(spec, mainDiameter, 0.888);
  final secondaryWeightPerM = _weightPerMeter(spec, stirrupDiameter, 0.395);

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: structureType == 0
          ? 'Арматура сетки ∅$mainDiameter мм — класс по проекту'
          : 'Продольная арматура ∅$mainDiameter мм — класс по проекту',
      quantity: roundValue(geometry.mainExactLength, 3),
      unit: 'пог. м',
      withReserve: roundValue(recPlan.mainPlanningLength, 3),
      purchaseQty: roundValue(recPlan.mainPurchaseLength, 3),
      category: 'Арматура',
      packageInfo: {
        'count': recPlan.mainRods,
        'size': rodLength,
        'packageUnit': 'прутков',
      },
    ),
  ];
  if (geometry.secondaryExactLength > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Хомуты ∅$stirrupDiameter мм — класс и форма по проекту',
        quantity: roundValue(geometry.secondaryExactLength, 3),
        unit: 'пог. м',
        withReserve: roundValue(recPlan.secondaryPlanningLength, 3),
        purchaseQty: roundValue(recPlan.secondaryPurchaseLength, 3),
        category: 'Арматура',
        packageInfo: {
          'count': recPlan.secondaryRods,
          'size': rodLength,
          'packageUnit': 'прутков',
        },
      ),
    );
  }
  if (wireExactKg > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Проволока вязальная отожжённая ∅1,2 мм',
        quantity: roundValue(wireExactKg, 3),
        unit: 'кг',
        withReserve: roundValue(wirePlanningKg, 3),
        purchaseQty: roundValue(wirePurchaseKg, 3),
        category: 'Расходные материалы',
        packageInfo: {
          'count': wirePackages,
          'size': wirePackage,
          'packageUnit': 'упаковок',
        },
      ),
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'structureType': structureType.toDouble(),
      'length': roundValue(length, 3),
      'width': roundValue(width, 3),
      'gridLayers': gridLayers.toDouble(),
      'gridStepMm': roundValue(gridStepMm, 3),
      'edgeCoverMm': roundValue(edgeCoverMm, 3),
      'frameLengthM': roundValue(frameLength, 3),
      'longitudinalBars': longitudinalBars.toDouble(),
      'stirrupWidthMm': roundValue(stirrupWidth, 3),
      'stirrupHeightMm': roundValue(stirrupHeight, 3),
      'stirrupStepMm': roundValue(stirrupStep, 3),
      'stirrupDiameterMm': stirrupDiameter.toDouble(),
      'stirrupHookAllowanceMm': roundValue(stirrupHookAllowance, 3),
      'mainDiameter': mainDiameter.toDouble(),
      'reservePercent': roundValue(reserve, 3),
      'rodLengthM': rodLength,
      'mainExactLengthM': roundValue(geometry.mainExactLength, 3),
      'mainPlanningLengthM': roundValue(recPlan.mainPlanningLength, 3),
      'mainPurchaseLengthM': roundValue(recPlan.mainPurchaseLength, 3),
      'mainRods': recPlan.mainRods.toDouble(),
      'mainExactWeightKg': roundValue(
        geometry.mainExactLength * mainWeightPerM,
        3,
      ),
      'mainPlanningWeightKg': roundValue(
        recPlan.mainPlanningLength * mainWeightPerM,
        3,
      ),
      'mainPurchaseWeightKg': roundValue(
        recPlan.mainPurchaseLength * mainWeightPerM,
        3,
      ),
      'secondaryExactLengthM': roundValue(geometry.secondaryExactLength, 3),
      'secondaryPlanningLengthM': roundValue(
        recPlan.secondaryPlanningLength,
        3,
      ),
      'secondaryPurchaseLengthM': roundValue(
        recPlan.secondaryPurchaseLength,
        3,
      ),
      'secondaryRods': recPlan.secondaryRods.toDouble(),
      'secondaryExactWeightKg': roundValue(
        geometry.secondaryExactLength * secondaryWeightPerM,
        3,
      ),
      'secondaryPurchaseWeightKg': roundValue(
        recPlan.secondaryPurchaseLength * secondaryWeightPerM,
        3,
      ),
      'intersections': geometry.intersections.toDouble(),
      'tieCount': tieCount.toDouble(),
      'tieSharePercent': roundValue(tieShare, 3),
      'wireLengthPerTieM': roundValue(wireLengthPerTie, 3),
      'wireExactLengthM': roundValue(wireExactLength, 3),
      'wireExactKg': roundValue(wireExactKg, 3),
      'wirePlanningKg': roundValue(wirePlanningKg, 3),
      'wirePurchaseKg': roundValue(wirePurchaseKg, 3),
      'wirePackages': wirePackages.toDouble(),
      'wirePackageKg': wirePackage,
      'barsAlongLength': geometry.barsAlongLength.toDouble(),
      'barsAlongWidth': geometry.barsAlongWidth.toDouble(),
      'stirrupCount': geometry.stirrupCount.toDouble(),
      'stirrupPieceLengthM': roundValue(geometry.stirrupPieceLength, 3),
      'minExactNeedM': scenarios['MIN']!.exactNeed,
      'recExactNeedM': scenarios['REC']!.exactNeed,
      'maxExactNeedM': scenarios['MAX']!.exactNeed,
      'minPurchaseM': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseM': scenarios['REC']!.purchaseQuantity,
      'maxPurchaseM': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: const [
      'Калькулятор не назначает диаметр, шаг, число слоёв, нахлёсты, анкеровку или форму хомутов. Все параметры схемы перенесите из проекта конструктора.',
    ],
    scenarios: scenarios,
  );
}
