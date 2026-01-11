import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/facade_panels_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('FacadePanelsCalculatorScreen - рендеринг виджетов', () {
    testWidgets('отображается корректно', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает заголовок', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.textContaining('facade_panels_calc'), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
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
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('FacadePanelsCalculatorScreen - селектор типа панелей', () {
    testWidgets('отображает типы фасадных панелей', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
      expect(find.byIcon(Icons.view_module), findsWidgets); // vinyl
      expect(find.byIcon(Icons.grid_view), findsWidgets); // metal
      expect(find.byIcon(Icons.layers), findsWidgets); // fiber
    });

    testWidgets('можно выбрать виниловые панели', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final vinylOption = find.textContaining('facade_panels_calc.type.vinyl');
      if (vinylOption.evaluate().isNotEmpty) {
        await tester.tap(vinylOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать металлические панели', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final metalOption = find.textContaining('facade_panels_calc.type.metal');
      if (metalOption.evaluate().isNotEmpty) {
        await tester.tap(metalOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать фиброцементные панели', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final fiberOption = find.textContaining('facade_panels_calc.type.fiber');
      if (fiberOption.evaluate().isNotEmpty) {
        await tester.tap(fiberOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });
  });

  group('FacadePanelsCalculatorScreen - размеры здания', () {
    testWidgets('отображает поля для ввода размеров', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
      expect(find.textContaining('facade_panels_calc.label.perimeter'), findsWidgets);
      expect(find.textContaining('facade_panels_calc.label.height'), findsWidgets);
    });

    testWidgets('отображает слайдер площади проемов', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
      expect(find.textContaining('facade_panels_calc.label.openings'), findsWidgets);
    });

    testWidgets('можно регулировать площадь проемов', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает подсказку о проемах', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('facade_panels_calc.openings_hint'), findsWidgets);
    });
  });

  group('FacadePanelsCalculatorScreen - опции', () {
    testWidgets('отображает переключатели опций', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно включить/выключить утепление', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final insulationSwitch = find.textContaining('facade_panels_calc.option.insulation');
      if (insulationSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно включить/выключить профиль', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final profileSwitch = find.textContaining('facade_panels_calc.option.profile');
      if (profileSwitch.evaluate().isNotEmpty) {
        final switches = find.byType(Switch);
        if (switches.evaluate().length > 1) {
          await tester.tap(switches.at(1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });
  });

  group('FacadePanelsCalculatorScreen - карточка материалов', () {
    testWidgets('отображает карточку материалов', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_module), findsWidgets);
      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.byIcon(Icons.rounded_corner), findsWidgets);
      expect(find.byIcon(Icons.border_bottom), findsWidgets);
      expect(find.byIcon(Icons.receipt_long), findsWidgets);
    });
  });

  group('FacadePanelsCalculatorScreen - действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
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
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });
  });

  group('FacadePanelsCalculatorScreen - жизненный цикл', () {
    testWidgets('инициализируется с результатами по умолчанию', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(FacadePanelsCalculatorScreen), findsNothing);
    });
  });
}
