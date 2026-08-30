import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

String _compactNumber(double value, [int decimals = 3]) {
  final fixed = value.toStringAsFixed(decimals);
  if (!fixed.contains('.')) return fixed;
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

double _reserveMultiplier(double percent) => 1 + percent / 100;

CanonicalMaterialResult _pieceMaterial({
  required String name,
  required String category,
  required double exactNeed,
  required double reservePercent,
}) {
  final withReserve = exactNeed * _reserveMultiplier(reservePercent);
  return CanonicalMaterialResult(
    name: name,
    quantity: roundValue(exactNeed, 6),
    unit: 'шт',
    withReserve: roundValue(withReserve, 6),
    purchaseQty: withReserve.ceilToDouble(),
    category: category,
  );
}

CanonicalMaterialResult _packagedMaterial({
  required String name,
  required String category,
  required double exactNeed,
  required double reservePercent,
  required double packageSize,
  required String unit,
  required String packageUnit,
}) {
  final withReserve = exactNeed * _reserveMultiplier(reservePercent);
  final packageCount = (withReserve / packageSize).ceil();
  return CanonicalMaterialResult(
    name: name,
    quantity: roundValue(exactNeed, 6),
    unit: unit,
    withReserve: roundValue(withReserve, 6),
    purchaseQty: roundValue(packageCount * packageSize, 6),
    category: category,
    packageInfo: {
      'count': packageCount,
      'size': packageSize,
      'packageUnit': packageUnit,
    },
  );
}

CanonicalMaterialResult _profileMaterial({
  required String name,
  required double exactLengthM,
  required double reservePercent,
  required double stockLengthM,
}) {
  final exactPieces = exactLengthM / stockLengthM;
  final withReservePieces = exactPieces * _reserveMultiplier(reservePercent);
  final purchasePieces = withReservePieces.ceil();
  return CanonicalMaterialResult(
    name: name,
    quantity: roundValue(exactPieces, 6),
    unit: 'шт',
    withReserve: roundValue(withReservePieces, 6),
    purchaseQty: purchasePieces.toDouble(),
    category: 'Каркас П 113',
    packageInfo: {
      'count': purchasePieces,
      'size': 1.0,
      'packageUnit': 'профилей',
    },
  );
}

CanonicalCalculatorContractResult calculateCanonicalDrywallCeiling(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(drywallCeilingSpecData);
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0))
      .round()
      .clamp(0, 1);
  final length = (inputs['length'] ?? defaultFor(spec, 'length', 5)).clamp(
    1.0,
    20.0,
  );
  final width = (inputs['width'] ?? defaultFor(spec, 'width', 4)).clamp(
    1.0,
    20.0,
  );
  final areaInput = (inputs['area'] ?? defaultFor(spec, 'area', 20)).clamp(
    1.0,
    500.0,
  );
  final perimeterInput =
      (inputs['perimeterM'] ?? defaultFor(spec, 'perimeterM', 18)).clamp(
        1.0,
        500.0,
      );
  final layersRaw = (inputs['layers'] ?? defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;
  final area = inputMode == 0 ? roundValue(length * width, 3) : areaInput;
  final perimeter = inputMode == 0 ? 2 * (length + width) : perimeterInput;

  final sheetWidthM =
      math.max(
        600,
        inputs['sheetWidthMm'] ?? defaultFor(spec, 'sheetWidthMm', 1200),
      ) /
      1000;
  final sheetLengthM =
      math.max(
        1200,
        inputs['sheetLengthMm'] ?? defaultFor(spec, 'sheetLengthMm', 2500),
      ) /
      1000;
  final sheetArea = sheetWidthM * sheetLengthM;
  final sheetReservePercent = math
      .max(
        0,
        inputs['sheetReservePercent'] ??
            defaultFor(spec, 'sheetReservePercent', 10),
      )
      .toDouble();
  final profileLengthM = math
      .max(2, inputs['profileLengthM'] ?? defaultFor(spec, 'profileLengthM', 3))
      .toDouble();
  final profileReservePercent = math
      .max(
        0,
        inputs['profileReservePercent'] ??
            defaultFor(spec, 'profileReservePercent', 5),
      )
      .toDouble();
  final fastenerReservePercent = math
      .max(
        0,
        inputs['fastenerReservePercent'] ??
            defaultFor(spec, 'fastenerReservePercent', 5),
      )
      .toDouble();
  final finishReservePercent = math
      .max(
        0,
        inputs['finishReservePercent'] ??
            defaultFor(spec, 'finishReservePercent', 10),
      )
      .toDouble();
  final tnScrewPackCount = math.max(
    1,
    (inputs['tnScrewPackCount'] ?? defaultFor(spec, 'tnScrewPackCount', 1000))
        .round(),
  );
  final lnScrewPackCount = math.max(
    1,
    (inputs['lnScrewPackCount'] ?? defaultFor(spec, 'lnScrewPackCount', 100))
        .round(),
  );
  final jointTapeRollM = math
      .max(
        1,
        inputs['jointTapeRollM'] ?? defaultFor(spec, 'jointTapeRollM', 50),
      )
      .toDouble();
  final sealingTapeRollM = math
      .max(
        1,
        inputs['sealingTapeRollM'] ?? defaultFor(spec, 'sealingTapeRollM', 30),
      )
      .toDouble();
  final separatingTapeRollM = math
      .max(
        1,
        inputs['separatingTapeRollM'] ??
            defaultFor(spec, 'separatingTapeRollM', 50),
      )
      .toDouble();
  final puttyBagKg = math
      .max(1, inputs['puttyBagKg'] ?? defaultFor(spec, 'puttyBagKg', 25))
      .toDouble();
  final primerCanL = math
      .max(0.5, inputs['primerCanL'] ?? defaultFor(spec, 'primerCanL', 5))
      .toDouble();

  final baseSheets = area * layers / sheetArea;
  final recSheets = baseSheets * _reserveMultiplier(sheetReservePercent);
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final reservePercent = scenarioName == 'MIN' ? 0.0 : sheetReservePercent;
    final exactNeed = roundValue(
      baseSheets * _reserveMultiplier(reservePercent),
      6,
    );
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'system:${spec.materialRule<String>('system_code')}.$layers',
        'input_mode:$inputMode',
        'layers:$layers',
        'sheet:${roundValue(sheetWidthM * 1000, 0)}x${roundValue(sheetLengthM * 1000, 0)}',
        scenarioName == 'MAX'
            ? 'no_hidden_max_reserve'
            : 'explicit_sheet_reserve',
      ],
      keyFactors: {
        'field_multiplier': roundValue(_reserveMultiplier(reservePercent), 6),
        'reserve_percent': roundValue(reservePercent, 3),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'gkl-sheet',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('sheet_unit'),
      ),
    );
  }

  double rate(String key) => spec.materialRule<num>(key).toDouble();
  final profileBaseM = area * rate('pp_m_per_m2');
  final totalProfileM =
      profileBaseM * _reserveMultiplier(profileReservePercent);
  final ppPcs = (totalProfileM / profileLengthM).ceil();
  final pnBaseM = perimeter;
  final pnM = pnBaseM * _reserveMultiplier(profileReservePercent);
  final pnPcs = (pnM / profileLengthM).ceil();
  final connectorsBase = area * rate('connector_per_m2');
  final extensionsBase = area * rate('extension_per_m2');
  final suspensionsBase = area * rate('suspension_per_m2');
  final lnScrewsBase = area * rate('ln_screws_per_m2');
  final anchorsBase = area * rate('anchors_per_m2');
  final perimeterDowelsBase = perimeter * rate('perimeter_dowels_per_m');
  final tn25Rate = layers == 2
      ? rate('tn25_per_m2_double')
      : rate('tn25_per_m2_single');
  final tn35Rate = layers == 2 ? rate('tn35_per_m2_double') : 0.0;
  final tn25Base = area * tn25Rate;
  final tn35Base = area * tn35Rate;
  final jointTapeBaseM = area * rate('joint_tape_m_per_m2');
  final puttyRate = layers == 2
      ? rate('putty_kg_per_m2_double')
      : rate('putty_kg_per_m2_single');
  final puttyBaseKg = area * puttyRate;
  final primerBaseL = area * rate('primer_l_per_m2');

  final connectors = _pieceMaterial(
    name: 'Одноуровневый соединитель для ПП 60×27',
    category: 'Каркас П 113',
    exactNeed: connectorsBase,
    reservePercent: fastenerReservePercent,
  );
  final extensions = _pieceMaterial(
    name: 'Удлинитель профилей ПП 60×27',
    category: 'Каркас П 113',
    exactNeed: extensionsBase,
    reservePercent: fastenerReservePercent,
  );
  final suspensions = _pieceMaterial(
    name: 'Подвес для профиля ПП 60×27',
    category: 'Каркас П 113',
    exactNeed: suspensionsBase,
    reservePercent: fastenerReservePercent,
  );
  final anchors = _pieceMaterial(
    name: 'Анкерный элемент подвеса к базовому потолку',
    category: 'Крепёж П 113',
    exactNeed: anchorsBase,
    reservePercent: fastenerReservePercent,
  );
  final perimeterDowels = _pieceMaterial(
    name: 'Крепёж профиля ПН 28×27 к стенам',
    category: 'Крепёж П 113',
    exactNeed: perimeterDowelsBase,
    reservePercent: fastenerReservePercent,
  );

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name:
          'Гипсовые плиты ${_compactNumber(sheetWidthM * 1000, 0)}×${_compactNumber(sheetLengthM * 1000, 0)} мм, $layers ${layers == 1 ? 'слой' : 'слоя'}',
      quantity: roundValue(baseSheets, 6),
      unit: 'шт',
      withReserve: roundValue(recSheets, 6),
      purchaseQty: scenarios['REC']!.purchaseQuantity,
      category: 'Обшивка П 113',
      packageInfo: {
        'count': scenarios['REC']!.buyPlan.packagesCount,
        'size': 1.0,
        'packageUnit': spec.packagingRule<String>('sheet_unit'),
      },
    ),
    _profileMaterial(
      name: 'Профиль ПП 60×27×${_compactNumber(profileLengthM * 1000, 0)} мм',
      exactLengthM: profileBaseM,
      reservePercent: profileReservePercent,
      stockLengthM: profileLengthM,
    ),
    _profileMaterial(
      name: 'Профиль ПН 28×27×${_compactNumber(profileLengthM * 1000, 0)} мм',
      exactLengthM: pnBaseM,
      reservePercent: profileReservePercent,
      stockLengthM: profileLengthM,
    ),
    _packagedMaterial(
      name: 'Уплотнительная лента (${_compactNumber(sealingTapeRollM, 1)} м)',
      category: 'Примыкания П 113',
      exactNeed: perimeter,
      reservePercent: finishReservePercent,
      packageSize: sealingTapeRollM,
      unit: 'м',
      packageUnit: spec.packagingRule<String>('roll_unit'),
    ),
    connectors,
    extensions,
    suspensions,
    _packagedMaterial(
      name: 'Шуруп LN для крепления ПП к подвесу ($lnScrewPackCount шт.)',
      category: 'Крепёж П 113',
      exactNeed: lnScrewsBase,
      reservePercent: fastenerReservePercent,
      packageSize: lnScrewPackCount.toDouble(),
      unit: 'шт',
      packageUnit: spec.packagingRule<String>('package_unit'),
    ),
    anchors,
    perimeterDowels,
    _packagedMaterial(
      name: 'Шуруп TN 25 ($tnScrewPackCount шт.)',
      category: 'Крепёж обшивки П 113',
      exactNeed: tn25Base,
      reservePercent: fastenerReservePercent,
      packageSize: tnScrewPackCount.toDouble(),
      unit: 'шт',
      packageUnit: spec.packagingRule<String>('package_unit'),
    ),
    if (layers == 2)
      _packagedMaterial(
        name: 'Шуруп TN 35 ($tnScrewPackCount шт.)',
        category: 'Крепёж обшивки П 113',
        exactNeed: tn35Base,
        reservePercent: fastenerReservePercent,
        packageSize: tnScrewPackCount.toDouble(),
        unit: 'шт',
        packageUnit: spec.packagingRule<String>('package_unit'),
      ),
    _packagedMaterial(
      name:
          'Бумажная армирующая лента (${_compactNumber(jointTapeRollM, 1)} м)',
      category: 'Заделка швов П 113',
      exactNeed: jointTapeBaseM,
      reservePercent: finishReservePercent,
      packageSize: jointTapeRollM,
      unit: 'м',
      packageUnit: spec.packagingRule<String>('roll_unit'),
    ),
    _packagedMaterial(
      name:
          'Разделительная лента (${_compactNumber(separatingTapeRollM, 1)} м)',
      category: 'Примыкания П 113',
      exactNeed: perimeter,
      reservePercent: finishReservePercent,
      packageSize: separatingTapeRollM,
      unit: 'м',
      packageUnit: spec.packagingRule<String>('roll_unit'),
    ),
    _packagedMaterial(
      name:
          'Гипсовая шпаклёвка для стыков (${_compactNumber(puttyBagKg, 1)} кг)',
      category: 'Заделка швов П 113',
      exactNeed: puttyBaseKg,
      reservePercent: finishReservePercent,
      packageSize: puttyBagKg,
      unit: 'кг',
      packageUnit: spec.packagingRule<String>('bag_unit'),
    ),
    _packagedMaterial(
      name: 'Грунтовка (${_compactNumber(primerCanL, 1)} л)',
      category: 'Заделка швов П 113',
      exactNeed: primerBaseL,
      reservePercent: finishReservePercent,
      packageSize: primerCanL,
      unit: 'л',
      packageUnit: spec.packagingRule<String>('can_unit'),
    ),
  ];

  final warnings = <String>[
    'Расчёт относится только к комплектной системе КНАУФ П 113.$layers на одноуровневом металлическом каркасе',
    'Расходы производителя рассчитаны для потолка ${_compactNumber(rate('reference_area_m2'), 0)} м² без потерь на раскрой и требуют уточнения по рабочим чертежам и проекту',
    'Светильники, люки, ниши, перепады уровня, криволинейные участки, усиления, изоляция и специальные швы не включены',
  ];
  if (inputMode == 1) {
    warnings.add(
      'В режиме площади периметр не вычисляется из условного квадрата — используйте фактическую сумму примыканий',
    );
  }
  if (layers == 2) {
    warnings.add(
      'Для П 113.2 рабочие чертежи требуют подвесы несущей способностью ${spec.warningRule<num>('double_layer_suspension_capacity_kn')} кН; шаг зависит от нагрузки',
    );
  }

  final lnScrewPacks =
      (lnScrewsBase *
              _reserveMultiplier(fastenerReservePercent) /
              lnScrewPackCount)
          .ceil();
  final tn25Packs =
      (tn25Base * _reserveMultiplier(fastenerReservePercent) / tnScrewPackCount)
          .ceil();
  final tn35Packs = layers == 2
      ? (tn35Base *
                _reserveMultiplier(fastenerReservePercent) /
                tnScrewPackCount)
            .ceil()
      : 0;

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'perimeter': roundValue(perimeter, 3),
      'perimeterM': roundValue(perimeter, 3),
      'inputMode': inputMode.toDouble(),
      'length': inputMode == 0 ? roundValue(length, 3) : 0,
      'width': inputMode == 0 ? roundValue(width, 3) : 0,
      'layers': layers.toDouble(),
      'systemVariant': layers.toDouble(),
      'sheetWidthMm': roundValue(sheetWidthM * 1000, 0),
      'sheetLengthMm': roundValue(sheetLengthM * 1000, 0),
      'sheetArea': roundValue(sheetArea, 6),
      'sheetReservePercent': roundValue(sheetReservePercent, 3),
      'baseSheets': roundValue(baseSheets, 6),
      'sheets': scenarios['REC']!.purchaseQuantity,
      'profileLengthM': roundValue(profileLengthM, 3),
      'profileReservePercent': roundValue(profileReservePercent, 3),
      'profileBaseM': roundValue(profileBaseM, 6),
      'totalProfileM': roundValue(totalProfileM, 6),
      'ppPcs': ppPcs.toDouble(),
      'pnM': roundValue(pnM, 6),
      'pnPcs': pnPcs.toDouble(),
      'suspCount': suspensions.purchaseQty ?? 0,
      'crabCount': connectors.purchaseQty ?? 0,
      'connectorCount': connectors.purchaseQty ?? 0,
      'extensionCount': extensions.purchaseQty ?? 0,
      'lnScrews': roundValue(lnScrewsBase, 6),
      'lnScrewPacks': lnScrewPacks.toDouble(),
      'tn25Screws': roundValue(tn25Base, 6),
      'tn25Packs': tn25Packs.toDouble(),
      'tn35Screws': roundValue(tn35Base, 6),
      'tn35Packs': tn35Packs.toDouble(),
      'screwsGKL': roundValue(tn25Base + tn35Base, 6),
      'screwsWithReserve': roundValue(
        (tn25Base + tn35Base) * _reserveMultiplier(fastenerReservePercent),
        6,
      ),
      'screwPacks': (tn25Packs + tn35Packs).toDouble(),
      'screwPackCount': tnScrewPackCount.toDouble(),
      'anchors': anchors.purchaseQty ?? 0,
      'perimeterDowels': perimeterDowels.purchaseQty ?? 0,
      'dowelCount':
          (anchors.purchaseQty ?? 0) + (perimeterDowels.purchaseQty ?? 0),
      'jointTapeM': roundValue(
        jointTapeBaseM * _reserveMultiplier(finishReservePercent),
        6,
      ),
      'sealingTapeM': roundValue(
        perimeter * _reserveMultiplier(finishReservePercent),
        6,
      ),
      'separatingTapeM': roundValue(
        perimeter * _reserveMultiplier(finishReservePercent),
        6,
      ),
      'puttyKg': roundValue(
        puttyBaseKg * _reserveMultiplier(finishReservePercent),
        6,
      ),
      'primerL': roundValue(
        primerBaseL * _reserveMultiplier(finishReservePercent),
        6,
      ),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': scenarios['REC']!.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'recPurchase': scenarios['REC']!.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
