import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
};

bool hasCanonicalLaminateInputs(Map<String, double> inputs) {
  return inputs.containsKey('layoutProfileId') ||
      inputs.containsKey('hasUnderlayment') ||
      inputs.containsKey('underlaymentRollArea');
}

int _legacyLayoutPattern(Map<String, double> inputs) {
  if (inputs.containsKey('layoutPattern')) {
    return (inputs['layoutPattern'] ?? 2).round();
  }
  if (inputs.containsKey('pattern')) {
    final pattern = (inputs['pattern'] ?? 0).round();
    switch (pattern) {
      case 1:
        return 4;
      default:
        return 1;
    }
  }
  return 2;
}

int _mapLegacyLayoutProfile(Map<String, double> inputs) {
  if (inputs.containsKey('layoutProfileId')) {
    return (inputs['layoutProfileId'] ?? 7).round().clamp(1, 8);
  }

  if (inputs.containsKey('layingMethod')) {
    final layingMethod = (inputs['layingMethod'] ?? 0).round();
    final offsetMode = (inputs['offsetMode'] ?? 0).round();
    if (layingMethod == 1) return 4;
    if (layingMethod == 2) return 5;
    if (offsetMode == 1) return 2;
    if (offsetMode == 2) return 3;
    return 1;
  }

  switch (_legacyLayoutPattern(inputs)) {
    case 1:
      return 6;
    case 3:
      return 8;
    case 4:
      return 4;
    default:
      return 7;
  }
}

Map<String, double> normalizeLegacyLaminateInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);

  if (!normalized.containsKey('length') && inputs.containsKey('roomLength')) {
    normalized['length'] = (inputs['roomLength'] ?? 0).toDouble();
  }
  if (!normalized.containsKey('width') && inputs.containsKey('roomWidth')) {
    normalized['width'] = (inputs['roomWidth'] ?? 0).toDouble();
  }
  if (!normalized.containsKey('layoutProfileId')) {
    normalized['layoutProfileId'] = _mapLegacyLayoutProfile(inputs).toDouble();
  }
  normalized['reservePercent'] = ((inputs['reservePercent'] ?? inputs['reserve'] ?? 10).toDouble()).clamp(0, 20).toDouble();
  normalized['hasUnderlayment'] = ((inputs['hasUnderlayment'] ?? inputs['needUnderlay'] ?? 1) > 0 ? 1 : 0).toDouble();
  normalized['underlaymentRollArea'] = (inputs['underlaymentRollArea'] ?? inputs['underlaymentRoll'] ?? 10).toDouble();
  normalized['doorThresholds'] = (inputs['doorThresholds'] ?? 1).toDouble();
  normalized['underlayType'] = (inputs['underlayType'] ?? 3).toDouble();
  normalized['laminateClass'] = (inputs['laminateClass'] ?? 32).toDouble();
  normalized['laminateThickness'] = (inputs['laminateThickness'] ?? 8).toDouble();
  normalized['packArea'] = (inputs['packArea'] ?? 2.0).toDouble();
  return normalized;
}

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveGeometry(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 1)).round();
  if (inputMode == 0) {
    final length = math.max(1, inputs['length'] ?? defaultFor(spec, 'length', 5)).toDouble();
    final width = math.max(1, inputs['width'] ?? defaultFor(spec, 'width', 4)).toDouble();
    return {
      'inputMode': 0.0,
      'area': roundValue(length * width, 3),
      'perimeter': roundValue(2 * (length + width), 3),
    };
  }

  final area = math.max(1, inputs['area'] ?? defaultFor(spec, 'area', 20)).toDouble();
  final explicitPerimeter = math.max(0, inputs['perimeter'] ?? 0).toDouble();
  return {
    'inputMode': 1.0,
    'area': roundValue(area, 3),
    'perimeter': roundValue(explicitPerimeter > 0 ? explicitPerimeter : _estimatePerimeter(area), 3),
  };
}

Map<String, dynamic> _resolveLayoutProfile(SpecReader spec, Map<String, double> inputs) {
  final profileId = (inputs['layoutProfileId'] ?? defaultFor(spec, 'layoutProfileId', 7)).round().clamp(1, 8);
  return spec.normativeList('layout_profiles').firstWhere(
    (profile) => (profile['id'] as num).toInt() == profileId,
    orElse: () => spec.normativeList('layout_profiles').first,
  );
}

