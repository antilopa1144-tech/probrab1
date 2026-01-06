import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';
import 'package:probrab_ai/presentation/widgets/calculator/grouped_results_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('GroupedResultsCard', () {
    testWidgets('renders nothing when results is empty', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return Scaffold(
                body: GroupedResultsCard(
                  results: const {},
                  loc: loc,
                ),
              );
            },
          ),
        ),
      );

      // Should be a SizedBox.shrink()
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders materials group', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return Scaffold(
                body: SingleChildScrollView(
                  child: GroupedResultsCard(
                    results: const {
                      'cementBags': 10.0,
                      'sandVolume': 2.5,
                    },
                    loc: loc,
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Should show materials icon
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('renders consumables group', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return Scaffold(
                body: SingleChildScrollView(
                  child: GroupedResultsCard(
                    results: const {
                      'screwsNeeded': 100.0,
                      'nailsNeeded': 50.0,
                    },
                    loc: loc,
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Should show build icon for consumables
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    });

    testWidgets('renders additional group', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return Scaffold(
                body: SingleChildScrollView(
                  child: GroupedResultsCard(
                    results: const {
                      'waterproofingArea': 25.0,
                      'primerLiters': 5.0,
                    },
                    loc: loc,
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Should show add circle icon for additional
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('excludes primary key from results', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return Scaffold(
                body: SingleChildScrollView(
                  child: GroupedResultsCard(
                    results: const {
                      'cementBags': 10.0,
                      'sandVolume': 2.5,
                    },
                    loc: loc,
                    primaryKey: 'cementBags',
                  ),
                ),
              );
            },
          ),
        ),
      );

      // cementBags should be excluded, only sandVolume shown
      expect(find.textContaining('2.5'), findsOneWidget);
    });

    testWidgets('filters out zero values', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return Scaffold(
                body: SingleChildScrollView(
                  child: GroupedResultsCard(
                    results: const {
                      'cementBags': 10.0,
                      'sandVolume': 0.0,
                    },
                    loc: loc,
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Zero values should not appear
      expect(find.textContaining('sandVolume'), findsNothing);
    });

    testWidgets('formats screw dimensions correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return Scaffold(
                body: SingleChildScrollView(
                  child: GroupedResultsCard(
                    results: const {
                      'screwDiameter': 4.0,
                      'screwLength': 35.0,
                    },
                    loc: loc,
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Should format as diameter×length
      expect(find.textContaining('4×35'), findsOneWidget);
    });

    test('groups constant contains expected keys', () {
      expect(GroupedResultsCard.groups['materials'], isNotEmpty);
      expect(GroupedResultsCard.groups['consumables'], isNotEmpty);
      expect(GroupedResultsCard.groups['additional'], isNotEmpty);
    });

    test('materials group contains expected keys', () {
      final materials = GroupedResultsCard.groups['materials']!;
      expect(materials, contains('cementBags'));
      expect(materials, contains('sandVolume'));
      expect(materials, contains('plasterBags'));
    });

    test('consumables group contains expected keys', () {
      final consumables = GroupedResultsCard.groups['consumables']!;
      expect(consumables, contains('screwsNeeded'));
      expect(consumables, contains('nailsNeeded'));
      expect(consumables, contains('meshArea'));
    });

    test('additional group contains expected keys', () {
      final additional = GroupedResultsCard.groups['additional']!;
      expect(additional, contains('waterproofingArea'));
      expect(additional, contains('primerLiters'));
    });
  });
}
