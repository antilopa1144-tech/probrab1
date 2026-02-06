// ignore_for_file: avoid_print, unintended_html_in_doc_comment, unnecessary_string_interpolations, prefer_const_declarations

/// Скрипт измерения baseline производительности.
///
/// Измеряет и сохраняет метрики:
/// - Размер APK/App Bundle
/// - Количество строк кода
/// - Количество файлов
/// - Время сборки (опционально)
/// - Размер assets
///
/// Использование: dart run scripts/performance_baseline.dart
///
/// Опции:
///   --save           Сохранить baseline в файл
///   --compare        Сравнить с предыдущим baseline
///   --output <path>  Путь для сохранения (по умолчанию .performance_baseline.json)
///   --build          Также измерить время сборки (медленно)
library;

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final shouldSave = args.contains('--save');
  final shouldCompare = args.contains('--compare');
  final shouldBuild = args.contains('--build');

  final outputIndex = args.indexOf('--output');
  final outputPath = outputIndex != -1 && args.length > outputIndex + 1
      ? args[outputIndex + 1]
      : '.performance_baseline.json';

  print('📊 Измерение метрик производительности...\n');

  final metrics = <String, dynamic>{};
  metrics['timestamp'] = DateTime.now().toIso8601String();
  metrics['gitCommit'] = _getGitCommit();
  metrics['gitBranch'] = _getGitBranch();

  // 1. Подсчёт строк кода
  print('📝 Подсчёт строк кода...');
  final codeMetrics = _countLinesOfCode();
  metrics['code'] = codeMetrics;
  print('   Dart файлов: ${codeMetrics['dartFiles']}');
  print('   Строк кода: ${codeMetrics['totalLines']}');
  print('   Строк без пустых: ${codeMetrics['nonEmptyLines']}');

  // 2. Размер assets
  print('\n📦 Измерение размера assets...');
  final assetsMetrics = _measureAssets();
  metrics['assets'] = assetsMetrics;
  print('   Всего файлов: ${assetsMetrics['totalFiles']}');
  print('   Общий размер: ${_formatSize(assetsMetrics['totalSizeBytes'] as int)}');

  // 3. Зависимости
  print('\n📚 Анализ зависимостей...');
  final depsMetrics = _analyzeDependencies();
  metrics['dependencies'] = depsMetrics;
  print('   Прямых зависимостей: ${depsMetrics['direct']}');
  print('   Dev зависимостей: ${depsMetrics['dev']}');

  // 4. Тесты
  print('\n🧪 Подсчёт тестов...');
  final testMetrics = _countTests();
  metrics['tests'] = testMetrics;
  print('   Тестовых файлов: ${testMetrics['testFiles']}');
  print('   Тестовых функций: ${testMetrics['testFunctions']}');

  // 5. Калькуляторы
  print('\n🧮 Подсчёт калькуляторов...');
  final calcMetrics = _countCalculators();
  metrics['calculators'] = calcMetrics;
  print('   Use cases: ${calcMetrics['useCases']}');
  print('   V2 Definitions: ${calcMetrics['v2Definitions']}');

  // 6. APK размер (если существует)
  print('\n📱 Поиск сборок...');
  final buildMetrics = _findBuilds();
  metrics['builds'] = buildMetrics;
  if (buildMetrics['apkSize'] != null) {
    print('   APK размер: ${_formatSize(buildMetrics['apkSize'] as int)}');
  }
  if (buildMetrics['aabSize'] != null) {
    print('   AAB размер: ${_formatSize(buildMetrics['aabSize'] as int)}');
  }
  if (buildMetrics['apkSize'] == null && buildMetrics['aabSize'] == null) {
    print('   Сборки не найдены (запустите flutter build apk)');
  }

  // 7. Время сборки (опционально)
  if (shouldBuild) {
    print('\n⏱️  Измерение времени сборки...');
    final buildTime = await _measureBuildTime();
    metrics['buildTimeMs'] = buildTime;
    print('   Время сборки: ${(buildTime / 1000).toStringAsFixed(1)} сек');
  }

  // Сравнение с предыдущим baseline
  if (shouldCompare) {
    final baselineFile = File(outputPath);
    if (baselineFile.existsSync()) {
      print('\n📈 Сравнение с предыдущим baseline...');
      final previous = jsonDecode(baselineFile.readAsStringSync()) as Map<String, dynamic>;
      _compareMetrics(previous, metrics);
    } else {
      print('\n⚠️  Предыдущий baseline не найден: $outputPath');
    }
  }

  // Сохранение
  if (shouldSave) {
    File(outputPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(metrics),
    );
    print('\n✅ Baseline сохранён в: $outputPath');
  }

  // Итоговый отчёт
  print('\n${'═' * 60}');
  print('ИТОГОВЫЕ МЕТРИКИ');
  print('${'═' * 60}');
  print('');
  print('Код:');
  print('  Строк кода:          ${codeMetrics['totalLines']}');
  print('  Dart файлов:         ${codeMetrics['dartFiles']}');
  print('');
  print('Тесты:');
  print('  Тестовых файлов:     ${testMetrics['testFiles']}');
  print('  Тестовых функций:    ${testMetrics['testFunctions']}');
  print('');
  print('Калькуляторы:');
  print('  Use cases:           ${calcMetrics['useCases']}');
  print('  V2 Definitions:      ${calcMetrics['v2Definitions']}');
  print('');
  print('Assets:');
  print('  Файлов:              ${assetsMetrics['totalFiles']}');
  print('  Размер:              ${_formatSize(assetsMetrics['totalSizeBytes'] as int)}');
}

