# Руководство по Premium подпискам

## 📋 Обзор системы

Premium система построена на базе **RuStore Billing API** и позволяет монетизировать приложение через подписки.

### Доступные тарифы

- **Месячная подписка**: 399 ₽/месяц
- **Годовая подписка**: 3990 ₽/год (экономия 17%)
- **Пожизненная покупка**: 7990 ₽ (разовый платёж)

### Premium функции

✅ Расширенные калькуляторы (3D панели, тёплый пол, вагонка)
✅ Неограниченное количество проектов
✅ Экспорт в PDF
✅ Детальные списки материалов
✅ **Без рекламы**
✅ QR-коды проектов
✅ Голосовой ввод размеров
✅ Deep links
✅ Чек-листы ремонта
✅ Конвертер единиц

---

## 🔧 Как работает управление подписками

### 1. Локальное хранение статуса

Статус подписки сохраняется в **SharedPreferences**:

```dart
// Файл: lib/core/services/premium_service.dart

class PremiumService {
  PremiumSubscription _currentSubscription;

  // Автоматически загружается при старте приложения
  Future<void> _loadSubscription() async {
    final json = _prefs?.getString('premium_subscription');
    if (json != null) {
      _currentSubscription = PremiumSubscription.fromJson(data);

      // Проверка истечения срока
      if (_currentSubscription.isExpired) {
        _currentSubscription = const PremiumSubscription.free();
      }
    }
  }
}
```

### 2. Потоковое обновление (Stream)

Все изменения подписки транслируются через **Stream**, UI автоматически обновляется:

```dart
// Провайдер отслеживает изменения
final currentSubscriptionProvider = StreamProvider<PremiumSubscription>((ref) {
  final service = ref.watch(premiumServiceProvider);
  return service.subscriptionStream; // Авто-обновление UI
});

// В UI компонентах
final isPremium = ref.watch(isPremiumProvider); // Реактивно обновляется
```

### 3. Проверка доступа

```dart
// Проверка перед открытием калькулятора
if (checkPremium && _isPremiumCalculator(definition.id)) {
  final hasAccess = await _checkPremiumAccess(context, definition.id);
  if (!hasAccess) {
    // Показывается диалог Premium Lock
    return null;
  }
}

// Проверка для отключения рекламы
final shouldShowAds = ref.watch(shouldShowAdsProvider);
if (!shouldShowAds) {
  // НЕ показываем рекламу для Premium пользователей
}
```

---

## 🛒 Интеграция RuStore Billing (TODO)

### Шаг 1: Добавить зависимость

В `pubspec.yaml` добавьте:

```yaml
dependencies:
  rustore_flutter_billing: ^1.0.0  # Проверьте актуальную версию
```

### Шаг 2: Настроить продукты в RuStore Console

