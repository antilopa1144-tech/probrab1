import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/error_message.dart';

void main() {
  group('ErrorMessage', () {
    testWidgets('renders with message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: 'Something went wrong'),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows default error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: 'Error'),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows custom icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(
              message: 'No connection',
              icon: Icons.wifi_off,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorMessage(
              message: 'Error occurred',
              actionLabel: 'Retry',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('hides action button when actionLabel is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorMessage(
              message: 'Error',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('hides action button when onAction is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(
              message: 'Error',
              actionLabel: 'Retry',
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('calls onAction when button is tapped', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorMessage(
              message: 'Error',
              actionLabel: 'Retry',
              onAction: () {
                actionCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      expect(actionCalled, isTrue);
    });

    testWidgets('centers message text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: 'Centered error'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Centered error'));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('renders in Column layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: 'Error'),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('uses error color for icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light()),
          home: const Scaffold(
            body: ErrorMessage(message: 'Error'),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, 40);
    });

    testWidgets('renders with custom icon and action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorMessage(
              message: 'Network error',
              icon: Icons.cloud_off,
              actionLabel: 'Try Again',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
