import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */



const Map<int, String> _insulationTypeLabels = {
  0: 'Минвата плиты',
  1: 'Минвата рулоны',
  2: 'ЭППС',
};

const Map<int, String> _vapourLabels = {
  0: 'Без пароизоляции',
  1: 'Стандартная',
  2: 'Армированная',
};


bool hasCanonicalAtticInputs(Map<String, double> inputs) {
  return inputs.containsKey('roofArea') ||
      inputs.containsKey('insulationType') ||
      inputs.containsKey('finishType');
}

Map<String, double> normalizeLegacyAtticInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['roofArea'] = (inputs['roofArea'] ?? 60).toDouble();
  normalized['insulationThickness'] = (inputs['insulationThickness'] ?? 200).toDouble();
  normalized['insulationType'] = (inputs['insulationType'] ?? 0).toDouble();
  normalized['finishType'] = (inputs['finishType'] ?? 0).toDouble();
  normalized['withVapourBarrier'] = (inputs['withVapourBarrier'] ?? 1).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalAttic(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(atticSpecData);

  final normalized = hasCanonicalAtticInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyAtticInputs(inputs);

  final roofArea = math.max(10.0, math.min(300.0, (normalized['roofArea'] ?? defaultFor(spec, 'roofArea', 60)).toDouble()));
  final insulationThickness = math.max(150.0, math.min(250.0, (normalized['insulationThickness'] ?? defaultFor(spec, 'insulationThickness', 200)).toDouble()));
  final insulationType = (normalized['insulationType'] ?? defaultFor(spec, 'insulationType', 0)).round().clamp(0, 2);
  final finishType = (normalized['finishType'] ?? defaultFor(spec, 'finishType', 0)).round().clamp(0, 2);
  final withVapourBarrier = (normalized['withVapourBarrier'] ?? defaultFor(spec, 'withVapourBarrier', 1)).round().clamp(0, 2);

  // Insulation
  final plateThickness = (spec.materialRule<Map>('plate_thickness')['$insulationType'] as num?)?.toDouble() ?? 100;
  final plateArea = (spec.materialRule<Map>('plate_area')['$insulationType'] as num?)?.toDouble() ?? 0.6;
  final layerCount = (insulationThickness / plateThickness).ceil();
  final insPlates = (roofArea * spec.materialRule<num>('plate_reserve').toDouble() / plateArea).ceil() * layerCount;
  final windRolls = (roofArea * spec.materialRule<num>('membrane_reserve').toDouble() / spec.materialRule<num>('wind_membrane_roll').toDouble()).ceil();
  final vbRolls = withVapourBarrier > 0 ? (roofArea * spec.materialRule<num>('membrane_reserve').toDouble() / spec.materialRule<num>('vapor_roll').toDouble()).ceil() : 0;
  final tapeRolls = (roofArea / spec.materialRule<num>('tape_area_coeff').toDouble()).ceil();

  // Finish: wood
  var panels = 0;
  var battenPcs = 0;
  var antisepticCans = 0;

  // Finish: GKL
  var gklSheets = 0;
  var profilePcs = 0;
  var puttyBags = 0;

  if (finishType == 0) {
    panels = (roofArea * spec.materialRule<num>('panel_reserve').toDouble() / spec.materialRule<num>('panel_area').toDouble()).ceil();
    battenPcs = (roofArea / spec.materialRule<num>('batten_pitch').toDouble()).ceil();
    antisepticCans = (roofArea * 0.15 * 1.1 / 5).ceil();
  } else if (finishType == 1) {
    gklSheets = (roofArea * spec.materialRule<num>('gkl_reserve').toDouble() / spec.materialRule<num>('gkl_sheet').toDouble()).ceil();
    profilePcs = (roofArea / spec.materialRule<num>('profile_step').toDouble() / 3).ceil();
    puttyBags = (roofArea * spec.materialRule<num>('putty_kg_per_m2').toDouble() / spec.materialRule<num>('putty_bag').toDouble()).ceil();
  }

  // Scenarios
  final basePrimary = insPlates;
  const packageLabel = 'insulation-plate';
  const packageUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'insulationType:$insulationType',
        'insulationThickness:${insulationThickness.round()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
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
  if (insulationThickness < spec.warningRule<num>('thin_insulation_threshold_mm').toDouble()) {
    warnings.add('Толщина утеплителя менее 200 мм — рекомендуется увеличить для средней полосы России');
  }
  if (withVapourBarrier == 0) {
    warnings.add('Без пароизоляции утеплитель подвержен намоканию и потере свойств');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_insulationTypeLabels[insulationType]} (${insulationThickness.round()} мм, $layerCount сл.)',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Утепление',
    ),
    CanonicalMaterialResult(
      name: 'Ветрозащитная мембрана (70 м²)',
      quantity: windRolls.toDouble(),
      unit: 'рулонов',
      withReserve: windRolls.toDouble(),
      purchaseQty: windRolls.toDouble(),
      category: 'Мембраны',
    ),
  ];

  if (withVapourBarrier > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Пароизоляция ${_vapourLabels[withVapourBarrier]} (70 м²)',
      quantity: vbRolls.toDouble(),
      unit: 'рулонов',
      withReserve: vbRolls.toDouble(),
      purchaseQty: vbRolls.toDouble(),
      category: 'Мембраны',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Скотч соединительный (25 м)',
    quantity: tapeRolls.toDouble(),
    unit: 'рулонов',
    withReserve: tapeRolls.toDouble(),
    purchaseQty: tapeRolls.toDouble(),
    category: 'Расходные',
  ));

  if (finishType == 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Вагонка деревянная',
        quantity: panels.toDouble(),
        unit: 'шт',
        withReserve: panels.toDouble(),
        purchaseQty: panels.toDouble(),
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'Обрешётка (рейки)',
        quantity: battenPcs.toDouble(),
        unit: 'шт',
        withReserve: battenPcs.toDouble(),
        purchaseQty: battenPcs.toDouble(),
        category: 'Каркас',
      ),
      CanonicalMaterialResult(
        name: 'Антисептик (5 л)',
        quantity: antisepticCans.toDouble(),
        unit: 'канистр',
        withReserve: antisepticCans.toDouble(),
        purchaseQty: antisepticCans.toDouble(),
        category: 'Защита',
      ),
    ]);
  } else if (finishType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'ГКЛ (3 м²)',
        quantity: gklSheets.toDouble(),
        unit: 'листов',
        withReserve: gklSheets.toDouble(),
        purchaseQty: gklSheets.toDouble(),
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'Профиль направляющий',
        quantity: profilePcs.toDouble(),
        unit: 'шт',
        withReserve: profilePcs.toDouble(),
        purchaseQty: profilePcs.toDouble(),
        category: 'Каркас',
      ),
      CanonicalMaterialResult(
        name: 'Шпаклёвка (25 кг)',
        quantity: puttyBags.toDouble(),
        unit: 'мешков',
        withReserve: puttyBags.toDouble(),
        purchaseQty: puttyBags.toDouble(),
        category: 'Отделка',
      ),
    ]);
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roofArea': roundValue(roofArea, 3),
      'insulationThickness': insulationThickness,
      'insulationType': insulationType.toDouble(),
      'finishType': finishType.toDouble(),
      'withVapourBarrier': withVapourBarrier.toDouble(),
      'layerCount': layerCount.toDouble(),
      'insPlates': insPlates.toDouble(),
      'windRolls': windRolls.toDouble(),
      'vbRolls': vbRolls.toDouble(),
      'tapeRolls': tapeRolls.toDouble(),
      'panels': panels.toDouble(),
      'battenPcs': battenPcs.toDouble(),
      'antisepticCans': antisepticCans.toDouble(),
      'gklSheets': gklSheets.toDouble(),
      'profilePcs': profilePcs.toDouble(),
      'puttyBags': puttyBags.toDouble(),
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
