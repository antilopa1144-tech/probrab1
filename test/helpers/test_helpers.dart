import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

bool _assetBundleMockInstalled = false;

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (int i = 0; i < 6; i++) {
    final pubspec = File(
      '${dir.path}${Platform.pathSeparator}pubspec.yaml',
    );
    if (pubspec.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current;
}

void _installAssetBundleMock() {
  if (_assetBundleMockInstalled) return;
  _assetBundleMockInstalled = true;

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    if (message == null) return null;

    final encodedKey = utf8.decode(message.buffer.asUint8List());
    final assetKey = Uri.decodeFull(encodedKey);
    if (assetKey == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, dynamic>{});
    }
    if (assetKey == 'AssetManifest.json') {
      final bytes = utf8.encode('{}');
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    final normalized = assetKey.replaceAll('/', Platform.pathSeparator);

    File file = File(normalized);
    if (!file.existsSync()) {
      final root = _findProjectRoot();
      file = File('${root.path}${Platform.pathSeparator}$normalized');
    }
    if (!file.existsSync()) return null;

    final bytes = file.readAsBytesSync();
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  });
}

/// Загружает локализацию из JSON-файла для тестов
Map<String, dynamic>? _cachedTranslations;

Map<String, dynamic>? _syncLoadTranslations() {
  if (_cachedTranslations != null) return _cachedTranslations;

  final root = _findProjectRoot();
  final file = File('${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}lang${Platform.pathSeparator}ru.json');

  if (file.existsSync()) {
    final content = file.readAsStringSync();
    _cachedTranslations = json.decode(content) as Map<String, dynamic>;
    return _cachedTranslations;
  }

  return null;
}

String _getNestedValue(Map<String, dynamic> map, String key) {
  final parts = key.split('.');
  dynamic current = map;

  for (final part in parts) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      return key; // Return key if not found
    }
  }

  return current is String ? current : key;
}

class TestAppLocalizations extends AppLocalizations {
  TestAppLocalizations(super.locale);

  @override
  String translate(String key, [Map<String, String>? params]) {
    final translations = _syncLoadTranslations();
    String resolved;

    if (translations != null) {
      resolved = _getNestedValue(translations, key);
    } else {
      resolved = key;
    }

    if (params != null && params.isNotEmpty) {
      for (final entry in params.entries) {
        resolved = resolved.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return resolved;
  }
}

class TestAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const TestAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(TestAppLocalizations(locale));
  }

  @override
  bool shouldReload(TestAppLocalizationsDelegate old) => false;
}

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
    // Для CalculateScreedUnified
    const PriceItem(sku: 'dry_mix', name: 'Сухая смесь', price: 200.0, unit: 'мешок', imageUrl: ''),
    const PriceItem(sku: 'cps_m150', name: 'ЦПС М150', price: 250.0, unit: 'мешок', imageUrl: ''),
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
        TestAppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Настраивает размер экрана для тестов (решает проблему layout overflow)
/// Вызывать ПЕРЕД pumpWidget в testWidgets
void setTestViewportSize(
  WidgetTester tester, {
  double width = 1200,
  double height = 2000,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
}

/// Настраивает mock для SharedPreferences и PackageInfo
void setupMocks({
  Map<String, Object>? sharedPreferencesValues,
  String appVersion = '1.0.0',
  String buildNumber = '1',
}) {
  SharedPreferences.setMockInitialValues(sharedPreferencesValues ?? {});
  _installAssetBundleMock();

  PackageInfo.setMockInitialValues(
    appName: 'Probrab AI',
    packageName: 'ru.probrab.app',
    version: appVersion,
    buildNumber: buildNumber,
    buildSignature: 'test-signature',
  );
}

/// Оборачивает widget в SingleChildScrollView для избежания overflow
/// Используется для больших виджетов в тестах
Widget makeScrollable(Widget child) {
  return SingleChildScrollView(
    child: child,
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

// ============================================================================
// Riverpod + Stream Test Helpers
// ============================================================================

/// Надёжное ожидание загрузки данных для Stream-провайдеров
///
/// Проблема: Isar watch() + asyncMap() не эмитит события синхронно в тестах.
/// Решение: Использовать фиксированные pump с таймаутом.
///
/// Использование:
/// ```dart
/// await tester.pumpWidget(...);
/// await pumpForStream(tester); // Вместо pumpAndSettle
/// expect(find.text('...'), findsOneWidget);
/// ```
Future<void> pumpForStream(
  WidgetTester tester, {
  int pumps = 20,
  Duration interval = const Duration(milliseconds: 50),
}) async {
  // Первый pump для запуска виджетов
  await tester.pump();

  // Pump для обработки микрозадач
  await tester.pump(Duration.zero);

  // Несколько pump с интервалами для Stream событий
  for (int i = 0; i < pumps; i++) {
    await tester.pump(interval);
  }
}
