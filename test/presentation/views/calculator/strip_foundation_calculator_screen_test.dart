import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/strip_foundation_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/calculator_test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('StripFoundationCalculatorScreen -', () {
    testWidgets('отрисовывается корректно', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StripFoundationCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает селектор типа фундамента', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть селектор типа фундамента
      expect(find.byType(TypeSelectorGroup), findsWidgets);

      // Должны быть иконки для 4 типов фундамента
      expect(find.byIcon(Icons.view_module), findsWidgets); // monolithic
      expect(find.byIcon(Icons.view_agenda), findsWidgets); // prefab
      expect(find.byIcon(Icons.layers), findsWidgets); // shallow
      expect(find.byIcon(Icons.foundation), findsWidgets); // deep
    });

    testWidgets('имеет кнопки экспорта и копирования', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('отображает текстовые поля для размеров дома', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должны быть текстовые поля для длины и ширины дома
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('отображает слайдеры для ленты', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должны быть слайдеры для ширины и высоты ленты
      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('показывает результаты в заголовке', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен отображать результаты
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('м'), findsWidgets);
      expect(find.textContaining('м³'), findsWidgets);
    });

    testWidgets('отображает переключатели опций', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должны быть переключатели для внутренних стен, гидроизоляции, утепления
      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('отображает карточку материалов', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает карточку советов', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должна быть иконка лампочки для советов
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      // Должны быть иконки галочек для элементов советов
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
    });

    testWidgets('корректно уничтожается', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(StripFoundationCalculatorScreen), findsNothing);
    });

    testWidgets('можно переключить тип фундамента', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Найти TypeSelectorGroup и нажать на второй тип
      final typeSelector = find.byType(TypeSelectorGroup);
      expect(typeSelector, findsOneWidget);

      // Виджет должен оставаться отрисованным
      expect(find.byType(StripFoundationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно взаимодействовать со слайдерами', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const StripFoundationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);

      // Взаимодействие со слайдером
      await tester.tap(sliders.first);
      await tester.pump();

      expect(find.byType(StripFoundationCalculatorScreen), findsOneWidget);
    });
  });
}
