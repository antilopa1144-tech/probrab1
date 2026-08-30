import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  testWidgets('открывает canonical flow радиаторов через ProCalculator', (
    tester,
  ) async {
    setTestViewportSize(tester);
    final definition = CalculatorRegistry.getById('engineering_heating');
    expect(definition, isNotNull);

    final routed = CalculatorScreenRegistry.build(
      'engineering_heating',
      definition!,
      null,
    );
    expect(routed, isA<ProCalculatorScreen>());

    await tester.pumpWidget(
      createTestApp(child: ProCalculatorScreen(definition: definition)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Тепловая нагрузка'), findsOneWidget);
    expect(find.text('Отопительный прибор'), findsOneWidget);
    expect(find.text('Закупка по ведомости'), findsOneWidget);
    expect(find.text('Исходная тепловая нагрузка'), findsOneWidget);
    expect(find.text('Тепловая нагрузка помещения'), findsOneWidget);
    expect(find.text('Площадь помещения'), findsNothing);
    expect(find.text('Что подбираем'), findsOneWidget);
    expect(find.text('Паспортная теплоотдача'), findsOneWidget);
    expect(find.text('Теплоотдача одной секции или прибора'), findsOneWidget);
    expect(find.text('Номинальная теплоотдача'), findsNothing);
    expect(find.text('Длина труб по схеме'), findsOneWidget);
    expect(find.text('ТЕПЛОВАЯ НАГРУЗКА, ВТ'), findsOneWidget);
    expect(find.text('МОЩНОСТЬ ЕДИНИЦЫ, ВТ'), findsOneWidget);
    expect(find.text('К ПОКУПКЕ'), findsOneWidget);
    expect(
      find.textContaining('не проектирует отопление', skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.textContaining('каждого помещения', skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.textContaining('диаметры труб', skipOffstage: false),
      findsWidgets,
    );
  });
}
