import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/measurement_diagram.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('DiagramType', () {
    test('has all expected values', () {
      expect(DiagramType.values.length, 4);
      expect(DiagramType.values, contains(DiagramType.room));
      expect(DiagramType.values, contains(DiagramType.wall));
      expect(DiagramType.values, contains(DiagramType.floor));
      expect(DiagramType.values, contains(DiagramType.roof));
    });

    test('has correct indices', () {
      expect(DiagramType.room.index, 0);
      expect(DiagramType.wall.index, 1);
      expect(DiagramType.floor.index, 2);
      expect(DiagramType.roof.index, 3);
    });
  });

  group('MeasurementDiagram', () {
    testWidgets('renders room diagram', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.room,
              values: {'length': 4.0, 'width': 3.0, 'height': 2.7},
            ),
          ),
        ),
      );

      expect(find.byType(MeasurementDiagram), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders wall diagram', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.wall,
              values: {'width': 5.0, 'height': 2.5},
            ),
          ),
        ),
      );

      expect(find.byType(MeasurementDiagram), findsOneWidget);
    });

    testWidgets('renders floor diagram', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.floor,
              values: {'length': 6.0, 'width': 4.0},
            ),
          ),
        ),
      );

      expect(find.byType(MeasurementDiagram), findsOneWidget);
    });

    testWidgets('renders roof diagram', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.roof,
              values: {'span': 8.0, 'rise': 2.5},
            ),
          ),
        ),
      );

      expect(find.byType(MeasurementDiagram), findsOneWidget);
    });

    testWidgets('uses default values when not provided', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.room,
              values: {},
            ),
          ),
        ),
      );

      expect(find.byType(MeasurementDiagram), findsOneWidget);
    });

    testWidgets('applies custom height', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.room,
              values: {'length': 4.0, 'width': 3.0},
              height: 250,
            ),
          ),
        ),
      );

      final diagram = tester.widget<MeasurementDiagram>(
        find.byType(MeasurementDiagram),
      );
      expect(diagram.height, 250);
    });

    testWidgets('uses default height of 180', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.room,
              values: {'length': 4.0},
            ),
          ),
        ),
      );

      final diagram = tester.widget<MeasurementDiagram>(
        find.byType(MeasurementDiagram),
      );
      expect(diagram.height, 180);
    });

    testWidgets('accepts highlights parameter', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.room,
              values: {'length': 4.0, 'width': 3.0},
              highlights: {'length'},
            ),
          ),
        ),
      );

      final diagram = tester.widget<MeasurementDiagram>(
        find.byType(MeasurementDiagram),
      );
      expect(diagram.highlights, contains('length'));
    });

    testWidgets('accepts labelFormatter parameter', (tester) async {
      setTestViewportSize(tester);
      String formatter(String key, double value) => '$key: ${value.toStringAsFixed(2)} m';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.room,
              values: const {'length': 4.0, 'width': 3.0},
              labelFormatter: formatter,
            ),
          ),
        ),
      );

      final diagram = tester.widget<MeasurementDiagram>(
        find.byType(MeasurementDiagram),
      );
      expect(diagram.labelFormatter, isNotNull);
    });

    testWidgets('wall diagram accepts length as width fallback', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.wall,
              values: {'length': 5.0, 'height': 2.5},
            ),
          ),
        ),
      );

      expect(find.byType(MeasurementDiagram), findsOneWidget);
    });

    testWidgets('roof diagram accepts width as span fallback', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.roof,
              values: {'width': 8.0, 'height': 2.5},
            ),
          ),
        ),
      );

      expect(find.byType(MeasurementDiagram), findsOneWidget);
    });

    testWidgets('applies theme colors', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.floor,
              values: {'length': 5.0, 'width': 4.0},
            ),
          ),
        ),
      );

      expect(find.byType(MeasurementDiagram), findsOneWidget);
    });

    testWidgets('stores values correctly', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.room,
              values: {'length': 4.0, 'width': 3.0, 'height': 2.7},
            ),
          ),
        ),
      );

      final diagram = tester.widget<MeasurementDiagram>(
        find.byType(MeasurementDiagram),
      );
      expect(diagram.values['length'], 4.0);
      expect(diagram.values['width'], 3.0);
      expect(diagram.values['height'], 2.7);
    });

    testWidgets('stores type correctly', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeasurementDiagram(
              type: DiagramType.floor,
              values: {'length': 4.0},
            ),
          ),
        ),
      );

      final diagram = tester.widget<MeasurementDiagram>(
        find.byType(MeasurementDiagram),
      );
      expect(diagram.type, DiagramType.floor);
    });
  });
}
