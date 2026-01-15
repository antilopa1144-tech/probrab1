// ignore_for_file: avoid_print

/// Скрипт поиска неиспользуемых ресурсов.
///
/// Анализирует:
/// - Изображения (png, jpg, jpeg, gif, webp, svg)
/// - Иконки
/// - Шрифты
/// - JSON файлы
///
/// Использование: dart run scripts/unused_assets_cleaner.dart
///
/// Опции:
///   --delete    Удалить неиспользуемые файлы (ОСТОРОЖНО!)
///   --json      Вывод в JSON формате
///   --verbose   Подробный вывод
library;

import 'dart:io';

void main(List<String> args) {
  final shouldDelete = args.contains('--delete');
  final jsonOutput = args.contains('--json');
  final verbose = args.contains('--verbose');

  if (!jsonOutput) {
    print('🔍 Поиск неиспользуемых ресурсов...\n');
  }

  // 1. Собираем все файлы ресурсов
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    print('ERROR: Папка assets не найдена!');
    exit(1);
  }

  final assetFiles = <AssetFile>[];
  final imageExtensions = {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.ico'};
  final fontExtensions = {'.ttf', '.otf', '.woff', '.woff2'};
  final dataExtensions = {'.json', '.xml', '.yaml', '.yml'};

  _collectFiles(assetsDir, assetFiles, imageExtensions, fontExtensions, dataExtensions);

  if (!jsonOutput) {
    print('Найдено файлов ресурсов: ${assetFiles.length}');
    print('  - Изображения: ${assetFiles.where((f) => f.type == AssetType.image).length}');
    print('  - Шрифты: ${assetFiles.where((f) => f.type == AssetType.font).length}');
    print('  - Данные: ${assetFiles.where((f) => f.type == AssetType.data).length}');
    print('  - Другое: ${assetFiles.where((f) => f.type == AssetType.other).length}');
    print('');
  }

  // 2. Собираем все Dart файлы
  final libDir = Directory('lib');
  final testDir = Directory('test');

  final dartFiles = <File>[];
  if (libDir.existsSync()) {
    _collectDartFiles(libDir, dartFiles);
  }
  if (testDir.existsSync()) {
    _collectDartFiles(testDir, dartFiles);
  }

  if (!jsonOutput) {
    print('Dart файлов для анализа: ${dartFiles.length}');
  }

  // 3. Читаем содержимое всех Dart файлов
  final allDartContent = StringBuffer();
  for (final file in dartFiles) {
    allDartContent.writeln(file.readAsStringSync());
  }
  final dartContentStr = allDartContent.toString();

  // Также проверяем pubspec.yaml для шрифтов
  final pubspecFile = File('pubspec.yaml');
  final pubspecContent = pubspecFile.existsSync() ? pubspecFile.readAsStringSync() : '';

  // 4. Проверяем использование каждого ресурса
  final unusedAssets = <AssetFile>[];
  final usedAssets = <AssetFile>[];

  for (final asset in assetFiles) {
    final isUsed = _isAssetUsed(asset, dartContentStr, pubspecContent);
    if (isUsed) {
      usedAssets.add(asset);
    } else {
      unusedAssets.add(asset);
    }

    if (verbose && !jsonOutput) {
      final status = isUsed ? '✓' : '✗';
      print('  $status ${asset.relativePath}');
    }
  }

  // 5. Подсчитываем размер
  var unusedSize = 0;
  for (final asset in unusedAssets) {
    unusedSize += asset.file.lengthSync();
  }

  // 6. Выводим результаты
  if (jsonOutput) {
    _printJsonOutput(unusedAssets, usedAssets, unusedSize);
  } else {
    _printTextOutput(unusedAssets, usedAssets, unusedSize);
  }

  // 7. Удаление (если запрошено)
  if (shouldDelete && unusedAssets.isNotEmpty) {
    print('\n⚠️  УДАЛЕНИЕ ФАЙЛОВ...');
    for (final asset in unusedAssets) {
      try {
        asset.file.deleteSync();
        print('  Удалён: ${asset.relativePath}');
      } catch (e) {
        print('  ОШИБКА при удалении ${asset.relativePath}: $e');
      }
    }
    print('\n✅ Удалено файлов: ${unusedAssets.length}');
    print('   Освобождено: ${_formatSize(unusedSize)}');
  }

  // Exit code
  if (unusedAssets.isNotEmpty && !shouldDelete) {
    exit(1);
  }
}

void _collectFiles(
  Directory dir,
  List<AssetFile> assets,
  Set<String> imageExt,
  Set<String> fontExt,
  Set<String> dataExt,
) {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File) {
      final path = entity.path;
      final ext = path.contains('.') ? '.${path.split('.').last.toLowerCase()}' : '';

      // Пропускаем системные файлы
      if (path.contains('.DS_Store') || path.contains('Thumbs.db')) continue;

      AssetType type;
      if (imageExt.contains(ext)) {
        type = AssetType.image;
      } else if (fontExt.contains(ext)) {
        type = AssetType.font;
      } else if (dataExt.contains(ext)) {
        type = AssetType.data;
      } else {
        type = AssetType.other;
      }

      // Относительный путь
      final relativePath = path.replaceAll('\\', '/');

      assets.add(AssetFile(
        file: entity,
        relativePath: relativePath,
        type: type,
        fileName: path.split(Platform.pathSeparator).last,
      ));
    }
  }
}

