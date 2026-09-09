import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

double _read(
  SpecReader spec,
  Map<String, double> inputs,
  String key,
  double fallback,
  double min,
  double max,
) =>
    (inputs[key] ?? defaultFor(spec, key, fallback)).clamp(min, max).toDouble();

int _readWhole(
  SpecReader spec,
  Map<String, double> inputs,
  String key,
  double fallback,
  int min,
  int max,
) => (inputs[key] ?? defaultFor(spec, key, fallback)).round().clamp(min, max);

Map<String, dynamic> _matchingRule(
  List<Map<String, dynamic>> rules,
  int equivalentResidents,
) {
  for (final rule in rules) {
    final maximum = (rule['max_equivalent_residents'] as num).toInt();
    if (equivalentResidents <= maximum) return rule;
  }
  if (rules.isEmpty) {
    throw StateError('[sewage] В canonical-спеке не заданы правила расчёта');
  }
  return rules.last;
}

/// Предварительная оценка рабочего объёма септика или проверка проектного
/// суточного притока и выбранной системы. Конструкция, грунтовая доочистка и
/// санитарное размещение намеренно не проектируются.
CanonicalCalculatorContractResult calculateCanonicalSewage(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(sewageSpecData);
  final calculationMode = _readWhole(spec, inputs, 'calculationMode', 0, 0, 1);
  final equivalentResidents = _readWhole(
    spec,
    inputs,
    'equivalentResidents',
    4,
    1,
    100,
  );
  final wastewaterPerResidentL = _read(
    spec,
    inputs,
    'wastewaterPerResidentL',
    200,
    1,
    2000,
  );
  final projectDailyFlowM3 = _read(
    spec,
    inputs,
    'projectDailyFlowM3',
    0.8,
    0.001,
    100,
  );
  final selectedWorkingVolumeM3 = _read(
    spec,
    inputs,
    'selectedWorkingVolumeM3',
    0,
    0,
    1000,
  );
  final selectedChamberCount = _readWhole(
    spec,
    inputs,
    'selectedChamberCount',
    0,
    0,
    3,
  );
  final naturalTreatmentStatus = _readWhole(
    spec,
    inputs,
    'naturalTreatmentStatus',
    0,
    0,
    2,
  );
  final groundwaterStatus = _readWhole(
    spec,
    inputs,
    'groundwaterStatus',
    0,
    0,
    2,
  );
  final pipeLengthM = _read(spec, inputs, 'pipeLengthM', 0, 0, 1000);
  final pipeSectionLengthM = _read(
    spec,
    inputs,
    'pipeSectionLengthM',
    0,
    0,
    30,
  );
  final inspectionWellCount = _readWhole(
    spec,
    inputs,
    'inspectionWellCount',
    0,
    0,
    100,
  );
  final fittingCount = _readWhole(spec, inputs, 'fittingCount', 0, 0, 1000);

  final dailyFlowM3 = calculationMode == 0
      ? equivalentResidents * wastewaterPerResidentL / 1000
      : projectDailyFlowM3;
  final retentionRule = _matchingRule(
    spec.normativeList('retention_rules'),
    equivalentResidents,
  );
  final chamberRule = _matchingRule(
    spec.normativeList('chamber_rules'),
    equivalentResidents,
  );
  final retentionMultiplier = (retentionRule['daily_flow_multiplier'] as num)
      .toDouble();
  final minimumChamberCount = (chamberRule['minimum_chambers'] as num).toInt();
  final minimumWorkingVolumeM3 = dailyFlowM3 * retentionMultiplier;
  final volumeShortfallM3 = selectedWorkingVolumeM3 > 0
      ? (minimumWorkingVolumeM3 - selectedWorkingVolumeM3)
            .clamp(0, double.infinity)
            .toDouble()
      : 0.0;
  final volumeMarginM3 = selectedWorkingVolumeM3 > 0
      ? (selectedWorkingVolumeM3 - minimumWorkingVolumeM3)
            .clamp(0, double.infinity)
            .toDouble()
      : 0.0;
  final verifiedWorkingVolumeM3 =
      selectedWorkingVolumeM3 >= minimumWorkingVolumeM3
      ? selectedWorkingVolumeM3
      : minimumWorkingVolumeM3;

  final pipeSections = pipeLengthM > 0 && pipeSectionLengthM > 0
      ? (pipeLengthM / pipeSectionLengthM).ceil()
      : 0;
  final purchasePipeLengthM = pipeSections > 0
      ? pipeSections * pipeSectionLengthM
      : pipeLengthM;
  final pipeLeftoverM = purchasePipeLengthM - pipeLengthM;
  final volumeUnit = spec.packagingRule<String>('volume_unit');
  final meterUnit = spec.packagingRule<String>('meter_unit');
  final pieceUnit = spec.packagingRule<String>('piece_unit');
  final systemUnit = spec.packagingRule<String>('system_unit');
  final pipeSectionUnit = spec.packagingRule<String>('pipe_section_unit');
  final materials = <CanonicalMaterialResult>[];

  if (selectedWorkingVolumeM3 > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Выбранная система септика по проекту или паспорту',
        quantity: 1,
        unit: systemUnit,
        withReserve: 1,
        purchaseQty: 1,
        category: 'Выбранная система',
      ),
    );
  }
  if (pipeLengthM > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: pipeSectionLengthM > 0
            ? 'Труба наружной канализации по проектной трассе, отрезок ${roundValue(pipeSectionLengthM, 3)} м'
            : 'Труба наружной канализации по проектной трассе',
        quantity: roundValue(pipeLengthM, 6),
        unit: meterUnit,
        withReserve: roundValue(purchasePipeLengthM, 6),
        purchaseQty: roundValue(purchasePipeLengthM, 6),
        category: 'Проектная трасса',
        packageInfo: pipeSections > 0
            ? {
                'count': pipeSections,
                'size': roundValue(pipeSectionLengthM, 6),
                'packageUnit': pipeSectionUnit,
              }
            : null,
      ),
    );
  }
  if (inspectionWellCount > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Смотровой колодец по проектной ведомости',
        quantity: inspectionWellCount.toDouble(),
        unit: pieceUnit,
        withReserve: inspectionWellCount.toDouble(),
        purchaseQty: inspectionWellCount.toDouble(),
        category: 'Проектная трасса',
      ),
    );
  }
  if (fittingCount > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Фасонные части по проектной ведомости',
        quantity: fittingCount.toDouble(),
        unit: pieceUnit,
        withReserve: fittingCount.toDouble(),
        purchaseQty: fittingCount.toDouble(),
        category: 'Проектная трасса',
      ),
    );
  }

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: roundValue(minimumWorkingVolumeM3, 6),
      purchaseQuantity: roundValue(verifiedWorkingVolumeM3, 6),
      leftover: roundValue(verifiedWorkingVolumeM3 - minimumWorkingVolumeM3, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'calculationMode:$calculationMode',
        'equivalentResidents:$equivalentResidents',
        'no_hidden_reserve',
      ],
      keyFactors: {
        'field_multiplier': 1,
        'retention_multiplier': retentionMultiplier,
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'septic-working-volume',
        packageSize: roundValue(verifiedWorkingVolumeM3, 6),
        packagesCount: 1,
        unit: volumeUnit,
      ),
    );
  }

  final warnings = <String>[
    'Септик выполняет только предварительную механическую очистку: обработанный сток требует последующей очистки по обоснованной проектной схеме.',
    'Калькулятор не назначает конструкцию сооружения, санитарные разрывы, уклон и отметки трассы, вентиляцию, защиту от всплытия или способ сброса.',
  ];
  if (calculationMode == 0) {
    warnings.add(
      'Суточный объём на одного ЭЧЖ введён пользователем; стартовые 200 л/сут не заменяют расчёт фактического водоотведения.',
    );
  }
  if (selectedWorkingVolumeM3 <= 0) {
    warnings.add(
      'Рабочий объём выбранной системы не введён — показан только минимальный расчётный объём.',
    );
  } else if (volumeShortfallM3 > 0) {
    warnings.add(
      'Рабочий объём выбранной системы меньше расчётного минимума на ${roundValue(volumeShortfallM3, 3)} м³.',
    );
  }
  if (selectedChamberCount <= 0) {
    warnings.add(
      'Количество камер выбранной системы не введено и не проверено.',
    );
  } else if (selectedChamberCount < minimumChamberCount) {
    warnings.add(
      'В выбранной системе $selectedChamberCount камер(ы), а для $equivalentResidents ЭЧЖ расчётное правило требует не менее $minimumChamberCount.',
    );
  }
  if (naturalTreatmentStatus == 0) {
    warnings.add(
      'Пригодность грунта и схема последующей очистки не подтверждены изысканиями и проектом.',
    );
  } else if (naturalTreatmentStatus == 2) {
    warnings.add(
      'Естественная почвенная доочистка не подтверждена — требуется отдельное инженерное решение.',
    );
  }
  if (groundwaterStatus == 0) {
    warnings.add('Расчётный сезонный уровень грунтовых вод не проверен.');
  } else if (groundwaterStatus == 2) {
    warnings.add(
      'Высокий или сезонно высокий уровень грунтовых вод требует отдельной проверки конструкции и способа доочистки.',
    );
  }
  if (pipeSectionLengthM > 0 && pipeLengthM <= 0) {
    warnings.add(
      'Длина товарного отрезка трубы введена без длины проектной трассы.',
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'calculationMode': calculationMode.toDouble(),
      'equivalentResidents': equivalentResidents.toDouble(),
      'wastewaterPerResidentL': roundValue(wastewaterPerResidentL, 3),
      'projectDailyFlowM3': roundValue(projectDailyFlowM3, 3),
      'dailyFlowM3': roundValue(dailyFlowM3, 3),
      'retentionMultiplier': roundValue(retentionMultiplier, 3),
      'minimumWorkingVolumeM3': roundValue(minimumWorkingVolumeM3, 3),
      'selectedWorkingVolumeM3': roundValue(selectedWorkingVolumeM3, 3),
      'verifiedWorkingVolumeM3': roundValue(verifiedWorkingVolumeM3, 3),
      'volumeShortfallM3': roundValue(volumeShortfallM3, 3),
      'volumeMarginM3': roundValue(volumeMarginM3, 3),
      'minimumChamberCount': minimumChamberCount.toDouble(),
      'selectedChamberCount': selectedChamberCount.toDouble(),
      'naturalTreatmentStatus': naturalTreatmentStatus.toDouble(),
      'groundwaterStatus': groundwaterStatus.toDouble(),
      'pipeLengthM': roundValue(pipeLengthM, 3),
      'pipeSectionLengthM': roundValue(pipeSectionLengthM, 3),
      'pipeSections': pipeSections.toDouble(),
      'purchasePipeLengthM': roundValue(purchasePipeLengthM, 3),
      'pipeLeftoverM': roundValue(pipeLeftoverM, 3),
      'inspectionWellCount': inspectionWellCount.toDouble(),
      'fittingCount': fittingCount.toDouble(),
      'minExactNeed': roundValue(minimumWorkingVolumeM3, 6),
      'recExactNeed': roundValue(minimumWorkingVolumeM3, 6),
      'maxExactNeed': roundValue(minimumWorkingVolumeM3, 6),
      'minPurchase': roundValue(verifiedWorkingVolumeM3, 6),
      'recPurchase': roundValue(verifiedWorkingVolumeM3, 6),
      'maxPurchase': roundValue(verifiedWorkingVolumeM3, 6),
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
