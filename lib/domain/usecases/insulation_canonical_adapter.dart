import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

/* ─── Default spec (mirrors insulation-canonical.v1.json) ─── */

/* ─── Constants (must match TS engine exactly) ─── */

const Map<int, double> _plateAreas = {0: 0.72, 1: 0.50, 2: 2.00};
const Map<int, String> _plateLabels = {0: '1200×600', 1: '1000×500', 2: '2000×1000'};
const Map<int, int> _dowelsPerSqm = {0: 7, 1: 5, 2: 6, 3: 0};
const double _dowelReserve = 1.05;

const double _membraneReserve = 1.15;
const double _aluTapeM2PerM2 = 2;
const double _aluTapeRollM = 50;

const double _glueKgPerM2 = 2.5;
const double _glueBagKg = 25;

const double _primerLPerM2 = 0.15;
const double _primerReserve = 1.15;
const double _primerCanL = 10;

const double _ecowoolDensity = 35;
const double _ecowoolWaste = 1.10;
const double _ecowoolBagKg = 15;

/* ─── Factor table ─── */


const Map<int, String> _insulationTypeLabels = {
  0: 'Минеральная вата',
  1: 'ЭППС / пеноплекс',
  2: 'ЕПС / пенопласт',
  3: 'Эковата',
};

/* ─── Helpers ─── */

/* ─── Main calculator ─── */

