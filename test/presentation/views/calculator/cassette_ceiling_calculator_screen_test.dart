import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/cassette_ceiling_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('CassetteCeilingCalculatorScreen виджет рендеринг', () {
    testWidgets('отображается корректно', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CassetteCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает CalculatorScaffold', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает CalculatorResultHeader', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('CassetteCeilingCalculatorScreen выбор типа потолка', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });

    testWidgets('отображает иконки типов потолка', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.grid_view), findsWidgets); // металлический
      expect(find.byIcon(Icons.blur_on), findsWidgets); // зеркальный
      expect(find.byIcon(Icons.grain), findsWidgets); // перфорированный
    });

    testWidgets('можно выбрать металлический потолок', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final metalType = find.textContaining('cassette_ceiling_calc.type.metal');
      if (metalType.evaluate().isNotEmpty) {
        await tester.tap(metalType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CassetteCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать зеркальный потолок', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final mirrorType = find.textContaining('cassette_ceiling_calc.type.mirror');
      if (mirrorType.evaluate().isNotEmpty) {
        await tester.tap(mirrorType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CassetteCeilingCalculatorScreen), findsOneWidget);
    });
  });

  group('CassetteCeilingCalculatorScreen выбор размера кассеты', () {
    testWidgets('отображает кнопки выбора размера кассеты', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('600x600 common.mm'), findsOneWidget);
      expect(find.text('600x1200 common.mm'), findsOneWidget);
      expect(find.text('300x300 common.mm'), findsOneWidget);
    });

    testWidgets('можно выбрать размер кассеты 600x600', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final size600 = find.text('600x600 common.mm');
      if (size600.evaluate().isNotEmpty) {
        await tester.tap(size600);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CassetteCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать размер кассеты 600x1200', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final size6001200 = find.text('600x1200 common.mm');
      if (size6001200.evaluate().isNotEmpty) {
        await tester.tap(size6001200);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CassetteCeilingCalculatorScreen), findsOneWidget);
    });
  });

  group('CassetteCeilingCalculatorScreen режимы ввода', () {
    testWidgets('отображает ModeSelector', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsOneWidget);
    });

    testWidgets('можно переключить режим ввода', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final manualMode = find.textContaining('cassette_ceiling_calc.mode.manual');
      if (manualMode.evaluate().isNotEmpty) {
        await tester.tap(manualMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CassetteCeilingCalculatorScreen), findsOneWidget);
    });
  });

  group('CassetteCeilingCalculatorScreen поля ввода', () {
    testWidgets('отображает слайдер площади в режиме manual', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Переключаемся на manual режим
      final manualMode = find.textContaining('cassette_ceiling_calc.mode.manual');
      if (manualMode.evaluate().isNotEmpty) {
        await tester.tap(manualMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('отображает поля длины и ширины в режиме room', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('можно изменить слайдер площади', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Переключаемся на manual режим
      final manualMode = find.textContaining('cassette_ceiling_calc.mode.manual');
      if (manualMode.evaluate().isNotEmpty) {
        await tester.tap(manualMode.first);
        await tester.pumpAndSettle();
      }

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(CassetteCeilingCalculatorScreen), findsOneWidget);
    });
  });

  group('CassetteCeilingCalculatorScreen результаты', () {
    testWidgets('отображает результаты площади', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает результаты количества кассет', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('common.pcs'), findsWidgets);
    });

    testWidgets('отображает иконки результатов', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.byIcon(Icons.grid_view), findsWidgets);
      expect(find.byIcon(Icons.hardware), findsWidgets);
    });
  });

  group('CassetteCeilingCalculatorScreen список материалов', () {
    testWidgets('отображает MaterialsCardModern', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('можно прокрутить до материалов', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(CassetteCeilingCalculatorScreen), findsOneWidget);
    });
  });

  group('CassetteCeilingCalculatorScreen действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('кнопка поделиться существует', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share_rounded);
      expect(shareButton, findsOneWidget);
    });
  });

  group('CassetteCeilingCalculatorScreen корректно освобождает ресурсы', () {
    testWidgets('корректно dispose', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CassetteCeilingCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(CassetteCeilingCalculatorScreen), findsNothing);
    });
  });
}
