import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/definitions.dart';

void main() {
  group('CalculatorRegistryV1', () {
    late CalculatorRegistryV1 registry;

    setUp(() {
      registry = CalculatorRegistryV1.instance;
    });

    group('singleton', () {
      test('returns same instance', () {
        final instance1 = CalculatorRegistryV1.instance;
        final instance2 = CalculatorRegistryV1.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('getById', () {
      test('returns calculator with matching ID', () {
        final calc = registry.getById('calculator.stripTitle');

        expect(calc, isNotNull);
        expect(calc?.id, equals('calculator.stripTitle'));
      });

      test('returns null for non-existent ID', () {
        final calc = registry.getById('non_existent_id');

        expect(calc, isNull);
      });

      test('lookup is case-sensitive', () {
        final calc = registry.getById('CALCULATOR.STRIPTITLE');

        expect(calc, isNull);
      });

      test('performs O(1) lookup', () {
        // Test that repeated lookups are fast (from index, not linear search)
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          registry.getById('calculator.stripTitle');
        }
        stopwatch.stop();

        // Should complete in well under 10ms for 1000 lookups
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });

    group('getByCategory', () {
      test('returns calculators for existing category', () {
        final calcs = registry.getByCategory('Фундамент');

        expect(calcs, isNotEmpty);
        expect(calcs.every((c) => c.category == 'Фундамент'), isTrue);
      });

      test('returns empty list for non-existent category', () {
        final calcs = registry.getByCategory('NonExistentCategory');

        expect(calcs, isEmpty);
      });

      test('returns all calculators in category', () {
        final calcs = registry.getByCategory('Фундамент');

        // Should match foundationCalculators list
        expect(calcs.length, equals(foundationCalculators.length));
      });

      test('performs O(1) lookup', () {
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          registry.getByCategory('Фундамент');
        }
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });

    group('getBySubCategory', () {
      test('returns calculators for existing subcategory', () {
        final calcs = registry.getBySubCategory('Ленточный фундамент');

        expect(calcs, isNotEmpty);
        expect(calcs.every((c) => c.subCategory == 'Ленточный фундамент'), isTrue);
      });

      test('returns empty list for non-existent subcategory', () {
        final calcs = registry.getBySubCategory('NonExistent');

        expect(calcs, isEmpty);
      });
    });

    group('getAllCategories', () {
      test('returns all unique categories', () {
        final categories = registry.getAllCategories();

        expect(categories, isNotEmpty);
        expect(categories, contains('Фундамент'));
        expect(categories, contains('Внутренняя отделка'));
        expect(categories, contains('Наружная отделка'));
      });

      test('returns sorted list', () {
        final categories = registry.getAllCategories();
        final sorted = List<String>.from(categories)..sort();

        expect(categories, equals(sorted));
      });

      test('returns unique categories', () {
        final categories = registry.getAllCategories();
        final unique = categories.toSet().toList();

        expect(categories.length, equals(unique.length));
      });
    });

    group('getSubCategories', () {
      test('returns subcategories for category', () {
        final subCategories = registry.getSubCategories('Фундамент');

        expect(subCategories, isNotEmpty);
        expect(subCategories, contains('Ленточный фундамент'));
      });

      test('returns empty list for category without subcategories', () {
        final subCategories = registry.getSubCategories('NonExistent');

        expect(subCategories, isEmpty);
      });

      test('returns sorted list', () {
        final subCategories = registry.getSubCategories('Фундамент');
        final sorted = List<String>.from(subCategories)..sort();

        expect(subCategories, equals(sorted));
      });

      test('returns unique subcategories', () {
        final subCategories = registry.getSubCategories('Фундамент');
        final unique = subCategories.toSet().toList();

        expect(subCategories.length, equals(unique.length));
      });
    });

    group('search', () {
      test('returns empty list for empty query', () {
        final results = registry.search('');

        expect(results, isEmpty);
      });

      test('finds calculators by ID', () {
        final results = registry.search('stripTitle');

        expect(results, isNotEmpty);
        expect(results.any((c) => c.id.contains('stripTitle')), isTrue);
      });

      test('finds calculators by title key', () {
        final results = registry.search('laminate');

        expect(results, isNotEmpty);
      });

      test('finds calculators by category', () {
        final results = registry.search('Фундамент');

        expect(results, isNotEmpty);
        expect(results.every((c) => c.category == 'Фундамент'), isTrue);
      });

      test('finds calculators by subcategory', () {
        final results = registry.search('Ленточный');

        expect(results, isNotEmpty);
      });

      test('search is case-insensitive', () {
        final results1 = registry.search('фундамент');
        final results2 = registry.search('ФУНДАМЕНТ');
        final results3 = registry.search('Фундамент');

        expect(results1.length, equals(results2.length));
        expect(results2.length, equals(results3.length));
      });

      test('trims whitespace from query', () {
        final results = registry.search('  Фундамент  ');

        expect(results, isNotEmpty);
      });

      test('sorts results by relevance', () {
        // ID matches should come before category matches
        final results = registry.search('strip');

        if (results.length > 1) {
          // First result should have 'strip' in ID (higher relevance)
          expect(results.first.id.toLowerCase().contains('strip'), isTrue);
        }
      });
    });

    group('getAll', () {
      test('returns all calculators', () {
        final all = registry.getAll();

        expect(all.length, equals(calculators.length));
      });

      test('returns unmodifiable list', () {
        final all = registry.getAll();

        expect(() => all.add(foundationCalculators.first), throwsUnsupportedError);
      });
    });

    group('count', () {
      test('returns total number of calculators', () {
        expect(registry.count, equals(calculators.length));
        expect(registry.count, greaterThan(0));
      });
    });

    group('contains', () {
      test('returns true for existing calculator', () {
        expect(registry.contains('calculator.stripTitle'), isTrue);
      });

      test('returns false for non-existent calculator', () {
        expect(registry.contains('non_existent'), isFalse);
      });
    });

    group('getCategoryStats', () {
      test('returns count for each category', () {
        final stats = registry.getCategoryStats();

        expect(stats, isNotEmpty);
        expect(stats['Фундамент'], equals(foundationCalculators.length));
      });

      test('includes all categories', () {
        final stats = registry.getCategoryStats();
        final categories = registry.getAllCategories();

        for (final category in categories) {
          if (category.isNotEmpty) {
            expect(stats.containsKey(category), isTrue);
          }
        }
      });

      test('counts match actual calculator count', () {
        final stats = registry.getCategoryStats();
        final totalCount = stats.values.fold<int>(0, (sum, count) => sum + count);

        expect(totalCount, equals(registry.count));
      });
    });

    group('filter', () {
      test('filters calculators by predicate', () {
        final filtered = registry.filter((c) => c.category == 'Фундамент');

        expect(filtered, isNotEmpty);
        expect(filtered.every((c) => c.category == 'Фундамент'), isTrue);
      });

      test('returns empty list when no match', () {
        final filtered = registry.filter((c) => c.id == 'non_existent');

        expect(filtered, isEmpty);
      });

      test('can filter by field count', () {
        final filtered = registry.filter((c) => c.fields.length > 5);

        expect(filtered, isNotEmpty);
        expect(filtered.every((c) => c.fields.length > 5), isTrue);
      });
    });

    group('performance', () {
      test('indices are pre-built on initialization', () {
        // Creating a new instance should be fast because indices are built in constructor
        final stopwatch = Stopwatch()..start();
        final _ = CalculatorRegistryV1.instance;
        stopwatch.stop();

        // Should complete in well under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('category lookup is faster than linear search', () {
        const category = 'Фундамент';

        // Indexed lookup
        final stopwatch1 = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          registry.getByCategory(category);
        }
        stopwatch1.stop();

        // Linear search
        final stopwatch2 = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          calculators.where((c) => c.category == category).toList();
        }
        stopwatch2.stop();

        // Indexed lookup should be significantly faster
        expect(stopwatch1.elapsedMilliseconds, lessThan(stopwatch2.elapsedMilliseconds));
      });
    });
  });
}
