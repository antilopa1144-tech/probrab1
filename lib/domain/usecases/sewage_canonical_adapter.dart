import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.05},
};

CanonicalCalculatorContractResult calculateCanonicalSewage(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(sewageSpecData);

  final residents = (inputs['residents'] ?? defaultFor(spec, 'residents', 4)).round().clamp(1, 20);
  final septikType = (inputs['septikType'] ?? defaultFor(spec, 'septikType', 0)).round().clamp(0, 2);
  final chambersCount = (inputs['chambersCount'] ?? defaultFor(spec, 'chambersCount', 2)).round().clamp(1, 3);
  final pipeLength = (inputs['pipeLength'] ?? defaultFor(spec, 'pipeLength', 10)).clamp(1.0, 50.0);
  final groundType = (inputs['groundType'] ?? defaultFor(spec, 'groundType', 0)).round().clamp(0, 2);

  /* ─── volume calculation ─── */
  final dailyVolumeLiters = residents * spec.materialRule<num>('liters_per_person_per_day').toDouble();
  final totalVolumeLiters = dailyVolumeLiters * spec.materialRule<num>('reserve_days').toDouble();
  final totalVolume = totalVolumeLiters / 1000;
  final volumePerChamber = totalVolume / chambersCount;

  /* ─── type-specific ─── */
  final materials = <CanonicalMaterialResult>[];
  double basePrimary;

  int totalRings = 0;
  int ringsPerChamber = 0;
  int bottomPlates = 0;
  int topPlates = 0;
  int covers = 0;
  int sealingRings = 0;
  int septicCount = 0;
  int sandBackfill = 0;
  int eurocubes = 0;

  if (septikType == 0) {
    // Concrete rings KS 10-9
    ringsPerChamber = (volumePerChamber / spec.materialRule<num>('ring_volume_m3').toDouble()).ceil();
    totalRings = ringsPerChamber * chambersCount;
    bottomPlates = chambersCount;
    topPlates = chambersCount;
    covers = chambersCount;
    sealingRings = totalRings;
    basePrimary = totalRings.toDouble();

    materials.addAll([
      CanonicalMaterialResult(
        name: 'Кольца ЖБ КС 10-9',
        quantity: totalRings.toDouble(),
        unit: 'шт',
        withReserve: totalRings.toDouble(),
        purchaseQty: totalRings.toInt(),
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Днища ПН-10',
        quantity: bottomPlates.toDouble(),
        unit: 'шт',
        withReserve: bottomPlates.toDouble(),
        purchaseQty: bottomPlates.toInt(),
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Плиты перекрытия ПП-10',
        quantity: topPlates.toDouble(),
        unit: 'шт',
        withReserve: topPlates.toDouble(),
        purchaseQty: topPlates.toInt(),
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Люки чугунные',
        quantity: covers.toDouble(),
        unit: 'шт',
        withReserve: covers.toDouble(),
        purchaseQty: covers.toInt(),
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Кольца уплотнительные',
        quantity: sealingRings.toDouble(),
        unit: 'шт',
        withReserve: sealingRings.toDouble(),
        purchaseQty: sealingRings.toInt(),
        category: 'Герметизация',
      ),
    ]);
  } else if (septikType == 1) {
    // Plastic septic
    septicCount = 1;
    sandBackfill = (totalVolume * spec.materialRule<num>('sand_backfill_factor').toDouble()).ceil();
    basePrimary = septicCount.toDouble();

    materials.addAll([
      CanonicalMaterialResult(
        name: 'Септик пластиковый',
        quantity: septicCount.toDouble(),
        unit: 'шт',
        withReserve: septicCount.toDouble(),
        purchaseQty: septicCount.toInt(),
        category: 'Ёмкость',
      ),
      CanonicalMaterialResult(
        name: 'Песок для обсыпки',
        quantity: sandBackfill.toDouble(),
        unit: 'м\u00b3',
        withReserve: sandBackfill.toDouble(),
        purchaseQty: sandBackfill.toInt(),
        category: 'Обсыпка',
      ),
    ]);
  } else {
    // Eurocubes
    eurocubes = (totalVolume / spec.materialRule<num>('eurocube_usable_m3').toDouble()).ceil();
    basePrimary = eurocubes.toDouble();

    materials.add(CanonicalMaterialResult(
      name: 'Еврокубы',
      quantity: eurocubes.toDouble(),
      unit: 'шт',
      withReserve: eurocubes.toDouble(),
      purchaseQty: eurocubes.toInt(),
      category: 'Ёмкость',
    ));
  }

  /* ─── common materials ─── */
  final pipeSections = (pipeLength * spec.materialRule<num>('pipe_reserve').toDouble() / spec.materialRule<num>('pipe_section_m').toDouble()).ceil();
  final elbows = spec.materialRule<num>('default_elbows').toDouble();
  final tees = spec.materialRule<num>('default_tees').toDouble();
  final gravel = ((spec.materialRule<Map>('gravel_by_ground')['$groundType'] as num?)?.toDouble() ?? 0).round();
  final geotextile = groundType >= 1 ? (totalVolume * spec.materialRule<num>('geotextile_factor').toDouble()).ceil() : 0;

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Труба ПВХ \u00f8110 (секции 3 м)',
      quantity: pipeSections.toDouble(),
      unit: 'шт',
      withReserve: pipeSections.toDouble(),
      purchaseQty: pipeSections.toInt(),
      category: 'Трубопровод',
    ),
    CanonicalMaterialResult(
      name: 'Отводы (колена)',
      quantity: elbows.toDouble(),
      unit: 'шт',
      withReserve: elbows.toDouble(),
      purchaseQty: elbows.toInt(),
      category: 'Фасонные',
    ),
    CanonicalMaterialResult(
      name: 'Тройники',
      quantity: tees.toDouble(),
      unit: 'шт',
      withReserve: tees.toDouble(),
      purchaseQty: tees.toInt(),
      category: 'Фасонные',
    ),
  ]);

  if (gravel > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Щебень фракция 20-40',
      quantity: gravel.toDouble(),
      unit: 'м\u00b3',
      withReserve: gravel.toDouble(),
      purchaseQty: gravel.toInt(),
      category: 'Дренаж',
    ));
  }

  if (geotextile > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Геотекстиль',
      quantity: geotextile.toDouble(),
      unit: 'м\u00b2',
      withReserve: geotextile.toDouble(),
      purchaseQty: geotextile.toInt(),
      category: 'Дренаж',
    ));
  }

  /* ─── scenarios ─── */
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;
    final purchaseQuantity = roundValue(packageCount.toDouble(), 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'septikType:$septikType',
        'chambersCount:$chambersCount',
        'groundType:$groundType',
        'packaging:sewage-unit',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'sewage-unit',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'шт',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ─── warnings ─── */
  final warnings = <String>[];
  if (groundType == 2) {
    warnings.add('Глинистый грунт \u2014 рекомендуется дренажный тоннель');
  }
  if (residents > spec.warningRule<num>('bio_treatment_residents_threshold').toDouble()) {
    warnings.add('Более 10 жителей \u2014 рекомендуется станция биологической очистки');
  }
  if (chambersCount == 1) {
    warnings.add('Одна камера \u2014 минимум, рекомендуется 2-3 камеры');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'residents': residents.toDouble(),
      'septikType': septikType.toDouble(),
      'chambersCount': chambersCount.toDouble(),
      'pipeLength': roundValue(pipeLength, 3),
      'groundType': groundType.toDouble(),
      'dailyVolumeLiters': dailyVolumeLiters,
      'totalVolumeLiters': totalVolumeLiters,
      'totalVolume': roundValue(totalVolume, 3),
      'volumePerChamber': roundValue(volumePerChamber, 3),
      'totalRings': totalRings.toDouble(),
      'ringsPerChamber': ringsPerChamber.toDouble(),
      'bottomPlates': bottomPlates.toDouble(),
      'topPlates': topPlates.toDouble(),
      'covers': covers.toDouble(),
      'sealingRings': sealingRings.toDouble(),
      'septicCount': septicCount.toDouble(),
      'sandBackfill': sandBackfill.toDouble(),
      'eurocubes': eurocubes.toDouble(),
      'pipeSections': pipeSections.toDouble(),
      'elbows': elbows.toDouble(),
      'tees': tees.toDouble(),
      'gravel': gravel.toDouble(),
      'geotextile': geotextile.toDouble(),
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
