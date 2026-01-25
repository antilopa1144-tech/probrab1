import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('OnboardingScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders first page by default', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const OnboardingScreen()),
      );
      await tester.pump();

      // First page content
      expect(find.text('55+ калькуляторов'), findsOneWidget);
      expect(find.byIcon(Icons.calculate_outlined), findsOneWidget);
    });

    testWidgets('shows skip button', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const OnboardingScreen()),
      );
      await tester.pump();

      expect(find.text('Пропустить'), findsOneWidget);
    });

    testWidgets('shows next button', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const OnboardingScreen()),
      );
      await tester.pump();

      expect(find.text('Далее'), findsOneWidget);
    });

    testWidgets('shows page indicators', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const OnboardingScreen()),
      );
      await tester.pump();

      // 4 page indicators
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('navigates to next page on button tap', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const OnboardingScreen()),
      );
      await tester.pump();

      // First page
      expect(find.text('55+ калькуляторов'), findsOneWidget);

      // Tap next
      await tester.tap(find.text('Далее'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should show second page
      expect(find.text('Точные расчёты'), findsOneWidget);
    });

    testWidgets('swipe navigates to next page', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const OnboardingScreen()),
      );
      await tester.pump();

      // First page
      expect(find.text('55+ калькуляторов'), findsOneWidget);

      // Swipe left
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should show second page
      expect(find.text('Точные расчёты'), findsOneWidget);
    });

    testWidgets('shows all 4 pages content', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const OnboardingScreen()),
      );
      await tester.pump();

      // Page 1
      expect(find.text('55+ калькуляторов'), findsOneWidget);

      // Navigate to page 2 using button
      await tester.tap(find.text('Далее'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Точные расчёты'), findsOneWidget);

      // Navigate to page 3
      await tester.tap(find.text('Далее'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Сохраняйте расчёты'), findsOneWidget);

      // Navigate to page 4
      await tester.tap(find.text('Далее'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Поделитесь сметой'), findsOneWidget);
    });

    testWidgets('shows start button on last page', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const OnboardingScreen()),
      );
      await tester.pump();

      // Navigate to last page using next button
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Далее'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }

      expect(find.text('Начать'), findsOneWidget);
    });
  });

  group('OnboardingScreen.shouldShow', () {
    test('returns true when onboarding not completed', () async {
      SharedPreferences.setMockInitialValues({});

      final shouldShow = await OnboardingScreen.shouldShow();
      expect(shouldShow, true);
    });

    test('returns false when onboarding completed', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
      });

      final shouldShow = await OnboardingScreen.shouldShow();
      expect(shouldShow, false);
    });
  });

  group('OnboardingScreen.complete', () {
    test('sets onboarding_completed to true', () async {
      SharedPreferences.setMockInitialValues({});

      await OnboardingScreen.complete();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), true);
    });
  });

  group('OnboardingPage', () {
    test('creates with all properties', () {
      const page = OnboardingPage(
        icon: Icons.home,
        title: 'Test Title',
        description: 'Test Description',
        color: Colors.blue,
      );

      expect(page.icon, Icons.home);
      expect(page.title, 'Test Title');
      expect(page.description, 'Test Description');
      expect(page.color, Colors.blue);
    });
  });
}
