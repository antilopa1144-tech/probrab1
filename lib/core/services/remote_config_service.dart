import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с Firebase Remote Config и A/B тестирования
///
/// Позволяет:
/// - Получать удалённые конфигурации
/// - Проводить A/B тесты
/// - Динамически менять параметры приложения без обновления
class RemoteConfigService {
  static FirebaseRemoteConfig? _remoteConfig;

  /// Получить инстанс Remote Config
  static Future<FirebaseRemoteConfig> get instance async {
    if (_remoteConfig != null) return _remoteConfig!;

    _remoteConfig = FirebaseRemoteConfig.instance;
    await _initialize();
    return _remoteConfig!;
  }

  /// Инициализация Remote Config
  static Future<void> _initialize() async {
    if (_remoteConfig == null) return;

    try {
      // Настройки для разработки (короткий интервал обновления)
      if (kDebugMode) {
        await _remoteConfig!.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 10),
            minimumFetchInterval: const Duration(minutes: 1),
          ),
        );
      } else {
        // Настройки для продакшена
        await _remoteConfig!.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 10),
            minimumFetchInterval: const Duration(hours: 1),
          ),
        );
      }

      // Установить значения по умолчанию
      await _remoteConfig!.setDefaults(_defaultValues);

      // Загрузить и активировать конфигурацию
      await _remoteConfig!.fetchAndActivate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Remote Config initialization error: $e');
      }
    }
  }

  /// Значения по умолчанию
  static const Map<String, dynamic> _defaultValues = {
    // A/B тест: показывать ли новую главную страницу
    'enable_new_home': false,

    // A/B тест: новый дизайн карточек калькуляторов
    'enable_modern_calculator_cards': true,

    // A/B тест: показывать ли советы экспертов
    'enable_expert_tips': true,

    // Минимальная версия приложения
    'min_app_version': '1.0.0',

    // Показывать ли баннер с акцией
    'show_promo_banner': false,
    'promo_banner_text': 'Специальное предложение!',
    'promo_banner_url': '',

    // Лимиты для бесплатной версии
    'free_version_calculator_limit': 10,
    'free_version_project_limit': 3,

    // Коэффициенты для калькуляторов (для экспериментов)
    'plaster_consumption_coefficient': 1.0,
    'paint_consumption_coefficient': 1.0,
    'tile_adhesive_coefficient': 1.0,

    // Включить ли новые функции
    'enable_weather_recommendations': false,
    'enable_waste_optimization': false,
    'enable_material_comparison': true,

    // Настройки UI
    'default_theme_mode': 'system', // system, light, dark
    'enable_animations': true,

    // Рекламные настройки
    'show_ads_in_free_version': false,
    'ad_frequency_minutes': 5,

    // Ссылки
    'support_url': 'https://example.com/support',
    'feedback_url': 'https://example.com/feedback',
    'privacy_policy_url': 'https://example.com/privacy',

    // Сообщения для пользователей
    'maintenance_mode': false,
    'maintenance_message': 'Идёт техническое обслуживание',

    // A/B тест: новый онбординг
    'enable_new_onboarding': false,
    'onboarding_step_count': 3,
  };

  /// Обновить конфигурацию из Firebase
  static Future<bool> refresh() async {
    try {
      final config = await instance;
      return await config.fetchAndActivate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Remote Config refresh error: $e');
      }
      return false;
    }
  }

  // ============================================================================
  // Getters для конфигурационных параметров
  // ============================================================================

  /// Включена ли новая главная страница (A/B тест)
  static Future<bool> get enableNewHome async {
    final config = await instance;
    return config.getBool('enable_new_home');
  }

  /// Включены ли современные карточки калькуляторов (A/B тест)
  static Future<bool> get enableModernCalculatorCards async {
    final config = await instance;
    return config.getBool('enable_modern_calculator_cards');
  }

  /// Показывать ли советы экспертов (A/B тест)
  static Future<bool> get enableExpertTips async {
    final config = await instance;
    return config.getBool('enable_expert_tips');
  }

  /// Минимальная версия приложения
  static Future<String> get minAppVersion async {
    final config = await instance;
    return config.getString('min_app_version');
  }

  /// Показывать ли баннер с промо-акцией
  static Future<bool> get showPromoBanner async {
    final config = await instance;
    return config.getBool('show_promo_banner');
  }

  /// Текст промо-баннера
  static Future<String> get promoBannerText async {
    final config = await instance;
    return config.getString('promo_banner_text');
  }

  /// URL промо-баннера
  static Future<String> get promoBannerUrl async {
    final config = await instance;
    return config.getString('promo_banner_url');
  }

  /// Лимит калькуляторов для бесплатной версии
  static Future<int> get freeVersionCalculatorLimit async {
    final config = await instance;
    return config.getInt('free_version_calculator_limit');
  }

  /// Лимит проектов для бесплатной версии
  static Future<int> get freeVersionProjectLimit async {
    final config = await instance;
    return config.getInt('free_version_project_limit');
  }

  /// Коэффициент расхода штукатурки (для экспериментов)
  static Future<double> get plasterConsumptionCoefficient async {
    final config = await instance;
    return config.getDouble('plaster_consumption_coefficient');
  }

  /// Коэффициент расхода краски (для экспериментов)
  static Future<double> get paintConsumptionCoefficient async {
    final config = await instance;
    return config.getDouble('paint_consumption_coefficient');
  }

  /// Коэффициент расхода плиточного клея (для экспериментов)
  static Future<double> get tileAdhesiveCoefficient async {
    final config = await instance;
    return config.getDouble('tile_adhesive_coefficient');
  }

  /// Включены ли рекомендации по погоде
  static Future<bool> get enableWeatherRecommendations async {
    final config = await instance;
    return config.getBool('enable_weather_recommendations');
  }

  /// Включена ли оптимизация отходов
  static Future<bool> get enableWasteOptimization async {
    final config = await instance;
    return config.getBool('enable_waste_optimization');
  }

  /// Включено ли сравнение материалов
  static Future<bool> get enableMaterialComparison async {
    final config = await instance;
    return config.getBool('enable_material_comparison');
  }

  /// Режим темы по умолчанию
  static Future<String> get defaultThemeMode async {
    final config = await instance;
    return config.getString('default_theme_mode');
  }

  /// Включены ли анимации
  static Future<bool> get enableAnimations async {
    final config = await instance;
    return config.getBool('enable_animations');
  }

  /// Показывать ли рекламу в бесплатной версии
  static Future<bool> get showAdsInFreeVersion async {
    final config = await instance;
    return config.getBool('show_ads_in_free_version');
  }

  /// Частота показа рекламы (в минутах)
  static Future<int> get adFrequencyMinutes async {
    final config = await instance;
    return config.getInt('ad_frequency_minutes');
  }

  /// URL службы поддержки
  static Future<String> get supportUrl async {
    final config = await instance;
    return config.getString('support_url');
  }

  /// URL для обратной связи
  static Future<String> get feedbackUrl async {
    final config = await instance;
    return config.getString('feedback_url');
  }

  /// URL политики конфиденциальности
  static Future<String> get privacyPolicyUrl async {
    final config = await instance;
    return config.getString('privacy_policy_url');
  }

  /// Режим технического обслуживания
  static Future<bool> get maintenanceMode async {
    final config = await instance;
    return config.getBool('maintenance_mode');
  }

  /// Сообщение технического обслуживания
  static Future<String> get maintenanceMessage async {
    final config = await instance;
    return config.getString('maintenance_message');
  }

  /// Включён ли новый онбординг (A/B тест)
  static Future<bool> get enableNewOnboarding async {
    final config = await instance;
    return config.getBool('enable_new_onboarding');
  }

  /// Количество шагов онбординга
  static Future<int> get onboardingStepCount async {
    final config = await instance;
    return config.getInt('onboarding_step_count');
  }

  // ============================================================================
  // Универсальные методы
  // ============================================================================

  /// Получить строковое значение
  static Future<String> getString(String key, {String defaultValue = ''}) async {
    try {
      final config = await instance;
      return config.getString(key);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Получить числовое значение
  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    try {
      final config = await instance;
      return config.getInt(key);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Получить double значение
  static Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    try {
      final config = await instance;
      return config.getDouble(key);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Получить boolean значение
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      final config = await instance;
      return config.getBool(key);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Получить все параметры
  static Future<Map<String, dynamic>> getAllParameters() async {
    final config = await instance;
    final keys = config.getAll();
    final Map<String, dynamic> result = {};

    for (final entry in keys.entries) {
      result[entry.key] = entry.value.asString();
    }

    return result;
  }

  /// Проверить, нужно ли обновить приложение
  ///
  /// Сравнивает текущую версию с минимальной требуемой
  static Future<bool> isUpdateRequired(String currentVersion) async {
    final minVersion = await minAppVersion;
    return _compareVersions(currentVersion, minVersion) < 0;
  }

  /// Сравнить две версии (формат: X.Y.Z)
  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final v1 = i < v1Parts.length ? v1Parts[i] : 0;
      final v2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1 < v2) return -1;
      if (v1 > v2) return 1;
    }

    return 0;
  }
}