String _getGitCommit() {
  final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
  return (result.stdout as String).trim();
}

String _getGitBranch() {
  final result = Process.runSync('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  return (result.stdout as String).trim();
}

Map<String, dynamic> _countLinesOfCode() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    return {'dartFiles': 0, 'totalLines': 0, 'nonEmptyLines': 0, 'commentLines': 0};
  }

  var dartFiles = 0;
  var totalLines = 0;
  var nonEmptyLines = 0;
  var commentLines = 0;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      dartFiles++;
      final lines = entity.readAsLinesSync();
      totalLines += lines.length;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          nonEmptyLines++;
          if (trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) {
            commentLines++;
          }
        }
      }
    }
  }

  return {
    'dartFiles': dartFiles,
    'totalLines': totalLines,
    'nonEmptyLines': nonEmptyLines,
    'commentLines': commentLines,
    'codeLines': nonEmptyLines - commentLines,
  };
}

Map<String, dynamic> _measureAssets() {
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    return {'totalFiles': 0, 'totalSizeBytes': 0, 'byType': {}};
  }

  var totalFiles = 0;
  var totalSize = 0;
  final byType = <String, int>{};

  for (final entity in assetsDir.listSync(recursive: true)) {
    if (entity is File) {
      totalFiles++;
      final size = entity.lengthSync();
      totalSize += size;

      final ext = entity.path.contains('.') ? entity.path.split('.').last.toLowerCase() : 'other';
      byType[ext] = (byType[ext] ?? 0) + size;
    }
  }

  return {
    'totalFiles': totalFiles,
    'totalSizeBytes': totalSize,
    'byType': byType,
  };
}

Map<String, dynamic> _analyzeDependencies() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    return {'direct': 0, 'dev': 0};
  }

  final content = pubspecFile.readAsStringSync();
  final lines = content.split('\n');

  var inDependencies = false;
  var inDevDependencies = false;
  var direct = 0;
  var dev = 0;

  for (final line in lines) {
    if (line.startsWith('dependencies:')) {
      inDependencies = true;
      inDevDependencies = false;
      continue;
    }
    if (line.startsWith('dev_dependencies:')) {
      inDependencies = false;
      inDevDependencies = true;
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('\t')) {
      inDependencies = false;
      inDevDependencies = false;
    }

    if (line.trim().isNotEmpty && !line.trim().startsWith('#')) {
      if (inDependencies && line.startsWith('  ') && line.contains(':')) {
        direct++;
      }
      if (inDevDependencies && line.startsWith('  ') && line.contains(':')) {
        dev++;
      }
    }
  }

  return {'direct': direct, 'dev': dev};
}

Map<String, dynamic> _countTests() {
  final testDir = Directory('test');
  if (!testDir.existsSync()) {
    return {'testFiles': 0, 'testFunctions': 0};
  }

  var testFiles = 0;
  var testFunctions = 0;

  for (final entity in testDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('_test.dart')) {
      testFiles++;
      final content = entity.readAsStringSync();
      // Считаем test() и testWidgets() вызовы
      testFunctions += RegExp(r'\btest\s*\(').allMatches(content).length;
      testFunctions += RegExp(r'\btestWidgets\s*\(').allMatches(content).length;
    }
  }

  return {'testFiles': testFiles, 'testFunctions': testFunctions};
}