void _collectDartFiles(Directory dir, List<File> files) {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity);
    }
  }
}

bool _isAssetUsed(AssetFile asset, String dartContent, String pubspecContent) {
  final fileName = asset.fileName;
  final relativePath = asset.relativePath;

  // Проверяем различные способы ссылки на ресурс
  final checks = [
    // Полный путь
    relativePath,
    // Путь без начального слэша
    relativePath.replaceFirst('assets/', ''),
    // Только имя файла
    fileName,
    // Имя без расширения (для Image.asset с условиями)
    fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName,
  ];

  // Специальные проверки для разных типов
  if (asset.type == AssetType.font) {
    // Шрифты обычно указываются в pubspec.yaml
    for (final check in checks) {
      if (pubspecContent.contains(check)) return true;
    }
  }

  // JSON файлы данных — проверяем особые случаи
  if (asset.type == AssetType.data && fileName.endsWith('.json')) {
    // Ценовые файлы используются через PriceDataSource
    if (fileName.startsWith('prices_')) return true;
    // Языковые файлы используются через LocalizationService
    if (relativePath.contains('lang/')) return true;
    // Константы используются через ConstantsDataSource
    if (fileName.contains('constants')) return true;
  }

  // Иконки приложения всегда используются
  if (fileName.contains('app_icon') || fileName.contains('ic_launcher')) {
    return true;
  }

  // Проверяем в Dart коде
  for (final check in checks) {
    if (dartContent.contains(check)) return true;
    // Также проверяем с одинарными кавычками
    if (dartContent.contains("'$check'")) return true;
    // И с двойными
    if (dartContent.contains('"$check"')) return true;
  }

  return false;
}

void _printTextOutput(List<AssetFile> unused, List<AssetFile> used, int unusedSize) {
  print('\n${'═' * 60}');
  print('РЕЗУЛЬТАТЫ АНАЛИЗА РЕСУРСОВ');
  print('${'═' * 60}');
  print('');
  print('СТАТИСТИКА:');
  print('  Всего ресурсов:        ${unused.length + used.length}');
  print('  Используется:          ${used.length}');
  print('  Не используется:       ${unused.length}');
  print('  Потенциальная экономия: ${_formatSize(unusedSize)}');
  print('');

  if (unused.isNotEmpty) {
    print('НЕИСПОЛЬЗУЕМЫЕ РЕСУРСЫ:');
    print('-' * 50);

    // Группируем по типу
    final byType = <AssetType, List<AssetFile>>{};
    for (final asset in unused) {
      byType.putIfAbsent(asset.type, () => []).add(asset);
    }

    for (final entry in byType.entries) {
      print('\n  ${_typeToString(entry.key)} (${entry.value.length}):');
      for (final asset in entry.value) {
        final size = _formatSize(asset.file.lengthSync());
        print('    - ${asset.relativePath} ($size)');
      }
    }

    print('\n');
    print('💡 Для удаления запустите: dart run scripts/unused_assets_cleaner.dart --delete');
  } else {
    print('✅ Все ресурсы используются!');
  }
}

void _printJsonOutput(List<AssetFile> unused, List<AssetFile> used, int unusedSize) {
  final output = {
    'total': unused.length + used.length,
    'used': used.length,
    'unused': unused.length,
    'unusedSizeBytes': unusedSize,
    'unusedSizeFormatted': _formatSize(unusedSize),
    'unusedFiles': unused
        .map((a) => {
              'path': a.relativePath,
              'type': a.type.toString().split('.').last,
              'sizeBytes': a.file.lengthSync(),
            })
        .toList(),
  };

  print(_jsonEncode(output));
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

String _typeToString(AssetType type) {
  switch (type) {
    case AssetType.image:
      return 'Изображения';
    case AssetType.font:
      return 'Шрифты';
    case AssetType.data:
      return 'Файлы данных';
    case AssetType.other:
      return 'Другое';
  }
}

String _jsonEncode(Map<String, dynamic> data) {
  // Простой JSON encoder без зависимостей
  final buffer = StringBuffer();
  buffer.write('{');
  var first = true;
  for (final entry in data.entries) {
    if (!first) buffer.write(',');
    first = false;
    buffer.write('"${entry.key}":');
    buffer.write(_encodeValue(entry.value));
  }
  buffer.write('}');
  return buffer.toString();
}

String _encodeValue(dynamic value) {
  if (value == null) return 'null';
  if (value is bool) return value.toString();
  if (value is num) return value.toString();
  if (value is String) return '"${_escapeString(value)}"';
  if (value is List) {
    return '[${value.map(_encodeValue).join(',')}]';
  }
  if (value is Map) {
    final entries = value.entries.map((e) => '"${e.key}":${_encodeValue(e.value)}');
    return '{${entries.join(',')}}';
  }
  return '"$value"';
}

String _escapeString(String s) {
  return s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}

enum AssetType { image, font, data, other }

class AssetFile {
  final File file;
  final String relativePath;
  final AssetType type;
  final String fileName;

  AssetFile({
    required this.file,
    required this.relativePath,
    required this.type,
    required this.fileName,
  });
}