CanonicalCalculatorContractResult calculateCanonicalLaminate(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(laminateSpecData);

  final normalized = hasCanonicalLaminateInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyLaminateInputs(inputs);
  final geometry = _resolveGeometry(spec, normalized);
  final packArea = (normalized['packArea'] ?? defaultFor(spec, 'packArea', 2.397)).clamp(0.5, 5).toDouble();
  final layoutProfile = _resolveLayoutProfile(spec, normalized);
  final reservePercent = (normalized['reservePercent'] ?? defaultFor(spec, 'reservePercent', spec.materialRule<num>('reserve_percent_default').toDouble()))
      .clamp(0, 25)
      .toDouble();
  final smallRoomAdjustment = geometry['area']! < spec.materialRule<num>('small_room_threshold_m2').toDouble()
      ? (spec.materialRule<num>('small_room_threshold_m2').toDouble() - geometry['area']!) * spec.materialRule<num>('small_room_waste_per_m2_percent').toDouble()
      : 0.0;
  final effectiveWastePercent = math.max((layoutProfile['waste_percent'] as num).toDouble() + smallRoomAdjustment, reservePercent);
  final baseExactNeedArea = roundValue(geometry['area']! * (1 + effectiveWastePercent / 100), 6);
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseExactNeedArea * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / packArea).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packArea, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'layout:${layoutProfile['key'] as String}',
        'packaging:laminate-pack-${roundValue(packArea, 3)}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
        'reserve_percent': roundValue(reservePercent, 3),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'laminate-pack-${roundValue(packArea, 3)}',
        packageSize: packArea,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('laminate_pack_area_unit'),
      ),
    );
  }

  final hasUnderlayment = (normalized['hasUnderlayment'] ?? defaultFor(spec, 'hasUnderlayment', 1)) > 0;
  final underlaymentRollArea = (normalized['underlaymentRollArea'] ?? defaultFor(spec, 'underlaymentRollArea', spec.packagingRule<num>('underlayment_roll_area_m2').toDouble()))
      .clamp(5, 20)
      .toDouble();
  final underlaymentArea = hasUnderlayment
      ? roundValue(geometry['area']! * (1 + spec.materialRule<num>('underlayment_overlap_percent').toDouble() / 100), 6)
      : 0.0;
  final underlaymentRolls = hasUnderlayment ? (underlaymentArea / underlaymentRollArea).ceil() : 0;
  final doorThresholds = math.max(0, (normalized['doorThresholds'] ?? defaultFor(spec, 'doorThresholds', 1)).round());
  final plinthLengthRaw = math.max(0, geometry['perimeter']! - doorThresholds * spec.materialRule<num>('default_door_opening_width_m').toDouble());
  final plinthPieces = (plinthLengthRaw / spec.packagingRule<num>('plinth_piece_length_m').toDouble()).ceil();
  final plinthLength = roundValue(plinthPieces * spec.packagingRule<num>('plinth_piece_length_m').toDouble(), 6);
  final innerCorners = spec.materialRule<num>('rectangle_inner_corners').toDouble();
  final plinthConnectors = math.max(0, plinthPieces - innerCorners);
  final wedges = (geometry['perimeter']! / spec.materialRule<num>('wedge_spacing_m').toDouble()).ceil();
  final vaporBarrierArea = roundValue(geometry['area']! * (1 + spec.materialRule<num>('vapor_barrier_overlap_percent').toDouble() / 100), 6);
  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (geometry['area']! < spec.warningRule<num>('small_area_warning_threshold_m2').toDouble()) {
    warnings.add('Маленькая площадь: процент отходов может быть выше из-за коротких обрезков');
  }
  if ((spec.warningRule<List>('diagonal_warning_profile_ids') ?? []).contains((layoutProfile['id'] as num).toInt())) {
    warnings.add('Диагональная укладка требует более высокого запаса и аккуратной раскладки');
  }
  if ((spec.warningRule<List>('herringbone_warning_profile_ids') ?? []).contains((layoutProfile['id'] as num).toInt())) {
    warnings.add('Укладка ёлочкой требует идеально ровного основания и высокой квалификации');
  }
  if ((spec.warningRule<List>('half_shift_warning_profile_ids') ?? []).contains((layoutProfile['id'] as num).toInt())) {
    warnings.add('Смещение досок на 1/2 увеличивает количество коротких обрезков');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Ламинат (${roundValue(packArea, 3)} м² в упаковке)',
      quantity: roundValue(recScenario.exactNeed / packArea, 6),
      unit: 'упак.',
      withReserve: recScenario.buyPlan.packagesCount.toDouble(),
      purchaseQty: recScenario.buyPlan.packagesCount,
      category: 'Напольное покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Плинтус напольный (${spec.packagingRule<num>('plinth_piece_length_m').toDouble()} м)',
      quantity: roundValue(plinthLength / spec.packagingRule<num>('plinth_piece_length_m').toDouble(), 6),
      unit: 'шт',
      withReserve: plinthPieces.toDouble(),
      purchaseQty: plinthPieces.toInt(),
      category: 'Плинтус',
    ),
    CanonicalMaterialResult(
      name: 'Внутренние углы для плинтуса',
      quantity: innerCorners.toDouble(),
      unit: 'шт',
      withReserve: innerCorners.toDouble(),
      purchaseQty: innerCorners.toInt(),
      category: 'Плинтус',
    ),
    CanonicalMaterialResult(
      name: 'Соединители для плинтуса',
      quantity: plinthConnectors.toDouble(),
      unit: 'шт',
      withReserve: plinthConnectors.toDouble(),
      purchaseQty: plinthConnectors.toInt(),
      category: 'Плинтус',
    ),
    CanonicalMaterialResult(
      name: 'Клинья распорные',
      quantity: wedges.toDouble(),
      unit: 'шт',
      withReserve: wedges.toDouble(),
      purchaseQty: wedges.toInt(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Пароизоляционная плёнка',
      quantity: vaporBarrierArea,
      unit: 'м²',
      withReserve: vaporBarrierArea,
      purchaseQty: vaporBarrierArea.ceil(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Порожек стыковочный',
      quantity: doorThresholds.toDouble(),
      unit: 'шт',
      withReserve: doorThresholds.toDouble(),
      purchaseQty: doorThresholds.toInt(),
      category: 'Плинтус',
    ),
  ];

  if (hasUnderlayment) {
    materials.insert(
      1,
      CanonicalMaterialResult(
        name: 'Подложка под ламинат',
        quantity: roundValue(underlaymentArea / underlaymentRollArea, 6),
        unit: 'рулонов',
        withReserve: underlaymentRolls.toDouble(),
        purchaseQty: underlaymentRolls.toInt(),
        category: 'Подложка',
      ),
    );
    materials.add(
      const CanonicalMaterialResult(
        name: 'Скотч для стыков подложки',
        quantity: 1,
        unit: 'рулон',
        withReserve: 1,
        purchaseQty: 1,
        category: 'Подложка',
      ),
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': geometry['area']!,
      'perimeter': geometry['perimeter']!,
      'inputMode': geometry['inputMode']!,
      'packArea': roundValue(packArea, 6),
      'layoutProfileId': (layoutProfile['id'] as num).toInt().toDouble(),
      'reservePercent': roundValue(reservePercent, 3),
      'smallRoomAdjustment': roundValue(smallRoomAdjustment, 3),
      'wastePercent': roundValue(effectiveWastePercent, 3),
      'baseExactNeedArea': baseExactNeedArea,
      'packsNeeded': recScenario.buyPlan.packagesCount.toDouble(),
      'underlayArea': underlaymentArea,
      'underlaymentRolls': underlaymentRolls.toDouble(),
      'plinthLength': plinthLength,
      'plinthPieces': plinthPieces.toDouble(),
      'innerCorners': innerCorners.toDouble(),
      'plinthConnectors': plinthConnectors.toDouble(),
      'wedgesNeeded': wedges.toDouble(),
      'vaporBarrierArea': vaporBarrierArea,
      'doorThresholds': doorThresholds.toDouble(),
      'underlayType': ((normalized['underlayType'] ?? defaultFor(spec, 'underlayType', 3)).round().clamp(2, 5)).toDouble(),
      'laminateClass': ((normalized['laminateClass'] ?? defaultFor(spec, 'laminateClass', 32)).round().clamp(31, 34)).toDouble(),
      'laminateThickness': ((normalized['laminateThickness'] ?? defaultFor(spec, 'laminateThickness', 8)).round().clamp(6, 14)).toDouble(),
      'minExactNeedArea': scenarios['MIN']!.exactNeed,
      'recExactNeedArea': recScenario.exactNeed,
      'maxExactNeedArea': scenarios['MAX']!.exactNeed,
      'minPurchaseArea': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseArea': recScenario.purchaseQuantity,
      'maxPurchaseArea': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}

