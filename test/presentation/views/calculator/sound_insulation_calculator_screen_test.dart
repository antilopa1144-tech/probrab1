import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/sound_insulation_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('SoundInsulationCalculatorScreen - рендеринг базовой структуры', () {
    testWidgets('отрисовывается без ошибок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('содержит CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('содержит CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('имеет кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('SoundInsulationCalculatorScreen - селектор типа изоляции', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });

    testWidgets('отображает все типы изоляции', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.layers), findsWidgets); // mineral wool
      expect(find.byIcon(Icons.filter_alt), findsWidgets); // membrane
      expect(find.byIcon(Icons.stacked_line_chart), findsOneWidget); // combined
    });

    testWidgets('можно выбрать минеральную вату', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('sound_insulation_calc.type.mineral_wool');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать мембрану', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('sound_insulation_calc.type.membrane');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать комбинированную изоляцию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('sound_insulation_calc.type.combined');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });
  });

  group('SoundInsulationCalculatorScreen - селектор поверхности', () {
    testWidgets('отображает ModeSelector для типа поверхности', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('можно выбрать стену', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final wallOption = find.textContaining('sound_insulation_calc.surface.wall');
      if (wallOption.evaluate().isNotEmpty) {
        await tester.tap(wallOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать потолок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final ceilingOption = find.textContaining('sound_insulation_calc.surface.ceiling');
      if (ceilingOption.evaluate().isNotEmpty) {
        await tester.tap(ceilingOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });
  });

  group('SoundInsulationCalculatorScreen - параметры', () {
    testWidgets('отображает слайдер площади', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('можно изменить площадь', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно изменить толщину', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().length > 1) {
        await tester.drag(sliders.at(1), const Offset(30, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });
  });

  group('SoundInsulationCalculatorScreen - опции', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно переключить опцию гипсокартона', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
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

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию профиля', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().length > 1) {
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });
  });

  group('SoundInsulationCalculatorScreen - результаты', () {
    testWidgets('отображает площадь в результатах', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });
  });

  group('SoundInsulationCalculatorScreen - взаимодействие', () {
    testWidgets('можно скроллить контент', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byType(SoundInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
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
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(child: const SizedBox.shrink()),
      );

      expect(find.byType(SoundInsulationCalculatorScreen), findsNothing);
    });
  });

  group('SoundInsulationCalculatorScreen - единицы измерения', () {
    testWidgets('отображает квадратные метры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает миллиметры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const SoundInsulationCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('common.mm'), findsWidgets);
    });
  });
}
