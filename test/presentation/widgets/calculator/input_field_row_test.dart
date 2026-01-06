import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/input_field_row.dart';

void main() {
  group('InputFieldRow', () {
    testWidgets('renders label and field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputFieldRow(
              label: 'Area',
              field: TextField(),
            ),
          ),
        ),
      );

      expect(find.text('Area'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows required asterisk when required is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputFieldRow(
              label: 'Name',
              field: TextField(),
              required: true,
            ),
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('does not show asterisk when required is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputFieldRow(
              label: 'Optional',
              field: TextField(),
              required: false,
            ),
          ),
        ),
      );

      expect(find.text('Optional'), findsOneWidget);
      expect(find.text('*'), findsNothing);
    });

    testWidgets('shows helper text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputFieldRow(
              label: 'Width',
              field: TextField(),
              helperText: 'Enter width in meters',
            ),
          ),
        ),
      );

      expect(find.text('Width'), findsOneWidget);
      expect(find.text('Enter width in meters'), findsOneWidget);
    });

    testWidgets('does not show helper text when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputFieldRow(
              label: 'Height',
              field: TextField(),
            ),
          ),
        ),
      );

      expect(find.text('Height'), findsOneWidget);
      // Should only have label and asterisk is not shown
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders all elements together', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputFieldRow(
              label: 'Full Field',
              field: TextField(),
              helperText: 'Helper text here',
              required: true,
            ),
          ),
        ),
      );

      expect(find.text('Full Field'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.text('Helper text here'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('uses Column as root widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputFieldRow(
              label: 'Test',
              field: SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('accepts custom field widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputFieldRow(
              label: 'Slider Field',
              field: Slider(
                value: 50,
                min: 0,
                max: 100,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Slider Field'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('applies theme styles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: InputFieldRow(
              label: 'Dark Theme',
              field: TextField(),
              helperText: 'Helper in dark mode',
            ),
          ),
        ),
      );

      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.text('Helper in dark mode'), findsOneWidget);
    });

    testWidgets('required defaults to false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputFieldRow(
              label: 'Default',
              field: TextField(),
            ),
          ),
        ),
      );

      // No asterisk should be shown
      expect(find.text('*'), findsNothing);
    });
  });
}
