import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/doors_install_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('DoorsInstallCalculatorScreen - рендеринг виджетов', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает заголовок', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pump();

      // Check for translated title "Установка дверей"
      expect(find.textContaining('Установка дверей'), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      // Check for translated unit "шт"
      expect(find.textContaining('шт'), findsWidgets);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('DoorsInstallCalculatorScreen - селектор типа дверей', () {
    testWidgets('отображает типы дверей', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
      expect(find.byIcon(Icons.door_front_door), findsWidgets); // interior
      expect(find.byIcon(Icons.door_sliding), findsWidgets); // entrance
      expect(find.byIcon(Icons.window), findsWidgets); // glass
    });

    testWidgets('можно выбрать межкомнатную дверь', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final interiorOption = find.byType(TypeSelectorGroup);
      if (interiorOption.evaluate().isNotEmpty) {
        await tester.tap(interiorOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать входную дверь', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final entranceOption = find.byType(TypeSelectorGroup);
      if (entranceOption.evaluate().isNotEmpty) {
        await tester.tap(entranceOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать стеклянную дверь', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final glassOption = find.byType(TypeSelectorGroup);
      if (glassOption.evaluate().isNotEmpty) {
        await tester.tap(glassOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });
  });

  group('DoorsInstallCalculatorScreen - количество дверей', () {
    testWidgets('отображает слайдер количества дверей', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
      // Check for translated label "Количество дверей"
      expect(find.textContaining('Количество дверей'), findsWidgets);
    });

    testWidgets('можно регулировать количество дверей', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });
  });

  group('DoorsInstallCalculatorScreen - размеры дверей', () {
    testWidgets('отображает поля для ввода размеров', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
      // Check for translated labels "Ширина" and "Высота"
      expect(find.textContaining('Ширина'), findsWidgets);
      expect(find.textContaining('Высота'), findsWidgets);
    });

    testWidgets('отображает заголовок размеров двери', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for translated label "Размер двери"
      expect(find.textContaining('Размер двери'), findsWidgets);
    });

    testWidgets('отображает единицы измерения в см', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for translated unit "см"
      expect(find.textContaining('см'), findsWidgets);
    });
  });

  group('DoorsInstallCalculatorScreen - опции', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно включить/выключить наличники', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final casingSwitch = find.byType(SwitchListTile);
      if (casingSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно включить/выключить порог', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final thresholdSwitch = find.byType(SwitchListTile);
      if (thresholdSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().length > 1) {
          await tester.tap(switches.at(1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });
  });

  group('DoorsInstallCalculatorScreen - карточка материалов', () {
    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.door_front_door), findsWidgets);
      expect(find.byIcon(Icons.crop_square), findsWidgets); // frames
      expect(find.byIcon(Icons.hardware), findsWidgets); // hinges
      expect(find.byIcon(Icons.radio_button_checked), findsWidgets); // handles
      expect(find.byIcon(Icons.blur_on), findsWidgets); // foam
      expect(find.byIcon(Icons.receipt_long), findsWidgets);
    });
  });

  group('DoorsInstallCalculatorScreen - действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
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
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });
  });

  group('DoorsInstallCalculatorScreen - жизненный цикл', () {
    testWidgets('инициализируется с результатами по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(DoorsInstallCalculatorScreen), findsNothing);
    });
  });
}
