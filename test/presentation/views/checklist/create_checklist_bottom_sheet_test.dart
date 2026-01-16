import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/checklist.dart';
import 'package:probrab_ai/domain/models/checklist_template.dart';
import 'package:probrab_ai/presentation/views/checklist/create_checklist_bottom_sheet.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('CreateChecklistBottomSheet', () {
    Widget createTestWidget({int? projectId}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SizedBox(
                      height: 600,
                      child: CreateChecklistBottomSheet(projectId: projectId),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('отображает заголовок в AppBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Заголовок - в Row с иконкой
      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
      // Есть текст "Создать чек-лист" (минимум 1 - в заголовке)
      expect(find.text('Создать чек-лист'), findsWidgets);
    });

    testWidgets('отображает кнопку закрытия', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('отображает первый шаблон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final template = ChecklistTemplates.all.first;
      expect(find.text(template.name), findsOneWidget);
    });

    testWidgets('отображает описание первого шаблона', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final template = ChecklistTemplates.all.first;
      expect(find.text(template.description), findsOneWidget);
    });

    testWidgets('отображает количество задач', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final template = ChecklistTemplates.all.first;
      expect(find.text('${template.items.length} задач'), findsOneWidget);
    });

    testWidgets('выбранный шаблон показывает галочку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // До выбора нет галочки
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      // Выбираем первый шаблон
      final template = ChecklistTemplates.all.first;
      await tester.tap(find.text(template.name));
      await tester.pumpAndSettle();

      // После выбора появляется галочка
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('можно переключать выбор шаблона', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final templates = ChecklistTemplates.all;
      if (templates.length < 2) return;

      // Выбираем первый шаблон
      await tester.tap(find.text(templates[0].name));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Выбираем второй шаблон
      await tester.tap(find.text(templates[1].name));
      await tester.pumpAndSettle();

      // Всё ещё только одна галочка
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('закрывается по кнопке X', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsNothing);
    });

    testWidgets('отображает иконку задачи на кнопке', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_task_rounded), findsOneWidget);
    });

    testWidgets('отображает иконку категории шаблона', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final template = ChecklistTemplates.all.first;
      expect(find.text(template.category.icon), findsOneWidget);
    });

    testWidgets('принимает projectId без ошибок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(projectId: 42));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsOneWidget);
    });

    testWidgets('содержит ListView для прокрутки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('содержит DraggableScrollableSheet', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('отображает Divider', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('шаблоны отображаются в Card', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    test('ChecklistTemplates содержит 8 шаблонов включая новые', () {
      // Проверяем, что теперь 8 шаблонов (5 старых + 3 новых)
      expect(ChecklistTemplates.all.length, equals(8));

      // Проверяем наличие новых шаблонов по ID
      final ids = ChecklistTemplates.all.map((t) => t.id).toList();
      expect(ids, contains('hallway_renovation'));
      expect(ids, contains('balcony_renovation'));
      expect(ids, contains('facade_renovation'));

      // Проверяем правильность категорий
      final hallway = ChecklistTemplates.findById('hallway_renovation');
      expect(hallway, isNotNull);
      expect(hallway!.category, equals(ChecklistCategory.hallway));

      final balcony = ChecklistTemplates.findById('balcony_renovation');
      expect(balcony, isNotNull);
      expect(balcony!.category, equals(ChecklistCategory.balcony));

      final facade = ChecklistTemplates.findById('facade_renovation');
      expect(facade, isNotNull);
      expect(facade!.category, equals(ChecklistCategory.facade));
    });
  });

  group('CreateChecklistBottomSheet.show', () {
    testWidgets('статический метод show открывает bottom sheet', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    CreateChecklistBottomSheet.show(context);
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsOneWidget);
    });

    testWidgets('статический метод show принимает projectId', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    CreateChecklistBottomSheet.show(context, projectId: 123);
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsOneWidget);
    });
  });
}
