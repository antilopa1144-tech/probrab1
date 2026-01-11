import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/premium_lock_dialog.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('PremiumLockDialog', () {
    testWidgets('отображает название функции', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumLockDialog(
              featureName: 'Тестовая функция',
            ),
          ),
        ),
      );

      expect(find.text('Тестовая функция'), findsOneWidget);
    });

    testWidgets('отображает описание если указано', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumLockDialog(
              featureName: 'Функция',
              description: 'Описание функции',
            ),
          ),
        ),
      );

      expect(find.text('Описание функции'), findsOneWidget);
    });

    testWidgets('отображает описание по умолчанию если не указано',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumLockDialog(
              featureName: 'Функция',
            ),
          ),
        ),
      );

      expect(
        find.text('Эта функция доступна только в Premium версии'),
        findsOneWidget,
      );
    });

    testWidgets('отображает иконку замка', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumLockDialog(
              featureName: 'Функция',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('отображает список преимуществ Premium', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumLockDialog(
              featureName: 'Функция',
            ),
          ),
        ),
      );

      expect(find.text('Расширенные калькуляторы'), findsOneWidget);
      expect(find.text('Неограниченное число проектов'), findsOneWidget);
      expect(find.text('Экспорт в PDF'), findsOneWidget);
      expect(find.text('И многое другое...'), findsOneWidget);
    });

    testWidgets('отображает кнопку Отмена', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumLockDialog(
              featureName: 'Функция',
            ),
          ),
        ),
      );

      expect(find.text('Отмена'), findsOneWidget);
    });

    testWidgets('отображает кнопку Получить Premium', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumLockDialog(
              featureName: 'Функция',
            ),
          ),
        ),
      );

      expect(find.text('Получить Premium'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('отображает иконки галочек для преимуществ', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumLockDialog(
              featureName: 'Функция',
            ),
          ),
        ),
      );

      // 4 преимущества = 4 иконки галочек
      expect(
        find.byIcon(Icons.check_circle_outline_rounded),
        findsNWidgets(4),
      );
    });
  });

  group('PremiumLockDialog.show', () {
    testWidgets('возвращает false при нажатии Отмена', (tester) async {
      setTestViewportSize(tester);
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await PremiumLockDialog.show(
                      context,
                      featureName: 'Тест',
                    );
                  },
                  child: const Text('Показать'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Показать'));
      await tester.pumpAndSettle();

      // Проверяем что диалог появился
      expect(find.text('Тест'), findsOneWidget);

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('кнопка Получить Premium закрывает диалог с true',
        (tester) async {
      setTestViewportSize(tester);
      bool? result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      result = await showDialog<bool>(
                        context: context,
                        builder: (context) => const PremiumLockDialog(
                          featureName: 'Тест',
                        ),
                      );
                    },
                    child: const Text('Показать'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Показать'));
      await tester.pumpAndSettle();

      // Проверяем что диалог открылся
      expect(find.text('Получить Premium'), findsOneWidget);

      // Нажимаем кнопку (но не используем pumpAndSettle из-за навигации)
      await tester.tap(find.text('Получить Premium'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Проверяем что result был установлен в true
      expect(result, true);
    });

    testWidgets('возвращает false при закрытии диалога', (tester) async {
      setTestViewportSize(tester);
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await PremiumLockDialog.show(
                      context,
                      featureName: 'Тест',
                    );
                  },
                  child: const Text('Показать'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Показать'));
      await tester.pumpAndSettle();

      // Нажимаем вне диалога для закрытия
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('передаёт description в диалог', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await PremiumLockDialog.show(
                      context,
                      featureName: 'Тест',
                      description: 'Кастомное описание',
                    );
                  },
                  child: const Text('Показать'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Показать'));
      await tester.pumpAndSettle();

      expect(find.text('Кастомное описание'), findsOneWidget);
    });
  });
}
