import 'dart:math' as math;

import '../generated/canonical_specs.g.dart' show defaultFactorTable;
import '../generated/sound_insulation_spec_v3.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

CanonicalCalculatorContractResult calculateCanonicalSoundInsulation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(soundInsulationSpecV3Data);

  final area = math.max(
    1.0,
    math.min(500.0, inputs['area'] ?? defaultFor(spec, 'area', 30)),
  );
  final system = (inputs['system'] ?? defaultFor(spec, 'system', 0))
      .round()
      .clamp(0, 3);
  final surfaceType = system == 2 ? 1 : (system == 3 ? 2 : 0);
  final enteredPerimeter = math.max(
    0.0,
    math.min(2000.0, inputs['perimeter'] ?? defaultFor(spec, 'perimeter', 0)),
  );
  final perimeterEstimated = enteredPerimeter <= 0;
  final perim = perimeterEstimated ? math.sqrt(area) * 4 : enteredPerimeter;
  final screedThicknessMm = math.max(
    30.0,
    math.min(
      100.0,
      inputs['screedThicknessMm'] ?? defaultFor(spec, 'screedThicknessMm', 50),
    ),
  );
  final acousticPlatesPerPack = math.max(
    1,
    math.min(
      50,
      (inputs['acousticPlatesPerPack'] ??
              defaultFor(
                spec,
                'acousticPlatesPerPack',
                spec.packagingRule<num>('package_size').toDouble(),
              ))
          .round(),
    ),
  );

  final materials = <CanonicalMaterialResult>[];
  var primaryQtyRaw = 0.0;
  var primaryUnit = '\u0448\u0442';
  var primaryLabel = 'sound-insulation';
  var primaryMaterialIndex = -1;

  // System 0: Basic GKL + Rockwool
  if (system == 0) {
    final rockwoolPlates =
        (area *
                spec.materialRule<num>('rockwool_reserve').toDouble() /
                spec.materialRule<num>('rockwool_plate').toDouble())
            .ceil();
    final gklSheets =
        (area *
                spec.materialRule<num>('rockwool_reserve').toDouble() *
                spec.materialRule<num>('gkl_reserve_2layers').toDouble() /
                spec.materialRule<num>('gkl_sheet').toDouble())
            .ceil();
    final ppPcs =
        ((area / spec.materialRule<num>('pp_spacing').toDouble()) *
                spec.materialRule<num>('pp_length').toDouble() *
                spec.materialRule<num>('rockwool_reserve').toDouble() /
                spec.materialRule<num>('pp_length').toDouble())
            .ceil();
    final vibro =
        (area *
                spec.materialRule<num>('vibro_per_m2').toDouble() *
                spec.materialRule<num>('vibro_reserve').toDouble())
            .ceil();
    final vibroTape =
        ((area / spec.materialRule<num>('pp_spacing').toDouble()) *
                spec.materialRule<num>('pp_length').toDouble() *
                spec.materialRule<num>('rockwool_reserve').toDouble() /
                spec.materialRule<num>('vibro_tape_roll').toDouble())
            .ceil();
    final screws = (gklSheets * 25 / 200).ceil();

    primaryQtyRaw = area / spec.materialRule<num>('rockwool_plate').toDouble();
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'rockwool-plate';
    primaryMaterialIndex = materials.length;

    materials.addAll([
      CanonicalMaterialResult(
        name: 'Акустическая минеральная плита 600×1000×50 мм',
        quantity: rockwoolPlates.toDouble(),
        unit: '\u0448\u0442',
        withReserve: rockwoolPlates.toDouble(),
        purchaseQty: rockwoolPlates.toDouble(),
        category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
      ),
      CanonicalMaterialResult(
        name: 'Гипсокартонные листы (ГКЛ) 1200×2500×12,5 мм, два слоя',
        quantity: gklSheets.toDouble(),
        unit: '\u0448\u0442',
        withReserve: gklSheets.toDouble(),
        purchaseQty: gklSheets.toDouble(),
        category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
      ),
      CanonicalMaterialResult(
        name: 'Потолочный профиль ПП 60×27×3000 мм',
        quantity: ppPcs.toDouble(),
        unit: '\u0448\u0442',
        withReserve: ppPcs.toDouble(),
        purchaseQty: ppPcs.toDouble(),
        category: '\u041a\u0430\u0440\u043a\u0430\u0441',
      ),
      CanonicalMaterialResult(
        name: 'Виброподвес для профиля 60×27 мм',
        quantity: vibro.toDouble(),
        unit: '\u0448\u0442',
        withReserve: vibro.toDouble(),
        purchaseQty: vibro.toDouble(),
        category: '\u041a\u0440\u0435\u043f\u0451\u0436',
      ),
      CanonicalMaterialResult(
        name: 'Вибролента 50 мм (30 м)',
        quantity: vibroTape.toDouble(),
        unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
        withReserve: vibroTape.toDouble(),
        purchaseQty: vibroTape.toDouble(),
        category: '\u0418\u0437\u043e\u043b\u044f\u0446\u0438\u044f',
      ),
      CanonicalMaterialResult(
        name:
            'Чёрные саморезы для гипсокартона по металлу 3,5×25 и 3,5×35 мм (по 200 шт)',
        quantity: screws.toDouble(),
        unit: '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a',
        withReserve: screws.toDouble(),
        purchaseQty: screws.toDouble(),
        category: '\u041a\u0440\u0435\u043f\u0451\u0436',
      ),
    ]);
  }

  // System 1: ZIPS panels
  if (system == 1) {
    final zipsPanels =
        (area *
                spec.materialRule<num>('zips_reserve').toDouble() /
                spec.materialRule<num>('zips_plate').toDouble())
            .ceil();
    final gklOverlay =
        (area *
                spec.materialRule<num>('zips_reserve').toDouble() /
                spec.materialRule<num>('gkl_sheet').toDouble())
            .ceil();

    primaryQtyRaw = area / spec.materialRule<num>('zips_plate').toDouble();
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'zips-panel';
    primaryMaterialIndex = materials.length;

    materials.addAll([
      CanonicalMaterialResult(
        name: 'Звукоизоляционные сэндвич-панели (ЗИПС) 1200×600 мм',
        quantity: zipsPanels.toDouble(),
        unit: '\u0448\u0442',
        withReserve: zipsPanels.toDouble(),
        purchaseQty: zipsPanels.toDouble(),
        category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
      ),
      CanonicalMaterialResult(
        name:
            '\u041a\u043e\u043c\u043f\u043b\u0435\u043a\u0442 \u043a\u0440\u0435\u043f\u0435\u0436\u0430, \u043f\u043e\u0441\u0442\u0430\u0432\u043b\u044f\u0435\u043c\u044b\u0439 \u0441 \u043f\u0430\u043d\u0435\u043b\u044c\u044e \u0417\u0418\u041f\u0421',
        quantity: zipsPanels.toDouble(),
        unit: '\u043a\u043e\u043c\u043f\u043b\u0435\u043a\u0442\u043e\u0432',
        withReserve: zipsPanels.toDouble(),
        purchaseQty: zipsPanels.toDouble(),
        category: '\u041a\u0440\u0435\u043f\u0451\u0436',
      ),
      CanonicalMaterialResult(
        name: 'Гипсокартонные листы (ГКЛ) 1200×2500×12,5 мм для облицовки',
        quantity: gklOverlay.toDouble(),
        unit: '\u0448\u0442',
        withReserve: gklOverlay.toDouble(),
        purchaseQty: gklOverlay.toDouble(),
        category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
      ),
    ]);
  }

  // System 2: Floating floor
  if (system == 2) {
    final mats =
        (area *
                spec.materialRule<num>('float_reserve').toDouble() /
                spec.materialRule<num>('float_mat_roll').toDouble())
            .ceil();
    final dampTape =
        (perim / spec.materialRule<num>('damp_tape_roll').toDouble()).ceil();
    final screedBags =
        (area *
                (screedThicknessMm / 1000) *
                spec.materialRule<num>('screed_density').toDouble() /
                spec.materialRule<num>('screed_bag').toDouble())
            .ceil();

    primaryQtyRaw = area / spec.materialRule<num>('float_mat_roll').toDouble();
    primaryUnit = '\u0440\u0443\u043b\u043e\u043d\u043e\u0432';
    primaryLabel = 'float-mat';
    primaryMaterialIndex = materials.length;

    materials.addAll([
      CanonicalMaterialResult(
        name:
            'Рулонный звукоизоляционный материал под плавающую стяжку (10 м²)',
        quantity: mats.toDouble(),
        unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
        withReserve: mats.toDouble(),
        purchaseQty: mats.toDouble(),
        category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
      ),
      CanonicalMaterialResult(
        name: 'Кромочная демпферная лента (20 м)',
        quantity: dampTape.toDouble(),
        unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
        withReserve: dampTape.toDouble(),
        purchaseQty: dampTape.toDouble(),
        category: '\u0418\u0437\u043e\u043b\u044f\u0446\u0438\u044f',
      ),
      CanonicalMaterialResult(
        name: 'Сухая смесь для стяжки (50 кг)',
        quantity: screedBags.toDouble(),
        unit: '\u043c\u0435\u0448\u043a\u043e\u0432',
        withReserve: screedBags.toDouble(),
        purchaseQty: screedBags.toDouble(),
        category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
      ),
    ]);
  }

  // System 3: Acoustic ceiling
  if (system == 3) {
    final rockwoolPlates =
        (area *
                spec.materialRule<num>('rockwool_reserve').toDouble() /
                spec.materialRule<num>('rockwool_plate').toDouble())
            .ceil();
    final gklSheets =
        (area *
                spec.materialRule<num>('rockwool_reserve').toDouble() *
                spec.materialRule<num>('gkl_reserve_2layers').toDouble() /
                spec.materialRule<num>('gkl_sheet').toDouble())
            .ceil();
    final vibro =
        (area *
                spec.materialRule<num>('vibro_per_m2').toDouble() *
                spec.materialRule<num>('vibro_reserve').toDouble())
            .ceil();

    primaryQtyRaw = area / spec.materialRule<num>('rockwool_plate').toDouble();
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'acoustic-ceiling';
    primaryMaterialIndex = materials.length;

    materials.addAll([
      CanonicalMaterialResult(
        name: 'Акустическая минеральная плита 600×1000×50 мм',
        quantity: rockwoolPlates.toDouble(),
        unit: '\u0448\u0442',
        withReserve: rockwoolPlates.toDouble(),
        purchaseQty: rockwoolPlates.toDouble(),
        category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
      ),
      CanonicalMaterialResult(
        name: 'Гипсокартонные листы (ГКЛ) 1200×2500×12,5 мм, два слоя',
        quantity: gklSheets.toDouble(),
        unit: '\u0448\u0442',
        withReserve: gklSheets.toDouble(),
        purchaseQty: gklSheets.toDouble(),
        category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
      ),
      CanonicalMaterialResult(
        name: 'Виброподвес для акустического потолка',
        quantity: vibro.toDouble(),
        unit: '\u0448\u0442',
        withReserve: vibro.toDouble(),
        purchaseQty: vibro.toDouble(),
        category: '\u041a\u0440\u0435\u043f\u0451\u0436',
      ),
      CanonicalMaterialResult(
        name:
            'Чёрные саморезы для гипсокартона по металлу 3,5×25 и 3,5×35 мм (по 200 шт)',
        quantity: (gklSheets * 25 / 200).ceilToDouble(),
        unit: '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a',
        withReserve: (gklSheets * 25 / 200).ceilToDouble(),
        purchaseQty: (gklSheets * 25 / 200).ceilToDouble(),
        category: '\u041a\u0440\u0435\u043f\u0451\u0436',
      ),
    ]);
  }

  // Common: sealant + sealing tape
  final sealant =
      (perim * 2 / spec.materialRule<num>('sealant_per_perim').toDouble())
          .ceil();
  final sealTape =
      (perim *
              2 *
              spec.materialRule<num>('seal_tape_reserve').toDouble() /
              spec.materialRule<num>('seal_tape_roll').toDouble())
          .ceil();

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Невысыхающий акустический герметик, 280–310 мл',
      quantity: sealant.toDouble(),
      unit: '\u0442\u044e\u0431\u0438\u043a\u043e\u0432',
      withReserve: sealant.toDouble(),
      purchaseQty: sealant.toDouble(),
      category:
          '\u0413\u0435\u0440\u043c\u0435\u0442\u0438\u0437\u0430\u0446\u0438\u044f',
    ),
    CanonicalMaterialResult(
      name: 'Уплотнительная виброизоляционная лента (30 м)',
      quantity: sealTape.toDouble(),
      unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
      withReserve: sealTape.toDouble(),
      purchaseQty: sealTape.toDouble(),
      category:
          '\u0413\u0435\u0440\u043c\u0435\u0442\u0438\u0437\u0430\u0446\u0438\u044f',
    ),
  ]);

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  final accuracyMode = parseAccuracyMode(inputs);
  final accuracyMult = accuracyPrimaryMultiplier('insulation', accuracyMode);
  final isAcousticPlateSystem = system == 0 || system == 3;
  final packageSize = isAcousticPlateSystem
      ? acousticPlatesPerPack.toDouble()
      : 1.0;
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(primaryQtyRaw * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'surfaceType:$surfaceType',
        'system:$system',
        'packaging:$primaryLabel',
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
        packageLabel: primaryLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: primaryUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  if (primaryMaterialIndex >= 0) {
    final current = materials[primaryMaterialIndex];
    materials[primaryMaterialIndex] = CanonicalMaterialResult(
      name: current.name,
      quantity: recScenario.exactNeed,
      unit: current.unit,
      withReserve: recScenario.purchaseQuantity,
      purchaseQty: recScenario.purchaseQuantity,
      category: current.category,
    );
  }
  if (system == 1 && primaryMaterialIndex + 1 < materials.length) {
    final current = materials[primaryMaterialIndex + 1];
    materials[primaryMaterialIndex + 1] = CanonicalMaterialResult(
      name: current.name,
      quantity: recScenario.purchaseQuantity,
      unit: current.unit,
      withReserve: recScenario.purchaseQuantity,
      purchaseQty: recScenario.purchaseQuantity,
      category: current.category,
    );
  }

  final warnings = <String>[];
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add(
      '\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0444\u0435\u0441\u0441\u0438\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u043e\u043d\u0442\u0430\u0436',
    );
  }
  if (system == 1) {
    warnings.add(
      '\u0422\u0440\u0435\u0431\u043e\u0432\u0430\u043d\u0438\u044f \u043a \u043e\u0441\u043d\u043e\u0432\u0430\u043d\u0438\u044e, \u043a\u0440\u0435\u043f\u0435\u0436\u0443 \u0438 \u0434\u043e\u043f\u0443\u0441\u0442\u0438\u043c\u043e\u043c\u0443 \u043c\u043e\u043d\u0442\u0430\u0436\u0443 \u0417\u0418\u041f\u0421 \u043f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u043f\u043e \u0438\u043d\u0441\u0442\u0440\u0443\u043a\u0446\u0438\u0438 \u0432\u044b\u0431\u0440\u0430\u043d\u043d\u043e\u0439 \u043c\u043e\u0434\u0435\u043b\u0438',
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'surfaceType': surfaceType.toDouble(),
      'system': system.toDouble(),
      'perim': roundValue(perim, 3),
      'perimeterEstimated': perimeterEstimated ? 1.0 : 0.0,
      'screedThicknessMm': system == 2 ? roundValue(screedThicknessMm, 1) : 0.0,
      'primaryQty': roundValue(primaryQtyRaw * accuracyMult, 6),
      'acousticPlatesPerPack': isAcousticPlateSystem
          ? acousticPlatesPerPack.toDouble()
          : 0.0,
      'packagesNeeded': isAcousticPlateSystem
          ? recScenario.buyPlan.packagesCount.toDouble()
          : 0.0,
      'sealant': sealant.toDouble(),
      'sealTape': sealTape.toDouble(),
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
