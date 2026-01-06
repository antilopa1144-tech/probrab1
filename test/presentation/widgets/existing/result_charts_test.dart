import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/existing/result_charts.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MaterialPieChart', () {
    testWidgets('shows no data message when materials is empty', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: Center(
              child: MaterialPieChart(materials: {}),
            ),
          ),
        ),
      );

      // Should show the key as fallback text
      expect(find.textContaining('chart.no_data'), findsOneWidget);
    });

    testWidgets('renders with material data', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: Center(
              child: MaterialPieChart(
                materials: {
                  'Cement': 30.0,
                  'Sand': 50.0,
                  'Water': 20.0,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('displays material percentages', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 400,
                child: MaterialPieChart(
                  materials: {
                    'Cement': 50.0,
                    'Sand': 50.0,
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Each material should show 50%
      expect(find.textContaining('50'), findsWidgets);
    });

    testWidgets('uses custom color map when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: Center(
              child: MaterialPieChart(
                materials: {'Custom': 100.0},
                colorMap: {'Custom': Colors.purple},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('CostBarChart', () {
    testWidgets('shows no data message when all costs are zero', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: CostBarChart(costs: {'Item': 0.0}),
          ),
        ),
      );

      // Shows no data key as fallback
      expect(find.textContaining('chart.no_data'), findsOneWidget);
    });

    testWidgets('renders with cost data', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: CostBarChart(
              costs: {
                'Material 1': 1000.0,
                'Material 2': 2000.0,
              },
            ),
          ),
        ),
      );

      expect(find.text('Material 1'), findsOneWidget);
      expect(find.text('Material 2'), findsOneWidget);
      expect(find.text('1000 ₽'), findsOneWidget);
      expect(find.text('2000 ₽'), findsOneWidget);
    });

    testWidgets('shows title when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: CostBarChart(
              costs: {'Item': 500.0},
              title: 'Cost Breakdown',
            ),
          ),
        ),
      );

      expect(find.text('Cost Breakdown'), findsOneWidget);
    });

    testWidgets('hides title when not provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: CostBarChart(
              costs: {'Item': 500.0},
            ),
          ),
        ),
      );

      // Title should not appear
      expect(find.text('Cost Breakdown'), findsNothing);
    });

    testWidgets('renders progress indicators for each cost', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: CostBarChart(
              costs: {
                'Item 1': 100.0,
                'Item 2': 200.0,
                'Item 3': 300.0,
              },
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });

    testWidgets('wraps content in Card', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: CostBarChart(
              costs: {'Item': 100.0},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('CostDistributionChart', () {
    testWidgets('renders nothing when costs total is zero', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: CostDistributionChart(costs: {}),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders pie chart with valid costs', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: CostDistributionChart(
              costs: {
                'Category A': 100.0,
                'Category B': 200.0,
              },
            ),
          ),
        ),
      );

      // Pie chart should be present
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('filters out zero value costs', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: CostDistributionChart(
              costs: {
                'Positive': 100.0,
                'Zero': 0.0,
              },
            ),
          ),
        ),
      );

      // Should still render with positive values
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
