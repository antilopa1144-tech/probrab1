import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/canonical_adapter_registry.dart';
import '../../helpers/canonical_parity_harness.dart';

void main() {
  final fixtureDir = Directory('test/parity_fixtures');
  final fixtures = fixtureDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.parity.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final fixtureFile in fixtures) {
    final fixtureName = fixtureFile.uri.pathSegments.last;
    final raw = fixtureFile.readAsStringSync();
    final calculatorId = RegExp(r'"calculator_id"\s*:\s*"([^"]+)"')
        .firstMatch(raw)
        ?.group(1);

    if (calculatorId == null) {
      test('skip malformed fixture $fixtureName', () {}, skip: 'missing calculator_id');
      continue;
    }

    final normalizedId = calculatorId.replaceAll('-', '_');
    if (pendingCanonicalAdapterIds.contains(normalizedId)) {
      test('pending adapter: $calculatorId', () {}, skip: 'adapter not implemented');
      continue;
    }

    final adapter = lookupCanonicalAdapter(calculatorId);
    if (adapter == null) {
      test('missing adapter: $calculatorId', () {
        fail('No adapter registered for $calculatorId ($fixtureName)');
      });
      continue;
    }

    runWebParityFixtureFile(
      fixturePath: fixtureFile.path,
      calculate: adapter,
      skipCaseIds: knownParityDriftByCalculator[calculatorId] ?? const {},
    );
  }
}
