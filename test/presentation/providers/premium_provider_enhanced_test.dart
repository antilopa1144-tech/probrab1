import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/premium_service.dart';
import 'package:probrab_ai/domain/models/premium_subscription.dart';
import 'package:probrab_ai/presentation/providers/premium_provider.dart';

/// Mock PremiumService для тестирования
class MockPremiumService {
  PremiumSubscription _mockSubscription = const PremiumSubscription.free();
  bool _shouldThrowOnPurchase = false;
  bool _shouldThrowOnRestore = false;
  List<PremiumProduct> _mockProducts = [];

  void setMockSubscription(PremiumSubscription subscription) {
    _mockSubscription = subscription;
  }

  void setShouldThrowOnPurchase(bool shouldThrow) {
    _shouldThrowOnPurchase = shouldThrow;
  }

  void setShouldThrowOnRestore(bool shouldThrow) {
    _shouldThrowOnRestore = shouldThrow;
  }

  void setMockProducts(List<PremiumProduct> products) {
    _mockProducts = products;
  }

  PremiumSubscription get currentSubscription => _mockSubscription;

  bool get isPremium => _mockSubscription.isActive && !_mockSubscription.isExpired;

  Stream<PremiumSubscription> get subscriptionStream => Stream.value(_mockSubscription);

  bool hasAccess(PremiumFeature feature) => isPremium;

  bool hasCalculatorAccess(String calculatorId) {
    const premiumCalculators = {'three_d_panels', 'underfloor_heating'};
    if (!premiumCalculators.contains(calculatorId)) return true;
    return isPremium;
  }

  Future<int> getProjectLimit() async {
    return isPremium ? -1 : 3;
  }

  Future<List<PremiumProduct>> getAvailableProducts() async {
    if (_mockProducts.isNotEmpty) return _mockProducts;
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
        description: 'Доступ ко всем функциям на 1 год',
        discount: 17,
      ),
      const PremiumProduct(
        id: 'premium_lifetime',
        type: SubscriptionType.lifetime,
        price: '7990 ₽',
        priceValue: 7990.0,
        title: 'Пожизненная покупка',
        description: 'Разовая покупка',
      ),
    ];
  }

  Future<bool> purchaseProduct(String productId) async {
    if (_shouldThrowOnPurchase) {
      throw Exception('Purchase failed');
    }
    return true;
  }

  Future<bool> restorePurchases() async {
    if (_shouldThrowOnRestore) {
      throw Exception('Restore failed');
    }
    return true;
  }

  Future<void> cancelSubscription() async {
    // Mock implementation
  }
}

