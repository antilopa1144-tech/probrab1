import 'dart:math' as math;

import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';

/// Round [value] to [decimals] decimal places.
double roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

/// Get default value for input field [key] from spec's inputSchema.
double defaultFor(SpecReader spec, String key, double fallback) {
  return spec.inputDefault(key, fallback);
}

/// Build key factors map for a given [scenario] from the factor table.
Map<String, double> buildKeyFactors(
  List<String> enabledFactors,
  Map<String, Map<String, double>> factorTable,
  String scenario,
) {
  final result = <String, double>{};
  for (final name in enabledFactors) {
    final range = factorTable[name];
    if (range == null) continue;
    result[name] = _pickFactor(range, scenario);
  }
  return result;
}

/// Calculate combined multiplier for a given [scenario].
double scenarioMultiplier(
  List<String> enabledFactors,
  Map<String, Map<String, double>> factorTable,
  String scenario,
) {
  var multiplier = 1.0;
  for (final name in enabledFactors) {
    final range = factorTable[name];
    if (range == null) continue;
    multiplier *= _pickFactor(range, scenario);
  }
  return multiplier;
}

double _pickFactor(Map<String, double> range, String scenario) {
  switch (scenario) {
    case 'MIN':
      return range['MIN'] ?? range['min'] ?? 1.0;
    case 'MAX':
      return range['MAX'] ?? range['max'] ?? 1.0;
    default:
      return range['REC'] ?? range['rec'] ?? 1.0;
  }
}

/// Standard scenario names.
const List<String> scenarioNames = ['MIN', 'REC', 'MAX'];

/// Resolve area from inputMode (0=by dims, 1=by area).
Map<String, double> resolveArea(
  SpecReader spec,
  Map<String, double> inputs, {
  String lengthKey = 'length',
  String widthKey = 'width',
  String areaKey = 'area',
  double minLength = 0.5,
  double minWidth = 0.5,
  double minArea = 1.0,
}) {
  final inputMode = (inputs['inputMode'] ?? spec.inputDefault('inputMode', 1)).round();
  if (inputMode == 0) {
    final length = math.max(minLength, inputs[lengthKey] ?? spec.inputDefault(lengthKey, 5));
    final width = math.max(minWidth, inputs[widthKey] ?? spec.inputDefault(widthKey, 4));
    return {'inputMode': 0, 'area': roundValue(length * width, 3)};
  }
  return {
    'inputMode': 1,
    'area': roundValue(math.max(minArea, inputs[areaKey] ?? spec.inputDefault(areaKey, 20)), 3),
  };
}

/// Build a standard CanonicalScenarioResult.
CanonicalScenarioResult buildScenarioResult({
  required double exactNeed,
  required double purchaseQuantity,
  required double leftover,
  required String formulaVersion,
  required String packageLabel,
  required double packageSize,
  required int packageCount,
  required String unit,
  required Map<String, double> keyFactors,
  required double multiplier,
  List<String> extraAssumptions = const [],
}) {
  return CanonicalScenarioResult(
    exactNeed: exactNeed,
    purchaseQuantity: purchaseQuantity,
    leftover: leftover,
    assumptions: [
      'formula_version:$formulaVersion',
      'packaging:$packageLabel',
      ...extraAssumptions,
    ],
    keyFactors: {
      ...keyFactors,
      'field_multiplier': roundValue(multiplier, 6),
    },
    buyPlan: CanonicalBuyPlan(
      packageLabel: packageLabel,
      packageSize: packageSize,
      packagesCount: packageCount,
      unit: unit,
    ),
  );
}
