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

CanonicalMaterialResult? findCanonicalMaterial(Iterable<CanonicalMaterialResult> materials, String namePart) {
  for (final material in materials) {
    if (material.name.contains(namePart)) return material;
  }
  return null;
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
        final inputs = (fixtureCase['inputs'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        final expected = fixtureCase['expected'] as Map<String, dynamic>;
        final result = calculate(inputs);
        assertCase(result, expected, inputs);
      });
    }
  });
}
