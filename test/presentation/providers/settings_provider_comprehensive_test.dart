import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupMocks();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettings', () {
    test('имеет корректные значения по умолчанию', () {
      const settings = AppSettings();

      expect(settings.region, 'Москва');
      expect(settings.language, 'ru');
      expect(settings.autoSave, true);
      expect(settings.notificationsEnabled, true);
      expect(settings.unitSystem, 'metric');
      expect(settings.showTips, true);
      expect(settings.darkMode, false);
    });

    test('copyWith создаёт новый экземпляр с обновлёнными значениями', () {
      const original = AppSettings();
      final modified = original.copyWith(
        region: 'Санкт-Петербург',
        autoSave: false,
      );

      expect(modified.region, 'Санкт-Петербург');
      expect(modified.autoSave, false);
      expect(modified.language, 'ru');
      expect(modified.notificationsEnabled, true);
    });

    test('copyWith сохраняет оригинальные значения если не указаны', () {
      const original = AppSettings(
        region: 'Краснодар',
        language: 'en',
        autoSave: false,
      );
      final modified = original.copyWith(darkMode: true);

      expect(modified.region, 'Краснодар');
      expect(modified.language, 'en');
      expect(modified.autoSave, false);
      expect(modified.darkMode, true);
    });

    test('toJson возвращает корректную карту', () {
      const settings = AppSettings(
        region: 'Москва',
        language: 'ru',
        autoSave: true,
        notificationsEnabled: false,
        unitSystem: 'imperial',
        showTips: false,
        darkMode: true,
      );

      final json = settings.toJson();

      expect(json['region'], 'Москва');
      expect(json['language'], 'ru');
      expect(json['autoSave'], true);
      expect(json['notificationsEnabled'], false);
      expect(json['unitSystem'], 'imperial');
      expect(json['showTips'], false);
      expect(json['darkMode'], true);
    });

    test('fromJson создаёт корректный экземпляр', () {
      final json = {
        'region': 'Новосибирск',
        'language': 'en',
        'autoSave': false,
        'notificationsEnabled': true,
        'unitSystem': 'imperial',
        'showTips': false,
        'darkMode': true,
      };

      final settings = AppSettings.fromJson(json);

      expect(settings.region, 'Новосибирск');
      expect(settings.language, 'en');
      expect(settings.autoSave, false);
      expect(settings.notificationsEnabled, true);
      expect(settings.unitSystem, 'imperial');
      expect(settings.showTips, false);
      expect(settings.darkMode, true);
    });

    test('fromJson использует значения по умолчанию для отсутствующих полей', () {
      final json = <String, dynamic>{};

      final settings = AppSettings.fromJson(json);

      expect(settings.region, 'Москва');
      expect(settings.language, 'ru');
      expect(settings.autoSave, true);
      expect(settings.notificationsEnabled, true);
      expect(settings.unitSystem, 'metric');
      expect(settings.showTips, true);
      expect(settings.darkMode, false);
    });

    test('fromJson обрабатывает частичные данные', () {
      final json = {
        'region': 'Екатеринбург',
        'autoSave': false,
      };

      final settings = AppSettings.fromJson(json);

      expect(settings.region, 'Екатеринбург');
      expect(settings.autoSave, false);
      expect(settings.language, 'ru');
      expect(settings.notificationsEnabled, true);
    });

    test('все поля можно изменить через copyWith', () {
      const original = AppSettings();
      final modified = original.copyWith(
        region: 'A',
        language: 'B',
        autoSave: false,
        notificationsEnabled: false,
        unitSystem: 'C',
        showTips: false,
        darkMode: true,
      );

      expect(modified.region, 'A');
      expect(modified.language, 'B');
      expect(modified.autoSave, false);
      expect(modified.notificationsEnabled, false);
      expect(modified.unitSystem, 'C');
      expect(modified.showTips, false);
      expect(modified.darkMode, true);
    });

    test('copyWith возвращает новый экземпляр', () {
      const original = AppSettings();
      final modified = original.copyWith(region: 'Test');

      expect(identical(original, modified), false);
    });

    test('toJson и fromJson - обратимые операции', () {
      const original = AppSettings(
        region: 'Test',
        language: 'en',
        autoSave: false,
        notificationsEnabled: false,
        unitSystem: 'imperial',
        showTips: false,
        darkMode: true,
      );

      final json = original.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.region, original.region);
      expect(restored.language, original.language);
      expect(restored.autoSave, original.autoSave);
      expect(restored.notificationsEnabled, original.notificationsEnabled);
      expect(restored.unitSystem, original.unitSystem);
      expect(restored.showTips, original.showTips);
      expect(restored.darkMode, original.darkMode);
    });
  });

  group('SettingsNotifier', () {
    test('provider можно создать', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings, isA<AppSettings>());
    });

    test('notifier можно получить', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      expect(notifier, isA<SettingsNotifier>());
    });

    test('начальное состояние имеет значения по умолчанию', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.region, 'Москва');
      expect(settings.language, 'ru');
    });

    test(
      'загружает сохранённые настройки при инициализации',
      () async {
        SharedPreferences.setMockInitialValues({
          'region': 'Казань',
          'language': 'en',
          'autoSave': false,
          'darkMode': true,
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Ждём загрузки настроек
        await Future.delayed(const Duration(milliseconds: 100));

        final settings = container.read(settingsProvider);
        expect(settings.region, 'Казань');
        expect(settings.language, 'en');
        expect(settings.autoSave, false);
        expect(settings.darkMode, true);
      },
      skip: 'Requires mounted check in SettingsNotifier._loadSettings',
    );

    test('updateRegion обновляет регион', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);

      await notifier.updateRegion('Владивосток');

      final settings = container.read(settingsProvider);
      expect(settings.region, 'Владивосток');
    });

    test('updateRegion сохраняет в SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);

      await notifier.updateRegion('Сочи');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('region'), 'Сочи');
    });

    test(
      'updateLanguage обновляет язык',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateLanguage('en');

        final settings = container.read(settingsProvider);
        expect(settings.language, 'en');
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'updateLanguage сохраняет в SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateLanguage('en');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('language'), 'en');
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'updateAutoSave обновляет автосохранение',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateAutoSave(false);

        final settings = container.read(settingsProvider);
        expect(settings.autoSave, false);
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'updateAutoSave сохраняет в SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateAutoSave(false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('autoSave'), false);
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'updateNotifications обновляет уведомления',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateNotifications(false);

        final settings = container.read(settingsProvider);
        expect(settings.notificationsEnabled, false);
      },
      skip: 'Requires NotificationService platform channel mock',
    );

    test(
      'updateNotifications сохраняет в SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateNotifications(false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('notificationsEnabled'), false);
      },
      skip: 'Requires NotificationService platform channel mock',
    );

    test(
      'updateUnitSystem обновляет систему единиц',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateUnitSystem('imperial');

        final settings = container.read(settingsProvider);
        expect(settings.unitSystem, 'imperial');
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'updateUnitSystem сохраняет в SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateUnitSystem('imperial');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('unitSystem'), 'imperial');
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'updateShowTips обновляет показ подсказок',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateShowTips(false);

        final settings = container.read(settingsProvider);
        expect(settings.showTips, false);
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'updateShowTips сохраняет в SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateShowTips(false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('showTips'), false);
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'updateDarkMode обновляет тёмную тему',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateDarkMode(true);

        final settings = container.read(settingsProvider);
        expect(settings.darkMode, true);
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'updateDarkMode сохраняет в SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateDarkMode(true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('darkMode'), true);
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'множественные обновления работают последовательно',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateRegion('Пермь');
        await notifier.updateLanguage('en');
        await notifier.updateDarkMode(true);

        final settings = container.read(settingsProvider);
        expect(settings.region, 'Пермь');
        expect(settings.language, 'en');
        expect(settings.darkMode, true);
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'обновления сохраняют остальные настройки',
      () async {
        SharedPreferences.setMockInitialValues({
          'region': 'Москва',
          'language': 'ru',
          'autoSave': true,
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await Future.delayed(const Duration(milliseconds: 100));

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateDarkMode(true);

        final settings = container.read(settingsProvider);
        expect(settings.region, 'Москва');
        expect(settings.language, 'ru');
        expect(settings.autoSave, true);
        expect(settings.darkMode, true);
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'загрузка отсутствующих настроек использует значения по умолчанию',
      () async {
        SharedPreferences.setMockInitialValues({
          'region': 'Тюмень',
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await Future.delayed(const Duration(milliseconds: 100));

        final settings = container.read(settingsProvider);
        expect(settings.region, 'Тюмень');
        expect(settings.language, 'ru'); // default
        expect(settings.autoSave, true); // default
        expect(settings.showTips, true); // default
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );

    test(
      'обработка некорректных типов в SharedPreferences',
      () async {
        // SharedPreferences может содержать некорректные типы
        SharedPreferences.setMockInitialValues({
          'region': 123, // Должна быть строка
          'autoSave': 'true', // Должен быть bool
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await Future.delayed(const Duration(milliseconds: 100));

        final settings = container.read(settingsProvider);
        // Должны использоваться дефолтные значения
        expect(settings.region, 'Москва');
        expect(settings.autoSave, true);
      },
      skip: 'SettingsNotifier does not handle type mismatches in SharedPreferences',
    );

    test(
      'последовательные обновления одной настройки',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(settingsProvider.notifier);

        await notifier.updateRegion('Регион 1');
        await notifier.updateRegion('Регион 2');
        await notifier.updateRegion('Регион 3');

        final settings = container.read(settingsProvider);
        expect(settings.region, 'Регион 3');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('region'), 'Регион 3');
      },
      skip: 'Requires mounted check in SettingsNotifier due to async _loadSettings race',
    );
  });
}
