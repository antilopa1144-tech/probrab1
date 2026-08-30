import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  testWidgets('открывает проектный flow кровли через ProCalculator', (
    tester,
  ) async {
    setTestViewportSize(tester);
    final definition = CalculatorRegistry.getById('roofing_unified');
    expect(definition, isNotNull);

    final routed = CalculatorScreenRegistry.build(
      'roofing_unified',
      definition!,
      null,
    );
    expect(routed, isA<ProCalculatorScreen>());

    await tester.pumpWidget(
      createTestApp(child: ProCalculatorScreen(definition: definition)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Площадь скатов'), findsOneWidget);
    expect(find.text('Основное покрытие'), findsOneWidget);
    expect(find.text('Доборные элементы'), findsOneWidget);
    expect(find.text('Мембрана и основание'), findsOneWidget);
    expect(find.text('Пиломатериал из проекта'), findsOneWidget);
    expect(find.text('Крепёж и безопасность'), findsOneWidget);
    expect(find.text('Суммарная площадь скатов'), findsOneWidget);
    expect(
      find.text('Полезная площадь одной покупной единицы'),
      findsOneWidget,
    );
    expect(find.text('Запас коньковых элементов'), findsNothing);
    expect(find.text('Полезная площадь одного рулона мембраны'), findsNothing);
    expect(find.text('Количество крепежа в упаковке'), findsNothing);
    expect(
      find.textContaining('не проектирует стропила', skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.textContaining('Сложность крыши', skipOffstage: false),
      findsNothing,
    );
  });
}
