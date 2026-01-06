import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/providers/constants_provider.dart';
import 'package:probrab_ai/presentation/views/calculator/terrace_calculator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

/// Mock constants for testing
final _mockConstantsOverrides = <Override>[
  calculatorConstantsProvider('terrace').overrideWith((ref) async => null),
  calculatorConstantsProvider('common').overrideWith((ref) async => null),
];

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    setupMocks();

    final realDefinition = CalculatorRegistry.getById('terrace');
    if (realDefinition == null) {
      throw StateError('terrace calculator not found in registry');
    }
    testDefinition = realDefinition;
  });

  group('TerraceCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(TerraceCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input fields', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: _mockConstantsOverrides,
        ),
      );

      expect(find.byType(TerraceCalculatorScreen), findsNothing);
    });

    testWidgets('can enter text in TextField', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.tap(textField);
      await tester.pumpAndSettle();
      await tester.enterText(textField, '10');
      await tester.pumpAndSettle();

      expect(find.byType(TerraceCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for selections', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can scroll content', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(TerraceCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TerraceCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 20.0,
            },
          ),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(TerraceCalculatorScreen), findsOneWidget);
    });
  });
}
