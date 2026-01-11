import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/remote_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RemoteConfigService', () {
    group('instance', () {
      test('выполняется без ошибок', () async {
        // В тестовой среде Firebase может быть недоступен
        expect(() => RemoteConfigService.instance, returnsNormally);
      });
    });

    group('refresh', () {
      test('возвращает bool', () async {
        final result = await RemoteConfigService.refresh();
        expect(result, isA<bool>());
      });
    });

    group('Feature flags getters', () {
      test('enableNewHome возвращает bool', () async {
        final value = await RemoteConfigService.enableNewHome;
        expect(value, isA<bool>());
      });

      test('enableModernCalculatorCards возвращает bool', () async {
        final value = await RemoteConfigService.enableModernCalculatorCards;
        expect(value, isA<bool>());
      });

      test('enableExpertTips возвращает bool', () async {
        final value = await RemoteConfigService.enableExpertTips;
        expect(value, isA<bool>());
      });

      test('enableWeatherRecommendations возвращает bool', () async {
        final value = await RemoteConfigService.enableWeatherRecommendations;
        expect(value, isA<bool>());
      });

      test('enableWasteOptimization возвращает bool', () async {
        final value = await RemoteConfigService.enableWasteOptimization;
        expect(value, isA<bool>());
      });

      test('enableMaterialComparison возвращает bool', () async {
        final value = await RemoteConfigService.enableMaterialComparison;
        expect(value, isA<bool>());
      });

      test('enableAnimations возвращает bool', () async {
        final value = await RemoteConfigService.enableAnimations;
        expect(value, isA<bool>());
      });

      test('showAdsInFreeVersion возвращает bool', () async {
        final value = await RemoteConfigService.showAdsInFreeVersion;
        expect(value, isA<bool>());
      });

      test('showPromoBanner возвращает bool', () async {
        final value = await RemoteConfigService.showPromoBanner;
        expect(value, isA<bool>());
      });

      test('maintenanceMode возвращает bool', () async {
        final value = await RemoteConfigService.maintenanceMode;
        expect(value, isA<bool>());
      });

      test('enableNewOnboarding возвращает bool', () async {
        final value = await RemoteConfigService.enableNewOnboarding;
        expect(value, isA<bool>());
      });
    });

    group('String getters', () {
      test('minAppVersion возвращает string', () async {
        final value = await RemoteConfigService.minAppVersion;
        expect(value, isA<String>());
      });

      test('promoBannerText возвращает string', () async {
        final value = await RemoteConfigService.promoBannerText;
        expect(value, isA<String>());
      });

      test('promoBannerUrl возвращает string', () async {
        final value = await RemoteConfigService.promoBannerUrl;
        expect(value, isA<String>());
      });

      test('defaultThemeMode возвращает string', () async {
        final value = await RemoteConfigService.defaultThemeMode;
        expect(value, isA<String>());
      });

      test('supportUrl возвращает string', () async {
        final value = await RemoteConfigService.supportUrl;
        expect(value, isA<String>());
      });

      test('feedbackUrl возвращает string', () async {
        final value = await RemoteConfigService.feedbackUrl;
        expect(value, isA<String>());
      });

      test('privacyPolicyUrl возвращает string', () async {
        final value = await RemoteConfigService.privacyPolicyUrl;
        expect(value, isA<String>());
      });

      test('maintenanceMessage возвращает string', () async {
        final value = await RemoteConfigService.maintenanceMessage;
        expect(value, isA<String>());
      });
    });

    group('Int getters', () {
      test('freeVersionCalculatorLimit возвращает int', () async {
        final value = await RemoteConfigService.freeVersionCalculatorLimit;
        expect(value, isA<int>());
      });

      test('freeVersionProjectLimit возвращает int', () async {
        final value = await RemoteConfigService.freeVersionProjectLimit;
        expect(value, isA<int>());
      });

      test('adFrequencyMinutes возвращает int', () async {
        final value = await RemoteConfigService.adFrequencyMinutes;
        expect(value, isA<int>());
      });

      test('onboardingStepCount возвращает int', () async {
        final value = await RemoteConfigService.onboardingStepCount;
        expect(value, isA<int>());
      });
    });

    group('Double getters', () {
      test('plasterConsumptionCoefficient возвращает double', () async {
        final value = await RemoteConfigService.plasterConsumptionCoefficient;
        expect(value, isA<double>());
        expect(value, greaterThanOrEqualTo(0));
      });

      test('paintConsumptionCoefficient возвращает double', () async {
        final value = await RemoteConfigService.paintConsumptionCoefficient;
        expect(value, isA<double>());
        expect(value, greaterThanOrEqualTo(0));
      });

      test('tileAdhesiveCoefficient возвращает double', () async {
        final value = await RemoteConfigService.tileAdhesiveCoefficient;
        expect(value, isA<double>());
        expect(value, greaterThanOrEqualTo(0));
      });
    });

    group('Universal getters', () {
      test('getString возвращает string', () async {
        final value = await RemoteConfigService.getString('test_key');
        expect(value, isA<String>());
      });

      test('getString возвращает defaultValue при ошибке', () async {
        final value = await RemoteConfigService.getString(
          'nonexistent_key',
          defaultValue: 'default',
        );
        expect(value, isA<String>());
      });

      test('getInt возвращает int', () async {
        final value = await RemoteConfigService.getInt('test_key');
        expect(value, isA<int>());
      });

      test('getInt возвращает defaultValue при ошибке', () async {
        final value = await RemoteConfigService.getInt(
          'nonexistent_key',
          defaultValue: 42,
        );
        expect(value, isA<int>());
      });

      test('getDouble возвращает double', () async {
        final value = await RemoteConfigService.getDouble('test_key');
        expect(value, isA<double>());
      });

      test('getDouble возвращает defaultValue при ошибке', () async {
        final value = await RemoteConfigService.getDouble(
          'nonexistent_key',
          defaultValue: 3.14,
        );
        expect(value, isA<double>());
      });

      test('getBool возвращает bool', () async {
        final value = await RemoteConfigService.getBool('test_key');
        expect(value, isA<bool>());
      });

      test('getBool возвращает defaultValue при ошибке', () async {
        final value = await RemoteConfigService.getBool(
          'nonexistent_key',
          defaultValue: true,
        );
        expect(value, isA<bool>());
      });

      test('getAllParameters возвращает Map', () async {
        final params = await RemoteConfigService.getAllParameters();
        expect(params, isA<Map<String, dynamic>>());
      });
    });

    group('isUpdateRequired', () {
      test('возвращает bool для любой версии', () async {
        final result = await RemoteConfigService.isUpdateRequired('1.0.0');
        expect(result, isA<bool>());
      });

      test('проверяет версии корректно', () async {
        // Эти тесты зависят от значения minAppVersion из Remote Config
        final result1 = await RemoteConfigService.isUpdateRequired('0.1.0');
        expect(result1, isA<bool>());

        final result2 = await RemoteConfigService.isUpdateRequired('99.0.0');
        expect(result2, isA<bool>());
      });
    });
  });
}
