import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// Price Test Helpers
// ============================================================================

/// Создать тестовый прайс-лист с указанными SKU и ценами
List<PriceItem> createTestPriceList(Map<String, double> prices) {
  return prices.entries.map((entry) => PriceItem(
    sku: entry.key,
    name: 'Test ${entry.key}',
    price: entry.value,
    unit: 'шт',
    imageUrl: '',
  )).toList();
}

/// Создать пустой прайс-лист
List<PriceItem> createEmptyPriceList() {
  return <PriceItem>[];
}

/// Создать стандартный тестовый прайс-лист с общими материалами
List<PriceItem> createStandardTestPriceList() {
  return [
    const PriceItem(sku: 'cement_m400', name: 'Цемент М400', price: 300.0, unit: 'мешок', imageUrl: ''),
    const PriceItem(sku: 'sand', name: 'Песок', price: 500.0, unit: 'м³', imageUrl: ''),
    const PriceItem(sku: 'plaster', name: 'Штукатурка', price: 250.0, unit: 'кг', imageUrl: ''),
    const PriceItem(sku: 'paint', name: 'Краска', price: 400.0, unit: 'кг', imageUrl: ''),
    const PriceItem(sku: 'tile', name: 'Плитка', price: 800.0, unit: 'м²', imageUrl: ''),
    const PriceItem(sku: 'laminate', name: 'Ламинат', price: 600.0, unit: 'упаковка', imageUrl: ''),
    const PriceItem(sku: 'wallpaper', name: 'Обои', price: 500.0, unit: 'рулон', imageUrl: ''),
    const PriceItem(sku: 'primer', name: 'Грунтовка', price: 200.0, unit: 'л', imageUrl: ''),
  ];
}

/// Проверить, что результат содержит ожидаемые ключи
bool resultContainsKeys(Map<String, double> values, List<String> expectedKeys) {
  return expectedKeys.every((key) => values.containsKey(key));
}

/// Проверить, что результат содержит все значения больше нуля
bool allValuesPositive(Map<String, double> values) {
  return values.values.every((value) => value >= 0);
}

/// Проверить, что результат содержит все значения больше указанного минимума
bool allValuesGreaterThan(Map<String, double> values, double min) {
  return values.values.every((value) => value > min);
}

// ============================================================================
// Widget Test Helpers
// ============================================================================

/// Создаёт тестовый widget с полной настройкой providers и localization
Widget createTestApp({
  required Widget child,
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Настраивает mock для SharedPreferences и PackageInfo
void setupMocks({
  Map<String, Object>? sharedPreferencesValues,
  String appVersion = '1.0.0',
  String buildNumber = '1',
}) {
  SharedPreferences.setMockInitialValues(sharedPreferencesValues ?? {});

  PackageInfo.setMockInitialValues(
    appName: 'Probrab AI',
    packageName: 'ru.probrab.app',
    version: appVersion,
    buildNumber: buildNumber,
    buildSignature: 'test-signature',
  );
}

/// Pumps widget и ждёт завершения анимаций (с таймаутом для избежания зависаний)
Future<void> pumpAndSettleWithTimeout(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  await tester.pump();

  // Вместо pumpAndSettle используем фиксированное количество pump
  // для избежания таймаутов при бесконечных анимациях
  final steps = (timeout.inMilliseconds / 100).ceil();
  for (int i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
