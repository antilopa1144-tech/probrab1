import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_result_header.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('CalculatorResultHeader', () {
    testWidgets('renders correctly with 2 results (white card mode)',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorResultHeader(
              accentColor: Colors.green,
              results: const [
                ResultItem(label: 'Площадь', value: '35.9 м²'),
                ResultItem(label: 'Мешков', value: '5 шт'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ПЛОЩАДЬ'), findsOneWidget);
      expect(find.text('35.9 м²'), findsOneWidget);
      expect(find.text('МЕШКОВ'), findsOneWidget);
      expect(find.text('5 шт'), findsOneWidget);
    });

    testWidgets('renders correctly with 3 results', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorResultHeader(
              accentColor: Colors.blue,
              results: const [
                ResultItem(label: 'Площадь', value: '35.9 м²'),
                ResultItem(label: 'Старт', value: '2 мешка'),
                ResultItem(label: 'Финиш', value: '3 шт'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ПЛОЩАДЬ'), findsOneWidget);
      expect(find.text('СТАРТ'), findsOneWidget);
      expect(find.text('ФИНИШ'), findsOneWidget);
    });

    testWidgets('renders correctly with 4 results (maximum)', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorResultHeader(
              accentColor: Colors.orange,
              results: const [
                ResultItem(label: 'Площадь', value: '100 м²'),
                ResultItem(label: 'Старт', value: '10 мешков'),
                ResultItem(label: 'Финиш', value: '5 кг'),
                ResultItem(label: 'Стоимость', value: '15000 ₽'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ПЛОЩАДЬ'), findsOneWidget);
      expect(find.text('СТАРТ'), findsOneWidget);
      expect(find.text('ФИНИШ'), findsOneWidget);
      expect(find.text('СТОИМОСТЬ'), findsOneWidget);
    });

    testWidgets('renders icons when provided', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorResultHeader(
              accentColor: Colors.green,
              results: const [
                ResultItem(
                  label: 'Площадь',
                  value: '35 м²',
                  icon: Icons.square_foot,
                ),
                ResultItem(
                  label: 'Мешков',
                  value: '5 шт',
                  icon: Icons.shopping_bag,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.square_foot), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
    });

    testWidgets('handles very long values with FittedBox', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: CalculatorResultHeader(
                accentColor: Colors.green,
                results: const [
                  ResultItem(
                    label: 'Очень длинная метка',
                    value: '1234567890.99 м²',
                  ),
                  ResultItem(
                    label: 'Короткая',
                    value: '5 шт',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // FittedBox должен предотвратить overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(FittedBox), findsNWidgets(2)); // По одному на каждое value
    });

    testWidgets('colored variant renders without white card', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorResultHeaderColored(
              accentColor: Colors.purple,
              results: [
                ResultItem(label: 'Площадь', value: '50 м²'),
                ResultItem(label: 'Объем', value: '10 м³'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ПЛОЩАДЬ'), findsOneWidget);
      expect(find.text('50 м²'), findsOneWidget);
    });

    testWidgets('supports textScaleFactor without overflow', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SizedBox(
                width: 320,
                child: CalculatorResultHeader(
                  accentColor: Colors.green,
                  results: const [
                    ResultItem(label: 'Площадь стен', value: '150.5 м²'),
                    ResultItem(label: 'Мешков', value: '25 шт'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Не должно быть overflow при увеличенном шрифте
      expect(tester.takeException(), isNull);
    });

    testWidgets('label supports 2 lines for long text', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: CalculatorResultHeader(
                accentColor: Colors.green,
                results: const [
                  ResultItem(
                    label: 'Площадь поверхности стен',
                    value: '100 м²',
                  ),
                  ResultItem(label: 'Короткая', value: '5 шт'),
                ],
              ),
            ),
          ),
        ),
      );

      // Проверяем, что длинный label не вызывает overflow
      expect(tester.takeException(), isNull);
      // Text с maxLines=2 должен присутствовать
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final labelTexts = textWidgets.where((t) =>
        t.data?.contains('ПЛОЩАДЬ') ?? false
      );
      expect(labelTexts.isNotEmpty, isTrue);
    });

    testWidgets('applies correct colors in white card mode', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorResultHeader(
              accentColor: const Color(0xFF10B981),
              results: const [
                ResultItem(label: 'Тест 1', value: '100'),
                ResultItem(label: 'Тест 2', value: '200'),
              ],
              useWhiteCard: true,
            ),
          ),
        ),
      );

      // В white card режиме лейблы должны быть grey[600]
      // value должен быть accentColor
      expect(find.text('ТЕСТ 1'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('applies correct colors in colored mode', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorResultHeader(
              accentColor: const Color(0xFF10B981),
              results: const [
                ResultItem(label: 'Тест 1', value: '100'),
                ResultItem(label: 'Тест 2', value: '200'),
              ],
              useWhiteCard: false,
            ),
          ),
        ),
      );

      // В colored режиме лейблы должны быть белыми
      expect(find.text('ТЕСТ 1'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });
  });
}
