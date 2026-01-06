import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/providers/constants_provider.dart';
import 'package:probrab_ai/presentation/views/osb/osb_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';
import 'package:probrab_ai/presentation/widgets/existing/hint_card.dart';

import '../../../helpers/test_helpers.dart';

final _mockConstantsOverrides = <Override>[
  calculatorConstantsProvider('sheeting_osb_plywood').overrideWith((ref) async => null),
  calculatorConstantsProvider('common').overrideWith((ref) async => null),
];

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();

    final realDefinition = CalculatorRegistry.getById('sheeting_osb_plywood');
    if (realDefinition == null) {
      throw StateError('sheeting_osb_plywood calculator not found in registry');
    }
    testDefinition = realDefinition;
  });

  group('OsbCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input sliders', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('uses Cards for sections', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
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
          child: OsbCalculatorScreen(definition: testDefinition),
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

      expect(find.byType(OsbCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for type selection', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can tap type selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can scroll content', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
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
          child: OsbCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 50.0,
            },
          ),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('accepts initial thickness input', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 30.0,
              'thickness': 18.0,
            },
          ),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Construction Types', () {
    testWidgets('shows wall construction type selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Стены'), findsOneWidget);
    });

    testWidgets('shows floor construction type selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Пол'), findsOneWidget);
    });

    testWidgets('shows roof construction type selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Крыша'), findsOneWidget);
    });

    testWidgets('shows partition construction type selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Перегородка'), findsOneWidget);
    });

    testWidgets('shows SIP construction type selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('СИП'), findsOneWidget);
    });

    testWidgets('shows formwork construction type selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Опалубка'), findsOneWidget);
    });

    testWidgets('can select floor construction type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Пол'));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select roof construction type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Крыша'));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select partition construction type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Перегородка'));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select SIP construction type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('СИП'));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select formwork construction type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Опалубка'));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Sheet Size Selector', () {
    testWidgets('shows sheet size selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Размер листа'), findsOneWidget);
    });

    testWidgets('shows ModeSelectorVertical', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectorVertical), findsOneWidget);
    });

    testWidgets('shows 2500x1250 sheet size option', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('2500×1250'), findsWidgets);
    });

    testWidgets('can select different sheet size', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('2800×1250');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Thickness Selector', () {
    testWidgets('shows thickness selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Толщина ОСБ'), findsOneWidget);
    });

    testWidgets('shows ModeSelector for thickness', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('can select 9mm thickness', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('9 мм'));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select 18mm thickness', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('18 мм'));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select 22mm thickness', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('22 мм'));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Input Mode', () {
    testWidgets('shows input mode selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Режим ввода'), findsOneWidget);
    });

    testWidgets('shows by area mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('По площади'), findsOneWidget);
    });

    testWidgets('shows by dimensions mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('По размерам'), findsOneWidget);
    });

    testWidgets('can switch to dimensions mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('По размерам'));
      await tester.pumpAndSettle();

      // Should show dimensions fields
      expect(find.text('Размеры помещения'), findsOneWidget);
    });

    testWidgets('shows length slider in dimensions mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('По размерам'));
      await tester.pumpAndSettle();

      expect(find.text('Длина'), findsOneWidget);
    });

    testWidgets('shows width slider in dimensions mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('По размерам'));
      await tester.pumpAndSettle();

      expect(find.text('Ширина'), findsOneWidget);
    });

    testWidgets('shows calculated area in dimensions mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('По размерам'));
      await tester.pumpAndSettle();

      expect(find.text('Расчётная площадь'), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Area Slider', () {
    testWidgets('shows area slider in area mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Площадь'), findsOneWidget);
    });

    testWidgets('can drag area slider', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Find slider and drag it
      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(100, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Reserve Slider', () {
    testWidgets('shows reserve slider', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Запас материала'), findsOneWidget);
    });

    testWidgets('shows reserve limits', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 %'), findsOneWidget);
      expect(find.text('20 %'), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Materials', () {
    testWidgets('shows main materials card', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Основные материалы'), findsOneWidget);
    });

    testWidgets('shows OSB plates in materials', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ОСБ плиты'), findsOneWidget);
    });

    testWidgets('shows MaterialsCardModern', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsWidgets);
    });
  });

  group('OsbCalculatorScreen Additional Materials', () {
    testWidgets('shows additional materials for wall type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Wall type is default, should show additional materials
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Дополнительные материалы'), findsOneWidget);
    });

    testWidgets('shows wind barrier for wall type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Ветрозащита'), findsOneWidget);
    });

    testWidgets('shows vapor barrier for wall type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Пароизоляция'), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Tips', () {
    testWidgets('shows tips section', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(HintsList), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Actions', () {
    testWidgets('shows copy button', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows share button', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('can tap copy button', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      // Should show snackbar
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Result Header', () {
    testWidgets('shows CalculatorResultHeader', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('shows area result', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ПЛОЩАДЬ'), findsOneWidget);
    });

    testWidgets('shows sheets result', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ЛИСТОВ'), findsOneWidget);
    });

    testWidgets('shows screws result', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('САМОРЕЗОВ'), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Floor Type', () {
    testWidgets('floor type shows recommended thickness', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Пол'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Рекомендуемая толщина'), findsOneWidget);
    });

    testWidgets('floor type shows underlay material', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Пол'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Подложка'), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen SIP Type', () {
    testWidgets('SIP type shows glue material', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('СИП'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Клей для СИП'), findsOneWidget);
    });

    testWidgets('SIP type shows foam material', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('СИП'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Монтажная пена'), findsOneWidget);
    });

    testWidgets('SIP type shows insulation', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('СИП'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Утеплитель'), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Roof Type', () {
    testWidgets('roof type shows roofing underlay', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Крыша'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Кровельная подложка'), findsOneWidget);
    });

    testWidgets('roof type shows counter battens', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Крыша'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Контррейка'), findsOneWidget);
    });

    testWidgets('roof type shows clips', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Крыша'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Кляймеры'), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Partition Type', () {
    testWidgets('partition type shows studs', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Перегородка'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Брус для стоек'), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Formwork Type', () {
    testWidgets('formwork type shows battens', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Опалубка'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Рейки'), findsOneWidget);
    });
  });
}
