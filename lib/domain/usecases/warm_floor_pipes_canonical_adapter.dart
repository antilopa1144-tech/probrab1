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

/// Геометрическая оценка трубы или проверка готовой проектной ведомости.
///
/// Адаптер намеренно не назначает шаг, длину петли, запас, слои пола или
/// гидравлику. Все проектные значения вводятся явно и совпадают с web v2.
CanonicalCalculatorContractResult calculateCanonicalWarmFloorPipes(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(warmFloorPipesSpecData);
  final calculationMode = _readWhole(spec, inputs, 'calculationMode', 0, 0, 1);
  final layoutAreaM2 = _read(spec, inputs, 'layoutAreaM2', 15, 0.1, 500);
  final pipeSpacingMm = _read(spec, inputs, 'pipeSpacingMm', 150, 50, 500);
  final connectionLengthM = _read(
    spec,
    inputs,
    'connectionLengthM',
    0,
    0,
    1000,
  );
  final projectTotalPipeLengthM = _read(
    spec,
    inputs,
    'projectTotalPipeLengthM',
    0,
    0,
    10000,
  );
  final circuitCount = _readWhole(spec, inputs, 'circuitCount', 0, 0, 100);
  final longestCircuitLengthM = _read(
    spec,
    inputs,
    'longestCircuitLengthM',
    0,
    0,
    1000,
  );
  final maxCircuitLengthM = _read(
    spec,
    inputs,
    'maxCircuitLengthM',
    0,
    0,
    1000,
  );
  final coilLengthM = _read(spec, inputs, 'coilLengthM', 0, 0, 5000);
  final collectorCount = _readWhole(spec, inputs, 'collectorCount', 0, 0, 20);
  final manifoldOutletCount = _readWhole(
    spec,
    inputs,
    'manifoldOutletCount',
    0,
    0,
    200,
  );

  final fieldPipeLengthM = calculationMode == 0
      ? layoutAreaM2 / (pipeSpacingMm / 1000)
      : 0.0;
  final exactPipeLengthM = calculationMode == 0
      ? fieldPipeLengthM + connectionLengthM
      : projectTotalPipeLengthM;
  final requiredCoilCount = coilLengthM > 0 && exactPipeLengthM > 0
      ? (exactPipeLengthM / coilLengthM).ceil()
      : 0;
  final purchasePipeLengthM = coilLengthM > 0
      ? requiredCoilCount * coilLengthM
      : exactPipeLengthM;
  final leftoverPipeLengthM = purchasePipeLengthM - exactPipeLengthM;
  final averageCircuitLengthM = circuitCount > 0
      ? exactPipeLengthM / circuitCount
      : 0.0;

  final meterUnit = spec.packagingRule<String>('meter_unit');
  final coilUnit = spec.packagingRule<String>('coil_unit');
  final pieceUnit = spec.packagingRule<String>('piece_unit');
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: calculationMode == 0
          ? 'Труба для водяного тёплого пола — предварительная геометрия'
          : 'Труба для водяного тёплого пола по проектной ведомости',
      quantity: roundValue(exactPipeLengthM, 6),
      unit: meterUnit,
      withReserve: roundValue(purchasePipeLengthM, 6),
      purchaseQty: roundValue(purchasePipeLengthM, 6),
      category: 'Основное',
      packageInfo: coilLengthM > 0
          ? {
              'count': requiredCoilCount,
              'size': roundValue(coilLengthM, 6),
              'packageUnit': coilUnit,
            }
          : null,
    ),
  ];

  if (collectorCount > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: manifoldOutletCount > 0
            ? 'Коллектор по проектной ведомости — всего $manifoldOutletCount выходов'
            : 'Коллектор по проектной ведомости',
        quantity: collectorCount.toDouble(),
        unit: pieceUnit,
        withReserve: collectorCount.toDouble(),
        purchaseQty: collectorCount.toDouble(),
        category: 'Управление',
      ),
    );
  }

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: roundValue(exactPipeLengthM, 6),
      purchaseQuantity: roundValue(purchasePipeLengthM, 6),
      leftover: roundValue(leftoverPipeLengthM, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'calculationMode:$calculationMode',
        'no_hidden_reserve',
        coilLengthM > 0 ? 'coil_length_from_user' : 'purchase_by_meter',
      ],
      keyFactors: const {'field_multiplier': 1},
      buyPlan: CanonicalBuyPlan(
        packageLabel: coilLengthM > 0
            ? 'water-floor-pipe-coil'
            : 'water-floor-pipe-meter',
        packageSize: coilLengthM > 0 ? roundValue(coilLengthM, 6) : 1,
        packagesCount: coilLengthM > 0
            ? requiredCoilCount
            : exactPipeLengthM.ceil(),
        unit: coilLengthM > 0 ? coilUnit : meterUnit,
      ),
    );
  }

  final warnings = <String>[
    'Калькулятор не назначает шаг трубы и не проверяет теплоотдачу, температуру поверхности, гидравлику, насос, балансировку или источник тепла.',
    'ЭППС, демпферная лента, крепёж, арматура коллектора и стяжка не добавлены: состав конструкции пола и ведомость материалов берутся из проекта.',
  ];
  if (calculationMode == 0) {
    warnings.add(
      'Предварительный режим оценивает геометрическую длину по фактической площади раскладки и шагу из проекта; повороты, краевые зоны и трассы учитывайте планом.',
    );
  } else if (projectTotalPipeLengthM <= 0) {
    warnings.add(
      'Введите суммарную длину всех контуров из проектной ведомости.',
    );
  }
  if (circuitCount <= 0) {
    warnings.add(
      'Число контуров не введено — средняя и фактическая длина петель не проверяются.',
    );
  } else if (longestCircuitLengthM <= 0) {
    warnings.add(
      'Показана только средняя длина: для гидравлической проверки нужна длина самого длинного контура.',
    );
  }
  if (maxCircuitLengthM > 0 && longestCircuitLengthM <= 0) {
    warnings.add(
      'Введён предельный размер контура, но не введена длина самой длинной петли.',
    );
  } else if (maxCircuitLengthM > 0 &&
      longestCircuitLengthM > maxCircuitLengthM) {
    warnings.add(
      'Самый длинный контур превышает предел из проекта или документации выбранной системы.',
    );
  }
  if (coilLengthM > 0) {
    warnings.add(
      'Округление по общей длине до бухт не проверяет план раскроя непрерывных контуров и отсутствие соединений в конструкции пола.',
    );
    if (longestCircuitLengthM > coilLengthM) {
      warnings.add(
        'Самый длинный контур больше одной выбранной бухты — такой комплект не обеспечивает непрерывную петлю.',
      );
    }
  }
  if (manifoldOutletCount > 0 && collectorCount <= 0) {
    warnings.add('Выходы коллектора введены без количества самих коллекторов.');
  }
  if (circuitCount > 0 &&
      manifoldOutletCount > 0 &&
      manifoldOutletCount < circuitCount) {
    warnings.add(
      'Введённых выходов коллектора меньше числа контуров по ведомости.',
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'calculationMode': calculationMode.toDouble(),
      'layoutAreaM2': roundValue(layoutAreaM2, 3),
      'pipeSpacingMm': roundValue(pipeSpacingMm, 3),
      'fieldPipeLengthM': roundValue(fieldPipeLengthM, 3),
      'connectionLengthM': roundValue(connectionLengthM, 3),
      'projectTotalPipeLengthM': roundValue(projectTotalPipeLengthM, 3),
      'exactPipeLengthM': roundValue(exactPipeLengthM, 3),
      'circuitCount': circuitCount.toDouble(),
      'averageCircuitLengthM': roundValue(averageCircuitLengthM, 3),
      'longestCircuitLengthM': roundValue(longestCircuitLengthM, 3),
      'maxCircuitLengthM': roundValue(maxCircuitLengthM, 3),
      'coilLengthM': roundValue(coilLengthM, 3),
      'requiredCoilCount': requiredCoilCount.toDouble(),
      'purchasePipeLengthM': roundValue(purchasePipeLengthM, 3),
      'leftoverPipeLengthM': roundValue(leftoverPipeLengthM, 3),
      'collectorCount': collectorCount.toDouble(),
      'manifoldOutletCount': manifoldOutletCount.toDouble(),
      'minExactNeed': roundValue(exactPipeLengthM, 6),
      'recExactNeed': roundValue(exactPipeLengthM, 6),
      'maxExactNeed': roundValue(exactPipeLengthM, 6),
      'minPurchase': roundValue(purchasePipeLengthM, 6),
      'recPurchase': roundValue(purchasePipeLengthM, 6),
      'maxPurchase': roundValue(purchasePipeLengthM, 6),
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
