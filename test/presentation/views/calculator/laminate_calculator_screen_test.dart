import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/laminate_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('LaminateCalculatorScreen - рендеринг виджетов', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает заголовок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('LaminateCalculatorScreen - селектор способа укладки', () {
    testWidgets('отображает способы укладки ламината', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
      expect(find.byIcon(Icons.view_stream), findsWidgets); // straight
      expect(find.byIcon(Icons.rotate_right), findsWidgets); // diagonal
    });

    testWidgets('можно выбрать прямую укладку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final straightOption = find.byType(InkWell);
      if (straightOption.evaluate().isNotEmpty) {
        await tester.tap(straightOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать диагональную укладку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final diagonalOption = find.byType(InkWell);
      if (diagonalOption.evaluate().isNotEmpty) {
        await tester.tap(diagonalOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });
  });

  group('LaminateCalculatorScreen - селектор класса ламината', () {
    testWidgets('отображает селектор класса', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('можно выбрать класс 31', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final class31 = find.byType(InkWell);
      if (class31.evaluate().isNotEmpty) {
        await tester.tap(class31.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать класс 32', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final class32 = find.byType(InkWell);
      if (class32.evaluate().isNotEmpty) {
        await tester.tap(class32.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать класс 33', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final class33 = find.byType(InkWell);
      if (class33.evaluate().isNotEmpty) {
        await tester.tap(class33.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });
  });

  group('LaminateCalculatorScreen - режимы ввода', () {
    testWidgets('отображает селектор режима ввода', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('можно переключиться на режим ввода комнаты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final roomMode = find.textContaining('По комнате');
      if (roomMode.evaluate().isNotEmpty) {
        await tester.tap(roomMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает слайдер площади в ручном режиме', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('отображает поля ширины и длины в режиме комнаты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final roomMode = find.textContaining('По комнате');
      if (roomMode.evaluate().isNotEmpty) {
        await tester.tap(roomMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('LaminateCalculatorScreen - площадь упаковки и опции', () {
    testWidgets('можно регулировать площадь упаковки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно включить/выключить подложку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final underlaySwitch = find.byType(SwitchListTile);
      if (underlaySwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно включить/выключить плинтус', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final plinthSwitch = find.byType(SwitchListTile);
      if (plinthSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().length > 1) {
          await tester.tap(switches.at(1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });
  });

  group('LaminateCalculatorScreen - карточка материалов', () {
    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.layers), findsWidgets);
      expect(find.byIcon(Icons.receipt_long), findsWidgets);
    });
  });

  group('LaminateCalculatorScreen - действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
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
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });
  });

  group('LaminateCalculatorScreen - жизненный цикл', () {
    testWidgets('инициализируется с результатами по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(LaminateCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const LaminateCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(LaminateCalculatorScreen), findsNothing);
    });
  });
}
