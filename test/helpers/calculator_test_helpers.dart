import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/providers/constants_provider.dart';

// ============================================================================
// Calculator Test Constants
// ============================================================================

/// Стандартный размер экрана для тестов калькуляторов
const kTestScreenSize = Size(1440, 2560);

/// Стандартный devicePixelRatio для тестов
const kTestDevicePixelRatio = 1.0;

// ============================================================================
// Mock Overrides для провайдеров констант
// ============================================================================

/// Создаёт mock overrides для калькулятора с указанным ключом констант
List<Override> createCalculatorConstantsOverrides(String constantsKey) {
  return [
    calculatorConstantsProvider(constantsKey).overrideWith((ref) async => null),
    calculatorConstantsProvider('common').overrideWith((ref) async => null),
  ];
}

/// Стандартные mock overrides для разных калькуляторов
class CalculatorMockOverrides {
  static List<Override> get gypsum => createCalculatorConstantsOverrides('gypsum');
  static List<Override> get gasblock => createCalculatorConstantsOverrides('gasblock');
  static List<Override> get tile => createCalculatorConstantsOverrides('tile');
  static List<Override> get tileAdhesive => createCalculatorConstantsOverrides('tile_adhesive');
  static List<Override> get wallpaper => createCalculatorConstantsOverrides('wallpaper');
  static List<Override> get electrical => createCalculatorConstantsOverrides('electrical');
  static List<Override> get underfloorHeating => createCalculatorConstantsOverrides('warmfloor');
  static List<Override> get woodLining => createCalculatorConstantsOverrides('wood_lining');
  static List<Override> get terrace => createCalculatorConstantsOverrides('terrace');
  static List<Override> get osb => createCalculatorConstantsOverrides('sheeting_osb_plywood');
  static List<Override> get plaster => createCalculatorConstantsOverrides('plaster');
  static List<Override> get putty => createCalculatorConstantsOverrides('putty');
  static List<Override> get selfLevelingFloor => createCalculatorConstantsOverrides('self_leveling_floor');
}

// ============================================================================
// Calculator Definition Helpers
// ============================================================================

/// Получает определение калькулятора по ID с проверкой на null
CalculatorDefinitionV2 getCalculatorDefinition(String calculatorId) {
  final definition = CalculatorRegistry.getById(calculatorId);
  if (definition == null) {
    throw StateError('$calculatorId calculator not found in registry');
  }
  return definition;
}

// ============================================================================
// Screen Size Setup Helpers
// ============================================================================

/// Настраивает размер экрана для теста калькулятора
///
/// Использование:
/// ```dart
/// testWidgets('test name', (tester) async {
///   setupTestScreenSize(tester);
///   // ... тест
/// });
/// ```
void setupTestScreenSize(
  WidgetTester tester, {
  Size size = kTestScreenSize,
  double devicePixelRatio = kTestDevicePixelRatio,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
}

// ============================================================================
// Pump Helpers
// ============================================================================

/// Выполняет pump с ожиданием для калькуляторов
///
/// Использует фиксированное количество pump вместо pumpAndSettle
/// для избежания таймаутов при бесконечных анимациях
Future<void> pumpCalculatorWidget(
  WidgetTester tester, {
  int pumps = 3,
  Duration pumpDuration = const Duration(milliseconds: 100),
}) async {
  for (int i = 0; i < pumps; i++) {
    await tester.pump(pumpDuration);
  }
}

/// Полный pump для калькулятора с pumpAndSettle
///
/// Используется когда нужно дождаться всех анимаций
Future<void> pumpCalculatorWidgetAndSettle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    timeout,
  );
}

// ============================================================================
// Widget Finding Helpers
// ============================================================================

/// Проверяет наличие текста с ключом локализации
///
/// TestAppLocalizations возвращает ключи, поэтому ищем по ключу
bool hasLocalizedText(String localizationKey) {
  return find.text(localizationKey).evaluate().isNotEmpty ||
      find.textContaining(localizationKey).evaluate().isNotEmpty;
}

/// Находит виджет с текстом, содержащим часть ключа локализации
Finder findByLocalizationKeyPart(String keyPart) {
  return find.textContaining(keyPart);
}

// ============================================================================
// Common Test Patterns
// ============================================================================

/// Создаёт стандартный setUp для теста калькулятора
///
/// Возвращает функцию для использования в setUpAll
void Function() createCalculatorSetUp({
  required void Function(CalculatorDefinitionV2) onDefinitionLoaded,
  required String calculatorId,
}) {
  return () {
    final definition = getCalculatorDefinition(calculatorId);
    onDefinitionLoaded(definition);
  };
}

/// Прокручивает ListView вниз для нахождения скрытых элементов
Future<void> scrollDownToFind(
  WidgetTester tester,
  Finder target, {
  double scrollAmount = 300,
  int maxScrolls = 5,
}) async {
  final listView = find.byType(ListView);
  if (listView.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) return;

    for (int i = 0; i < maxScrolls; i++) {
      if (target.evaluate().isNotEmpty) break;
      await tester.drag(scrollable.first, Offset(0, -scrollAmount));
      await tester.pump();
    }
    return;
  }

  for (int i = 0; i < maxScrolls; i++) {
    if (target.evaluate().isNotEmpty) break;
    await tester.drag(listView.first, Offset(0, -scrollAmount));
    await tester.pump();
  }
}
