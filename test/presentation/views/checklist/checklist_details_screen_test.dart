import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/checklist/checklist_details_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  // Простые тесты без базы данных - проверяем начальное состояние загрузки
  // Полные тесты с БД требуют более сложной настройки, которая занимает время

  group('ChecklistDetailsScreen', () {
    testWidgets('показывает индикатор загрузки при старте', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );
      // Не ждём async операций - сразу проверяем loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('содержит AppBar с заголовком Чек-лист при загрузке', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Чек-лист'), findsOneWidget);
    });

    testWidgets('checklistId передаётся в widget', (tester) async {
      const testId = 42;

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: testId),
        ),
      );

      final widget = tester.widget<ChecklistDetailsScreen>(
        find.byType(ChecklistDetailsScreen),
      );
      expect(widget.checklistId, testId);
    });

    testWidgets('имеет Scaffold', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('индикатор загрузки центрирован', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });
  });
}
