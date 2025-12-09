import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Фейковая реализация PathProvider для модульных тестов.
///
/// Flutter тесты запускаются без нативных плагинов, поэтому обращения
/// к [getApplicationDocumentsDirectory] завершаются MissingPluginException.
/// Этот класс предоставляет временную директорию внутри [Directory.systemTemp].
class TestPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  TestPathProviderPlatform() {
    _documentsDir = Directory.systemTemp.createTempSync('probrab_test_docs_');
  }

  late final Directory _documentsDir;

  /// Путь к каталогу документов приложения.
  @override
  Future<String?> getApplicationDocumentsPath() async => _documentsDir.path;

  /// Используем тот же путь для application support, чтобы не плодить каталоги.
  @override
  Future<String?> getApplicationSupportPath() async => _documentsDir.path;

  /// Возвращаем отдельную временную директорию.
  @override
  Future<String?> getTemporaryPath() async {
    final dir = await Directory.systemTemp.createTemp('probrab_test_tmp_');
    return dir.path;
  }

  /// Освобождаем созданные ресурсы.
  void dispose() {
    if (_documentsDir.existsSync()) {
      _documentsDir.deleteSync(recursive: true);
    }
  }
}

/// Устанавливает тестовый PathProvider и возвращает экземпляр для очистки.
TestPathProviderPlatform installTestPathProvider() {
  final provider = TestPathProviderPlatform();
  PathProviderPlatform.instance = provider;
  return provider;
}
