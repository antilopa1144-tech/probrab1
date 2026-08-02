import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

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

  final perimeter = math
      .max(
        10.0,
        math.min(
          200.0,
          normalized['perimeter'] ?? defaultFor(spec, 'perimeter', 40),
        ),
      )
      .toDouble();
  final width = math
      .max(
        0.6,
        math.min(1.5, normalized['width'] ?? defaultFor(spec, 'width', 1.0)),
      )
      .toDouble();
  final thickness = math
      .max(
        70.0,
        math.min(
          150.0,
          normalized['thickness'] ?? defaultFor(spec, 'thickness', 100),
        ),
      )
      .toDouble();
  final materialType =
      (normalized['materialType'] ?? defaultFor(spec, 'materialType', 0))
          .round()
          .clamp(0, 2);
  final withInsulation = math
      .max(
        0.0,
        math.min(
          100.0,
          normalized['withInsulation'] ?? defaultFor(spec, 'withInsulation', 0),
        ),
      )
      .toDouble();

  final materialRules =
      spec.raw['material_rules'] as Map<String, dynamic>? ?? const {};
  final gravelLayers =
      materialRules['gravel_layer_by_type'] as Map<String, dynamic>? ??
      const {};
  final sandLayers =
      materialRules['sand_layer_by_type'] as Map<String, dynamic>? ?? const {};

  // Closed rectilinear contour: straight runs plus the net four corner areas.
  final straightStripArea = perimeter * width;
  final cornerAllowanceArea = 4 * width * width;
  final area = straightStripArea + cornerAllowanceArea;
  final outerEdgeLength = perimeter + 8 * width;

  var concreteM3 = 0.0;
  var meshAreaM2 = 0.0;
  var damperM = 0.0;
  var tileM2 = 0.0;
  var borderPcs = 0;
  var membraneM2 = 0.0;
  var membraneWithOverlapM2 = 0.0;
  var decorGravelM3 = 0.0;

  if (materialType == 0) {
    concreteM3 = roundValue(area * (thickness / 1000.0), 6);
    meshAreaM2 = thickness >= 100 ? roundValue(area, 6) : 0;
    damperM = roundValue(perimeter, 6);
  } else if (materialType == 1) {
    tileM2 = roundValue(area, 6);
    final borderPieceLength = spec
        .materialRule<num>('border_piece_length_m')
        .toDouble();
    borderPcs = (outerEdgeLength / borderPieceLength).ceil();
  } else {
    membraneM2 = roundValue(area, 6);
    membraneWithOverlapM2 = roundValue(
      area * spec.materialRule<num>('membrane_overlap_factor').toDouble(),
      6,
    );
    decorGravelM3 = roundValue(
      area * spec.materialRule<num>('decorative_gravel_layer_m').toDouble(),
      3,
    );
  }

  final gravelLayer = (gravelLayers['$materialType'] as num?)?.toDouble() ?? 0;
  final sandLayer = (sandLayers['$materialType'] as num?)?.toDouble() ?? 0;
  final gravel = roundValue(area * gravelLayer, 3);
  final sand = roundValue(area * sandLayer, 3);
  final geotextileRolls = materialType == 2
      ? 0
      : (area *
                spec.materialRule<num>('geotextile_reserve').toDouble() /
                spec.materialRule<num>('geotextile_roll_m2').toDouble())
            .ceil();
  final eppsPlates = withInsulation > 0
      ? (area *
                spec.materialRule<num>('epps_reserve').toDouble() /
                spec.materialRule<num>('epps_plate_m2').toDouble())
            .ceil()
      : 0;

  final basePrimaryRaw = materialType == 0
      ? concreteM3
      : materialType == 1
      ? tileM2
      : membraneWithOverlapM2;
  final accuracyBaseRaw = materialType == 2 ? membraneM2 : basePrimaryRaw;
  final materialCategory = materialType == 0
      ? 'concrete'
      : materialType == 1
      ? 'tile'
      : 'waterproofing';
  final accuracyMode = parseAccuracyMode(normalized);
  final accuracyMultiplier = accuracyPrimaryMultiplier(
    materialCategory,
    accuracyMode,
  );
  final packageLabel = materialType == 0
      ? 'concrete-m3'
      : materialType == 1
      ? 'tile-m2'
      : 'membrane-m2';
  final packageUnit = materialType == 0 ? 'м³' : 'м²';
  final packageSize = materialType == 0
      ? spec.packagingRule<num>('concrete_step_m3').toDouble()
      : spec.packagingRule<num>('surface_step_m2').toDouble();

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(
      math
          .max(
            basePrimaryRaw,
            accuracyBaseRaw * accuracyMultiplier * multiplier,
          )
          .toDouble(),
      6,
    );
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'materialType:$materialType',
        'thickness:${thickness.round()}',
        'geometry:closed-orthogonal-contour',
        if (materialType == 2)
          'membrane_overlap_factor:${spec.materialRule<num>('membrane_overlap_factor')}',
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
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final warnings = <String>[];
  if (width < spec.warningRule<num>('narrow_width_threshold_m').toDouble()) {
    warnings.add(
      'Ширина менее 0,8 м — узкий вариант: проверьте свес кровли, грунт и схему водоотвода по проекту',
    );
  }
  if (materialType == 0 &&
      thickness <
          spec.warningRule<num>('thin_concrete_threshold_mm').toDouble()) {
    warnings.add(
      'Слой бетона 70 мм требует проверки основания, класса бетона и армирования по проекту; сетка автоматически не добавлена',
    );
  }
  if (materialType == 1) {
    warnings.add(
      'Укладочный слой и швы плитки не рассчитаны: их расход зависит от выбранной системы, толщины слоя и паспорта смеси',
    );
  }
  if (materialType == 2) {
    warnings.add(
      'Для мягкой системы рассчитана профилированная мембрана с прикреплённым геотекстилем; отдельный рулон геотекстиля не добавлен',
    );
  }

  final materials = <CanonicalMaterialResult>[];
  if (materialType == 0) {
    final meshWithOverlap = roundValue(
      meshAreaM2 * spec.materialRule<num>('mesh_reserve').toDouble(),
      6,
    );
    final damperWithReserve = roundValue(
      damperM * spec.materialRule<num>('damper_reserve').toDouble(),
      6,
    );
    materials.add(
      CanonicalMaterialResult(
        name: 'Бетон В15 (М200), слой ${thickness.round()} мм',
        quantity: concreteM3,
        unit: 'м³',
        withReserve: recScenario.exactNeed,
        purchaseQty: recScenario.purchaseQuantity,
        packageInfo: {
          'count': recScenario.buyPlan.packagesCount,
          'size': recScenario.buyPlan.packageSize,
          'packageUnit': 'шагов заказа',
        },
        category: 'Бетон',
      ),
    );
    if (meshAreaM2 > 0) {
      materials.add(
        CanonicalMaterialResult(
          name: 'Арматурная сетка 100×100×4 мм',
          quantity: meshAreaM2,
          unit: 'м²',
          withReserve: meshWithOverlap,
          purchaseQty: meshWithOverlap.ceilToDouble(),
          category: 'Армирование',
        ),
      );
    }
    materials.add(
      CanonicalMaterialResult(
        name: 'Демпферная разделительная лента для примыкания к цоколю',
        quantity: damperM,
        unit: 'м',
        withReserve: damperWithReserve,
        purchaseQty: damperWithReserve.ceilToDouble(),
        category: 'Расходные',
      ),
    );
  } else if (materialType == 1) {
    final borderPieceLength = spec
        .materialRule<num>('border_piece_length_m')
        .toDouble();
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Тротуарная плитка для наружных работ',
        quantity: tileM2,
        unit: 'м²',
        withReserve: recScenario.exactNeed,
        purchaseQty: recScenario.purchaseQuantity,
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Бордюр тротуарный, длина $borderPieceLength м',
        quantity: roundValue(outerEdgeLength / borderPieceLength, 6),
        unit: 'шт',
        withReserve: borderPcs.toDouble(),
        purchaseQty: borderPcs.toDouble(),
        category: 'Покрытие',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Профилированная дренажная мембрана',
        quantity: membraneM2,
        unit: 'м²',
        withReserve: recScenario.exactNeed,
        purchaseQty: recScenario.purchaseQuantity,
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Декоративный щебень фракции 20–40 мм',
        quantity: decorGravelM3,
        unit: 'м³',
        withReserve: decorGravelM3,
        purchaseQty: (decorGravelM3 * 10).ceil() / 10.0,
        category: 'Покрытие',
      ),
    ]);
  }

  if (gravel > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Щебень фракции 20–40 мм для подушки',
        quantity: gravel,
        unit: 'м³',
        withReserve: gravel,
        purchaseQty: (gravel * 10).ceil() / 10.0,
        category: 'Подготовка',
      ),
    );
  }
  if (sand > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Песок строительный средней крупности для подушки',
        quantity: sand,
        unit: 'м³',
        withReserve: sand,
        purchaseQty: (sand * 10).ceil() / 10.0,
        category: 'Подготовка',
      ),
    );
  }
  if (geotextileRolls > 0) {
    final rollArea = spec.materialRule<num>('geotextile_roll_m2').toDouble();
    materials.add(
      CanonicalMaterialResult(
        name: 'Геотекстиль 200 г/м², рулон ${rollArea.round()} м²',
        quantity: geotextileRolls.toDouble(),
        unit: 'рулонов',
        withReserve: geotextileRolls.toDouble(),
        purchaseQty: geotextileRolls.toDouble(),
        category: 'Подготовка',
      ),
    );
  }
  if (eppsPlates > 0) {
    materials.add(
      CanonicalMaterialResult(
        name:
            'Экструдированный пенополистирол (ЭППС) ${withInsulation.round()} мм, плита 1200×600 мм',
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
      'perimeter': roundValue(perimeter, 3),
      'width': roundValue(width, 3),
      'area': roundValue(area, 3),
      'straightStripArea': roundValue(straightStripArea, 3),
      'cornerAllowanceArea': roundValue(cornerAllowanceArea, 3),
      'outerEdgeLength': roundValue(outerEdgeLength, 3),
      'thickness': thickness,
      'materialType': materialType.toDouble(),
      'withInsulation': withInsulation,
      'concreteM3': concreteM3,
      'meshPcs': meshAreaM2,
      'meshAreaM2': meshAreaM2,
      'damperM': damperM,
      'tileM2': tileM2,
      'mixBags': 0,
      'borderPcs': borderPcs.toDouble(),
      'membraneM2': membraneM2,
      'membraneWithOverlapM2': membraneWithOverlapM2,
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
