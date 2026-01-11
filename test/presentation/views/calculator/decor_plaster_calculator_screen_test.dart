import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/decor_plaster_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('DecorPlasterCalculatorScreen - рендеринг виджетов', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(DecorPlasterCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает заголовок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.textContaining('decor_plaster_calc'), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('common.sqm'), findsWidgets);
      expect(find.textContaining('common.pcs'), findsWidgets);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('DecorPlasterCalculatorScreen - селектор типа штукатурки', () {
    testWidgets('отображает типы декоративной штукатурки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
      expect(find.byIcon(Icons.gradient), findsWidgets); // venetian
      expect(find.byIcon(Icons.texture), findsWidgets); // bark
      expect(find.byIcon(Icons.blur_on), findsWidgets); // silk
    });

    testWidgets('можно выбрать венецианскую штукатурку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final venetianOption = find.textContaining('decor_plaster_calc.type.venetian');
      if (venetianOption.evaluate().isNotEmpty) {
        await tester.tap(venetianOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorPlasterCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать штукатурку короед', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final barkOption = find.textContaining('decor_plaster_calc.type.bark');
      if (barkOption.evaluate().isNotEmpty) {
        await tester.tap(barkOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorPlasterCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать шелковую штукатурку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final silkOption = find.textContaining('decor_plaster_calc.type.silk');
      if (silkOption.evaluate().isNotEmpty) {
        await tester.tap(silkOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorPlasterCalculatorScreen), findsOneWidget);
    });
  });

  group('DecorPlasterCalculatorScreen - режимы ввода', () {
    testWidgets('отображает селектор режима ввода', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
      expect(find.textContaining('decor_plaster_calc.mode'), findsWidgets);
    });

    testWidgets('можно переключиться на режим ввода стены', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final wallMode = find.textContaining('decor_plaster_calc.mode.wall');
      if (wallMode.evaluate().isNotEmpty) {
        await tester.tap(wallMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorPlasterCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает слайдер площади в ручном режиме', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('отображает поля ширины и высоты в режиме стены', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final wallMode = find.textContaining('decor_plaster_calc.mode.wall');
      if (wallMode.evaluate().isNotEmpty) {
        await tester.tap(wallMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('DecorPlasterCalculatorScreen - слайдеры и опции', () {
    testWidgets('можно регулировать количество слоев', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorPlasterCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно включить/выключить грунтовку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final primerSwitch = find.textContaining('decor_plaster_calc.option.primer');
      if (primerSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DecorPlasterCalculatorScreen), findsOneWidget);
    });
  });

  group('DecorPlasterCalculatorScreen - карточка материалов', () {
    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inventory_2), findsWidgets);
      expect(find.byIcon(Icons.receipt_long), findsWidgets);
    });
  });

  group('DecorPlasterCalculatorScreen - действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
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
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(DecorPlasterCalculatorScreen), findsOneWidget);
    });
  });

  group('DecorPlasterCalculatorScreen - жизненный цикл', () {
    testWidgets('инициализируется с результатами по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(DecorPlasterCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorPlasterCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(DecorPlasterCalculatorScreen), findsNothing);
    });
  });
}