Map<String, dynamic> _countCalculators() {
  var useCases = 0;
  var v2Definitions = 0;

  // Use cases
  final useCasesDir = Directory('lib/domain/usecases');
  if (useCasesDir.existsSync()) {
    for (final entity in useCasesDir.listSync()) {
      if (entity is File && entity.path.contains('calculate_') && entity.path.endsWith('.dart')) {
        useCases++;
      }
    }
  }

  // V2 Definitions
  final calculatorsDir = Directory('lib/domain/calculators');
  if (calculatorsDir.existsSync()) {
    for (final entity in calculatorsDir.listSync()) {
      if (entity is File && entity.path.endsWith('_v2.dart')) {
        v2Definitions++;
      }
    }
  }

  // Definitions from index
  final definitionsDir = Directory('lib/domain/calculators/definitions');
  if (definitionsDir.existsSync()) {
    for (final entity in definitionsDir.listSync()) {
      if (entity is File && entity.path.endsWith('.dart') && !entity.path.contains('index')) {
        final content = entity.readAsStringSync();
        v2Definitions +=
            RegExp(r'final\s+\w+\s*=\s*CalculatorDefinitionV2').allMatches(content).length;
      }
    }
  }

  return {'useCases': useCases, 'v2Definitions': v2Definitions};
}

Map<String, dynamic> _findBuilds() {
  final result = <String, dynamic>{};

  // APK
  final apkPath = 'build/app/outputs/flutter-apk/app-release.apk';
  final apkFile = File(apkPath);
  if (apkFile.existsSync()) {
    result['apkSize'] = apkFile.lengthSync();
    result['apkPath'] = apkPath;
  }

  // AAB
  final aabPath = 'build/app/outputs/bundle/release/app-release.aab';
  final aabFile = File(aabPath);
  if (aabFile.existsSync()) {
    result['aabSize'] = aabFile.lengthSync();
    result['aabPath'] = aabPath;
  }

  return result;
}

Future<int> _measureBuildTime() async {
  final stopwatch = Stopwatch()..start();

  final result = await Process.run(
    'flutter',
    ['build', 'apk', '--release'],
    runInShell: true,
  );

  stopwatch.stop();

  if (result.exitCode != 0) {
    print('   ⚠️  Ошибка сборки: ${result.stderr}');
  }

  return stopwatch.elapsedMilliseconds;
}

void _compareMetrics(Map<String, dynamic> previous, Map<String, dynamic> current) {
  print('');

  // Код
  final prevCode = previous['code'] as Map<String, dynamic>?;
  final currCode = current['code'] as Map<String, dynamic>;
  if (prevCode != null) {
    final linesDiff = (currCode['totalLines'] as int) - (prevCode['totalLines'] as int);
    final filesDiff = (currCode['dartFiles'] as int) - (prevCode['dartFiles'] as int);
    print('Код:');
    print('  Строк: ${_formatDiff(linesDiff)}');
    print('  Файлов: ${_formatDiff(filesDiff)}');
  }

  // Assets
  final prevAssets = previous['assets'] as Map<String, dynamic>?;
  final currAssets = current['assets'] as Map<String, dynamic>;
  if (prevAssets != null) {
    final sizeDiff =
        (currAssets['totalSizeBytes'] as int) - (prevAssets['totalSizeBytes'] as int);
    print('Assets:');
    print('  Размер: ${_formatSizeDiff(sizeDiff)}');
  }

  // Тесты
  final prevTests = previous['tests'] as Map<String, dynamic>?;
  final currTests = current['tests'] as Map<String, dynamic>;
  if (prevTests != null) {
    final testsDiff =
        (currTests['testFunctions'] as int) - (prevTests['testFunctions'] as int);
    print('Тесты:');
    print('  Функций: ${_formatDiff(testsDiff)}');
  }

  // APK
  final prevBuilds = previous['builds'] as Map<String, dynamic>?;
  final currBuilds = current['builds'] as Map<String, dynamic>;
  if (prevBuilds != null && prevBuilds['apkSize'] != null && currBuilds['apkSize'] != null) {
    final apkDiff = (currBuilds['apkSize'] as int) - (prevBuilds['apkSize'] as int);
    print('APK:');
    print('  Размер: ${_formatSizeDiff(apkDiff)}');
  }
}

String _formatDiff(int diff) {
  if (diff == 0) return '0 (без изменений)';
  if (diff > 0) return '+$diff ↑';
  return '$diff ↓';
}

String _formatSizeDiff(int diff) {
  if (diff == 0) return '0 (без изменений)';
  final formatted = _formatSize(diff.abs());
  if (diff > 0) return '+$formatted ↑';
  return '-$formatted ↓';
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
