import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const double _cableChannelPieceM = 2;
const int _rcdModules = 2;
const int _panelSpareModules = 2;
const double _gypsumBagKg = 5;

CanonicalCalculatorContractResult calculateCanonicalElectric(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(electricSpecData);

  final apartmentArea =
      (inputs['apartmentArea'] ?? defaultFor(spec, 'apartmentArea', 60)).clamp(
        20.0,
        500.0,
      );
  final roomsCount = (inputs['roomsCount'] ?? defaultFor(spec, 'roomsCount', 3))
      .round()
      .clamp(1, 10);
  final ceilingHeight =
      (inputs['ceilingHeight'] ?? defaultFor(spec, 'ceilingHeight', 2.7)).clamp(
        2.4,
        4.0,
      );
  final wiringType = (inputs['wiringType'] ?? defaultFor(spec, 'wiringType', 0))
      .round()
      .clamp(0, 1);
  final hasKitchen = (inputs['hasKitchen'] ?? defaultFor(spec, 'hasKitchen', 1))
      .round()
      .clamp(0, 1);
  final cablePurchaseMode =
      (inputs['cablePurchaseMode'] ?? defaultFor(spec, 'cablePurchaseMode', 0))
          .round()
          .clamp(0, 1);
  final reserve = (inputs['reserve'] ?? defaultFor(spec, 'reserve', 15)).clamp(
    5.0,
    30.0,
  );

  /* ─── groups ─── */
  final lightingGroups = roomsCount + 1;
  final outletGroups = roomsCount + 2;
  final acGroups =
      (roomsCount / spec.materialRule<num>('ac_groups_divisor').toDouble())
          .ceil();
  final breakersCount =
      lightingGroups + outletGroups + acGroups + (hasKitchen == 1 ? 1 : 0);
  final uzoCount = (outletGroups / 2).ceil() + (hasKitchen == 1 ? 1 : 0) + 1;
  final panelModules =
      breakersCount + uzoCount * _rcdModules + _panelSpareModules;

  /* ─── cable lengths ─── */
  final wiringMultiplier = wiringType == 1
      ? spec.materialRule<num>('cable_open_wiring_multiplier').toDouble()
      : spec.materialRule<num>('cable_hidden_wiring_multiplier').toDouble();
  final cable15BaseLength =
      (apartmentArea * spec.materialRule<num>('cable_15_rate').toDouble() +
          lightingGroups * ceilingHeight) *
      wiringMultiplier;
  final cable25BaseLength =
      (apartmentArea * spec.materialRule<num>('cable_25_rate').toDouble() +
          outletGroups * ceilingHeight * 1.5) *
      wiringMultiplier;
  final cable15length = cable15BaseLength * (1 + reserve / 100);
  final cable25length = cable25BaseLength * (1 + reserve / 100);
  final cable6length = hasKitchen == 1
      ? (math.sqrt(apartmentArea) *
                    spec
                        .materialRule<num>('cable_6_kitchen_factor')
                        .toDouble() +
                ceilingHeight) *
            spec.materialRule<num>('cable_6_reserve').toDouble() *
            wiringMultiplier
      : 0.0;
  final conduitLength =
      ((cable15length + cable25length + cable6length) *
              spec.materialRule<num>('conduit_ratio').toDouble())
          .ceil();

  /* ─── outlets & switches ─── */
  final outletsCount =
      (apartmentArea * spec.materialRule<num>('outlets_per_m2').toDouble())
          .ceil() +
      roomsCount * spec.materialRule<num>('outlets_per_room').toDouble();
  final switchesCount =
      roomsCount + spec.materialRule<num>('switches_base').toDouble();

  /* ─── packaging ─── */
  final cableSpoolM = spec.packagingRule<num>('cable_spool_m').toDouble();
  final cable15spools = cablePurchaseMode == 1
      ? (cable15length / cableSpoolM).ceil()
      : 0;
  final cable25spools = cablePurchaseMode == 1
      ? (cable25length / cableSpoolM).ceil()
      : 0;
  final cable15Purchase = cablePurchaseMode == 1
      ? cable15spools * cableSpoolM
      : cable15length.ceilToDouble();
  final cable25Purchase = cablePurchaseMode == 1
      ? cable25spools * cableSpoolM
      : cable25length.ceilToDouble();
  final conduitPackageSize = wiringType == 1
      ? _cableChannelPieceM
      : cableSpoolM;
  final conduitPacks = (conduitLength / conduitPackageSize).ceil();
  final socketBoxes =
      ((outletsCount + switchesCount) *
              spec.materialRule<num>('socket_box_reserve').toDouble())
          .ceil();
  final gypsumKg = ((outletsCount + switchesCount) / 5).ceil();
  final gypsumBags = (gypsumKg / _gypsumBagKg).ceil();
  final reserveField = spec.inputSchema.firstWhere(
    (field) => field['key'] == 'reserve',
    orElse: () => const <String, dynamic>{},
  );
  final scenarioReserve = <String, double>{
    'MIN': (reserveField['min'] as num?)?.toDouble() ?? reserve,
    'REC': reserve,
    'MAX': (reserveField['max'] as num?)?.toDouble() ?? reserve,
  };

  ({double exactNeed, double purchaseQuantity}) calculateCableScenario(
    double reservePercent,
  ) {
    final cable15 = cable15BaseLength * (1 + reservePercent / 100);
    final cable25 = cable25BaseLength * (1 + reservePercent / 100);
    final exactNeed = roundValue(cable15 + cable25 + cable6length, 6);
    final purchaseQuantity =
        (cablePurchaseMode == 1
            ? (cable15 / cableSpoolM).ceil() * cableSpoolM
            : cable15.ceil()) +
        (cablePurchaseMode == 1
            ? (cable25 / cableSpoolM).ceil() * cableSpoolM
            : cable25.ceil()) +
        (hasKitchen == 1 ? cable6length.ceil() : 0);
    return (
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity.toDouble(),
    );
  }

  /* ─── materials ─── */
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Медный кабель ВВГнг(А)-LS 3×1,5 мм²',
      quantity: roundValue(cable15length, 1),
      unit: 'м',
      withReserve: roundValue(cable15length, 1),
      purchaseQty: cable15Purchase,
      category: 'Кабель',
      packageInfo: cablePurchaseMode == 1
          ? {
              'count': cable15spools,
              'unitSize': cableSpoolM,
              'packageUnit': 'бухт',
            }
          : null,
    ),
    CanonicalMaterialResult(
      name: 'Медный кабель ВВГнг(А)-LS 3×2,5 мм²',
      quantity: roundValue(cable25length, 1),
      unit: 'м',
      withReserve: roundValue(cable25length, 1),
      purchaseQty: cable25Purchase,
      category: 'Кабель',
      packageInfo: cablePurchaseMode == 1
          ? {
              'count': cable25spools,
              'unitSize': cableSpoolM,
              'packageUnit': 'бухт',
            }
          : null,
    ),
  ];

  if (hasKitchen == 1 && cable6length > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Медный кабель ВВГнг(А)-LS 3×6 мм²',
        quantity: roundValue(cable6length, 1),
        unit: 'м',
        withReserve: roundValue(cable6length, 1),
        purchaseQty: cable6length.ceil().toDouble(),
        category: 'Кабель',
      ),
    );
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Распределительный щит не менее чем на $panelModules модулей',
      quantity: 1,
      unit: 'шт',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Щиток',
    ),
    CanonicalMaterialResult(
      name: 'Автоматический выключатель 1P, характеристика C, 10 А — освещение',
      quantity: lightingGroups.toDouble(),
      unit: 'шт',
      withReserve: lightingGroups.toDouble(),
      purchaseQty: lightingGroups.toDouble(),
      category: 'Защита',
    ),
    CanonicalMaterialResult(
      name: 'Автоматический выключатель 1P, характеристика C, 16 А — розетки',
      quantity: outletGroups.toDouble(),
      unit: 'шт',
      withReserve: outletGroups.toDouble(),
      purchaseQty: outletGroups.toDouble(),
      category: 'Защита',
    ),
    CanonicalMaterialResult(
      name:
          'Автоматические выключатели для кондиционеров и отдельных потребителей',
      quantity: acGroups.toDouble(),
      unit: 'шт',
      withReserve: acGroups.toDouble(),
      purchaseQty: acGroups.toDouble(),
      category: 'Защита',
    ),
  ]);

  if (hasKitchen == 1) {
    materials.add(
      const CanonicalMaterialResult(
        name:
            'Автоматический выключатель 1P, характеристика C, 32 А — электроплита',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1,
        category: 'Защита',
      ),
    );
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Устройство защитного отключения (УЗО), 2P, тип A, 30 мА',
      quantity: uzoCount.toDouble(),
      unit: 'шт',
      withReserve: uzoCount.toDouble(),
      purchaseQty: uzoCount.toDouble(),
      category: 'Защита',
    ),
    CanonicalMaterialResult(
      name: 'Розетки с заземляющим контактом, 16 А',
      quantity: outletsCount.toDouble(),
      unit: 'шт',
      withReserve: outletsCount.toDouble(),
      purchaseQty: outletsCount.toDouble(),
      category: 'Установка',
    ),
    CanonicalMaterialResult(
      name: 'Выключатели освещения, 10 А',
      quantity: switchesCount.toDouble(),
      unit: 'шт',
      withReserve: switchesCount.toDouble(),
      purchaseQty: switchesCount.toDouble(),
      category: 'Установка',
    ),
    CanonicalMaterialResult(
      name: 'Подрозетники ∅68 мм, глубина 45–60 мм',
      quantity: socketBoxes.toDouble(),
      unit: 'шт',
      withReserve: socketBoxes.toDouble(),
      purchaseQty: socketBoxes.toDouble(),
      category: 'Установка',
    ),
    CanonicalMaterialResult(
      name: wiringType == 1
          ? 'Кабель-канал ПВХ с крышкой'
          : 'Гофрированная ПВХ-труба для кабеля с протяжкой, ∅16–20 мм',
      quantity: conduitLength.toDouble(),
      unit: 'м',
      withReserve: conduitLength.toDouble(),
      purchaseQty: conduitPacks * conduitPackageSize,
      category: 'Монтаж',
      packageInfo: {
        'count': conduitPacks,
        'unitSize': conduitPackageSize,
        'packageUnit': wiringType == 1 ? 'отрезков' : 'бухт',
      },
    ),
    CanonicalMaterialResult(
      name: 'Гипс монтажный (алебастр), мешок 5 кг',
      quantity: gypsumKg.toDouble(),
      unit: 'кг',
      withReserve: gypsumKg.toDouble(),
      purchaseQty: gypsumBags * _gypsumBagKg,
      category: 'Монтаж',
      packageInfo: {
        'count': gypsumBags,
        'unitSize': _gypsumBagKg,
        'packageUnit': 'мешков',
      },
    ),
  ]);

  /* ─── scenarios ─── */
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final reservePercent = scenarioReserve[scenarioName] ?? reserve;
    final cableScenario = calculateCableScenario(reservePercent);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: cableScenario.exactNeed,
      purchaseQuantity: cableScenario.purchaseQuantity,
      leftover: roundValue(
        cableScenario.purchaseQuantity - cableScenario.exactNeed,
        6,
      ),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'wiringType:$wiringType',
        'reserve:$reservePercent',
        'purchase_mode:${cablePurchaseMode == 1 ? "spool_50m" : "per_meter"}',
        'coefficients:project_assumptions_not_normative_limits',
        'scenario:separate-rounding-by-cable-section',
      ],
      keyFactors: {
        'input_reserve_multiplier': roundValue(1 + reservePercent / 100, 6),
        'stove_line_reserve_multiplier': hasKitchen == 1
            ? spec.materialRule<num>('cable_6_reserve').toDouble()
            : 1,
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: cablePurchaseMode == 1
            ? 'electric-cable-lines-mixed-packaging'
            : 'electric-cable-lines-per-meter',
        packageSize: 1,
        packagesCount: cableScenario.purchaseQuantity.round(),
        unit: 'м',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ─── warnings ─── */
  final warnings = <String>[];
  if (spec.warningRule<bool>('phase_selection_requires_load_data')) {
    warnings.add(
      'Однофазный или трёхфазный ввод выбирают по выделенной мощности, расчётным нагрузкам и техническим условиям — площадь сама по себе этого не определяет',
    );
  }
  if (hasKitchen == 1) {
    warnings.add(
      'Электроплита: кабель 3×6 мм² и автомат 32 А — ориентир для однофазной линии; проверьте мощность по паспорту плиты',
    );
  }
  warnings.add(
    'Тип, количество, номиналы и уставки УЗО/дифавтоматов выбирают по проекту, схеме групп, системе заземления и условиям помещений',
  );
  warnings.add(
    'Это предварительная ведомость. Сечения кабелей, номиналы защиты и схему щита должен проверить электропроектировщик',
  );

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'apartmentArea': roundValue(apartmentArea, 3),
      'roomsCount': roomsCount.toDouble(),
      'ceilingHeight': roundValue(ceilingHeight, 3),
      'wiringType': wiringType.toDouble(),
      'hasKitchen': hasKitchen.toDouble(),
      'cablePurchaseMode': cablePurchaseMode.toDouble(),
      'reserve': reserve,
      'lightingGroups': lightingGroups.toDouble(),
      'outletGroups': outletGroups.toDouble(),
      'acGroups': acGroups.toDouble(),
      'breakersCount': breakersCount.toDouble(),
      'uzoCount': uzoCount.toDouble(),
      'panelModules': panelModules.toDouble(),
      'cable15length': roundValue(cable15length, 1),
      'cable25length': roundValue(cable25length, 1),
      'cable6length': roundValue(cable6length, 1),
      'conduitLength': conduitLength.toDouble(),
      'outletsCount': outletsCount.toDouble(),
      'switchesCount': switchesCount.toDouble(),
      'cable15spools': cable15spools.toDouble(),
      'cable25spools': cable25spools.toDouble(),
      'conduitPacks': conduitPacks.toDouble(),
      'socketBoxes': socketBoxes.toDouble(),
      'gypsumKg': gypsumKg.toDouble(),
      'gypsumBags': gypsumBags.toDouble(),
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
