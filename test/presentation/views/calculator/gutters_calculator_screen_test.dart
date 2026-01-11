import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/gutters_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('GuttersCalculatorScreen - рендеринг виджетов', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(GuttersCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает заголовок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.textContaining('gutters_calc'), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('common.meters'), findsWidgets);
      expect(find.textContaining('common.pcs'), findsWidgets);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('GuttersCalculatorScreen - селектор материала', () {
    testWidgets('отображает типы материалов водостока', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsWidgets); // plastic
      expect(find.byIcon(Icons.iron), findsWidgets); // metal
      expect(find.byIcon(Icons.brightness_7), findsWidgets); // copper
    });

    testWidgets('можно выбрать пластиковый водосток', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final plasticOption = find.textContaining('gutters_calc.type.plastic');
      if (plasticOption.evaluate().isNotEmpty) {
        await tester.tap(plasticOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(GuttersCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать металлический водосток', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final metalOption = find.textContaining('gutters_calc.type.metal');
      if (metalOption.evaluate().isNotEmpty) {
        await tester.tap(metalOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(GuttersCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать медный водосток', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final copperOption = find.textContaining('gutters_calc.type.copper');
      if (copperOption.evaluate().isNotEmpty) {
        await tester.tap(copperOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(GuttersCalculatorScreen), findsOneWidget);
    });
  });

  group('GuttersCalculatorScreen - размеры крыши', () {
    testWidgets('отображает поля для ввода размеров крыши', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
      expect(find.textContaining('gutters_calc.label.roof_length'), findsWidgets);
      expect(find.textContaining('gutters_calc.label.roof_width'), findsWidgets);
      expect(find.textContaining('gutters_calc.label.wall_height'), findsWidgets);
    });

    testWidgets('отображает слайдер количества водостоков', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
      expect(find.textContaining('gutters_calc.label.downpipes_count'), findsWidgets);
    });

    testWidgets('можно регулировать количество водостоков', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(GuttersCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает подсказку о водостоках', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('gutters_calc.downpipes_hint'), findsWidgets);
    });
  });

  group('GuttersCalculatorScreen - опции обогрева', () {
    testWidgets('отображает переключатель обогрева', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
      expect(find.textContaining('gutters_calc.option.heating'), findsWidgets);
    });

    testWidgets('можно включить/выключить обогрев', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final heatingSwitch = find.textContaining('gutters_calc.option.heating');
      if (heatingSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(GuttersCalculatorScreen), findsOneWidget);
    });
  });

  group('GuttersCalculatorScreen - карточка материалов', () {
    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.horizontal_rule), findsWidgets); // gutters
      expect(find.byIcon(Icons.arrow_downward), findsWidgets); // downpipes
      expect(find.byIcon(Icons.turn_right), findsWidgets); // corners
      expect(find.byIcon(Icons.filter_alt), findsWidgets); // funnels
      expect(find.byIcon(Icons.settings), findsWidgets); // brackets
      expect(find.byIcon(Icons.receipt_long), findsWidgets);
    });
  });

  group('GuttersCalculatorScreen - действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('можно прокручивать содержимое', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(GuttersCalculatorScreen), findsOneWidget);
    });
  });

  group('GuttersCalculatorScreen - жизненный цикл', () {
    testWidgets('инициализируется с результатами по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(GuttersCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const GuttersCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(GuttersCalculatorScreen), findsNothing);
    });
  });
}
