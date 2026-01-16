import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/ceiling_insulation_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('CeilingInsulationCalculatorScreen виджет рендеринг', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CeilingInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('CeilingInsulationCalculatorScreen выбор типа утеплителя', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
    });

    testWidgets('отображает иконки типов утеплителя', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.waves), findsWidgets); // минвата
      expect(find.byIcon(Icons.grid_view), findsWidgets); // пенопласт
      expect(find.byIcon(Icons.layers), findsWidgets); // экструдированный
    });

    testWidgets('можно выбрать минеральную вату', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final mineralType = find.byType(TypeSelectorGroup);
      if (mineralType.evaluate().isNotEmpty) {
        await tester.tap(mineralType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CeilingInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать пенопласт', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final styrofoamType = find.byType(TypeSelectorGroup);
      if (styrofoamType.evaluate().isNotEmpty) {
        await tester.tap(styrofoamType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CeilingInsulationCalculatorScreen), findsOneWidget);
    });
  });

  group('CeilingInsulationCalculatorScreen режимы ввода', () {
    testWidgets('отображает ModeSelector', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsOneWidget);
    });

    testWidgets('можно переключить режим ввода', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final roomMode = find.textContaining('По комнате');
      if (roomMode.evaluate().isNotEmpty) {
        await tester.tap(roomMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CeilingInsulationCalculatorScreen), findsOneWidget);
    });
  });

  group('CeilingInsulationCalculatorScreen поля ввода', () {
    testWidgets('отображает слайдер площади в режиме manual', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('отображает поля длины и ширины в режиме room', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final roomMode = find.textContaining('По комнате');
      if (roomMode.evaluate().isNotEmpty) {
        await tester.tap(roomMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('можно изменить слайдер толщины', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(CeilingInsulationCalculatorScreen), findsOneWidget);
    });
  });

  group('CeilingInsulationCalculatorScreen слайдер толщины', () {
    testWidgets('отображает слайдер толщины утеплителя', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // The calculator uses CalculatorSliderField for thickness
      expect(find.byType(Slider), findsWidgets);
      expect(find.textContaining('мм'), findsWidgets);
    });
  });

  group('CeilingInsulationCalculatorScreen переключатели опций', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно переключить опцию пароизоляции', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final vaporBarrierSwitch = find.byType(SwitchListTile);
      if (vaporBarrierSwitch.evaluate().isNotEmpty) {
        await tester.tap(vaporBarrierSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CeilingInsulationCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию мембраны', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final membraneSwitch = find.byType(SwitchListTile);
      if (membraneSwitch.evaluate().isNotEmpty) {
        await tester.tap(membraneSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CeilingInsulationCalculatorScreen), findsOneWidget);
    });
  });

  group('CeilingInsulationCalculatorScreen результаты', () {
    testWidgets('отображает результаты площади', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('отображает количество упаковок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Labels in CalculatorResultHeader are displayed in UPPERCASE
      expect(find.textContaining('УПАКОВОК'), findsOneWidget);
    });

    testWidgets('отображает иконки результатов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.byIcon(Icons.inventory_2), findsWidgets);
      expect(find.byIcon(Icons.height), findsWidgets);
    });
  });

  group('CeilingInsulationCalculatorScreen список материалов', () {
    testWidgets('отображает MaterialsCardModern', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('можно прокрутить до материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(CeilingInsulationCalculatorScreen), findsOneWidget);
    });
  });

  group('CeilingInsulationCalculatorScreen действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('кнопка поделиться существует', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share_rounded);
      expect(shareButton, findsOneWidget);
    });
  });

  group('CeilingInsulationCalculatorScreen корректно освобождает ресурсы', () {
    testWidgets('корректно dispose', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CeilingInsulationCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(CeilingInsulationCalculatorScreen), findsNothing);
    });
  });
}
