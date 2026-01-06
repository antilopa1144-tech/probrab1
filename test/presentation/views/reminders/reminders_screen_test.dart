import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/reminders/reminders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('RemindersScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders with app bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      expect(find.text('Напоминания'), findsOneWidget);
    });

    testWidgets('shows tab bar with 3 tabs', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Скоро'), findsOneWidget);
      expect(find.text('Просрочено'), findsOneWidget);
    });

    testWidgets('shows tab icons', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('shows add button in app bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no reminders', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      expect(find.text('Нет напоминаний'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('tapping add opens dialog', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Новое напоминание'), findsOneWidget);
    });

    testWidgets('add dialog shows input fields', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Название'), findsOneWidget);
      expect(find.text('Описание'), findsOneWidget);
      // Dialog should have text fields and a dropdown
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('add dialog shows action buttons', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Создать'), findsOneWidget);
    });

    testWidgets('can cancel add dialog', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(find.text('Новое напоминание'), findsNothing);
    });

    testWidgets('can switch between tabs', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      // Tap on "Скоро" tab
      await tester.tap(find.text('Скоро'));
      await tester.pumpAndSettle();

      expect(find.text('Нет напоминаний'), findsOneWidget);
    });

    testWidgets('uses TabBarView', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('uses DefaultTabController', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const RemindersScreen()),
      );
      await tester.pump();

      expect(find.byType(DefaultTabController), findsOneWidget);
    });
  });
}
