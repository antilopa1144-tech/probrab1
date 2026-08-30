import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  testWidgets('открывает canonical flow вентиляции через ProCalculator', (
    tester,
  ) async {
    setTestViewportSize(tester);
    final definition = CalculatorRegistry.getById('engineering_ventilation');
    expect(definition, isNotNull);

    final routed = CalculatorScreenRegistry.build(
      'engineering_ventilation',
      definition!,
      null,
    );
    expect(routed, isA<ProCalculatorScreen>());

    await tester.pumpWidget(
      createTestApp(child: ProCalculatorScreen(definition: definition)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Расход воздуха'), findsOneWidget);
    expect(find.text('Проверка воздуховода'), findsOneWidget);
    expect(find.text('Закупка по ведомости'), findsOneWidget);
    expect(find.text('Исходный расход воздуха'), findsOneWidget);
    expect(find.text('Площадь жилых помещений'), findsOneWidget);
    expect(find.text('Высота помещений'), findsOneWidget);
    expect(find.text('Постоянно находящихся людей'), findsOneWidget);
    expect(find.text('Проектный расход воздуха'), findsNothing);
    expect(find.text('Форма проверяемого канала'), findsOneWidget);
    expect(find.text('Внутренний диаметр'), findsOneWidget);
    expect(find.text('Внутренняя ширина'), findsNothing);
    expect(find.text('Длина воздуховода по трассе'), findsOneWidget);
    expect(find.text('РАСЧЁТНЫЙ РАСХОД, М³/Ч'), findsOneWidget);
    expect(find.text('СКОРОСТЬ В КАНАЛЕ, М/С'), findsOneWidget);
    expect(find.text('ЭКВИВАЛЕНТНЫЙ ДИАМЕТР, ММ'), findsOneWidget);
    expect(
      find.textContaining('не проект системы вентиляции', skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.textContaining(
        'не угадывает трассу по площади',
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
}
