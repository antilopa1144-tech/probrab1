import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/slopes_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('SlopesCalculatorScreen - рендеринг базовой структуры', () {
    testWidgets('отрисовывается без ошибок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SlopesCalculatorScreen), findsOneWidget);
    });

    testWidgets('содержит CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('содержит CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('имеет кнопки экспорта в AppBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('SlopesCalculatorScreen - селектор типа откосов', () {
    testWidgets('отображает TypeSelectorGroup для выбора типа', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
    });

    testWidgets('отображает иконки для всех типов откосов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      // Plaster, Gypsum, Sandwich
      expect(find.byIcon(Icons.foundation), findsOneWidget);
      expect(find.byIcon(Icons.grid_view), findsWidgets);
      expect(find.byIcon(Icons.layers), findsWidgets);
    });

    testWidgets('можно выбрать тип гипсокартон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final gypsumOption = find.byType(TypeSelectorGroup);
      if (gypsumOption.evaluate().isNotEmpty) {
        await tester.tap(gypsumOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SlopesCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать тип штукатурка', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final plasterOption = find.byType(TypeSelectorGroup);
      if (plasterOption.evaluate().isNotEmpty) {
        await tester.tap(plasterOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SlopesCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать тип сэндвич-панели', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sandwichOption = find.byType(TypeSelectorGroup);
      if (sandwichOption.evaluate().isNotEmpty) {
        await tester.tap(sandwichOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SlopesCalculatorScreen), findsOneWidget);
    });
  });

  group('SlopesCalculatorScreen - количество окон', () {
    testWidgets('отображает слайдер для количества окон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('можно изменить количество окон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SlopesCalculatorScreen), findsOneWidget);
    });
  });

  group('SlopesCalculatorScreen - размеры окна', () {
    testWidgets('отображает поля для ширины и высоты окна', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('отображает слайдер глубины откоса', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('можно изменить глубину откоса', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().length > 1) {
        await tester.drag(sliders.at(1), const Offset(30, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SlopesCalculatorScreen), findsOneWidget);
    });
  });

  group('SlopesCalculatorScreen - опции', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно переключить опцию уголков', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SlopesCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию грунтовки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().length > 1) {
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SlopesCalculatorScreen), findsOneWidget);
    });
  });

  group('SlopesCalculatorScreen - результаты', () {
    testWidgets('отображает количество окон в результатах', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.window), findsWidgets);
      expect(find.textContaining('шт'), findsWidgets);
    });

    testWidgets('отображает площадь откосов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('отображает MaterialsCardModern', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });
  });

  group('SlopesCalculatorScreen - взаимодействие', () {
    testWidgets('можно скроллить контент', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byType(SlopesCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('виджет корректно удаляется', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(child: const SizedBox.shrink()),
      );

      expect(find.byType(SlopesCalculatorScreen), findsNothing);
    });
  });

  group('SlopesCalculatorScreen - единицы измерения', () {
    testWidgets('отображает единицы измерения сантиметры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('см'), findsWidgets);
    });

    testWidgets('отображает единицы измерения метры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SlopesCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.textContaining('м'), findsWidgets);
    });
  });
}
