import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

double _positive(double? value, double fallback) =>
    math.max(0.000001, value ?? fallback);

CanonicalCalculatorContractResult calculateCanonicalFacadePanelsV3(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(facadePanelsSpecData);
  final inputMode =
      (inputs['inputMode'] ??
                  (inputs.containsKey('wallLength')
                      ? 0
                      : defaultFor(spec, 'inputMode', 1)))
              .round() ==
          0
      ? 0
      : 1;
  final houseLength = _positive(
    inputs['houseLength'],
    defaultFor(spec, 'houseLength', 10),
  );
  final houseWidth = _positive(
    inputs['houseWidth'],
    defaultFor(spec, 'houseWidth', 10),
  );
  final wallHeight = _positive(
    inputs['wallHeight'],
    defaultFor(spec, 'wallHeight', 3),
  );
  final perimeter = _positive(
    inputs['wallLength'],
    2 * (houseLength + houseWidth),
  );
  final openingsArea = math
      .max(0, inputs['openingsArea'] ?? defaultFor(spec, 'openingsArea', 10))
      .toDouble();
  final grossArea =
      (inputMode == 0
              ? perimeter * wallHeight
              : _positive(inputs['area'], defaultFor(spec, 'area', 100)))
          .toDouble();
  final netArea =
      (inputMode == 0 ? math.max(0, grossArea - openingsArea) : grossArea)
          .toDouble();

  final panelType = (inputs['panelType'] ?? defaultFor(spec, 'panelType', 0))
      .round()
      .clamp(0, 6);
  final panelUsefulArea = _positive(
    inputs['panelUsefulArea'],
    defaultFor(spec, 'panelUsefulArea', 0.84),
  );
  final reservePercent =
      (inputs['reservePercent'] ?? defaultFor(spec, 'reservePercent', 10))
          .clamp(0.0, 30.0);
  final maxReservePercent = math.max(
    reservePercent,
    spec.materialRule<num>('max_reserve_percent').toDouble(),
  );

  final exactPanelsMin = netArea / panelUsefulArea;
  final exactPanelsRec = exactPanelsMin * (1 + reservePercent / 100);
  final exactPanelsMax = exactPanelsMin * (1 + maxReservePercent / 100);

  CanonicalScenarioResult makeScenario(double exactNeed, double reserve) {
    final purchase = exactNeed.ceil();
    return CanonicalScenarioResult(
      exactNeed: roundValue(exactNeed, 6),
      purchaseQuantity: purchase.toDouble(),
      leftover: roundValue(purchase - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'panelType:$panelType',
        'panelUsefulArea:$panelUsefulArea',
        'reservePercent:$reserve',
      ],
      keyFactors: {'reserve_percent': reserve},
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'панель',
        packageSize: 1,
        packagesCount: purchase,
        unit: 'шт',
      ),
    );
  }

  final scenarios = <String, CanonicalScenarioResult>{
    'MIN': makeScenario(exactPanelsMin, 0),
    'REC': makeScenario(exactPanelsRec, reservePercent),
    'MAX': makeScenario(exactPanelsMax, maxReservePercent),
  };
  final panelsCount = scenarios['REC']!.purchaseQuantity.toInt();
  final panelsArea = panelsCount * panelUsefulArea;

  final needProfile =
      (inputs['needProfile'] ?? defaultFor(spec, 'needProfile', 1)).round() ==
      1;
  final profileStep = _positive(
    inputs['profileStep'],
    defaultFor(spec, 'profileStep', 0.4),
  );
  final profilePieceLength = _positive(
    inputs['profilePieceLength'],
    defaultFor(spec, 'profilePieceLength', 3),
  );
  final profileRuns = needProfile ? (perimeter / profileStep).ceil() : 0;
  final profileLength = profileRuns * wallHeight;
  final profilePieces = needProfile
      ? (profileLength / profilePieceLength).ceil()
      : 0;

  final fastenersPerPanel = math.max(
    0,
    inputs['fastenersPerPanel'] ?? defaultFor(spec, 'fastenersPerPanel', 0),
  );
  final fasteners = (panelsCount * fastenersPerPanel).ceil();
  final needInsulation =
      (inputs['needInsulation'] ?? defaultFor(spec, 'needInsulation', 0))
          .round() ==
      1;
  final insulationPackArea = _positive(
    inputs['insulationPackArea'],
    defaultFor(spec, 'insulationPackArea', 5.76),
  );
  final insulationPacks = needInsulation
      ? (netArea / insulationPackArea).ceil()
      : 0;
  final insulationPurchaseArea = insulationPacks * insulationPackArea;

  final externalCorners = math.max(
    0,
    (inputs['externalCorners'] ?? defaultFor(spec, 'externalCorners', 4))
        .round(),
  );
  final cornerPieceLength = _positive(
    inputs['cornerPieceLength'],
    defaultFor(spec, 'cornerPieceLength', 3),
  );
  final starterPieceLength = _positive(
    inputs['starterPieceLength'],
    defaultFor(spec, 'starterPieceLength', 3),
  );
  final cornersCount = (externalCorners * wallHeight / cornerPieceLength)
      .ceil();
  final startersCount = (perimeter / starterPieceLength).ceil();

  final labels = spec.materialRule<Map>('panel_type_labels');
  final panelName = labels['$panelType'] as String? ?? 'Фасадные панели';
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: panelName,
      quantity: roundValue(exactPanelsRec, 6),
      unit: 'шт',
      withReserve: roundValue(exactPanelsRec, 6),
      purchaseQty: panelsCount.toDouble(),
      category: 'Облицовка',
    ),
    if (profilePieces > 0)
      CanonicalMaterialResult(
        name: 'Профиль/рейка',
        quantity: roundValue(profileLength, 6),
        unit: 'м',
        withReserve: roundValue(profileLength, 6),
        purchaseQty: roundValue(profilePieces * profilePieceLength, 6),
        category: 'Подсистема',
        packageInfo: {
          'count': profilePieces,
          'size': profilePieceLength,
          'packageUnit': 'шт',
        },
      ),
    if (fasteners > 0)
      CanonicalMaterialResult(
        name: 'Крепёж панелей',
        quantity: fasteners.toDouble(),
        unit: 'шт',
        withReserve: fasteners.toDouble(),
        purchaseQty: fasteners.toDouble(),
        category: 'Крепёж',
      ),
    if (needInsulation)
      CanonicalMaterialResult(
        name: 'Фасадный утеплитель',
        quantity: roundValue(netArea, 6),
        unit: 'м²',
        withReserve: roundValue(insulationPurchaseArea, 6),
        purchaseQty: roundValue(insulationPurchaseArea, 6),
        category: 'Утепление',
        packageInfo: {
          'count': insulationPacks,
          'size': insulationPackArea,
          'packageUnit': 'упак.',
        },
      ),
    if (cornersCount > 0)
      CanonicalMaterialResult(
        name: 'Наружные угловые элементы',
        quantity: cornersCount.toDouble(),
        unit: 'шт',
        withReserve: cornersCount.toDouble(),
        purchaseQty: cornersCount.toDouble(),
        category: 'Доборные элементы',
      ),
    if (startersCount > 0)
      CanonicalMaterialResult(
        name: 'Стартовые элементы',
        quantity: startersCount.toDouble(),
        unit: 'шт',
        withReserve: startersCount.toDouble(),
        purchaseQty: startersCount.toDouble(),
        category: 'Доборные элементы',
      ),
  ];

  final warnings = <String>[
    if (netArea <= 0) 'Площадь проёмов должна быть меньше общей площади стен',
    if (netArea > spec.warningRule<num>('large_area_threshold_m2').toDouble())
      'Для большого фасада закажите раскрой и спецификацию у поставщика системы',
    if (fastenersPerPanel == 0)
      'Крепёж не добавлен: укажите расход из паспорта выбранной фасадной системы',
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'inputMode': inputMode.toDouble(),
      'houseLength': houseLength,
      'houseWidth': houseWidth,
      'wallLength': perimeter,
      'wallHeight': wallHeight,
      'openingsArea': openingsArea,
      'grossArea': roundValue(grossArea, 6),
      'wallArea': roundValue(netArea, 6),
      'area': roundValue(netArea, 6),
      'panelType': panelType.toDouble(),
      'panelUsefulArea': panelUsefulArea,
      'reservePercent': reservePercent,
      'panelsArea': roundValue(panelsArea, 6),
      'panelsCount': panelsCount.toDouble(),
      'panels': panelsCount.toDouble(),
      'profileLength': roundValue(profileLength, 6),
      'profilePieces': profilePieces.toDouble(),
      'fasteners': fasteners.toDouble(),
      'insulationArea': roundValue(needInsulation ? netArea : 0, 6),
      'insulationPacks': insulationPacks.toDouble(),
      'insulationPurchaseArea': roundValue(insulationPurchaseArea, 6),
      'cornersCount': cornersCount.toDouble(),
      'startersCount': startersCount.toDouble(),
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
