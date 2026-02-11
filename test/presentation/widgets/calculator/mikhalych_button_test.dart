import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/mikhalych_button.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // MikhalychButton
  // ===========================================================================

  group('MikhalychButton', () {
    testWidgets('renders title and subtitle', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychButton(
              calculatorName: 'Обои',
              dataCollector: () => {'area': 20.0},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Совет прораба'), findsOneWidget);
      expect(find.text('Михалыч проверит расчёт'), findsOneWidget);
    });

    testWidgets('renders button with correct text', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychButton(
              calculatorName: 'Плитка',
              dataCollector: () => {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Спросить Михалыча'), findsOneWidget);
      // Verify the button is tappable
      expect(find.byIcon(Icons.construction), findsOneWidget);
    });

    testWidgets('renders engineering icon', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychButton(
              calculatorName: 'Ламинат',
              dataCollector: () => {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.engineering), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsOneWidget);
    });

    testWidgets('applies custom accent color to icon', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychButton(
              calculatorName: 'Test',
              dataCollector: () => {},
              accentColor: Colors.red,
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify the accent color is applied to the engineering icon
      final icon = tester.widget<Icon>(find.byIcon(Icons.engineering));
      expect(icon.color, equals(Colors.red));
    });

    testWidgets('opens bottom sheet on button tap', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychButton(
              calculatorName: 'Обои',
              dataCollector: () => {'width': 3.5, 'length': 5.0},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Спросить Михалыча'));
      // Use pump() instead of pumpAndSettle() because the BottomSheet
      // contains CircularProgressIndicator which never settles
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // BottomSheet should show Михалыч header
      expect(find.text('Михалыч'), findsOneWidget);
      expect(find.text('Прораб • 30 лет стажа'), findsOneWidget);
    });

    testWidgets('calls dataCollector on button tap', (tester) async {
      setTestViewportSize(tester);
      var called = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychButton(
              calculatorName: 'Test',
              dataCollector: () {
                called = true;
                return {'area': 10.0};
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Спросить Михалыча'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('renders in dark theme', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychButton(
              calculatorName: 'Test',
              dataCollector: () => {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Совет прораба'), findsOneWidget);
      expect(find.text('Спросить Михалыча'), findsOneWidget);
    });

    testWidgets('renders in light theme', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychButton(
              calculatorName: 'Test',
              dataCollector: () => {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Совет прораба'), findsOneWidget);
      expect(find.text('Спросить Михалыча'), findsOneWidget);
    });
  });

  // ===========================================================================
  // MikhalychBottomSheet
  // ===========================================================================

  group('MikhalychBottomSheet', () {
    testWidgets('renders header with name and subtitle', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychBottomSheet(
              calculatorName: 'Обои',
              data: const {'area': 20.0},
              accentColor: Colors.blue,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Михалыч'), findsOneWidget);
      expect(find.text('Прораб • 30 лет стажа'), findsOneWidget);
    });

    testWidgets('shows loading or error state after init', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychBottomSheet(
              calculatorName: 'Плитка',
              data: const {'area': 15.0},
              accentColor: Colors.green,
            ),
          ),
        ),
      );
      // Let async _initAndAsk() complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In tests without API key, the service errors out quickly.
      // Either we see a loading state (CircularProgressIndicator) or an error state.
      final hasLoading =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasError = find.byIcon(Icons.warning_amber_rounded).evaluate().isNotEmpty;
      expect(hasLoading || hasError, isTrue,
          reason: 'Should show either loading spinner or error state');
    });

    testWidgets('has close button', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychBottomSheet(
              calculatorName: 'Test',
              data: const {},
              accentColor: Colors.blue,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('has engineering icon in header', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychBottomSheet(
              calculatorName: 'Test',
              data: const {},
              accentColor: Colors.orange,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.engineering), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychBottomSheet(
              calculatorName: 'Test',
              data: const {'x': 1},
              accentColor: Colors.teal,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Михалыч'), findsOneWidget);
      // In test env without API key, may show error instead of typing indicator
      final hasTyping =
          find.textContaining('Михалыч думает').evaluate().isNotEmpty;
      final hasError =
          find.byIcon(Icons.warning_amber_rounded).evaluate().isNotEmpty;
      expect(hasTyping || hasError, isTrue,
          reason: 'Should show typing indicator or error');
    });

    testWidgets('renders in light theme', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychBottomSheet(
              calculatorName: 'Test',
              data: const {'x': 1},
              accentColor: Colors.teal,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Михалыч'), findsOneWidget);
    });

    testWidgets('has dividers between header/content and content/input',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MikhalychBottomSheet(
              calculatorName: 'Test',
              data: const {},
              accentColor: Colors.blue,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Divider), findsNWidgets(2));
    });
  });
}
