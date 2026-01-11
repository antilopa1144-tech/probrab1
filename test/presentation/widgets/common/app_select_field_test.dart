import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/app_select_field.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('SelectOption', () {
    test('creates with required parameters', () {
      const option = SelectOption(value: 1, label: 'Option 1');
      expect(option.value, 1);
      expect(option.label, 'Option 1');
      expect(option.enabled, isTrue);
      expect(option.leading, isNull);
    });

    test('creates with all parameters', () {
      const leading = Icon(Icons.star);
      const option = SelectOption(
        value: 'test',
        label: 'Test Option',
        leading: leading,
        enabled: false,
      );
      expect(option.value, 'test');
      expect(option.label, 'Test Option');
      expect(option.enabled, isFalse);
      expect(option.leading, leading);
    });
  });

  group('AppSelectField', () {
    testWidgets('renders dropdown', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppSelectField<int>(
                options: const [
                  SelectOption(value: 1, label: 'One'),
                  SelectOption(value: 2, label: 'Two'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });

    testWidgets('renders with label', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppSelectField<String>(
                label: 'Select Category',
                options: const [
                  SelectOption(value: 'a', label: 'A'),
                  SelectOption(value: 'b', label: 'B'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Select Category'), findsOneWidget);
    });

    testWidgets('renders with hint', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppSelectField<int>(
                hint: 'Choose an option',
                options: const [
                  SelectOption(value: 1, label: 'Option 1'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Choose an option'), findsOneWidget);
    });

    testWidgets('shows selected value', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppSelectField<int>(
                value: 2,
                options: const [
                  SelectOption(value: 1, label: 'First'),
                  SelectOption(value: 2, label: 'Second'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('calls onChanged when option is selected', (tester) async {
      setTestViewportSize(tester);
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppSelectField<int>(
                options: const [
                  SelectOption(value: 1, label: 'One'),
                  SelectOption(value: 2, label: 'Two'),
                ],
                onChanged: (value) {
                  selectedValue = value;
                },
              ),
            ),
          ),
        ),
      );

      // Tap dropdown to open
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Select second option
      await tester.tap(find.text('Two').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 2);
    });

    testWidgets('disables dropdown when enabled is false', (tester) async {
      setTestViewportSize(tester);
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppSelectField<int>(
                enabled: false,
                options: const [
                  SelectOption(value: 1, label: 'One'),
                ],
                onChanged: (value) {
                  selectedValue = value;
                },
              ),
            ),
          ),
        ),
      );

      // Try to tap dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Should not open and onChanged should not be called
      expect(selectedValue, isNull);
    });

    testWidgets('renders options with leading widget', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppSelectField<int>(
                value: 1,
                options: const [
                  SelectOption(value: 1, label: 'Star', leading: Icon(Icons.star)),
                  SelectOption(value: 2, label: 'Heart', leading: Icon(Icons.favorite)),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsWidgets);
      expect(find.byIcon(Icons.favorite), findsWidgets);
    });

    testWidgets('handles string type options', (tester) async {
      setTestViewportSize(tester);
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppSelectField<String>(
                options: const [
                  SelectOption(value: 'red', label: 'Red'),
                  SelectOption(value: 'blue', label: 'Blue'),
                ],
                onChanged: (value) {
                  selectedValue = value;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Blue').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'blue');
    });

    testWidgets('renders multiple options', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppSelectField<int>(
                options: const [
                  SelectOption(value: 1, label: 'Option 1'),
                  SelectOption(value: 2, label: 'Option 2'),
                  SelectOption(value: 3, label: 'Option 3'),
                  SelectOption(value: 4, label: 'Option 4'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      expect(find.text('Option 1'), findsWidgets);
      expect(find.text('Option 2'), findsWidgets);
      expect(find.text('Option 3'), findsWidgets);
      expect(find.text('Option 4'), findsWidgets);
    });
  });
}