1. Зайдите в [RuStore Console](https://console.rustore.ru/)
2. Выберите ваше приложение "Мастерок"
3. Перейдите в раздел **Монетизация** → **Подписки**
4. Создайте 3 продукта:

```
SKU: premium_monthly
Название: Месячная подписка Premium
Цена: 399 ₽
Период: 1 месяц
Автопродление: Да

SKU: premium_yearly
Название: Годовая подписка Premium
Цена: 3990 ₽
Период: 1 год
Автопродление: Да

SKU: premium_lifetime
Название: Пожизненный Premium
Цена: 7990 ₽
Тип: Разовая покупка (не подписка)
```

### Шаг 3: Инициализация SDK

Раскомментируйте и доработайте код в `premium_service.dart`:

```dart
import 'package:rustore_flutter_billing/rustore_flutter_billing.dart';

Future<void> _initialize() async {
  _prefs = await SharedPreferences.getInstance();
  await _loadSubscription();

  // Инициализация RuStore Billing
  await _initializeRuStoreBilling();
}

Future<void> _initializeRuStoreBilling() async {
  try {
    // Проверка доступности RuStore
    final isAvailable = await RustoreBilling.isAvailable();
    if (!isAvailable) {
      debugPrint('RuStore Billing недоступен на этом устройстве');
      return;
    }

    // Инициализация
    await RustoreBilling.initialize(
      consoleApplicationId: 'ВАШ_APPLICATION_ID', // Из RuStore Console
      deeplinkScheme: 'masterokapp', // Для Deep Links
    );

    // Проверить активные покупки при старте
    await _checkActivePurchases();
  } catch (e) {
    debugPrint('Ошибка инициализации RuStore Billing: $e');
  }
}
```

### Шаг 4: Получение продуктов из RuStore

```dart
Future<List<PremiumProduct>> getAvailableProducts() async {
  try {
    // Получить продукты из RuStore
    final products = await RustoreBilling.getProducts([
      'premium_monthly',
      'premium_yearly',
      'premium_lifetime',
    ]);

    return products.map((product) {
      return PremiumProduct(
        id: product.productId,
        type: _getSubscriptionType(product.productId),
        price: product.priceLabel, // "399 ₽"
        priceValue: product.price / 100, // Копейки -> рубли
        title: product.title,
        description: product.description,
      );
    }).toList();
  } catch (e) {
    debugPrint('Ошибка загрузки продуктов: $e');
    // Возвращаем дефолтные продукты как fallback
    return _getDefaultProducts();
  }
}
```

### Шаг 5: Покупка продукта

```dart
Future<bool> purchaseProduct(String productId) async {
  try {
    // Запуск процесса покупки
    final purchaseResult = await RustoreBilling.purchaseProduct(
      productId: productId,
    );

    if (purchaseResult.success) {
      // Обновить локальный статус подписки
      _currentSubscription = PremiumSubscription(
        isActive: true,
        type: _getSubscriptionType(productId),
        source: PurchaseSource.rustore,
        startDate: DateTime.now(),
        expiryDate: _calculateExpiryDate(_getSubscriptionType(productId)),
        productId: productId,
        purchaseId: purchaseResult.purchaseId,
        purchaseToken: purchaseResult.purchaseToken,
      );

      await _saveSubscription();

      // Отправить подтверждение покупки на сервер RuStore
      await RustoreBilling.confirmPurchase(purchaseResult.purchaseToken);

      return true;
    }

    return false;
  } catch (e) {
    debugPrint('Ошибка покупки: $e');
    return false;
  }
}
```

### Шаг 6: Восстановление покупок

```dart
Future<bool> restorePurchases() async {
  try {
    // Получить все активные покупки пользователя
    final purchases = await RustoreBilling.getPurchases();

    if (purchases.isEmpty) {
      return false; // Нет активных покупок
    }

    // Найти активную подписку Premium
    for (final purchase in purchases) {
      if (_isPremiumProduct(purchase.productId)) {
        _currentSubscription = PremiumSubscription(
          isActive: true,
          type: _getSubscriptionType(purchase.productId),
          source: PurchaseSource.rustore,
          startDate: DateTime.fromMillisecondsSinceEpoch(purchase.purchaseTime),
          expiryDate: purchase.expiryTime != null
              ? DateTime.fromMillisecondsSinceEpoch(purchase.expiryTime!)
              : null,
          productId: purchase.productId,
          purchaseId: purchase.purchaseId,
          purchaseToken: purchase.purchaseToken,
        );

        await _saveSubscription();
        return true;
      }
    }

    return false;
  } catch (e) {
    debugPrint('Ошибка восстановления покупок: $e');
    return false;
  }
}
```

### Шаг 7: Проверка активных покупок при старте

```dart
Future<void> _checkActivePurchases() async {
  try {
    final purchases = await RustoreBilling.getPurchases();

    for (final purchase in purchases) {
      if (_isPremiumProduct(purchase.productId)) {
        // Проверить, не истекла ли подписка
        final isExpired = purchase.expiryTime != null &&
            DateTime.now().isAfter(
              DateTime.fromMillisecondsSinceEpoch(purchase.expiryTime!),
            );

        if (!isExpired) {
          _currentSubscription = PremiumSubscription(
            isActive: true,
            type: _getSubscriptionType(purchase.productId),
            source: PurchaseSource.rustore,
            startDate: DateTime.fromMillisecondsSinceEpoch(purchase.purchaseTime),
            expiryDate: purchase.expiryTime != null
                ? DateTime.fromMillisecondsSinceEpoch(purchase.expiryTime!)
                : null,
            productId: purchase.productId,
            purchaseId: purchase.purchaseId,
            purchaseToken: purchase.purchaseToken,
          );

          await _saveSubscription();
          break;
        }
      }
    }
  } catch (e) {
    debugPrint('Ошибка проверки покупок: $e');
  }
}
```

---

## 📊 Как отслеживать подписки

### В приложении

1. **Debug Panel** (только в debug режиме):

```dart
// Добавьте в Settings Page для тестирования
if (kDebugMode) {
  ListTile(
    title: Text('Debug Premium'),
    subtitle: Text('Включить Premium для тестирования'),
    trailing: Switch(
      value: debugPremium,
      onChanged: (value) async {
        final service = await PremiumService.instance;
        await service.setDebugPremium(value);
        setState(() => debugPremium = value);
      },
    ),
  ),
}
```

2. **Статус подписки в UI**:

```dart
// В Settings или Profile экране
Consumer(
  builder: (context, ref, _) {
    final subscription = ref.watch(currentSubscriptionProvider).value;

    if (subscription?.isActive ?? false) {
      return ListTile(
        leading: Icon(Icons.workspace_premium_rounded, color: Colors.amber),
        title: Text('Premium активен'),
        subtitle: Text('До ${_formatDate(subscription!.expiryDate)}'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PremiumScreen()),
        ),
      );
    }

    return PremiumUpgradeButton();
  },
)
```

### В RuStore Console

1. Зайдите в [RuStore Console](https://console.rustore.ru/)
2. Выберите ваше приложение
3. Перейдите в **Статистика** → **Подписки**

Там вы увидите:
- 📊 Количество активных подписок
- 💰 Доход по типам подписок
- 📈 График новых/отменённых подписок
- 👥 Список пользователей с подписками
- 💳 История транзакций

### Аналитика подписок

```dart
// Отправка событий в Firebase Analytics
FirebaseAnalytics.instance.logEvent(
  name: 'premium_purchase',
  parameters: {
    'product_id': productId,
    'price': priceValue,
    'currency': 'RUB',
  },
);

// Отслеживание отмен
FirebaseAnalytics.instance.logEvent(
  name: 'premium_expired',
  parameters: {
    'product_id': subscription.productId,
    'days_active': subscription.daysActive,
  },
);
```

---

## 🧪 Тестирование подписок

### В Debug режиме

```dart
// Включить тестовый Premium
final service = await PremiumService.instance;
await service.setDebugPremium(true);

// Проверить статус
print('Is Premium: ${service.isPremium}');
print('Should show ads: ${service.shouldShowAds}');

// Отключить
await service.setDebugPremium(false);
```

### Тестовые покупки в RuStore

1. В RuStore Console создайте **тестовую группу пользователей**
2. Добавьте свой аккаунт в тестовую группу
3. Включите **Тестовые покупки** для вашего приложения
4. Тестовые покупки будут бесплатными и сразу подтверждаться

---

## ❓ FAQ

### Как отменить подписку?

Пользователь отменяет подписку через **приложение RuStore**:
1. Открыть RuStore → Профиль → Подписки
2. Найти "Мастерок"
3. Нажать "Отменить подписку"

Кнопка в вашем приложении открывает эту страницу:

```dart
Future<void> cancelSubscription() async {
  // Открыть управление подписками в RuStore
  await RustoreBilling.openSubscriptionManagement();
}
```

### Что происходит при истечении подписки?

1. RuStore перестаёт продлевать подписку
2. При следующем запуске `_checkActivePurchases()` обнаружит истечение
3. `_currentSubscription.isExpired` вернёт `true`
4. UI автоматически обновится через Stream
5. Premium функции заблокируются

### Как проверить подписку на сервере?

RuStore предоставляет **Server-to-Server API** для проверки покупок:

```bash
POST https://public-api.rustore.ru/public/v1/purchase/check
Authorization: Bearer YOUR_API_KEY

{
  "packageName": "ru.masterok.app",
  "productId": "premium_monthly",
  "purchaseToken": "TOKEN_FROM_APP"
}
```

Ответ:
```json
{
  "purchaseState": "PURCHASED",
  "expiryTimeMillis": 1735689600000
}
```

### Как обрабатывать возвраты?

RuStore автоматически отправляет webhook при возврате средств. Настройте в Console:

1. **Webhooks** → **Добавить webhook**
2. URL: `https://yourdomain.com/api/rustore/webhook`
3. События: `PURCHASE_REFUNDED`

В приложении достаточно регулярно вызывать `_checkActivePurchases()` при старте.

---

## 🎯 Чек-лист интеграции

- [ ] Добавить `rustore_flutter_billing` в pubspec.yaml
- [ ] Создать продукты в RuStore Console
- [ ] Раскомментировать TODO в `premium_service.dart`
- [ ] Реализовать `_initializeRuStoreBilling()`
- [ ] Реализовать `getAvailableProducts()` с RuStore API
- [ ] Реализовать `purchaseProduct()` с RuStore API
- [ ] Реализовать `restorePurchases()` с RuStore API
- [ ] Добавить проверку покупок при старте приложения
- [ ] Настроить Firebase Analytics для отслеживания
- [ ] Протестировать покупки с тестовой группой
- [ ] Опубликовать обновление в RuStore

---

## 📞 Поддержка

**Документация RuStore Billing:**
https://www.rustore.ru/help/sdk/payments/flutter

**Техподдержка RuStore:**
https://www.rustore.ru/help/support

**Firebase Analytics:**
https://firebase.google.com/docs/analytics/get-started?platform=flutter
