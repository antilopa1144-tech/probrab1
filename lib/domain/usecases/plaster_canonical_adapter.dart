import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


bool hasCanonicalPlasterInputs(Map<String, double> inputs) {
  if (inputs.containsKey('inputMode') || inputs.containsKey('length') || inputs.containsKey('width') || inputs.containsKey('height')) {
    return true;
  }
  return inputs.containsKey('plasterType') || inputs.containsKey('bagWeight');
}

Map<String, double> _resolveWork(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  final openingsArea = (inputs['openingsArea'] ?? defaultFor(spec, 'openingsArea', 5)).clamp(0, 500).toDouble();

  if (inputMode == 0) {
    final length = (inputs['length'] ?? defaultFor(spec, 'length', 5)).clamp(1, 50).toDouble();
    final width = (inputs['width'] ?? defaultFor(spec, 'width', 4)).clamp(1, 50).toDouble();
    final height = (inputs['height'] ?? defaultFor(spec, 'height', 2.7)).clamp(2, 5).toDouble();
    final wallArea = 2 * (length + width) * height;
    return {
      'wallArea': roundValue(wallArea, 3),
      'netArea': roundValue((wallArea - openingsArea).clamp(0, double.infinity).toDouble(), 3),
      'inputMode': 0.0,
      'roomHeight': roundValue(height, 3),
    };
  }

  final wallArea = (inputs['area'] ?? defaultFor(spec, 'area', 50)).clamp(0.1, 100000).toDouble();
  return {
    'wallArea': roundValue(wallArea, 3),
    'netArea': roundValue((wallArea - openingsArea).clamp(0, double.infinity).toDouble(), 3),
    'inputMode': 1.0,
    'roomHeight': roundValue(defaultFor(spec, 'height', 2.7), 3),
  };
}

Map<String, dynamic> _resolvePlasterType(SpecReader spec, Map<String, double> inputs) {
  final typeId = (inputs['plasterType'] ?? defaultFor(spec, 'plasterType', 0)).round().clamp(0, 2);
  return spec.normativeList('plaster_types').firstWhere((item) => (item['id'] as num).toInt() == typeId, orElse: () => spec.normativeList('plaster_types').first);
}

Map<String, dynamic> _resolveSubstrate(SpecReader spec, Map<String, double> inputs) {
  final substrateId = (inputs['substrateType'] ?? defaultFor(spec, 'substrateType', 1)).round().clamp(1, 5);
  return spec.normativeList('substrate_types').firstWhere((item) => (item['id'] as num).toInt() == substrateId, orElse: () => spec.normativeList('substrate_types').first);
}

Map<String, dynamic> _resolveEvenness(SpecReader spec, Map<String, double> inputs) {
  final evennessId = (inputs['wallEvenness'] ?? defaultFor(spec, 'wallEvenness', 1)).round().clamp(1, 3);
  return spec.normativeList('wall_evenness_profiles').firstWhere((item) => (item['id'] as num).toInt() == evennessId, orElse: () => spec.normativeList('wall_evenness_profiles').first);
}

double _resolveThickness(SpecReader spec, Map<String, double> inputs) {
  return (inputs['thickness'] ?? defaultFor(spec, 'thickness', 15)).clamp(5, 100).toDouble();
}

double _resolveBagWeight(SpecReader spec, Map<String, dynamic> plasterType, Map<String, double> inputs) {
  final defaultBag = (plasterType['default_bag_weight'] as num).toDouble();
  final requested = (inputs['bagWeight'] ?? defaultBag).toDouble();
  final allowedBags = (plasterType['allowed_bag_weights'] as List?) ?? [defaultBag];
  if (allowedBags.contains(requested)) return requested;
  return defaultBag;
}