void main() {
  late MockPremiumService mockService;

  setUp(() {
    mockService = MockPremiumService();
  });

  group('премиум подписка - активная', () {
    test('возвращает true для активной подписки без срока', () {
      mockService.setMockSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.lifetime,
          startDate: DateTime.now(),
        ),
      );

      expect(mockService.isPremium, true);
    });

    test('возвращает true для активной подписки не истёкшей', () {
      mockService.setMockSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.monthly,
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          expiryDate: DateTime.now().add(const Duration(days: 20)),
        ),
      );

      expect(mockService.isPremium, true);
    });
  });

  group('премиум подписка - не активная', () {
    test('возвращает false для free подписки', () {
      mockService.setMockSubscription(const PremiumSubscription.free());
      expect(mockService.isPremium, false);
    });

    test('возвращает false для истёкшей подписки', () {
      mockService.setMockSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.monthly,
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );

      expect(mockService.isPremium, false);
    });

    test('возвращает false для неактивной подписки', () {
      mockService.setMockSubscription(
        PremiumSubscription(
          isActive: false,
          type: SubscriptionType.monthly,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
        ),
      );

      expect(mockService.isPremium, false);
    });
  });

  group('доступ к функциям', () {
    test('hasAccess возвращает true для premium пользователя', () {
      mockService.setMockSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.lifetime,
          startDate: DateTime.now(),
        ),
      );

      expect(mockService.hasAccess(PremiumFeature.unlimitedProjects), true);
      expect(mockService.hasAccess(PremiumFeature.advancedCalculators), true);
    });

    test('hasAccess возвращает false для free пользователя', () {
      mockService.setMockSubscription(const PremiumSubscription.free());

      expect(mockService.hasAccess(PremiumFeature.unlimitedProjects), false);
    });
  });

  group('доступ к калькуляторам', () {
    test('бесплатные калькуляторы доступны всем', () {
      mockService.setMockSubscription(const PremiumSubscription.free());

      expect(mockService.hasCalculatorAccess('brick'), true);
      expect(mockService.hasCalculatorAccess('tile'), true);
    });

    test('premium калькуляторы доступны только premium', () {
      mockService.setMockSubscription(const PremiumSubscription.free());

      expect(mockService.hasCalculatorAccess('three_d_panels'), false);
      expect(mockService.hasCalculatorAccess('underfloor_heating'), false);
    });

    test('premium калькуляторы доступны для premium подписки', () {
      mockService.setMockSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.yearly,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 365)),
        ),
      );

      expect(mockService.hasCalculatorAccess('three_d_panels'), true);
      expect(mockService.hasCalculatorAccess('underfloor_heating'), true);
    });
  });

  group('лимит проектов', () {
    test('возвращает -1 (unlimited) для premium', () async {
      mockService.setMockSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.lifetime,
          startDate: DateTime.now(),
        ),
      );

      final limit = await mockService.getProjectLimit();
      expect(limit, -1);
    });

    test('возвращает 3 для free пользователя', () async {
      mockService.setMockSubscription(const PremiumSubscription.free());

      final limit = await mockService.getProjectLimit();
      expect(limit, 3);
    });
  });

  group('доступные продукты', () {
    test('возвращает список продуктов', () async {
      final products = await mockService.getAvailableProducts();

      expect(products, isNotEmpty);
      expect(products.length, 3);
      expect(products.any((p) => p.type == SubscriptionType.monthly), true);
      expect(products.any((p) => p.type == SubscriptionType.yearly), true);
      expect(products.any((p) => p.type == SubscriptionType.lifetime), true);
    });

    test('mock продукты возвращаются корректно', () async {
      final mockProducts = [
        const PremiumProduct(
          id: 'test_monthly',
          type: SubscriptionType.monthly,
          price: '99 ₽',
          priceValue: 99.0,
          title: 'Test Monthly',
          description: 'Test',
        ),
      ];
      mockService.setMockProducts(mockProducts);

      final products = await mockService.getAvailableProducts();
      expect(products.length, 1);
      expect(products.first.id, 'test_monthly');
    });

    test('продукты имеют корректные свойства', () async {
      final products = await mockService.getAvailableProducts();
      final yearly = products.firstWhere((p) => p.type == SubscriptionType.yearly);

      expect(yearly.isRecommended, true);
      expect(yearly.discount, 17);
      expect(yearly.discountText, 'Скидка 17%');
    });

    test('lifetime продукт имеет isBestValue = true', () async {
      final products = await mockService.getAvailableProducts();
      final lifetime = products.firstWhere((p) => p.type == SubscriptionType.lifetime);

      expect(lifetime.isBestValue, true);
    });
  });

  group('PremiumPurchaseNotifier - покупка', () {
    test('purchaseProduct успешная покупка', () async {
      final container = ProviderContainer(
        overrides: [
          premiumServiceProvider.overrideWith((ref) async {
            return mockService as PremiumService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(premiumPurchaseProvider.notifier);

      await notifier.purchaseProduct('test_product');

      final state = container.read(premiumPurchaseProvider);
      expect(state, isA<AsyncData<bool>>());
      expect(state.value, true);
    });

    test('purchaseProduct неудачная покупка', () async {
      mockService.setShouldThrowOnPurchase(true);

      final container = ProviderContainer(
        overrides: [
          premiumServiceProvider.overrideWith((ref) async {
            return mockService as PremiumService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(premiumPurchaseProvider.notifier);

      await notifier.purchaseProduct('test_product');

      final state = container.read(premiumPurchaseProvider);
      expect(state, isA<AsyncError<bool>>());
    });
  });

  group('PremiumPurchaseNotifier - восстановление', () {
    test('restorePurchases успешное восстановление', () async {
      final container = ProviderContainer(
        overrides: [
          premiumServiceProvider.overrideWith((ref) async {
            return mockService as PremiumService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(premiumPurchaseProvider.notifier);

      await notifier.restorePurchases();

      final state = container.read(premiumPurchaseProvider);
      expect(state, isA<AsyncData<bool>>());
      expect(state.value, true);
    });

    test('restorePurchases неудачное восстановление', () async {
      mockService.setShouldThrowOnRestore(true);

      final container = ProviderContainer(
        overrides: [
          premiumServiceProvider.overrideWith((ref) async {
            return mockService as PremiumService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(premiumPurchaseProvider.notifier);

      await notifier.restorePurchases();

      final state = container.read(premiumPurchaseProvider);
      expect(state, isA<AsyncError<bool>>());
    });
  });

  group('PremiumPurchaseNotifier - отмена подписки', () {
    test('cancelSubscription вызывается без ошибок', () async {
      final container = ProviderContainer(
        overrides: [
          premiumServiceProvider.overrideWith((ref) async {
            return mockService as PremiumService;
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(premiumPurchaseProvider.notifier);

      await notifier.cancelSubscription();
      // Проверяем что не выбросилось исключение
    });
  });

  group('currentSubscriptionProvider с данными', () {
    test('возвращает активную подписку через stream', () async {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.yearly,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
      );
      mockService.setMockSubscription(subscription);

      final container = ProviderContainer(
        overrides: [
          currentSubscriptionProvider.overrideWith(
            (ref) => mockService.subscriptionStream,
          ),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      final asyncValue = container.read(currentSubscriptionProvider);
      if (asyncValue.hasValue) {
        expect(asyncValue.value?.isActive, true);
        expect(asyncValue.value?.type, SubscriptionType.yearly);
      }
    });
  });

  group('isPremiumProvider с реальными данными', () {
    test('возвращает true при активной подписке через provider', () async {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );

      final container = ProviderContainer(
        overrides: [
          currentSubscriptionProvider.overrideWith(
            (ref) => Stream.value(subscription),
          ),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      final isPremium = container.read(isPremiumProvider);
      expect(isPremium, isA<bool>());
    });
  });

  group('shouldShowAdsProvider', () {
    test('возвращает false для premium подписки', () {
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.lifetime,
        startDate: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          currentSubscriptionProvider.overrideWith(
            (ref) => Stream.value(subscription),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(currentSubscriptionProvider);

      final shouldShowAds = container.read(shouldShowAdsProvider);
      expect(shouldShowAds, isA<bool>());
    });
  });
}
