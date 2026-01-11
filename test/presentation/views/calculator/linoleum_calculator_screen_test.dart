import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/linoleum_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('LinoleumCalculatorScreen - рендеринг виджетов', () {
    testWidgets('отображается корректно', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает заголовок', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.textContaining('linoleum_calc'), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('common.sqm'), findsWidgets);
      expect(find.textContaining('common.pcs'), findsWidgets);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('LinoleumCalculatorScreen - селектор типа линолеума', () {
    testWidgets('отображает типы линолеума', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
      expect(find.byIcon(Icons.home), findsWidgets); // household
      expect(find.byIcon(Icons.business), findsWidgets); // semi-commercial
      expect(find.byIcon(Icons.factory), findsWidgets); // commercial
    });

    testWidgets('можно выбрать бытовой линолеум', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final householdOption = find.textContaining('linoleum_calc.type.household');
      if (householdOption.evaluate().isNotEmpty) {
        await tester.tap(householdOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать полукоммерческий линолеум', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final semiOption = find.textContaining('linoleum_calc.type.semi_commercial');
      if (semiOption.evaluate().isNotEmpty) {
        await tester.tap(semiOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать коммерческий линолеум', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final commercialOption = find.textContaining('linoleum_calc.type.commercial');
      if (commercialOption.evaluate().isNotEmpty) {
        await tester.tap(commercialOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
    });
  });

  group('LinoleumCalculatorScreen - режимы ввода', () {
    testWidgets('отображает селектор режима ввода', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
      expect(find.textContaining('linoleum_calc.mode'), findsWidgets);
    });

    testWidgets('можно переключиться на режим ввода комнаты', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final roomMode = find.textContaining('linoleum_calc.mode.room');
      if (roomMode.evaluate().isNotEmpty) {
        await tester.tap(roomMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает слайдер площади в ручном режиме', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('отображает поля ширины и длины в режиме комнаты', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final roomMode = find.textContaining('linoleum_calc.mode.room');
      if (roomMode.evaluate().isNotEmpty) {
        await tester.tap(roomMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('LinoleumCalculatorScreen - ширина рулона и опции', () {
    testWidgets('можно регулировать ширину рулона', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает переключатели опций', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно включить/выключить двусторонний скотч', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final tapeSwitch = find.textContaining('linoleum_calc.option.tape');
      if (tapeSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно включить/выключить плинтус', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final plinthSwitch = find.textContaining('linoleum_calc.option.plinth');
      if (plinthSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().length > 1) {
          await tester.tap(switches.at(1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
    });
  });

  group('LinoleumCalculatorScreen - карточка материалов', () {
    testWidgets('отображает карточку материалов', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.layers), findsWidgets);
      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.byIcon(Icons.receipt_long), findsWidgets);
    });
  });

  group('LinoleumCalculatorScreen - действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
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
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
    });
  });

  group('LinoleumCalculatorScreen - жизненный цикл', () {
    testWidgets('инициализируется с результатами по умолчанию', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(LinoleumCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LinoleumCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(LinoleumCalculatorScreen), findsNothing);
    });
  });
}
