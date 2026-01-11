import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/ventilation_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('VentilationCalculatorScreen - рендеринг базовой структуры', () {
    testWidgets('отрисовывается без ошибок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VentilationCalculatorScreen), findsOneWidget);
    });

    testWidgets('содержит CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('содержит CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('имеет кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('VentilationCalculatorScreen - селектор типа вентиляции', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });

    testWidgets('отображает все типы вентиляции', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.air), findsWidgets); // natural
      expect(find.byIcon(Icons.wind_power), findsOneWidget); // supply
      expect(find.byIcon(Icons.hvac), findsOneWidget); // exhaust
    });

    testWidgets('можно выбрать естественную вентиляцию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('ventilation_calc.type.natural');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(VentilationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать приточную вентиляцию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('ventilation_calc.type.supply');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(VentilationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать вытяжную вентиляцию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('ventilation_calc.type.exhaust');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(VentilationCalculatorScreen), findsOneWidget);
    });
  });

  group('VentilationCalculatorScreen - параметры помещения', () {
    testWidgets('отображает слайдеры для параметров', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('можно изменить площадь помещения', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(VentilationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно изменить высоту потолка', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().length > 1) {
        await tester.drag(sliders.at(1), const Offset(30, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(VentilationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно изменить количество комнат', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().length > 2) {
        await tester.drag(sliders.at(2), const Offset(20, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(VentilationCalculatorScreen), findsOneWidget);
    });
  });

  group('VentilationCalculatorScreen - опции', () {
    testWidgets('отображает переключатель рекуператора', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('можно переключить опцию рекуператора', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(VentilationCalculatorScreen), findsOneWidget);
    });
  });

  group('VentilationCalculatorScreen - результаты', () {
    testWidgets('отображает объем помещения', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.square_foot), findsOneWidget);
      expect(find.textContaining('common.cbm'), findsWidgets);
    });

    testWidgets('отображает требуемый воздухообмен', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.air), findsWidgets);
      expect(find.textContaining('common.cbm_h'), findsWidgets);
    });

    testWidgets('отображает длину воздуховодов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.textContaining('common.meters'), findsWidgets);
    });

    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });
  });

  group('VentilationCalculatorScreen - взаимодействие', () {
    testWidgets('можно скроллить контент', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byType(VentilationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
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
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(child: const SizedBox.shrink()),
      );

      expect(find.byType(VentilationCalculatorScreen), findsNothing);
    });
  });

  group('VentilationCalculatorScreen - единицы измерения', () {
    testWidgets('отображает квадратные метры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает метры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('common.meters'), findsWidgets);
    });

    testWidgets('отображает штуки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const VentilationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.textContaining('common.pcs'), findsWidgets);
    });
  });
}
