import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/accent_color_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccentColorNotifier', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with default yellow color', () {
      final color = container.read(accentColorProvider);

      // Default is 0xFFFFC107 (amber/yellow)
      expect(color.toARGB32(), 0xFFFFC107);
    });

    test('setColor updates state immediately', () async {
      const newColor = Color(0xFF4CAF50); // Green
      await container.read(accentColorProvider.notifier).setColor(newColor);

      final color = container.read(accentColorProvider);
      expect(color.toARGB32(), 0xFF4CAF50);
    });

    test('setColor saves to SharedPreferences', () async {
      const newColor = Color(0xFFE91E63); // Pink
      await container.read(accentColorProvider.notifier).setColor(newColor);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('accent_color'), 0xFFE91E63);
    });

    test('handles multiple color changes', () async {
      final colors = [
        const Color(0xFFFFC107), // Amber
        const Color(0xFF2196F3), // Blue
        const Color(0xFF4CAF50), // Green
      ];

      for (final testColor in colors) {
        await container.read(accentColorProvider.notifier).setColor(testColor);
        final currentColor = container.read(accentColorProvider);
        expect(currentColor.toARGB32(), testColor.toARGB32());
      }
    });

    test('blue color option works', () async {
      const blueColor = Color(0xFF2196F3);
      await container.read(accentColorProvider.notifier).setColor(blueColor);

      final color = container.read(accentColorProvider);
      expect(color.toARGB32(), 0xFF2196F3);
    });
  });
}
