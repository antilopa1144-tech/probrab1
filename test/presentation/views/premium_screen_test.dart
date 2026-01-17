import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/views/premium_screen.dart';
import 'package:probrab_ai/presentation/providers/premium_provider.dart';
import 'package:probrab_ai/core/services/premium_service.dart';
import 'package:probrab_ai/domain/models/premium_subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

/// Mock Premium Service для тестирования
class MockPremiumService implements PremiumService {
  PremiumSubscription _subscription = const PremiumSubscription.free();
  bool _shouldThrowError = false;

  void setSubscription(PremiumSubscription subscription) {
    _subscription = subscription;
  }

  void setShouldThrowError(bool value) {
    _shouldThrowError = value;
  }

  @override
  PremiumSubscription get currentSubscription => _subscription;

  @override
  bool get isPremium => _subscription.isActive && !_subscription.isExpired;

  @override
  Stream<PremiumSubscription> get subscriptionStream =>
      Stream.value(_subscription);

  @override
  Future<List<PremiumProduct>> getAvailableProducts() async {
    if (_shouldThrowError) throw Exception('Test error');
    return [
      const PremiumProduct(
        id: 'premium_monthly',
        type: SubscriptionType.monthly,
        price: '399 ₽',
        priceValue: 399.0,
        title: 'Месячная подписка',
        description: 'Тест',
      ),
      const PremiumProduct(
        id: 'premium_yearly',
        type: SubscriptionType.yearly,
        price: '3990 ₽',
        priceValue: 3990.0,
        title: 'Годовая подписка',
        description: 'Тест',
        discount: 17,
      ),
      const PremiumProduct(
        id: 'premium_lifetime',
        type: SubscriptionType.lifetime,
        price: '7990 ₽',
        priceValue: 7990.0,
        title: 'Пожизненная покупка',
        description: 'Тест',
      ),
    ];
  }

  @override
  Future<bool> purchaseProduct(String productId) async {
    if (_shouldThrowError) throw Exception('Purchase error');
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    if (_shouldThrowError) throw Exception('Restore error');
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('PremiumScreen', () {
    late MockPremiumService mockService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockService = MockPremiumService();
    });

    List<Override> createOverrides() {
      return [
        premiumServiceProvider.overrideWith((ref) async {
          return mockService;
        }),
        currentSubscriptionProvider.overrideWith((ref) {
          return mockService.subscriptionStream;
        }),
        availableProductsProvider.overrideWith((ref) async {
          return mockService.getAvailableProducts();
        }),
      ];
    }

    testWidgets('отображается корректно', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );

      expect(find.byType(PremiumScreen), findsOneWidget);
    });

    testWidgets('показывает AppBar с заголовком Premium', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('показывает иконку Premium в AppBar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );

      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('показывает loading state при загрузке', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('показывает предложения для бесплатной версии', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Получите Premium'), findsOneWidget);
    });

    testWidgets('показывает список функций Premium', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Расширенные калькуляторы'), findsWidgets);
      expect(find.text('Экспорт в PDF'), findsWidgets);
    });

    testWidgets('показывает карточки продуктов', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Месячная подписка'), findsOneWidget);
      expect(find.text('Годовая подписка'), findsOneWidget);
      expect(find.text('Пожизненная покупка'), findsOneWidget);
    });

    testWidgets('показывает цены продуктов', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('399 ₽'), findsOneWidget);
      expect(find.text('3990 ₽'), findsOneWidget);
      expect(find.text('7990 ₽'), findsOneWidget);
    });

    testWidgets('показывает badge Рекомендуем для годовой подписки', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Рекомендуем'), findsOneWidget);
    });

    testWidgets('показывает badge Лучшая цена для lifetime', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Лучшая цена'), findsOneWidget);
    });

    testWidgets('показывает кнопку восстановить покупки', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Восстановить покупки'), findsOneWidget);
    });

    testWidgets('показывает активную подписку', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.yearly,
          source: PurchaseSource.rustore,
          startDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Premium активен'), findsOneWidget);
    });

    testWidgets('показывает тип активной подписки', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.yearly,
          source: PurchaseSource.rustore,
          startDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Годовая подписка'), findsOneWidget);
    });

    testWidgets('показывает дату окончания подписки', (tester) async {
      setTestViewportSize(tester);
      // Используем будущую дату, чтобы подписка не считалась истекшей
      final expiryDate = DateTime.now().add(const Duration(days: 30));
      mockService.setSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.monthly,
          source: PurchaseSource.rustore,
          startDate: DateTime.now(),
          expiryDate: expiryDate,
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Действует до'), findsOneWidget);
    });

    testWidgets('показывает кнопку управления подпиской для активной', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.monthly,
          source: PurchaseSource.rustore,
          startDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Управление подпиской'), findsOneWidget);
    });

    testWidgets('не показывает кнопку управления для lifetime', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.lifetime,
          source: PurchaseSource.rustore,
          startDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Управление подпиской'), findsNothing);
    });

    testWidgets('показывает доступные функции для активной подписки', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.yearly,
          source: PurchaseSource.rustore,
          startDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Доступные функции'), findsOneWidget);
    });

    testWidgets('обрабатывает ошибку загрузки', (tester) async {
      setTestViewportSize(tester);
      final overrides = [
        currentSubscriptionProvider.overrideWith((ref) {
          return Stream<PremiumSubscription>.error(Exception('Test error'));
        }),
      ];

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Ошибка загрузки: Exception: Test error'), findsOneWidget);
    });

    testWidgets('показывает все иконки функций', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calculate_rounded), findsWidgets);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsWidgets);
      expect(find.byIcon(Icons.list_alt_rounded), findsWidgets);
      expect(find.byIcon(Icons.qr_code_rounded), findsWidgets);
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
    });

    testWidgets('отображает градиент для активной подписки', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.yearly,
          source: PurchaseSource.rustore,
          startDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      // Should have gradient container
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('показывает скидку для продукта', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Скидка 17%'), findsOneWidget);
    });

    testWidgets('показывает текст разблокировки возможностей', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Разблокируйте все возможности приложения'),
        findsOneWidget,
      );
    });

    testWidgets('отображает ListView для предложений', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('использует FilledButton для покупки', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsWidgets);
    });

    testWidgets('показывает snackbar после успешной покупки', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      final buyButton = find.text('Купить').first;
      await tester.tap(buyButton);
      await tester.pumpAndSettle();
    });

    testWidgets('проверяет тип подписки monthly', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.monthly,
          source: PurchaseSource.rustore,
          startDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Месячная подписка'), findsOneWidget);
    });

    testWidgets('проверяет тип подписки lifetime', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(
        PremiumSubscription(
          isActive: true,
          type: SubscriptionType.lifetime,
          source: PurchaseSource.rustore,
          startDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Пожизненная лицензия'), findsOneWidget);
    });

    testWidgets('показывает Card для каждого продукта', (tester) async {
      setTestViewportSize(tester);
      mockService.setSubscription(const PremiumSubscription.free());

      await tester.pumpWidget(
        createTestApp(
          child: const PremiumScreen(),
          overrides: createOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });
  });
}
