import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  testWidgets('открывает проектный flow лестницы через ProCalculator', (
    tester,
  ) async {
    setTestViewportSize(tester);
    final definition = CalculatorRegistry.getById('stairs');
    expect(definition, isNotNull);

    final routed = CalculatorScreenRegistry.build('stairs', definition!, null);
    expect(routed, isA<ProCalculatorScreen>());

    await tester.pumpWidget(
      createTestApp(child: ProCalculatorScreen(definition: definition)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Геометрия одного марша'), findsOneWidget);
    expect(find.text('Эскизная проверка прохода'), findsOneWidget);
    expect(find.text('Ступени и подступенки'), findsOneWidget);
    expect(find.text('Несущие элементы по проекту'), findsOneWidget);
    expect(find.text('Монолитная лестница по проекту'), findsOneWidget);
    expect(find.text('Ограждение по проекту'), findsOneWidget);
    expect(find.text('Высота от чистого пола до чистого пола'), findsOneWidget);
    expect(find.text('Целевая высота подступенка'), findsOneWidget);
    expect(find.text('Число подъёмов по проекту'), findsNothing);
    expect(find.text('Толщина перекрытия с чистовыми слоями'), findsNothing);
    expect(find.text('Запас подступенков'), findsNothing);
    expect(find.text('Масса арматуры по проекту'), findsOneWidget);
    expect(find.text('Запас арматуры'), findsNothing);
    expect(
      find.textContaining(
        'не проектирует несущие элементы',
        skipOffstage: false,
      ),
      findsWidgets,
    );
    expect(find.textContaining('Материал конструкции'), findsNothing);
  });
}
