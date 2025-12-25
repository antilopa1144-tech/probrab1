import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization Coverage', () {
    late Map<String, dynamic> ruJson;

    setUpAll(() {
      ruJson = jsonDecode(
        File('assets/lang/ru.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('ru.json has no empty values', () {
      final emptyKeys = <String>[];
      _checkEmptyValues(ruJson, '', emptyKeys);

      expect(
        emptyKeys,
        isEmpty,
        reason: 'Empty values in ru.json: ${emptyKeys.take(10).join(", ")}',
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
