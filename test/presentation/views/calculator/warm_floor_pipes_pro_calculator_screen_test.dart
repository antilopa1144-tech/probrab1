import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  testWidgets('водяной тёплый пол доступен через реальный canonical flow', (
    tester,
  ) async {
    setTestViewportSize(tester);
    final definition = CalculatorRegistry.getById('engineering_warm_floor');
    expect(definition, isNotNull);

    final routed = CalculatorScreenRegistry.build(
      'engineering_warm_floor',
      definition!,
      null,
    );
    expect(routed, isA<ProCalculatorScreen>());

    await tester.pumpWidget(
      createTestApp(child: ProCalculatorScreen(definition: definition)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Исходные данные'), findsWidgets);
    expect(find.text('Проверка контуров'), findsOneWidget);
    expect(find.text('Закупка по ведомости'), findsOneWidget);
    expect(find.text('Предварительно по раскладке'), findsOneWidget);
    expect(find.text('По ведомости проекта'), findsOneWidget);
    expect(find.text('Фактическая площадь раскладки'), findsOneWidget);
    expect(find.text('Шаг трубы из проекта'), findsOneWidget);
    expect(find.text('Подводки вне площади раскладки'), findsOneWidget);
    expect(find.text('Количество контуров по проекту'), findsOneWidget);
    expect(find.text('Длина фактической бухты'), findsOneWidget);
    expect(find.text('ТОЧНАЯ ПОТРЕБНОСТЬ, М'), findsOneWidget);
    expect(find.text('ТРУБЫ К ПОКУПКЕ, М'), findsOneWidget);
    expect(
      find.textContaining('ЭППС, демпферная лента', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      definition.afterHints.map((hint) => hint.messageKey),
      contains('hint.water_floor.noHydraulics'),
    );
  });
}
