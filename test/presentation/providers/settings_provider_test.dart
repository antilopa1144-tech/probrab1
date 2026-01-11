import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettings', () {
    test('has correct default values', () {
      const settings = AppSettings();

      expect(settings.region, 'Москва');
      expect(settings.language, 'ru');
      expect(settings.autoSave, true);
      expect(settings.notificationsEnabled, true);
      expect(settings.unitSystem, 'metric');
      expect(settings.showTips, true);
      expect(settings.darkMode, false);
    });

    test('copyWith creates new instance with updated values', () {
      const original = AppSettings();
      final modified = original.copyWith(
        region: 'Санкт-Петербург',
        autoSave: false,
      );

      expect(modified.region, 'Санкт-Петербург');
      expect(modified.autoSave, false);
      // Other fields unchanged
      expect(modified.language, 'ru');
      expect(modified.notificationsEnabled, true);
    });

    test('copyWith preserves original values when not specified', () {
      const original = AppSettings(
        region: 'Краснодар',
        language: 'en',
        autoSave: false,
      );
      final modified = original.copyWith(darkMode: false);

      expect(modified.region, 'Краснодар');
      expect(modified.language, 'en');
      expect(modified.autoSave, false);
      expect(modified.darkMode, false);
    });

    test('toJson returns correct map', () {
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

    test('fromJson creates correct instance', () {
      final json = {
        'region': 'Новосибирск',
        'language': 'en',
        'autoSave': false,
        'notificationsEnabled': true,
        'unitSystem': 'imperial',
        'showTips': false,
        'darkMode': false,
      };

      final settings = AppSettings.fromJson(json);

      expect(settings.region, 'Новосибирск');
      expect(settings.language, 'en');
      expect(settings.autoSave, false);
      expect(settings.notificationsEnabled, true);
      expect(settings.unitSystem, 'imperial');
      expect(settings.showTips, false);
      expect(settings.darkMode, false);
    });

    test('fromJson uses defaults for missing values', () {
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

    test('fromJson handles partial data', () {
      final json = {
        'region': 'Екатеринбург',
        'autoSave': false,
      };

      final settings = AppSettings.fromJson(json);

      expect(settings.region, 'Екатеринбург');
      expect(settings.autoSave, false);
      // Defaults for missing
      expect(settings.language, 'ru');
      expect(settings.notificationsEnabled, true);
    });

    test('all fields can be modified with copyWith', () {
      const original = AppSettings();
      final modified = original.copyWith(
        region: 'A',
        language: 'B',
        autoSave: false,
        notificationsEnabled: false,
        unitSystem: 'C',
        showTips: false,
        darkMode: false,
      );

      expect(modified.region, 'A');
      expect(modified.language, 'B');
      expect(modified.autoSave, false);
      expect(modified.notificationsEnabled, false);
      expect(modified.unitSystem, 'C');
      expect(modified.showTips, false);
      expect(modified.darkMode, false);
    });

    test('copyWith returns different instance', () {
      const original = AppSettings();
      final modified = original.copyWith(region: 'Test');

      expect(identical(original, modified), false);
    });

    test('toJson and fromJson are inverse operations', () {
      const original = AppSettings(
        region: 'Test',
        language: 'en',
        autoSave: false,
        notificationsEnabled: false,
        unitSystem: 'imperial',
        showTips: false,
        darkMode: false,
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
    // Note: SettingsNotifier has async initialization in constructor
    // which makes it difficult to test state changes reliably.
    // We test basic provider creation and type checks.

    test('provider can be created', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings, isA<AppSettings>());
    });

    test('notifier can be accessed', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      expect(notifier, isA<SettingsNotifier>());
    });

    test('initial state has default values', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.region, 'Москва');
      expect(settings.language, 'ru');
    });
  });
}
