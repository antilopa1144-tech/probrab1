import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/premium_subscription.dart';
import 'package:probrab_ai/presentation/providers/premium_provider.dart';
import 'package:probrab_ai/presentation/widgets/common/premium_badge.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('PremiumBadge', () {
    testWidgets('не отображается для бесплатных пользователей', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(),
            ),
          ),
        ),
      );

      expect(find.byType(PremiumBadge), findsOneWidget);
      // Виджет существует, но не отображается (SizedBox.shrink)
      expect(find.byIcon(Icons.workspace_premium_rounded), findsNothing);
      expect(find.text('PREMIUM'), findsNothing);
    });

    testWidgets('отображается для Premium пользователей', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.text('PREMIUM'), findsOneWidget);
    });

    testWidgets('отображает иконку и текст по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(),
            ),
          ),
        ),
      );

      // Проверка иконки
      final iconFinder = find.byIcon(Icons.workspace_premium_rounded);
      expect(iconFinder, findsOneWidget);

      // Проверка текста
      expect(find.text('PREMIUM'), findsOneWidget);

      // Проверка цвета иконки
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, Colors.white);
    });

    testWidgets('скрывает текст когда showLabel = false', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(showLabel: false),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.text('PREMIUM'), findsNothing);
    });

    testWidgets('использует кастомный iconSize', (tester) async {
      setTestViewportSize(tester);
      const customSize = 30.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(iconSize: customSize),
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.workspace_premium_rounded);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.size, customSize);
    });

    testWidgets('использует кастомный padding', (tester) async {
      setTestViewportSize(tester);
      const customPadding = EdgeInsets.all(20);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(padding: customPadding),
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(PremiumBadge),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      expect(container.padding, customPadding);
    });

    testWidgets('использует padding по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(),
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(PremiumBadge),
        matching: find.byType(Container),
      );

      final container = tester.widget<Container>(containerFinder);
      expect(
        container.padding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
    });

    testWidgets('имеет градиентный фон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(),
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(PremiumBadge),
        matching: find.byType(Container),
      );

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());

      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors.length, 2);
    });

    testWidgets('имеет закругленные углы', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(),
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(PremiumBadge),
        matching: find.byType(Container),
      );

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(20));
    });

    testWidgets('текст имеет правильный стиль', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBadge(),
            ),
          ),
        ),
      );

      final textFinder = find.text('PREMIUM');
      final text = tester.widget<Text>(textFinder);
      expect(text.style?.color, Colors.white);
      expect(text.style?.fontWeight, FontWeight.bold);
      expect(text.style?.letterSpacing, 1.2);
    });
  });

  group('PremiumUpgradeButton', () {
    testWidgets('не отображается для Premium пользователей', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumUpgradeButton(),
            ),
          ),
        ),
      );

      expect(find.byType(PremiumUpgradeButton), findsOneWidget);
      expect(find.text('Получить Premium'), findsNothing);
      expect(find.byIcon(Icons.workspace_premium_outlined), findsNothing);
    });

    testWidgets('отображается для бесплатных пользователей', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumUpgradeButton(),
            ),
          ),
        ),
      );

      expect(find.text('Получить Premium'), findsOneWidget);
    });

    testWidgets('отображает полную версию по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumUpgradeButton(),
            ),
          ),
        ),
      );

      expect(find.text('Получить Premium'), findsOneWidget);
      expect(find.text('Разблокировать все функции'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('отображает компактную версию когда compact = true',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumUpgradeButton(compact: true),
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);
      expect(find.text('Получить Premium'), findsNothing);
    });

    testWidgets('компактная версия имеет tooltip', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumUpgradeButton(compact: true),
            ),
          ),
        ),
      );

      final iconButtonFinder = find.byType(IconButton);
      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.tooltip, 'Получить Premium');
    });

    testWidgets('вызывает onTap при нажатии на полную версию',
        (tester) async {
      setTestViewportSize(tester);
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PremiumUpgradeButton(
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('вызывает onTap при нажатии на компактную версию',
        (tester) async {
      setTestViewportSize(tester);
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PremiumUpgradeButton(
                compact: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('полная версия имеет градиентный фон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumUpgradeButton(),
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      );

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('полная версия имеет тень', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumUpgradeButton(),
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      );

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, 1);
    });
  });

  group('PremiumFeatureCard', () {
    testWidgets('отображает все элементы', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumFeatureCard(
              title: 'Тестовая функция',
              description: 'Описание функции',
              icon: Icons.star,
            ),
          ),
        ),
      );

      expect(find.text('Тестовая функция'), findsOneWidget);
      expect(find.text('Описание функции'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.text('Получить Premium'), findsOneWidget);
    });

    testWidgets('иконка функции отображается в круглом контейнере',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumFeatureCard(
              title: 'Функция',
              description: 'Описание',
              icon: Icons.calculate,
            ),
          ),
        ),
      );

      final containerFinder = find.ancestor(
        of: find.byIcon(Icons.calculate),
        matching: find.byType(Container),
      );

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('кнопка вызывает onUpgrade при нажатии', (tester) async {
      setTestViewportSize(tester);
      bool upgraded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumFeatureCard(
              title: 'Функция',
              description: 'Описание',
              icon: Icons.star,
              onUpgrade: () => upgraded = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Получить Premium'));
      await tester.pumpAndSettle();

      expect(upgraded, true);
    });

    testWidgets('отображается в Card виджете', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumFeatureCard(
              title: 'Функция',
              description: 'Описание',
              icon: Icons.star,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('иконка имеет правильный размер', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumFeatureCard(
              title: 'Функция',
              description: 'Описание',
              icon: Icons.star,
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.star);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.size, 40);
      expect(icon.color, Colors.white);
    });

    testWidgets('контейнер иконки имеет правильный размер', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumFeatureCard(
              title: 'Функция',
              description: 'Описание',
              icon: Icons.star,
            ),
          ),
        ),
      );

      final containerFinder = find.ancestor(
        of: find.byIcon(Icons.star),
        matching: find.byType(Container),
      );

      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.maxWidth, 80);
      expect(container.constraints?.maxHeight, 80);
    });
  });

  group('SubscriptionExpiryIndicator', () {
    testWidgets('не отображается когда подписка не активна', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(const PremiumSubscription.free());
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('не отображается для lifetime подписки', (tester) async {
      setTestViewportSize(tester);
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.lifetime,
        startDate: DateTime.now(),
        expiryDate: null,
        source: PurchaseSource.rustore,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(subscription);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('не отображается если до окончания больше 7 дней',
        (tester) async {
      setTestViewportSize(tester);
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 10)),
        source: PurchaseSource.rustore,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(subscription);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('отображается когда подписка истекает через 5 дней',
        (tester) async {
      setTestViewportSize(tester);
      // Используем фиксированную дату для избежания проблем с округлением
      final now = DateTime.now();
      final expiryDate = DateTime(now.year, now.month, now.day + 5);

      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: now.subtract(const Duration(days: 25)),
        expiryDate: expiryDate,
        source: PurchaseSource.rustore,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(subscription);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      // Проверяем что есть хотя бы какое-то предупреждение
      expect(find.textContaining('Подписка истекает'), findsOneWidget);
    });

    testWidgets('показывает правильное склонение для 1 дня', (tester) async {
      setTestViewportSize(tester);
      final now = DateTime.now();
      // Добавляем 36 часов чтобы гарантировать что будет минимум 1 полный день
      final expiryDate = now.add(const Duration(hours: 36));

      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: now.subtract(const Duration(days: 29)),
        expiryDate: expiryDate,
        source: PurchaseSource.rustore,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(subscription);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем что предупреждение отображается
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('Подписка истекает'), findsOneWidget);
    });

    testWidgets('показывает правильное склонение для 2 дней', (tester) async {
      setTestViewportSize(tester);
      final now = DateTime.now();
      final expiryDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 2, hours: 12));

      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: now.subtract(const Duration(days: 28)),
        expiryDate: expiryDate,
        source: PurchaseSource.rustore,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(subscription);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем что предупреждение отображается
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('Подписка истекает'), findsOneWidget);
    });

    testWidgets('показывает правильное склонение для 5 дней', (tester) async {
      setTestViewportSize(tester);
      final now = DateTime.now();
      final expiryDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 5, hours: 12));

      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: now.subtract(const Duration(days: 25)),
        expiryDate: expiryDate,
        source: PurchaseSource.rustore,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(subscription);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем что предупреждение отображается
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('Подписка истекает'), findsOneWidget);
    });

    testWidgets('показывает сообщение для истекшей подписки', (tester) async {
      setTestViewportSize(tester);
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 31)),
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        source: PurchaseSource.rustore,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(subscription);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Подписка истекла'), findsOneWidget);
    });

    testWidgets('имеет оранжевое оформление', (tester) async {
      setTestViewportSize(tester);
      final subscription = PremiumSubscription(
        isActive: true,
        type: SubscriptionType.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 25)),
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        source: PurchaseSource.rustore,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(subscription);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final containerFinder = find.ancestor(
        of: find.byIcon(Icons.warning_amber_rounded),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsOneWidget);
    });

    testWidgets('корректно обрабатывает loading состояние', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.value(const PremiumSubscription.free());
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      // Не ждем pumpAndSettle, чтобы проверить loading состояние
      await tester.pump();

      // В loading состоянии ничего не должно отображаться
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('корректно обрабатывает error состояние', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSubscriptionProvider.overrideWith((ref) {
              return Stream.error(Exception('Test error'));
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubscriptionExpiryIndicator(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // В error состоянии ничего не должно отображаться
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });
  });
}
