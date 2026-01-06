import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/smart_project_provider.dart';

void main() {
  group('SmartProjectNotifier', () {
    test('starts with default state', () {
      final notifier = SmartProjectNotifier();
      expect(notifier.state.foundation, false);
      expect(notifier.state.walls, false);
      expect(notifier.state.roof, false);
      expect(notifier.state.finish, false);
      expect(notifier.state.results, isEmpty);
    });

    test('toggleFoundation updates foundation state', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFoundation(true);
      expect(notifier.state.foundation, true);

      notifier.toggleFoundation(false);
      expect(notifier.state.foundation, false);
    });

    test('toggleWalls updates walls state', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleWalls(true);
      expect(notifier.state.walls, true);

      notifier.toggleWalls(false);
      expect(notifier.state.walls, false);
    });

    test('toggleRoof updates roof state', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleRoof(true);
      expect(notifier.state.roof, true);

      notifier.toggleRoof(false);
      expect(notifier.state.roof, false);
    });

    test('toggleFinish updates finish state', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFinish(true);
      expect(notifier.state.finish, true);

      notifier.toggleFinish(false);
      expect(notifier.state.finish, false);
    });

    test('toggles do not affect other flags', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFoundation(true);
      notifier.toggleWalls(true);

      expect(notifier.state.foundation, true);
      expect(notifier.state.walls, true);
      expect(notifier.state.roof, false);
      expect(notifier.state.finish, false);
    });

    test('calculate with no selections returns empty results', () {
      final notifier = SmartProjectNotifier();

      notifier.calculate();

      expect(notifier.state.results['total'], 0);
    });

    test('calculate with foundation only', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFoundation(true);
      notifier.calculate();

      expect(notifier.state.results['foundation'], 100000);
      expect(notifier.state.results['total'], 100000);
      expect(notifier.state.results.containsKey('walls'), false);
    });

    test('calculate with walls only', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleWalls(true);
      notifier.calculate();

      expect(notifier.state.results['walls'], 150000);
      expect(notifier.state.results['total'], 150000);
      expect(notifier.state.results.containsKey('foundation'), false);
    });

    test('calculate with roof only', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleRoof(true);
      notifier.calculate();

      expect(notifier.state.results['roof'], 120000);
      expect(notifier.state.results['total'], 120000);
      expect(notifier.state.results.containsKey('walls'), false);
    });

    test('calculate with finish only', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFinish(true);
      notifier.calculate();

      expect(notifier.state.results['finish'], 80000);
      expect(notifier.state.results['total'], 80000);
      expect(notifier.state.results.containsKey('roof'), false);
    });

    test('calculate with all sections selected', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFoundation(true);
      notifier.toggleWalls(true);
      notifier.toggleRoof(true);
      notifier.toggleFinish(true);
      notifier.calculate();

      expect(notifier.state.results['foundation'], 100000);
      expect(notifier.state.results['walls'], 150000);
      expect(notifier.state.results['roof'], 120000);
      expect(notifier.state.results['finish'], 80000);
      expect(notifier.state.results['total'], 450000);
    });

    test('calculate with partial selection', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFoundation(true);
      notifier.toggleRoof(true);
      notifier.calculate();

      expect(notifier.state.results['foundation'], 100000);
      expect(notifier.state.results['roof'], 120000);
      expect(notifier.state.results['total'], 220000);
      expect(notifier.state.results.containsKey('walls'), false);
      expect(notifier.state.results.containsKey('finish'), false);
    });

    test('recalculate after changing selection', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFoundation(true);
      notifier.toggleWalls(true);
      notifier.calculate();

      expect(notifier.state.results['total'], 250000);

      notifier.toggleRoof(true);
      notifier.calculate();

      expect(notifier.state.results['total'], 370000);
    });

    test('calculate updates results but preserves flags', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFoundation(true);
      notifier.toggleWalls(true);
      notifier.calculate();

      expect(notifier.state.foundation, true);
      expect(notifier.state.walls, true);
      expect(notifier.state.results.isNotEmpty, true);
    });

    test('copyWith preserves unmodified fields', () {
      const initial = SmartProjectState(
        foundation: true,
        walls: true,
        roof: false,
        finish: false,
        results: {'test': 100},
      );

      final modified = initial.copyWith(roof: true);

      expect(modified.foundation, true);
      expect(modified.walls, true);
      expect(modified.roof, true);
      expect(modified.finish, false);
      expect(modified.results, {'test': 100});
    });

    test('calculate replaces previous results', () {
      final notifier = SmartProjectNotifier();

      notifier.toggleFoundation(true);
      notifier.toggleWalls(true);
      notifier.calculate();

      final firstTotal = notifier.state.results['total'];
      expect(firstTotal, 250000);

      notifier.toggleWalls(false);
      notifier.toggleRoof(true);
      notifier.calculate();

      final secondTotal = notifier.state.results['total'];
      expect(secondTotal, 220000);
      expect(notifier.state.results.containsKey('walls'), false);
    });
  });
}
