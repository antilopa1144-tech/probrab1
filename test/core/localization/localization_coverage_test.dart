import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization Coverage', () {
    late Map<String, dynamic> ruJson;
    late Map<String, dynamic> enJson;

    setUpAll(() {
      ruJson = jsonDecode(
        File('assets/lang/ru.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      enJson = jsonDecode(
        File('assets/lang/en.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('en.json contains all keys from ru.json', () {
      final ruKeys = _flattenKeys(ruJson);
      final enKeys = _flattenKeys(enJson);
      final missingInEn = ruKeys.difference(enKeys);

      expect(
        missingInEn,
        isEmpty,
        reason: 'Missing keys in en.json: ${missingInEn.take(10).join(", ")}... '
            '(total ${missingInEn.length})',
      );
    });

    test('en.json has no empty values', () {
      final emptyKeys = <String>[];
      _checkEmptyValues(enJson, '', emptyKeys);

      expect(
        emptyKeys,
        isEmpty,
        reason: 'Empty values in en.json: ${emptyKeys.take(10).join(", ")}',
      );
    });

    for (final lang in ['kk', 'ky', 'tg', 'tk', 'uz']) {
      test('$lang.json coverage is at least 90% of ru.json', () {
        final langJson = jsonDecode(
          File('assets/lang/$lang.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final ruKeys = _flattenKeys(ruJson);
        final langKeys = _flattenKeys(langJson);
        final coverage = langKeys.length / ruKeys.length;

        expect(
          coverage,
          greaterThanOrEqualTo(0.9),
          reason: '$lang.json coverage: ${(coverage * 100).toStringAsFixed(1)}%',
        );
      });
    }
  });
}

Set<String> _flattenKeys(Map<String, dynamic> map, [String prefix = '']) {
  final keys = <String>{};
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      keys.addAll(_flattenKeys(value, key));
    } else {
      keys.add(key);
    }
  }
  return keys;
}

void _checkEmptyValues(
  Map<String, dynamic> map,
  String prefix,
  List<String> emptyKeys,
) {
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      _checkEmptyValues(value, key, emptyKeys);
    } else if (value is String && value.isEmpty) {
      emptyKeys.add(key);
    }
  }
}
