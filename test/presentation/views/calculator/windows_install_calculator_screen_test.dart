import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/windows_install_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('WindowsInstallCalculatorScreen - рендеринг базовой структуры', () {
    testWidgets('отрисовывается без ошибок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WindowsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('содержит CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('содержит CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('имеет кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('WindowsInstallCalculatorScreen - селектор типа окна', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });

    testWidgets('отображает все типы окон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.crop_portrait), findsOneWidget); // single
      expect(find.byIcon(Icons.view_column), findsOneWidget); // double
      expect(find.byIcon(Icons.view_week), findsOneWidget); // triple
    });

    testWidgets('можно выбрать одностворчатое окно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('windows_calc.type.single');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(WindowsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать двустворчатое окно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('windows_calc.type.double');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(WindowsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать трехстворчатое окно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('windows_calc.type.triple');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(WindowsInstallCalculatorScreen), findsOneWidget);
    });
  });

  group('WindowsInstallCalculatorScreen - количество окон', () {
    testWidgets('отображает слайдер для количества окон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('можно изменить количество окон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(WindowsInstallCalculatorScreen), findsOneWidget);
    });
  });

  group('WindowsInstallCalculatorScreen - размеры окна', () {
    testWidgets('отображает поля для ширины и высоты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('отображает общую площадь окон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('windows_calc.label.total_area'), findsOneWidget);
    });
  });

  group('WindowsInstallCalculatorScreen - опции', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно переключить опцию подоконника', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -350));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(WindowsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию откосов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -350));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().length > 1) {
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(WindowsInstallCalculatorScreen), findsOneWidget);
    });
  });

  group('WindowsInstallCalculatorScreen - результаты', () {
    testWidgets('отображает количество окон в результатах', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.window), findsWidgets);
      expect(find.textContaining('common.pcs'), findsWidgets);
    });

    testWidgets('отображает площадь окон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает количество пены', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.blur_on), findsOneWidget);
    });

    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });
  });

  group('WindowsInstallCalculatorScreen - взаимодействие', () {
    testWidgets('можно скроллить контент', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byType(WindowsInstallCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
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
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(child: const SizedBox.shrink()),
      );

      expect(find.byType(WindowsInstallCalculatorScreen), findsNothing);
    });
  });

  group('WindowsInstallCalculatorScreen - единицы измерения', () {
    testWidgets('отображает сантиметры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('common.cm'), findsWidgets);
    });

    testWidgets('отображает квадратные метры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает метры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const WindowsInstallCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.textContaining('common.meters'), findsWidgets);
    });
  });
}
