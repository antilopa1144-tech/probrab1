import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/expert/expert_recommendations_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ExpertRecommendationsScreen', () {
    testWidgets('renders with app bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Экспертные рекомендации'), findsOneWidget);
    });

    testWidgets('shows recommendations for known work type', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Покраска стен и потолков'), findsOneWidget);
    });

    testWidgets('shows empty state for unknown work type', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'unknown_type_xyz'),
        ),
      );

      expect(
        find.text('Рекомендации для этого типа работ пока не добавлены'),
        findsOneWidget,
      );
    });

    testWidgets('shows level indicator', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      expect(find.textContaining('Уровень:'), findsWidgets);
    });

    testWidgets('shows beginner level for painting', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Уровень: Новичок'), findsOneWidget);
    });

    testWidgets('uses ExpansionTile for recommendations', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      expect(find.byType(ExpansionTile), findsWidgets);
    });

    testWidgets('can expand recommendation to see details', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      // Tap to expand
      await tester.tap(find.text('Покраска стен и потолков'));
      await tester.pumpAndSettle();

      // Should show expanded content
      expect(find.text('Типичные ошибки'), findsOneWidget);
      expect(find.text('Лучшие практики'), findsOneWidget);
    });

    testWidgets('shows common mistakes section when expanded', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      await tester.tap(find.text('Покраска стен и потолков'));
      await tester.pumpAndSettle();

      expect(find.text('Типичные ошибки'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsWidgets);
    });

    testWidgets('shows best practices section when expanded', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      await tester.tap(find.text('Покраска стен и потолков'));
      await tester.pumpAndSettle();

      expect(find.text('Лучшие практики'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('shows tools section when expanded', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      await tester.tap(find.text('Покраска стен и потолков'));
      await tester.pumpAndSettle();

      expect(find.text('Необходимые инструменты'), findsOneWidget);
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('shows materials section when expanded', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      await tester.tap(find.text('Покраска стен и потолков'));
      await tester.pumpAndSettle();

      expect(find.text('Необходимые материалы'), findsOneWidget);
    });

    testWidgets('shows recommendations for tile work', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'плитка'),
        ),
      );

      expect(find.text('Укладка плитки'), findsOneWidget);
      expect(find.text('Уровень: Средний'), findsOneWidget);
    });

    testWidgets('shows recommendations for screed work', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'стяжка'),
        ),
      );

      expect(find.text('Заливка стяжки'), findsOneWidget);
    });

    testWidgets('shows recommendations for wallpaper', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'обои'),
        ),
      );

      expect(find.text('Поклейка обоев'), findsOneWidget);
    });

    testWidgets('uses CircleAvatar for level indicator', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('scrollable list of recommendations', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('uses Card for each recommendation', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ExpertRecommendationsScreen(workType: 'покраска'),
        ),
      );

      expect(find.byType(Card), findsWidgets);
    });
  });
}
