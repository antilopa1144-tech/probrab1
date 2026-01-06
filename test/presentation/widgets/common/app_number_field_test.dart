import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/app_number_field.dart';

void main() {
  group('AppNumberField', () {
    testWidgets('renders with value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: 10,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: 5,
              label: 'Quantity',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Quantity'), findsOneWidget);
    });

    testWidgets('shows required asterisk when required is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: 1,
              label: 'Required Field',
              required: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('renders with unit suffix', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: 100,
              unit: 'м²',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AppNumberField), findsOneWidget);
    });

    testWidgets('renders increment and decrement buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: 10,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('increment button increases value', (tester) async {
      double currentValue = 10;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppNumberField(
                  value: currentValue,
                  onChanged: (value) {
                    setState(() {
                      currentValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(currentValue, 11);
    });

    testWidgets('decrement button decreases value', (tester) async {
      double currentValue = 10;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppNumberField(
                  value: currentValue,
                  onChanged: (value) {
                    setState(() {
                      currentValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(currentValue, 9);
    });

    testWidgets('respects step value', (tester) async {
      double currentValue = 10;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppNumberField(
                  value: currentValue,
                  step: 5,
                  onChanged: (value) {
                    setState(() {
                      currentValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(currentValue, 15);
    });

    testWidgets('clamps value to min', (tester) async {
      double currentValue = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppNumberField(
                  value: currentValue,
                  min: 0,
                  onChanged: (value) {
                    setState(() {
                      currentValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(currentValue, 0);
    });

    testWidgets('clamps value to max', (tester) async {
      double currentValue = 100;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppNumberField(
                  value: currentValue,
                  max: 100,
                  onChanged: (value) {
                    setState(() {
                      currentValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(currentValue, 100);
    });

    testWidgets('shows min and max labels when specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: 50,
              min: 0,
              max: 100,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('shows helper text instead of min/max', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: 50,
              helperText: 'Enter a value',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Enter a value'), findsOneWidget);
    });

    testWidgets('disables buttons when enabled is false', (tester) async {
      double currentValue = 10;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: currentValue,
              enabled: false,
              onChanged: (value) {
                currentValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Value should not change
      expect(currentValue, 10);
    });

    testWidgets('formats decimal values correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: 10.5,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('10.5'), findsOneWidget);
    });

    testWidgets('formats integer values without decimal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              value: 10.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
    });
  });
}
