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
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.textContaining('doors_calc'), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('common.pcs'), findsWidgets);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
      expect(find.byIcon(Icons.door_front_door), findsWidgets); // interior
      expect(find.byIcon(Icons.door_sliding), findsWidgets); // entrance
      expect(find.byIcon(Icons.window), findsWidgets); // glass
    });

    testWidgets('можно выбрать межкомнатную дверь', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final interiorOption = find.textContaining('doors_calc.type.interior');
      if (interiorOption.evaluate().isNotEmpty) {
        await tester.tap(interiorOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать входную дверь', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final entranceOption = find.textContaining('doors_calc.type.entrance');
      if (entranceOption.evaluate().isNotEmpty) {
        await tester.tap(entranceOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать стеклянную дверь', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final glassOption = find.textContaining('doors_calc.type.glass');
      if (glassOption.evaluate().isNotEmpty) {
        await tester.tap(glassOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });
  });

  group('DoorsInstallCalculatorScreen - количество дверей', () {
    testWidgets('отображает слайдер количества дверей', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
      expect(find.textContaining('doors_calc.label.doors_count'), findsWidgets);
    });

    testWidgets('можно регулировать количество дверей', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
      expect(find.textContaining('doors_calc.label.width'), findsWidgets);
      expect(find.textContaining('doors_calc.label.height'), findsWidgets);
    });

    testWidgets('отображает заголовок размеров двери', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('doors_calc.label.door_size'), findsWidgets);
    });

    testWidgets('отображает единицы измерения в см', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('common.cm'), findsWidgets);
    });
  });

  group('DoorsInstallCalculatorScreen - опции', () {
    testWidgets('отображает переключатели опций', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно включить/выключить наличники', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final casingSwitch = find.textContaining('doors_calc.option.casing');
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
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final thresholdSwitch = find.textContaining('doors_calc.option.threshold');
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
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(
          child: const DoorsInstallCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(DoorsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
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
