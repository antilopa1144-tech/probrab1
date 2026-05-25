import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/drainage_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/greenhouse_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/lawn_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/paving_tiles_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/septic_rings_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('Landscape calculator screens smoke tests', () {
    testWidgets('LawnCalculatorScreen рендерится', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const LawnCalculatorScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(LawnCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('DrainageCalculatorScreen рендерится', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const DrainageCalculatorScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(DrainageCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('GreenhouseCalculatorScreen рендерится', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const GreenhouseCalculatorScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GreenhouseCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('PavingTilesCalculatorScreen рендерится', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const PavingTilesCalculatorScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(PavingTilesCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('SepticRingsCalculatorScreen рендерится', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const SepticRingsCalculatorScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SepticRingsCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.byType(SwitchListTile), findsWidgets);
    });
  });

  group('Landscape screens — корректно освобождают ресурсы', () {
    for (final entry in <String, Widget>{
      'lawn': const LawnCalculatorScreen(),
      'drainage': const DrainageCalculatorScreen(),
      'greenhouse': const GreenhouseCalculatorScreen(),
      'paving_tiles': const PavingTilesCalculatorScreen(),
      'septic_rings': const SepticRingsCalculatorScreen(),
    }.entries) {
      testWidgets('${entry.key} dispose без падений', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: entry.value));
        await tester.pump();

        await tester.pumpWidget(createTestApp(child: const SizedBox.shrink()));
        expect(find.byType(entry.value.runtimeType), findsNothing);
      });
    }
  });
}
