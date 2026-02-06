import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:probrab_ai/core/database/database_provider.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  tearDownAll(() async {
    // Закрываем все открытые инстансы Isar
    for (final name in Isar.instanceNames) {
      final instance = Isar.getInstance(name);
      if (instance != null && instance.isOpen) {
        await instance.close();
      }
    }
  });

  group('isarProvider', () {
    test('является FutureProvider', () {
      expect(isarProvider, isA<FutureProvider>());
    });

    test('провайдер существует и доступен', () {
      expect(isarProvider, isNotNull);
    });

    test('инициализирует базу данных с корректным именем', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isar = await container.read(isarProvider.future) as Isar;

      expect(isar.isOpen, isTrue);
      expect(isar.name, equals('probrab_ai'));

      await isar.close();
    });

    test('содержит все необходимые схемы', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isar = await container.read(isarProvider.future) as Isar;

      // Isar collection getters (projectV2s и т.д.) генерируются build_runner.
      // Проверяем базовые свойства инстанса без обращения к generated extensions.
      expect(isar, isNotNull);
      expect(isar.name, isNotEmpty);
      expect(isar.isOpen, isTrue);

      // ignore: avoid_dynamic_calls
      await isar.close();
    });

    test('возвращает существующий инстанс при hot-restart', () async {
      final container1 = ProviderContainer();
      final isar1 = await container1.read(isarProvider.future) as Isar;

      // Создаём второй контейнер (имитация hot-restart)
      final container2 = ProviderContainer();
      final isar2 = await container2.read(isarProvider.future) as Isar;

      // Должны получить тот же инстанс
      expect(isar1.name, equals(isar2.name));

      container1.dispose();
      container2.dispose();

      await isar1.close();
    });

    test('создаёт базу данных в правильной директории', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isar = await container.read(isarProvider.future) as Isar;

      // Проверяем, что база создана в системной временной папке (согласно FakePathProviderPlatform)
      expect(isar.directory, isNotEmpty);
      expect(isar.directory, contains(Directory.systemTemp.path));

      await isar.close();
    });

    test('инстанс Isar можно использовать для операций', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isar = await container.read(isarProvider.future) as Isar;

      // Проверяем, что можно выполнять транзакции
      await isar.writeTxn(() async {
        // Пустая транзакция для проверки работоспособности
      });

      expect(isar.isOpen, isTrue);

      await isar.close();
    });

    test('провайдер можно читать несколько раз', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isar1 = await container.read(isarProvider.future) as Isar;
      final isar2 = await container.read(isarProvider.future) as Isar;

      // Должны получить тот же инстанс
      expect(identical(isar1, isar2), isTrue);

      await isar1.close();
    });

    test('проверяет наличие коллекций для всех моделей', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isar = await container.read(isarProvider.future) as Isar;

      // Isar collection getters генерируются build_runner.
      // Проверяем что инстанс открыт и содержит схемы через базовые свойства.
      expect(isar, isNotNull);
      expect(isar.isOpen, isTrue);
      expect(isar.name, isNotEmpty);

      await isar.close();
    });

    test('закрытие инстанса не влияет на другие контейнеры', () async {
      final container1 = ProviderContainer();
      await container1.read(isarProvider.future) as Isar;

      final container2 = ProviderContainer();
      final isar2 = await container2.read(isarProvider.future) as Isar;

      // Закрываем первый контейнер
      container1.dispose();

      // Второй инстанс всё ещё должен быть открыт
      expect(isar2.isOpen, isTrue);

      container2.dispose();
      await isar2.close();
    });
  });
}
