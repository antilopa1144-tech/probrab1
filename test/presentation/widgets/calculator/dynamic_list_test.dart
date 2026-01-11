import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/dynamic_list.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('OpeningData', () {
    test('creates with default values', () {
      final opening = OpeningData();
      expect(opening.width, 0.9);
      expect(opening.height, 2.1);
      expect(opening.count, 1);
    });

    test('creates with custom values', () {
      final opening = OpeningData(
        width: 1.2,
        height: 2.5,
        count: 2,
      );
      expect(opening.width, 1.2);
      expect(opening.height, 2.5);
      expect(opening.count, 2);
    });
  });

  group('DynamicList', () {
    testWidgets('renders items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              items: const ['Item 1', 'Item 2'],
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('renders with title', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              title: 'My List',
              items: const ['Test'],
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('My List'), findsOneWidget);
    });

    testWidgets('shows add button', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              title: 'List',
              items: const ['Test'],
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Добавить'), findsOneWidget);
    });

    testWidgets('calls onAdd when add button is pressed', (tester) async {
      setTestViewportSize(tester);
      bool addCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              title: 'List',
              items: const ['Test'],
              onAdd: () {
                addCalled = true;
              },
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Добавить'));
      expect(addCalled, isTrue);
    });

    testWidgets('shows remove buttons when can remove', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              items: const ['Item 1', 'Item 2'],
              minItems: 1,
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });

    testWidgets('hides remove buttons when at minItems', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              items: const ['Only Item'],
              minItems: 1,
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('calls onRemove when remove button is pressed', (tester) async {
      setTestViewportSize(tester);
      int? removedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              items: const ['Item 1', 'Item 2'],
              minItems: 0,
              onAdd: () {},
              onRemove: (index) {
                removedIndex = index;
              },
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close).first);
      expect(removedIndex, 0);
    });

    testWidgets('shows item indices when showIndex is true', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              items: const ['A', 'B'],
              showIndex: true,
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('hides add button when at maxItems', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              title: 'List',
              items: const ['A', 'B'],
              maxItems: 2,
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Добавить'), findsNothing);
    });

    testWidgets('uses custom add button text', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              title: 'List',
              items: const ['Test'],
              addButtonText: 'Add New',
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Add New'), findsOneWidget);
    });

    testWidgets('uses custom add button icon', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicList<String>(
              title: 'List',
              items: const ['Test'],
              addButtonIcon: Icons.plus_one,
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.plus_one), findsOneWidget);
    });
  });

  group('DynamicListSimple', () {
    testWidgets('renders items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListSimple<String>(
              items: const ['Simple 1', 'Simple 2'],
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Simple 1'), findsOneWidget);
      expect(find.text('Simple 2'), findsOneWidget);
    });

    testWidgets('shows add button when under maxItems', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListSimple<String>(
              items: const ['Test'],
              maxItems: 5,
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Добавить'), findsOneWidget);
    });

    testWidgets('shows remove icons when can remove', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListSimple<String>(
              items: const ['A', 'B', 'C'],
              minItems: 1,
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(3));
    });

    testWidgets('uses custom add button text', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicListSimple<String>(
              items: const ['Test'],
              addButtonText: 'Create New',
              onAdd: () {},
              onRemove: (_) {},
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Create New'), findsOneWidget);
    });
  });
}