CanonicalCalculatorContractResult calculateCanonicalPlaster(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(plasterSpecData);

  final work = _resolveWork(spec, inputs);
  final plasterType = _resolvePlasterType(spec, inputs);
  final substrate = _resolveSubstrate(spec, inputs);
  final evenness = _resolveEvenness(spec, inputs);
  final thickness = _resolveThickness(spec, inputs);
  final bagWeight = _resolveBagWeight(spec, plasterType, inputs);
  final netArea = work['netArea']!;
  final wallArea = work['wallArea']!;
  final consumptionKgPerM2Mm =
      ((plasterType['base_kg_per_m2_10mm'] as num).toDouble() / 10) * (substrate['multiplier'] as num).toDouble() * (evenness['multiplier'] as num).toDouble() * spec.materialRule<num>('reserve_factor').toDouble();
  final scenarios = <String, CanonicalScenarioResult>{};

final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('plaster', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(netArea * thickness * consumptionKgPerM2Mm * accuracyMult * multiplier, 6);
    final packagesCount = exactNeed > 0 ? (exactNeed / bagWeight).ceil() : 0;
    final purchaseQuantity = roundValue(packagesCount * bagWeight, 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'plaster:${plasterType['key'] as String}',
        'substrate:${substrate['key'] as String}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'plaster-bag-${bagWeight.toInt()}${spec.packagingRule<String>('unit')}',
        packageSize: bagWeight,
        packagesCount: packagesCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final totalKg = roundValue(recScenario.exactNeed, 3);
  final primerRate = (substrate['primer_type'] as num).toInt() == 2 ? spec.materialRule<num>('contact_primer_kg_per_m2').toDouble() : spec.materialRule<num>('deep_primer_l_per_m2').toDouble();
  final primerNeed = (netArea * primerRate * spec.materialRule<num>('reserve_factor').toDouble()).ceil().toDouble();
  final primerPackages = primerNeed > 0 ? (primerNeed / spec.materialRule<num>('primer_package_size').toDouble()).ceil() : 0;
  final meshArea = thickness > spec.warningRule<num>('mesh_threshold_mm').toDouble()
      ? roundValue(netArea * spec.materialRule<num>('mesh_overlap_factor').toDouble(), 3)
      : 0.0;
  final beacons = netArea > 0 ? (netArea / spec.materialRule<num>('beacons_area_m2_per_piece').toDouble()).ceil().clamp(2, 100000) : 0;
  final beaconSize = thickness < spec.materialRule<num>('thin_beacon_threshold_mm').toDouble()
      ? spec.materialRule<num>('beacon_thin_size_mm').toDouble()
      : spec.materialRule<num>('beacon_standard_size_mm').toDouble();
  final cornerProfiles = (work['inputMode'] ?? 1) == 0
      ? ((work['roomHeight']! * spec.materialRule<num>('corner_profile_count').toDouble() / spec.materialRule<num>('corner_profile_length_m').toDouble()) * spec.materialRule<num>('reserve_factor').toDouble()).ceil()
      : 0;

  final warnings = <String>[];
  if ((plasterType['id'] as num).toInt() == 0 && thickness > spec.warningRule<num>('gypsum_two_layer_threshold_mm').toDouble()) {
    warnings.add('Гипсовую штукатурку толщиной > 20 мм наносят в 2 слоя с армирующей сеткой');
  }
  if (thickness > spec.warningRule<num>('mesh_threshold_mm').toDouble()) {
    warnings.add('При толщине > 30 мм обязательно армирование стекловолоконной сеткой');
  }
  if (netArea < spec.warningRule<num>('small_area_threshold_m2').toDouble()) {
    warnings.add('Маленькая площадь — лучше использовать готовую шпаклёвку из ведра');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: '${plasterType['label'] as String} (мешки ${bagWeight.toInt()} кг)',
        quantity: roundValue(totalKg / bagWeight, 3),
        unit: 'мешков',
        withReserve: recScenario.buyPlan.packagesCount.toDouble(),
        purchaseQty: recScenario.buyPlan.packagesCount.toDouble(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: (substrate['primer_type'] as num).toInt() == 2
            ? 'Грунтовка бетоноконтакт (${spec.materialRule<num>('primer_package_size').toInt()} кг)'
            : 'Грунтовка (${spec.materialRule<num>('primer_package_size').toInt()} л)',
        quantity: primerNeed,
        unit: (substrate['primer_type'] as num).toInt() == 2 ? 'кг' : 'л',
        withReserve: (primerPackages * spec.materialRule<num>('primer_package_size').toDouble()),
        purchaseQty: (primerPackages * spec.materialRule<num>('primer_package_size').toDouble()).toDouble(),
        category: 'Подготовка',
        packageInfo: {'count': primerPackages, 'unitSize': spec.materialRule<num>('primer_package_size').toDouble(), 'packageUnit': 'канистр'},
      ),
      if (meshArea > 0)
        CanonicalMaterialResult(
          name: 'Стеклосетка армировочная (50x50 мм)',
          quantity: meshArea,
          unit: 'м²',
          withReserve: meshArea.ceil().toDouble(),
          purchaseQty: meshArea.ceil().toDouble(),
          category: 'Армирование',
        ),
      CanonicalMaterialResult(
        name: 'Маяки штукатурные ($beaconSize мм)',
        quantity: beacons.toDouble(),
        unit: 'шт',
        withReserve: beacons.toDouble(),
        purchaseQty: beacons.toDouble(),
        category: 'Вспомогательное',
      ),
      CanonicalMaterialResult(
        name: 'Правило алюминиевое (${spec.materialRule<num>('rule_size_m').toDouble()} м)',
        quantity: spec.materialRule<num>('rule_count').toDouble(),
        unit: 'шт',
        withReserve: spec.materialRule<num>('rule_count').toDouble(),
        purchaseQty: spec.materialRule<num>('rule_count').toDouble(),
        category: 'Инструмент',
      ),
      if (cornerProfiles > 0)
        CanonicalMaterialResult(
          name: 'Угловой профиль перфорированный 25x25 мм (3 м)',
          quantity: cornerProfiles.toDouble(),
          unit: 'шт',
          withReserve: cornerProfiles.toDouble(),
          purchaseQty: cornerProfiles.toDouble(),
          category: 'Вспомогательное',
        ),
    ],
    totals: {
      'wallArea': roundValue(wallArea, 3),
      'netArea': roundValue(netArea, 3),
      'thickness': roundValue(thickness, 3),
      'totalKg': totalKg,
      'plasterType': (plasterType['id'] as num).toInt().toDouble(),
      'substrateType': (substrate['id'] as num).toInt().toDouble(),
      'wallEvenness': (evenness['id'] as num).toInt().toDouble(),
      'bagWeight': bagWeight,
      'primerNeed': primerNeed,
      'primerType': (substrate['primer_type'] as num).toInt().toDouble(),
      'meshArea': meshArea,
      'beacons': beacons.toDouble(),
      'beaconSize': beaconSize.toDouble(),
      'ruleSize': spec.materialRule<num>('rule_size_m').toDouble(),
      'warningThickLayer': thickness > spec.warningRule<num>('thick_layer_warning_threshold_mm').toDouble() ? 1.0 : 0.0,
      'tipObryzg': spec.warningRule<List>('obryzg_tip_substrate_ids').contains((substrate['id'] as num).toInt()) && spec.warningRule<List>('obryzg_tip_evenness_ids').contains((evenness['id'] as num).toInt()) ? 1.0 : 0.0,
      'minExactNeedKg': scenarios['MIN']!.exactNeed,
      'recExactNeedKg': recScenario.exactNeed,
      'maxExactNeedKg': scenarios['MAX']!.exactNeed,
      'minPurchaseKg': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseKg': recScenario.purchaseQuantity,
      'maxPurchaseKg': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}


