import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

CanonicalCalculatorContractResult calculateCanonicalGreenhouse(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(greenhouseSpecData);
  final length = (inputs['length'] ?? defaultFor(spec, 'length', 6))
      .clamp(2.0, 12.0)
      .toDouble();
  final width = (inputs['width'] ?? defaultFor(spec, 'width', 3))
      .clamp(2.0, 6.0)
      .toDouble();
  final height = (inputs['height'] ?? defaultFor(spec, 'height', 2.1))
      .clamp(1.8, 3.0)
      .toDouble();
  final roofType = (inputs['roofType'] ?? defaultFor(spec, 'roofType', 0))
      .round()
      .clamp(0, 1)
      .toInt();
  final polycarbonateThickness =
      (inputs['polycarbonateThickness'] ??
              defaultFor(spec, 'polycarbonateThickness', 6))
          .round()
          .clamp(4, 10)
          .toInt();
  final archStep = (inputs['archStep'] ?? defaultFor(spec, 'archStep', 0.65))
      .clamp(0.5, 1.05)
      .toDouble();
  final doorCount = (inputs['doorCount'] ?? defaultFor(spec, 'doorCount', 2))
      .round()
      .clamp(1, 2)
      .toInt();
  final ventCount = (inputs['ventCount'] ?? defaultFor(spec, 'ventCount', 2))
      .round()
      .clamp(0, 6)
      .toInt();
  final foundationType =
      (inputs['foundationType'] ?? defaultFor(spec, 'foundationType', 1))
          .round()
          .clamp(0, 3)
          .toInt();

  final sheetArea =
      spec.materialRule<num>('polycarbonate_sheet_width_m').toDouble() *
      spec.materialRule<num>('polycarbonate_sheet_length_m').toDouble();
  final polyArea =
      roofType == 0
          ? math.pi * width * length / 2 + math.pi * width * width / 4
          : _gablePolyArea(length, width, height);
  final polyAreaWithReserve =
      polyArea * spec.materialRule<num>('polycarbonate_reserve').toDouble();
  final polySheets = (polyAreaWithReserve / sheetArea).ceil();

  final archCount = (length / archStep).ceil() + 1;
  final archLengthM =
      roofType == 0 ? math.pi * width / 2 : _gableRafterLength(width, height) * 2;
  final doorAreaTotal =
      doorCount *
      spec.materialRule<num>('door_width_m').toDouble() *
      spec.materialRule<num>('door_height_m').toDouble();
  final doorFrameTotalM =
      doorCount *
      (2 *
              (spec.materialRule<num>('door_width_m').toDouble() +
                  spec.materialRule<num>('door_height_m').toDouble()) +
          math.sqrt(
            math.pow(spec.materialRule<num>('door_width_m').toDouble(), 2) +
                math.pow(spec.materialRule<num>('door_height_m').toDouble(), 2),
          ));
  final ventFrameTotalM =
      ventCount *
      2 *
      (spec.materialRule<num>('vent_width_m').toDouble() +
          spec.materialRule<num>('vent_height_m').toDouble());
  final totalFrameLengthM =
      archCount * archLengthM +
      spec.materialRule<num>('longitudinal_purlins_count').toDouble() * length +
      doorFrameTotalM +
      width / 10.0;
  final frameProfilePieces =
      (totalFrameLengthM *
              spec.materialRule<num>('frame_profile_reserve').toDouble() /
              spec.materialRule<num>('frame_profile_pack_m').toDouble())
          .ceil();

  final thermalWashersTotal =
      (polyArea * spec.materialRule<num>('thermal_washers_per_m2').toDouble())
          .ceil();
  final thermalWasherPacks =
      (thermalWashersTotal /
              spec.materialRule<num>('thermal_washer_pack').toDouble())
          .ceil();
  final hSeamCount = math.max(0, polySheets - 2);
  final hProfilePieces =
      (hSeamCount *
              spec.materialRule<num>('polycarbonate_sheet_length_m').toDouble() /
              spec.materialRule<num>('h_profile_length_m').toDouble())
          .ceil();
  final upProfilePieces = polySheets * 2;
  final ventHinges = ventCount * 2;
  final ventLatches = ventCount;
  final perimeter = 2 * (length + width);
  final woodBeamLengthM =
      foundationType == 1
          ? (perimeter +
                  width *
                      math.max(
                        0,
                        (length /
                                    spec
                                        .materialRule<num>(
                                          'wood_beam_crossbeam_step_m',
                                        )
                                        .toDouble())
                                .ceil() -
                            1,
                      )) *
              spec.materialRule<num>('wood_beam_reserve').toDouble()
          : 0.0;
  final woodBeamPieces =
      woodBeamLengthM > 0
          ? (woodBeamLengthM /
                  spec.materialRule<num>('wood_beam_pack_m').toDouble())
              .ceil()
          : 0;
  final screwPileCount =
      foundationType == 2
          ? math.max(
            spec.materialRule<num>('screw_pile_corners_min').round(),
            (perimeter / spec.materialRule<num>('screw_pile_step_m').toDouble())
                .ceil(),
          )
          : 0;
  final concreteM3 =
      foundationType == 3
          ? perimeter *
              spec.materialRule<num>('concrete_strip_width_m').toDouble() *
              spec.materialRule<num>('concrete_strip_depth_m').toDouble() *
              spec.materialRule<num>('concrete_reserve').toDouble()
          : 0.0;
  final anchorCount =
      foundationType == 0
          ? (perimeter / spec.materialRule<num>('anchor_step_m').toDouble())
              .ceil()
          : 0;
  final screwsTotal =
      (polyArea * spec.materialRule<num>('self_tapping_screws_per_m2').toDouble())
          .ceil();
  final sealingTapeRolls =
      ((hSeamCount *
                  spec
                      .materialRule<num>('polycarbonate_sheet_length_m')
                      .toDouble() *
                  spec.materialRule<num>('sealing_tape_per_seam_factor').toDouble() +
              polySheets *
                  2 *
                  spec
                      .materialRule<num>('polycarbonate_sheet_length_m')
                      .toDouble()) /
              25)
          .ceil();

  final scenarios = _buildScenarios(
    spec,
    inputs,
    primaryQuantity: polySheets.toDouble(),
    packageLabel: 'polycarbonate-sheet',
    unit: 'лист',
    extraAssumptions: [
      'roofType:$roofType',
      'thickness:$polycarbonateThickness',
      'foundationType:$foundationType',
    ],
  );

  final warnings = <String>[];
  if (height < spec.warningRule<num>('low_height_threshold_m').toDouble()) {
    warnings.add('Высота ниже 2 м неудобна для обслуживания теплицы');
  }
  if (foundationType == 0 &&
      length > spec.warningRule<num>('no_foundation_max_length_m').toDouble()) {
    warnings.add('Для теплицы длиннее 4 м рекомендуется фундамент');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name:
          'Поликарбонат сотовый $polycarbonateThickness мм (универсальный), лист 2.1 × 6 м',
      quantity: polySheets.toDouble(),
      unit: 'лист',
      withReserve: polySheets.toDouble(),
      purchaseQty: polySheets.toDouble(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name:
          'Профиль каркаса ${spec.materialRule<String>('frame_profile_section_label')} (6 м)',
      quantity: frameProfilePieces.toDouble(),
      unit: 'шт',
      withReserve: frameProfilePieces.toDouble(),
      purchaseQty: frameProfilePieces.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Термошайбы для поликарбоната',
      quantity: thermalWashersTotal.toDouble(),
      unit: 'шт',
      withReserve: thermalWashersTotal.toDouble(),
      purchaseQty: thermalWasherPacks.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы для оцинковки',
      quantity: screwsTotal.toDouble(),
      unit: 'шт',
      withReserve: screwsTotal.toDouble(),
      purchaseQty: screwsTotal.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'H-профиль соединительный (6 м)',
      quantity: hProfilePieces.toDouble(),
      unit: 'шт',
      withReserve: hProfilePieces.toDouble(),
      purchaseQty: hProfilePieces.toDouble(),
      category: 'Профили',
    ),
    CanonicalMaterialResult(
      name: 'UP-профиль торцевой (2.1 м)',
      quantity: upProfilePieces.toDouble(),
      unit: 'шт',
      withReserve: upProfilePieces.toDouble(),
      purchaseQty: upProfilePieces.toDouble(),
      category: 'Профили',
    ),
    CanonicalMaterialResult(
      name: 'Уплотнительная лента (25 м рулон)',
      quantity: sealingTapeRolls.toDouble(),
      unit: 'рулон',
      withReserve: sealingTapeRolls.toDouble(),
      purchaseQty: sealingTapeRolls.toDouble(),
      category: 'Герметизация',
    ),
    CanonicalMaterialResult(
      name: 'Дверь распашная 90×185 см (комплект петли + ручка)',
      quantity: doorCount.toDouble(),
      unit: 'компл.',
      withReserve: doorCount.toDouble(),
      purchaseQty: doorCount.toDouble(),
      category: 'Проёмы',
    ),
    if (ventCount > 0) ...[
      CanonicalMaterialResult(
        name: 'Форточка 60×90 см (рамка)',
        quantity: ventCount.toDouble(),
        unit: 'шт',
        withReserve: ventCount.toDouble(),
        purchaseQty: ventCount.toDouble(),
        category: 'Проёмы',
      ),
      CanonicalMaterialResult(
        name: 'Петли для форточек',
        quantity: ventHinges.toDouble(),
        unit: 'шт',
        withReserve: ventHinges.toDouble(),
        purchaseQty: ventHinges.toDouble(),
        category: 'Фурнитура',
      ),
      CanonicalMaterialResult(
        name: 'Шпингалет / автомат для форточки',
        quantity: ventLatches.toDouble(),
        unit: 'шт',
        withReserve: ventLatches.toDouble(),
        purchaseQty: ventLatches.toDouble(),
        category: 'Фурнитура',
      ),
    ],
    if (foundationType == 1)
      CanonicalMaterialResult(
        name: '${spec.materialRule<String>('wood_beam_section_label')} антисептированный (6 м)',
        quantity: woodBeamPieces.toDouble(),
        unit: 'шт',
        withReserve: woodBeamPieces.toDouble(),
        purchaseQty: woodBeamPieces.toDouble(),
        category: 'Фундамент',
      ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': roundValue(length, 3),
      'width': roundValue(width, 3),
      'height': roundValue(height, 3),
      'roofType': roofType.toDouble(),
      'polycarbonateThickness': polycarbonateThickness.toDouble(),
      'archStep': roundValue(archStep, 3),
      'doorCount': doorCount.toDouble(),
      'ventCount': ventCount.toDouble(),
      'foundationType': foundationType.toDouble(),
      'polyArea': roundValue(polyArea, 3),
      'polyAreaWithReserve': roundValue(polyAreaWithReserve, 3),
      'polySheets': polySheets.toDouble(),
      'archCount': archCount.toDouble(),
      'archLengthM': roundValue(archLengthM, 3),
      'totalFrameLengthM': roundValue(totalFrameLengthM, 3),
      'frameProfilePieces': frameProfilePieces.toDouble(),
      'thermalWashersTotal': thermalWashersTotal.toDouble(),
      'thermalWasherPacks': thermalWasherPacks.toDouble(),
      'hSeamCount': hSeamCount.toDouble(),
      'hProfilePieces': hProfilePieces.toDouble(),
      'upProfilePieces': upProfilePieces.toDouble(),
      'doorAreaTotal': roundValue(doorAreaTotal, 3),
      'doorFrameTotalM': roundValue(doorFrameTotalM, 3),
      'ventFrameTotalM': roundValue(ventFrameTotalM, 3),
      'ventHinges': ventHinges.toDouble(),
      'ventLatches': ventLatches.toDouble(),
      'perimeter': roundValue(perimeter, 3),
      'woodBeamLengthM': roundValue(woodBeamLengthM, 3),
      'woodBeamPieces': woodBeamPieces.toDouble(),
      'screwPileCount': screwPileCount.toDouble(),
      'concreteM3': roundValue(concreteM3, 3),
      'anchorCount': anchorCount.toDouble(),
      'screwsTotal': screwsTotal.toDouble(),
      'sealingTapeRolls': sealingTapeRolls.toDouble(),
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

double _gableRafterLength(double width, double height) {
  final wallHeight = math.min(1.5, height);
  return math.sqrt(math.pow(width / 2, 2) + math.pow(height - wallHeight, 2));
}

double _gablePolyArea(double length, double width, double height) {
  final wallHeight = math.min(1.5, height);
  final roofArea = 2 * _gableRafterLength(width, height) * length;
  final wallArea = 2 * length * wallHeight + 2 * width * wallHeight;
  final gables = width * math.max(0, height - wallHeight);
  return roofArea + wallArea + gables;
}

Map<String, CanonicalScenarioResult> _buildScenarios(
  SpecReader spec,
  Map<String, double> inputs, {
  required double primaryQuantity,
  required String packageLabel,
  required String unit,
  List<String> extraAssumptions = const [],
}) {
  final scenarios = <String, CanonicalScenarioResult>{};
  final accuracyMult = accuracyPrimaryMultiplier(
    'generic',
    parseAccuracyMode(inputs),
  );
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(primaryQuantity * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'packaging:$packageLabel',
        ...extraAssumptions,
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: unit,
      ),
    );
  }
  return scenarios;
}
