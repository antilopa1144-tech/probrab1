import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/decor_stone_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('DecorStoneCalculatorScreen - рендеринг виджетов', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает заголовок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.textContaining('decor_stone_calc'), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
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
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('DecorStoneCalculatorScreen - селектор типа камня', () {
    testWidgets('отображает типы декоративного камня', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
      expect(find.byIcon(Icons.view_module), findsWidgets); // gypsum
      expect(find.byIcon(Icons.grid_view), findsWidgets); // concrete
      expect(find.byIcon(Icons.landscape), findsWidgets); // natural
    });

    testWidgets('можно выбрать гипсовый камень', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gypsumOption = find.textContaining('decor_stone_calc.type.gypsum');
      if (gypsumOption.evaluate().isNotEmpty) {
        await tester.tap(gypsumOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать бетонный камень', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final concreteOption = find.textContaining('decor_stone_calc.type.concrete');
      if (concreteOption.evaluate().isNotEmpty) {
        await tester.tap(concreteOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать натуральный камень', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final naturalOption = find.textContaining('decor_stone_calc.type.natural');
      if (naturalOption.evaluate().isNotEmpty) {
        await tester.tap(naturalOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
    });
  });

  group('DecorStoneCalculatorScreen - режимы ввода', () {
    testWidgets('отображает селектор режима ввода', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
      expect(find.textContaining('decor_stone_calc.mode'), findsWidgets);
    });

    testWidgets('можно переключиться на режим ввода стены', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final wallMode = find.textContaining('decor_stone_calc.mode.wall');
      if (wallMode.evaluate().isNotEmpty) {
        await tester.tap(wallMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает слайдер площади в ручном режиме', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('отображает поля ширины и высоты в режиме стены', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final wallMode = find.textContaining('decor_stone_calc.mode.wall');
      if (wallMode.evaluate().isNotEmpty) {
        await tester.tap(wallMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('DecorStoneCalculatorScreen - регулировка ширины шва', () {
    testWidgets('можно регулировать ширину шва', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает подсказку для ширины шва', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('decor_stone_calc.joint_hint'), findsWidgets);
    });
  });

  group('DecorStoneCalculatorScreen - опции', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно включить/выключить затирку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final groutSwitch = find.textContaining('decor_stone_calc.option.grout');
      if (groutSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно включить/выключить грунтовку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final primerSwitch = find.textContaining('decor_stone_calc.option.primer');
      if (primerSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().length > 1) {
          await tester.tap(switches.at(1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
    });
  });

  group('DecorStoneCalculatorScreen - карточка материалов', () {
    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_module), findsWidgets);
      expect(find.byIcon(Icons.inventory_2), findsWidgets);
      expect(find.byIcon(Icons.receipt_long), findsWidgets);
    });
  });

  group('DecorStoneCalculatorScreen - действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
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
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
    });
  });

  group('DecorStoneCalculatorScreen - жизненный цикл', () {
    testWidgets('инициализируется с результатами по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(DecorStoneCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DecorStoneCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(DecorStoneCalculatorScreen), findsNothing);
    });
  });
}
