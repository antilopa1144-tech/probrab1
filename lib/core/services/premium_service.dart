import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/premium_subscription.dart';

/// Сервис для управления Premium подпиской
///
/// Функции:
/// - Проверка статуса подписки
/// - Управление доступом к Premium функциям
/// - Интеграция с RuStore Billing (TODO)
/// - Кэширование статуса подписки
class PremiumService {
  static const String _subscriptionKey = 'premium_subscription';
  static const String _debugPremiumKey = 'debug_premium_enabled';

  static PremiumService? _instance;
  static SharedPreferences? _prefs;

  PremiumSubscription _currentSubscription = const PremiumSubscription.free();
  final StreamController<PremiumSubscription> _subscriptionController =
      StreamController<PremiumSubscription>.broadcast();

  /// Singleton instance
  static Future<PremiumService> get instance async {
    if (_instance != null) return _instance!;

    _instance = PremiumService._();
    await _instance!._initialize();
    return _instance!;
  }

  PremiumService._();

  /// Инициализация сервиса
  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSubscription();

    // В debug режиме можно включить Premium для тестирования
    if (kDebugMode) {
      final debugPremium = _prefs?.getBool(_debugPremiumKey) ?? false;
      if (debugPremium) {
        _currentSubscription = PremiumSubscription(
          isActive: true,
          type: SubscriptionType.lifetime,
          source: PurchaseSource.debug,
          startDate: DateTime.now(),
        );
        _subscriptionController.add(_currentSubscription);
      }
    }

