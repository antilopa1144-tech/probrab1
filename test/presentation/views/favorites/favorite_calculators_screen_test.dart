import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/favorites/favorite_calculators_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('FavoriteCalculatorsScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows empty state when no favorites', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_calculators': <String>[],
      });

      await tester.pumpWidget(
        createTestApp(child: const FavoriteCalculatorsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Добавьте калькуляторы в избранное, чтобы быстро открывать их здесь.'),
        findsOneWidget,
      );
    });

    testWidgets('shows app bar with title', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const FavoriteCalculatorsScreen()),
      );
      await tester.pump();

      expect(find.text('Избранное'), findsOneWidget);
    });

    testWidgets('shows all calculators button in app bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const FavoriteCalculatorsScreen()),
      );
      await tester.pump();

      expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
      expect(find.byTooltip('Все калькуляторы'), findsOneWidget);
    });

    testWidgets('shows favorite calculator when present', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_calculators': ['wall_paint'],
      });

      await tester.pumpWidget(
        createTestApp(child: const FavoriteCalculatorsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Should show the calculator card
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows unavailable calculator card for unknown id', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_calculators': ['unknown_calculator_123'],
      });

      await tester.pumpWidget(
        createTestApp(child: const FavoriteCalculatorsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Калькулятор недоступен'), findsOneWidget);
      expect(find.text('unknown_calculator_123'), findsOneWidget);
    });

    testWidgets('shows delete button for unavailable calculator', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_calculators': ['unknown_calculator_xyz'],
      });

      await tester.pumpWidget(
        createTestApp(child: const FavoriteCalculatorsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byTooltip('Удалить из избранного'), findsOneWidget);
    });

    testWidgets('shows star icon for favorite calculators', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_calculators': ['wall_paint'],
      });

      await tester.pumpWidget(
        createTestApp(child: const FavoriteCalculatorsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });

    testWidgets('can remove favorite by tapping delete', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_calculators': ['unknown_calc_id'],
      });

      await tester.pumpWidget(
        createTestApp(child: const FavoriteCalculatorsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Verify unavailable card is shown
      expect(find.text('Калькулятор недоступен'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pump(const Duration(milliseconds: 200));

      // Should show empty state now
      expect(
        find.text('Добавьте калькуляторы в избранное, чтобы быстро открывать их здесь.'),
        findsOneWidget,
      );
    });

    testWidgets('displays multiple favorites in list', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_calculators': ['wall_paint', 'tile_adhesive', 'gypsum'],
      });

      await tester.pumpWidget(
        createTestApp(child: const FavoriteCalculatorsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
