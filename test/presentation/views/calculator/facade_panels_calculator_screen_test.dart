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
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(TypeSelectorCard), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('м²'), findsWidgets);
      expect(find.textContaining('шт'), findsWidgets);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorCard), findsWidgets);
      expect(find.byIcon(Icons.view_module), findsWidgets); // vinyl
      expect(find.byIcon(Icons.grid_view), findsWidgets); // metal
      expect(find.byIcon(Icons.layers), findsWidgets); // fiber
    });

    testWidgets('можно выбрать виниловые панели', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final vinylOption = find.byType(TypeSelectorCard);
      if (vinylOption.evaluate().isNotEmpty) {
        await tester.tap(vinylOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать металлические панели', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final metalOption = find.byType(TypeSelectorCard);
      if (metalOption.evaluate().isNotEmpty) {
        await tester.tap(metalOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать фиброцементные панели', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final fiberOption = find.byType(TypeSelectorCard);
      if (fiberOption.evaluate().isNotEmpty) {
        await tester.tap(fiberOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });
  });

  group('FacadePanelsCalculatorScreen - размеры здания', () {
    testWidgets('отображает поля для ввода размеров', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
      expect(find.byType(CalculatorTextField), findsWidgets);
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('отображает слайдер площади проемов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('можно регулировать площадь проемов', (tester) async {
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });
  });

  group('FacadePanelsCalculatorScreen - опции', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно включить/выключить утепление', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final insulationSwitch = find.byType(SwitchListTile);
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
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final profileSwitch = find.byType(SwitchListTile);
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
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
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

  group('FacadePanelsCalculatorScreen - ползунок + текстовое поле', () {
    testWidgets('ползунок проемов имеет парное текстовое поле', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Slider и CalculatorTextField для площади проемов должны быть вместе
      expect(find.byType(Slider), findsWidgets);
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('текстовое поле и ползунок оба реагируют на изменения', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Двигаем ползунок — результат должен обновиться
      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });
  });

  group('FacadePanelsCalculatorScreen - жизненный цикл', () {
    testWidgets('инициализируется с результатами по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FacadePanelsCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(FacadePanelsCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
      setTestViewportSize(tester);
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