CanonicalCalculatorContractResult calculateCanonicalInsulation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(insulationSpecData);

  final area = (inputs['area'] ?? defaultFor(spec, 'area', 40)).clamp(1, 500).toDouble();
  final insulationType = (inputs['insulationType'] ?? defaultFor(spec, 'insulationType', 0)).round().clamp(0, 3);
  final thickness = (inputs['thickness'] ?? defaultFor(spec, 'thickness', 100)).clamp(50, 200).toDouble();
  final plateSize = (inputs['plateSize'] ?? defaultFor(spec, 'plateSize', 0)).round().clamp(0, 2);
  final reserve = (inputs['reserve'] ?? defaultFor(spec, 'reserve', 5)).clamp(0, 15).toDouble();

  final areaWithReserve = area * (1 + reserve / 100);
  final plateArea = _plateAreas[plateSize] ?? 0.72;

  /* ── plate-based types (0, 1, 2) ── */
  var platesNeeded = 0;
  var dowelsNeeded = 0;
  var membraneArea = 0;
  var aluTapeRolls = 0;
  var glueKg = 0.0;
  var glueBags = 0;

  if (insulationType <= 2) {
    platesNeeded = (areaWithReserve / plateArea).ceil();
    dowelsNeeded = (area * (_dowelsPerSqm[insulationType] ?? 0) * _dowelReserve).ceil();
  }

  if (insulationType == 0) {
    membraneArea = (area * _membraneReserve).ceil();
    aluTapeRolls = ((area * _aluTapeM2PerM2) / _aluTapeRollM).ceil();
  }

  if (insulationType == 1 || insulationType == 2) {
    glueKg = area * _glueKgPerM2;
    glueBags = (glueKg / _glueBagKg).ceil();
  }

  /* ── primer (all types) ── */
  final primerCans = (area * _primerLPerM2 * _primerReserve / _primerCanL).ceil();

  /* ── ecowool (type 3) ── */
  var ecowoolVolume = 0.0;
  var ecowoolKg = 0;
  var ecowoolBags = 0;

  if (insulationType == 3) {
    ecowoolVolume = area * (thickness / 1000);
    ecowoolKg = (ecowoolVolume * _ecowoolDensity * _ecowoolWaste).ceil();
    ecowoolBags = (ecowoolKg / _ecowoolBagKg).ceil();
  }

  /* ── scenarios ── */
  final basePrimary = insulationType <= 2 ? platesNeeded.toDouble() : ecowoolBags.toDouble();
  const packageSize = 1.0;
  final packageUnit = insulationType <= 2 ? 'шт' : 'мешков';
  final packageLabel = insulationType <= 2
      ? 'insulation-plate-${_plateLabels[plateSize]}'
      : 'ecowool-bag-15kg';

  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * multiplier, 6);
    final packages = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packages * packageSize, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'insulationType:$insulationType',
        'plateSize:$plateSize',
        'reserve:${reserve.toInt()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packages,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ── build materials list ── */
  final materials = <CanonicalMaterialResult>[];

  if (insulationType <= 2) {
    materials.add(CanonicalMaterialResult(
      name: '${_insulationTypeLabels[insulationType]} (${_plateLabels[plateSize]} мм)',
      quantity: roundValue(recScenario.exactNeed, 6),
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceil().toDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Основное',
    ));

    materials.add(CanonicalMaterialResult(
      name: 'Дюбели тарельчатые',
      quantity: dowelsNeeded.toDouble(),
      unit: 'шт',
      withReserve: dowelsNeeded.toDouble(),
      purchaseQty: dowelsNeeded.toDouble(),
      category: 'Крепёж',
    ));
  }

  if (insulationType == 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Пароизоляционная мембрана',
      quantity: membraneArea.toDouble(),
      unit: 'м²',
      withReserve: membraneArea.toDouble(),
      purchaseQty: membraneArea.toDouble(),
      category: 'Изоляция',
    ));

    materials.add(CanonicalMaterialResult(
      name: 'Алюминиевая лента (скотч)',
      quantity: aluTapeRolls.toDouble(),
      unit: 'рулонов',
      withReserve: aluTapeRolls.toDouble(),
      purchaseQty: aluTapeRolls.toDouble(),
      category: 'Изоляция',
    ));
  }

  if (insulationType == 1 || insulationType == 2) {
    materials.add(CanonicalMaterialResult(
      name: 'Клей для ${insulationType == 1 ? "ЭППС" : "ЕПС"} (${_glueBagKg.toInt()} кг)',
      quantity: roundValue(glueKg, 3),
      unit: 'кг',
      withReserve: (glueBags * _glueBagKg).toDouble(),
      purchaseQty: (glueBags * _glueBagKg).toDouble(),
      category: 'Клей',
      packageInfo: {'count': glueBags, 'unitSize': _glueBagKg, 'packageUnit': 'мешков'},
    ));
  }

  if (insulationType == 3) {
    materials.add(CanonicalMaterialResult(
      name: 'Эковата (${_ecowoolBagKg.toInt()} кг)',
      quantity: ecowoolKg.toDouble(),
      unit: 'кг',
      withReserve: (ecowoolBags * _ecowoolBagKg).toDouble(),
      purchaseQty: (ecowoolBags * _ecowoolBagKg).toDouble(),
      category: 'Основное',
      packageInfo: {'count': ecowoolBags, 'unitSize': _ecowoolBagKg, 'packageUnit': 'мешков'},
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Грунтовка (${_primerCanL.toInt()} л)',
    quantity: roundValue(area * _primerLPerM2 * _primerReserve, 3),
    unit: 'л',
    withReserve: (primerCans * _primerCanL).toDouble(),
    purchaseQty: (primerCans * _primerCanL).toDouble(),
    category: 'Подготовка',
    packageInfo: {'count': primerCans, 'unitSize': _primerCanL, 'packageUnit': 'канистр'},
  ));

  /* ── warnings ── */
  final warnings = <String>[];
  if (thickness < spec.warningRule<num>('thin_thickness_threshold_mm').toDouble()) {
    warnings.add('Толщина менее 50 мм — недостаточно для наружных стен');
  }
  if (insulationType == 3 && thickness > spec.warningRule<num>('ecowool_settle_threshold_mm').toDouble()) {
    warnings.add('Эковата при толщине более 150 мм оседает — рекомендуется укладка в 2 слоя');
  }
  if (area > spec.warningRule<num>('professional_area_threshold_m2').toDouble()) {
    warnings.add('При площади более 100 м² рекомендуется профессиональный монтаж');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'insulationType': insulationType.toDouble(),
      'thickness': roundValue(thickness, 3),
      'plateSize': plateSize.toDouble(),
      'reserve': reserve,
      'areaWithReserve': roundValue(areaWithReserve, 3),
      'plateArea': plateArea,
      'platesNeeded': insulationType <= 2 ? platesNeeded.toDouble() : 0,
      'dowelsNeeded': insulationType <= 2 ? dowelsNeeded.toDouble() : 0,
      'membraneArea': insulationType == 0 ? membraneArea.toDouble() : 0,
      'aluTapeRolls': insulationType == 0 ? aluTapeRolls.toDouble() : 0,
      'glueKg': insulationType == 1 || insulationType == 2 ? roundValue(glueKg, 3) : 0,
      'glueBags': insulationType == 1 || insulationType == 2 ? glueBags.toDouble() : 0,
      'primerCans': primerCans.toDouble(),
      'ecowoolVolume': insulationType == 3 ? roundValue(ecowoolVolume, 6) : 0,
      'ecowoolKg': insulationType == 3 ? ecowoolKg.toDouble() : 0,
      'ecowoolBags': insulationType == 3 ? ecowoolBags.toDouble() : 0,
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
