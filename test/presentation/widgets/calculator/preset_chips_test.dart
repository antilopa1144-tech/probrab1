import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/preset_chips.dart';

void main() {
  group('Preset', () {
    test('creates with required parameters', () {
      const preset = Preset(
        icon: Icons.bed,
        values: {'length': 4.0, 'width': 3.0},
      );
      expect(preset.icon, Icons.bed);
      expect(preset.values['length'], 4.0);
      expect(preset.values['width'], 3.0);
      expect(preset.label, isNull);
    });

    test('creates with optional label', () {
      const preset = Preset(
        icon: Icons.kitchen,
        values: {'length': 3.0},
        label: 'Kitchen',
      );
      expect(preset.label, 'Kitchen');
    });
  });

  group('PresetChips', () {
    testWidgets('renders nothing when presets is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetChips(
              presets: const [],
              onPresetSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('renders action chips for each preset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetChips(
              presets: const [
                Preset(icon: Icons.bed, values: {'length': 4.0}),
                Preset(icon: Icons.bathroom, values: {'length': 2.0}),
              ],
              onPresetSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ActionChip), findsNWidgets(2));
    });

    testWidgets('displays preset icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetChips(
              presets: const [
                Preset(icon: Icons.bed_outlined, values: {'length': 4.0}),
              ],
              onPresetSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.bed_outlined), findsOneWidget);
    });

    testWidgets('displays preset label when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetChips(
              presets: const [
                Preset(
                  icon: Icons.bed,
                  values: {'length': 4.0},
                  label: 'Bedroom',
                ),
              ],
              onPresetSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Bedroom'), findsOneWidget);
    });

    testWidgets('calls onPresetSelected with values when chip is tapped', (tester) async {
      Map<String, double>? selectedValues;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetChips(
              presets: const [
                Preset(
                  icon: Icons.bed,
                  values: {'length': 4.0, 'width': 3.0},
                ),
              ],
              onPresetSelected: (values) {
                selectedValues = values;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ActionChip));
      await tester.pump();

      expect(selectedValues, {'length': 4.0, 'width': 3.0});
    });

    testWidgets('uses labelBuilder when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetChips(
              presets: const [
                Preset(icon: Icons.bed, values: {'length': 4.0}),
              ],
              onPresetSelected: (_) {},
              labelBuilder: (preset) => 'Custom: ${preset.values['length']}',
            ),
          ),
        ),
      );

      expect(find.text('Custom: 4.0'), findsOneWidget);
    });

    testWidgets('formats dimensions as LxWxH when no label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetChips(
              presets: const [
                Preset(
                  icon: Icons.bed,
                  values: {'length': 4.0, 'width': 3.0, 'height': 2.7},
                ),
              ],
              onPresetSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('4x3x2.7'), findsOneWidget);
    });

    testWidgets('scrolls horizontally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetChips(
              presets: const [
                Preset(icon: Icons.bed, values: {'length': 1.0}),
                Preset(icon: Icons.bathroom, values: {'length': 2.0}),
                Preset(icon: Icons.kitchen, values: {'length': 3.0}),
                Preset(icon: Icons.living, values: {'length': 4.0}),
                Preset(icon: Icons.door_front_door, values: {'length': 5.0}),
              ],
              onPresetSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('formats integer values without decimal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetChips(
              presets: const [
                Preset(
                  icon: Icons.bed,
                  values: {'length': 4.0, 'width': 3.0},
                ),
              ],
              onPresetSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('4x3'), findsOneWidget);
    });
  });

  group('roomPresets', () {
    test('contains expected presets', () {
      expect(roomPresets.length, 5);
      expect(roomPresets.any((p) => p.icon == Icons.bed_outlined), isTrue);
      expect(roomPresets.any((p) => p.icon == Icons.bathroom_outlined), isTrue);
      expect(roomPresets.any((p) => p.icon == Icons.kitchen_outlined), isTrue);
    });
  });

  group('foundationPresets', () {
    test('contains expected presets', () {
      expect(foundationPresets.length, 3);
      expect(foundationPresets.any((p) => p.icon == Icons.home_outlined), isTrue);
      expect(foundationPresets.any((p) => p.icon == Icons.garage_outlined), isTrue);
    });
  });
}
