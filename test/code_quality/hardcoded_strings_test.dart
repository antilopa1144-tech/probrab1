import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No hardcoded Cyrillic text in Dart files', () {
    final roots = [
      Directory('lib/presentation/views/calculator'),
      Directory('lib/presentation/widgets'),
    ];
    final russianPattern = RegExp(
      "'[\\u0400-\\u04FF][^']*'|\"[\\u0400-\\u04FF][^\"]*\"",
    );

    final violations = <String>[];

    for (final root in roots) {
      if (!root.existsSync()) continue;
      for (final file in root.listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        if (file.path.contains('.g.dart')) continue;
        if (file.path.contains('localization')) continue;

        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) {
            continue;
          }

          final matches = russianPattern.allMatches(line);
          for (final match in matches) {
            violations.add('${file.path}:${i + 1}: ${match.group(0)}');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Hardcoded Cyrillic strings found:\n'
          '${violations.take(20).join("\n")}',
    );
  });
}
