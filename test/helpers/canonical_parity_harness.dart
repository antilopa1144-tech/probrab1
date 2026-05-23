import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/canonical_calculator_contract.dart';

typedef CanonicalCalculatorFn = CanonicalCalculatorContractResult Function(Map<String, double> inputs);
typedef CanonicalParityAssertion = void Function(
  CanonicalCalculatorContractResult result,
  Map<String, dynamic> expected,
  Map<String, double> inputs,
);

const double kParityNumericTolerance = 0.02;

CanonicalMaterialResult? findCanonicalMaterial(Iterable<CanonicalMaterialResult> materials, String namePart) {
  final needle = _normalizeMaterialLabel(namePart);
  for (final material in materials) {
    if (_normalizeMaterialLabel(material.name).contains(needle)) return material;
  }
  return null;
}

String _normalizeMaterialLabel(String value) {
  return value
      .replaceAll('U-', 'У-')
      .replaceAll('u-', 'у-')
      .toLowerCase();
}

bool materialLabelMatches(String actual, String expected) {
  final normalizedActual = _normalizeMaterialLabel(actual);
  final normalizedExpected = _normalizeMaterialLabel(expected);
  final expectedStem = normalizedExpected.split('(').first.trim();
  return normalizedActual.contains(expectedStem) ||
      normalizedExpected.contains(normalizedActual.split('(').first.trim());
}

void assertWebParityTotals(
  CanonicalCalculatorContractResult result,
  Map<String, dynamic> expectedTotals,
) {
  for (final entry in expectedTotals.entries) {
    final actual = result.totals[entry.key];
    expect(actual, isNotNull, reason: 'missing total "${entry.key}"');
    final expected = entry.value;
    if (expected is int) {
      expect(actual!.round(), expected, reason: 'total "${entry.key}"');
    } else if (expected is num) {
      expect(actual, closeTo(expected.toDouble(), kParityNumericTolerance),
          reason: 'total "${entry.key}"');
    }
  }
}

void assertWebParityCase(
  CanonicalCalculatorContractResult result,
  Map<String, dynamic> fixtureCase,
) {
  final expectedTotals = fixtureCase['expected_totals'] as Map<String, dynamic>?;
  if (expectedTotals != null) {
    assertWebParityTotals(result, expectedTotals);
  }

  final expectedMaterialsCount = fixtureCase['expected_materials_count'];
  if (expectedMaterialsCount is int) {
    expect(result.materials.length, expectedMaterialsCount);
  }

  final expectedMaterialNames =
      (fixtureCase['expected_material_names'] as List<dynamic>?)?.cast<String>();
  if (expectedMaterialNames != null) {
    for (final name in expectedMaterialNames) {
      expect(
        result.materials.any((material) => materialLabelMatches(material.name, name)),
        isTrue,
        reason: 'material "$name"',
      );
    }
  }

  final expectedWarningsCount = fixtureCase['expected_warnings_count'];
  if (expectedWarningsCount is int) {
    expect(result.warnings.length, expectedWarningsCount);
  }

  final expectedScenarios =
      fixtureCase['expected_scenarios'] as Map<String, dynamic>?;
  if (expectedScenarios != null) {
    for (final entry in expectedScenarios.entries) {
      final scenario = result.scenarios[entry.key];
      expect(scenario, isNotNull, reason: 'scenario ${entry.key}');
      final expected = entry.value as Map<String, dynamic>;
      if (expected['exact_need'] is num) {
        expect(
          scenario!.exactNeed,
          closeTo((expected['exact_need'] as num).toDouble(), kParityNumericTolerance),
          reason: '${entry.key}.exact_need',
        );
      }
      if (expected['purchase_quantity'] is num) {
        expect(
          scenario!.purchaseQuantity,
          closeTo((expected['purchase_quantity'] as num).toDouble(), kParityNumericTolerance),
          reason: '${entry.key}.purchase_quantity',
        );
      }
    }
  }
}

/// Cases where Flutter totals still diverge from the web parity baseline.
/// Remove entries after adapter/spec sync.
const Map<String, Set<String>> knownParityDriftByCalculator = {
};

void runWebParityFixtureFile({
  required String fixturePath,
  required CanonicalCalculatorFn calculate,
  Set<String> skipCaseIds = const {},
}) {
  final fixtureFile = File(fixturePath);
  final fixture = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
  final calculatorId = fixture['calculator_id'] as String? ?? fixturePath;
  final cases = (fixture['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

  group('web parity: $calculatorId', () {
    for (final fixtureCase in cases) {
      final caseId = fixtureCase['id'] as String;
      if (skipCaseIds.contains(caseId)) {
        test('$caseId (known drift)', () {}, skip: 'pending sync with web parity baseline');
        continue;
      }
      test(caseId, () {
        final rawInputs = (fixtureCase['inputs'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        final inputs = {...rawInputs, 'accuracyMode': 0.0};
        final result = calculate(inputs);
        assertWebParityCase(result, fixtureCase);
      });
    }
  });
}

void runCanonicalParitySuite({
  required String groupName,
  required String fixturePath,
  required CanonicalCalculatorFn calculate,
  required CanonicalParityAssertion assertCase,
}) {
  final fixtureFile = File(fixturePath);
  final fixture = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
  final cases = (fixture['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

  group(groupName, () {
    for (final fixtureCase in cases) {
      test(fixtureCase['id'] as String, () {
        final rawInputs = (fixtureCase['inputs'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        // Use basic accuracy mode for parity tests (matches web PARITY_ACCURACY_INPUTS)
        final inputs = {...rawInputs, 'accuracyMode': 0.0};
        final expected = fixtureCase['expected'] as Map<String, dynamic>;
        final result = calculate(inputs);
        assertCase(result, expected, inputs);
      });
    }
  });
}
