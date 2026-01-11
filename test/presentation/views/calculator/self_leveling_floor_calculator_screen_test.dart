import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/self_leveling_floor_calculator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    setupMocks();

    final realDefinition = CalculatorRegistry.getById('floors_self_leveling');
    if (realDefinition == null) {
      throw StateError('floors_self_leveling calculator not found in registry');
    }
    testDefinition = realDefinition;
  });

  group('SelfLevelingFloorCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: SelfLevelingFloorCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pump();

      expect(find.byType(SelfLevelingFloorCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: SelfLevelingFloorCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input sliders', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: SelfLevelingFloorCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: SelfLevelingFloorCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: SelfLevelingFloorCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(SelfLevelingFloorCalculatorScreen), findsNothing);
    });
  });
}
