import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;

bool _isarInitialized = false;

/// Инициализация нативной библиотеки Isar для модульных тестов.
///
/// Flutter тесты выполняются в изолированной среде без плагинов, поэтому
/// автоматическое подключение `libisar.dll` не срабатывает. Эта функция
/// находит библиотеку внутри `isar_community_flutter_libs` и явно
/// инициализирует IsarCore.
Future<void> ensureIsarInitialized() async {
  if (_isarInitialized) return;

  final packageDir = await _findPackageRoot('isar_community_flutter_libs');
  final windowsLib = File(p.join(packageDir.path, 'windows', 'libisar.dll'));

  if (!windowsLib.existsSync()) {
    throw StateError('Файл Isar не найден: ${windowsLib.path}');
  }

  await Isar.initializeIsarCore(
    libraries: {Abi.windowsX64: windowsLib.path},
  );
  _isarInitialized = true;
}

Future<Directory> _findPackageRoot(String packageName) async {
  final configFile = File(p.join('.dart_tool', 'package_config.json'));
  if (!configFile.existsSync()) {
    throw StateError('Не найден .dart_tool/package_config.json');
  }

  final json = jsonDecode(await configFile.readAsString())
      as Map<String, dynamic>;
  final packages = (json['packages'] as List<dynamic>?) ?? const [];
  final configDir = configFile.parent.uri;

  for (final entry in packages) {
    final map = entry as Map<String, dynamic>;
    if (map['name'] == packageName) {
      final rootUri = configDir.resolve(map['rootUri'] as String);
      return Directory.fromUri(rootUri);
    }
  }
  throw StateError('Пакет $packageName не найден в package_config.json');
}
