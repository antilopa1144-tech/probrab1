import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/app_slider_field.dart';

void main() {
  group('AppSliderField', () {
    testWidgets('renders slider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              value: 50,
              min: 0,
              max: 100,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              label: 'Volume',
              value: 50,
              min: 0,
              max: 100,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Volume'), findsOneWidget);
    });

    testWidgets('shows current value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              label: 'Level',
              value: 75,
              min: 0,
              max: 100,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('shows value with unit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              label: 'Distance',
              value: 50,
              min: 0,
              max: 100,
              unit: 'км',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('50 км'), findsOneWidget);
    });

    testWidgets('shows min value label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              value: 50,
              min: 10,
              max: 100,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows max value label with unit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              value: 50,
              min: 0,
              max: 100,
              unit: 'м',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('100 м'), findsOneWidget);
    });

    testWidgets('calls onChanged when slider is moved', (tester) async {
      double changedValue = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              value: 50,
              min: 0,
              max: 100,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      // Drag slider to the right
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();

      expect(changedValue, isNot(50));
    });

    testWidgets('respects divisions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              value: 50,
              min: 0,
              max: 100,
              divisions: 10,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 10);
    });

    testWidgets('clamps value within range', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              value: 150, // Over max
              min: 0,
              max: 100,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 100);
    });

    testWidgets('calls onChangeEnd when provided', (tester) async {
      double endValue = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              value: 50,
              min: 0,
              max: 100,
              onChanged: (_) {},
              onChangeEnd: (value) {
                endValue = value;
              },
            ),
          ),
        ),
      );

      // Find the slider center
      final slider = find.byType(Slider);
      final center = tester.getCenter(slider);

      // Drag to new position
      await tester.dragFrom(center, const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(endValue, isNot(0));
    });

    testWidgets('formats integer values without decimal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              label: 'Count',
              value: 10.0,
              min: 0,
              max: 100,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('formats decimal values with one decimal place', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              label: 'Value',
              value: 10.5,
              min: 0,
              max: 100,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('10.5'), findsOneWidget);
    });

    testWidgets('renders without label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              value: 50,
              min: 0,
              max: 100,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('uses correct slider properties', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSliderField(
              value: 30,
              min: 10,
              max: 90,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 30);
      expect(slider.min, 10);
      expect(slider.max, 90);
    });
  });
}
