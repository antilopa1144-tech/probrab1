import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/components/mat_card.dart';

void main() {
  group('MatCardButton', () {
    testWidgets('renders title correctly', (tester) async {
      const testTitle = 'Test Title';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: testTitle,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
    });

    testWidgets('renders icon correctly', (tester) async {
      const testIcon = Icons.calculate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: testIcon,
              title: 'Test',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(testIcon), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      const testSubtitle = 'Test Subtitle';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Test',
              subtitle: testSubtitle,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(testSubtitle), findsOneWidget);
    });

    testWidgets('does not render subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Test',
              onTap: () {},
            ),
          ),
        ),
      );

      // Should only have one Text widget (the title)
      final textWidgets = find.descendant(
        of: find.byType(MatCardButton),
        matching: find.byType(Text),
      );
      expect(textWidgets, findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Test',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MatCardButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('uses custom background color', (tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Test',
              backgroundColor: customColor,
              onTap: () {},
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(MatCardButton),
          matching: find.byType(Material),
        ),
      );

      expect(material.color, customColor);
    });

    testWidgets('uses custom icon color', (tester) async {
      const customColor = Colors.blue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Test',
              iconColor: customColor,
              onTap: () {},
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(MatCardButton),
          matching: find.byType(Icon),
        ),
      );

      expect(icon.color, customColor);
    });

    testWidgets('has InkWell for tap effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Test',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('has proper border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Test',
              onTap: () {},
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(MatCardButton),
          matching: find.byType(Material),
        ),
      );

      expect(material.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('title truncates with ellipsis when too long', (tester) async {
      const longTitle = 'This is a very long title that should be truncated';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: MatCardButton(
                icon: Icons.home,
                title: longTitle,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatCardButton),
          matching: find.text(longTitle),
        ),
      );

      expect(titleText.overflow, TextOverflow.ellipsis);
      expect(titleText.maxLines, 2);
    });

    testWidgets('subtitle truncates with ellipsis when too long', (tester) async {
      const longSubtitle = 'This is a very long subtitle that should be truncated';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: MatCardButton(
                icon: Icons.home,
                title: 'Test',
                subtitle: longSubtitle,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final subtitleText = tester.widget<Text>(
        find.descendant(
          of: find.byType(MatCardButton),
          matching: find.text(longSubtitle),
        ),
      );

      expect(subtitleText.overflow, TextOverflow.ellipsis);
      expect(subtitleText.maxLines, 2);
    });

    testWidgets('icon is placed in decorated container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Test',
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the Container that wraps the Icon
      final containers = find.descendant(
        of: find.byType(MatCardButton),
        matching: find.byType(Container),
      );

      expect(containers, findsWidgets);

      // Find the Container that has the icon as a child
      final iconContainer = tester.widget<Container>(
        find.ancestor(
          of: find.byType(Icon),
          matching: find.byType(Container),
        ).first,
      );

      // Verify it has decoration with border radius
      expect(iconContainer.decoration, isA<BoxDecoration>());
      final decoration = iconContainer.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
    });
  });
}