    // TODO: Инициализация RuStore Billing SDK
    // await _initializeRuStoreBilling();
  }

  /// Загрузить подписку из SharedPreferences
  Future<void> _loadSubscription() async {
    try {
      final json = _prefs?.getString(_subscriptionKey);
      if (json != null) {
        final data = Map<String, dynamic>.from(
          // В реальном приложении использовать json.decode
          {},
        );
        _currentSubscription = PremiumSubscription.fromJson(data);

        // Проверить, не истекла ли подписка
        if (_currentSubscription.isExpired) {
          _currentSubscription = const PremiumSubscription.free();
          await _saveSubscription();
        }

        _subscriptionController.add(_currentSubscription);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading subscription: $e');
      }
    }
  }

  /// Сохранить подписку в SharedPreferences
  Future<void> _saveSubscription() async {
    try {
      final json = _currentSubscription.toJson();
      // В реальном приложении использовать json.encode
      await _prefs?.setString(_subscriptionKey, json.toString());
      _subscriptionController.add(_currentSubscription);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving subscription: $e');
      }
    }
  }

  /// Stream изменений подписки
  Stream<PremiumSubscription> get subscriptionStream =>
      _subscriptionController.stream;

  /// Текущая подписка
  PremiumSubscription get currentSubscription => _currentSubscription;

  /// Активна ли Premium подписка
  bool get isPremium => _currentSubscription.isActive && !_currentSubscription.isExpired;

  /// Показывать ли рекламу (реклама отключается для Premium)
  bool get shouldShowAds => !isPremium;

  /// Проверить доступ к функции
  bool hasAccess(PremiumFeature feature) {
    // Всегда доступные функции
    const alwaysFree = <PremiumFeature>{};

    if (alwaysFree.contains(feature)) {
      return true;
    }

    // Premium функции требуют активную подписку
    return isPremium;
  }

  /// Проверить доступ к калькулятору по ID
  bool hasCalculatorAccess(String calculatorId) {
    // Список Premium калькуляторов
    const premiumCalculators = <String>{
      'three_d_panels',
      'underfloor_heating',
      'tile_adhesive_v2',
      'wood_lining',
      // TODO: Добавить другие premium калькуляторы
    };

    if (!premiumCalculators.contains(calculatorId)) {
      return true; // Бесплатный калькулятор
    }

    return isPremium;
  }

  /// Проверить лимит проектов
  Future<bool> canCreateProject(int currentProjectCount) async {
    if (isPremium) {
      return true; // Без лимитов для Premium
    }

    // Для бесплатной версии - лимит из Remote Config
    // TODO: Интегрировать с RemoteConfigService
    const freeProjectLimit = 3;
    return currentProjectCount < freeProjectLimit;
  }

  /// Получить лимит проектов
  Future<int> getProjectLimit() async {
    if (isPremium) {
      return -1; // Unlimited
    }

    // TODO: Интегрировать с RemoteConfigService
    return 3;
  }

  // ============================================================================
  // Методы для работы с покупками (RuStore Billing)
  // ============================================================================

  /// Получить доступные продукты для покупки
  Future<List<PremiumProduct>> getAvailableProducts() async {
    // TODO: Получить реальные продукты из RuStore
    return [
      const PremiumProduct(
        id: 'premium_monthly',
        type: SubscriptionType.monthly,
        price: '399 ₽',
        priceValue: 399.0,
        title: 'Месячная подписка',
        description: 'Доступ ко всем функциям на 1 месяц',
      ),
      const PremiumProduct(
        id: 'premium_yearly',
        type: SubscriptionType.yearly,
        price: '3990 ₽',
        priceValue: 3990.0,
        title: 'Годовая подписка',
        description: 'Доступ ко всем функциям на 1 год. Экономия 17%!',
        discount: 17,
      ),
      const PremiumProduct(
        id: 'premium_lifetime',
        type: SubscriptionType.lifetime,
        price: '7990 ₽',
        priceValue: 7990.0,
        title: 'Пожизненная покупка',
        description: 'Разовая покупка. Все функции навсегда!',
      ),
    ];
  }

  /// Купить продукт
  Future<bool> purchaseProduct(String productId) async {
    try {
      // TODO: Реализовать покупку через RuStore Billing
      if (kDebugMode) {
        debugPrint('Attempting to purchase: $productId');
      }

      // Заглушка для разработки
      if (kDebugMode) {
        // Симулировать успешную покупку в debug режиме
        final product = (await getAvailableProducts())
            .firstWhere((p) => p.id == productId);

        _currentSubscription = PremiumSubscription(
          isActive: true,
          type: product.type,
          source: PurchaseSource.debug,
          startDate: DateTime.now(),
          expiryDate: _calculateExpiryDate(product.type),
          productId: productId,
          purchaseId: 'debug_${DateTime.now().millisecondsSinceEpoch}',
        );

        await _saveSubscription();
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Purchase error: $e');
      }
      return false;
    }
  }

  /// Восстановить покупки
  Future<bool> restorePurchases() async {
    try {
      // TODO: Реализовать восстановление покупок через RuStore Billing
      if (kDebugMode) {
        debugPrint('Attempting to restore purchases');
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Restore purchases error: $e');
      }
      return false;
    }
  }

  /// Отменить подписку (перенаправить в RuStore)
  Future<void> cancelSubscription() async {
    // TODO: Открыть страницу управления подписками в RuStore
    if (kDebugMode) {
      debugPrint('Opening RuStore subscription management');
    }
  }

  /// Рассчитать дату окончания подписки
  DateTime? _calculateExpiryDate(SubscriptionType type) {
    final now = DateTime.now();
    switch (type) {
      case SubscriptionType.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case SubscriptionType.yearly:
        return DateTime(now.year + 1, now.month, now.day);
      case SubscriptionType.lifetime:
        return null; // Без срока действия
      case SubscriptionType.free:
        return null;
    }
  }

  // ============================================================================
  // Debug методы (только для разработки)
  // ============================================================================

  /// Включить/выключить debug Premium (только в debug режиме)
  Future<void> setDebugPremium(bool enabled) async {
    if (!kDebugMode) return;

    await _prefs?.setBool(_debugPremiumKey, enabled);

    if (enabled) {
      _currentSubscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.lifetime,
        source: PurchaseSource.debug,
        startDate: DateTime.now(),
      );
    } else {
      _currentSubscription = const PremiumSubscription.free();
    }

    await _saveSubscription();
  }

  /// Получить debug статус Premium
  bool get isDebugPremium {
    if (!kDebugMode) return false;
    return _prefs?.getBool(_debugPremiumKey) ?? false;
  }

  /// Очистить подписку (только для тестирования)
  Future<void> clearSubscription() async {
    if (!kDebugMode) return;

    _currentSubscription = const PremiumSubscription.free();
    await _prefs?.remove(_subscriptionKey);
    await _prefs?.remove(_debugPremiumKey);
    _subscriptionController.add(_currentSubscription);
  }

  /// Dispose
  void dispose() {
    _subscriptionController.close();
  }
}

/// Модель продукта для покупки
class PremiumProduct {
  final String id;
  final SubscriptionType type;
  final String price;
  final double priceValue;
  final String title;
  final String description;
  final int? discount; // Процент скидки

  const PremiumProduct({
    required this.id,
    required this.type,
    required this.price,
    required this.priceValue,
    required this.title,
    required this.description,
    this.discount,
  });

  /// Текст со скидкой
  String? get discountText {
    if (discount == null) return null;
    return 'Скидка $discount%';
  }

  /// Рекомендуемый продукт (годовая подписка)
  bool get isRecommended => type == SubscriptionType.yearly;

  /// Лучшее предложение (lifetime)
  bool get isBestValue => type == SubscriptionType.lifetime;
}
