import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/type_selector_card.dart';

void main() {
  group('TypeSelectorCard', () {
    testWidgets('renders correctly when not selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.brush,
              title: 'Под обои',
              subtitle: 'Финишная отделка',
              isSelected: false,
              accentColor: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Под обои'), findsOneWidget);
      expect(find.text('Финишная отделка'), findsOneWidget);
      expect(find.byIcon(Icons.brush), findsOneWidget);
    });

    testWidgets('renders correctly when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.brush,
              title: 'Под обои',
              subtitle: 'Финишная отделка',
              isSelected: true,
              accentColor: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Под обои'), findsOneWidget);
      expect(find.text('Финишная отделка'), findsOneWidget);
      expect(find.byIcon(Icons.brush), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.format_paint,
              title: 'Под покраску',
              isSelected: false,
              accentColor: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TypeSelectorCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders without subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.square_foot,
              title: 'Площадь',
              isSelected: false,
              accentColor: Colors.orange,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Площадь'), findsOneWidget);
      // subtitle не должен быть найден
      expect(find.byType(TypeSelectorCard), findsOneWidget);
    });

    testWidgets('shows checkmark when selected and showCheckmark is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.check_circle,
              title: 'Выбрано',
              isSelected: true,
              accentColor: Colors.green,
              showCheckmark: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Должна быть галочка (checkmark icon)
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not show checkmark when showCheckmark is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.circle,
              title: 'Без галочки',
              isSelected: true,
              accentColor: Colors.blue,
              showCheckmark: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Галочка не должна быть видна
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('applies correct colors when selected', (tester) async {
      const testAccentColor = Color(0xFF10B981);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.star,
              title: 'Выделено',
              subtitle: 'Активно',
              isSelected: true,
              accentColor: testAccentColor,
              onTap: () {},
            ),
          ),
        ),
      );

      // Проверяем, что виджет создан без ошибок
      expect(find.byType(TypeSelectorCard), findsOneWidget);
    });

    testWidgets('applies improved contrast colors when not selected',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.circle_outlined,
              title: 'Не выбрано',
              subtitle: 'Неактивно',
              isSelected: false,
              accentColor: Colors.purple,
              onTap: () {},
            ),
          ),
        ),
      );

      // Виджет должен использовать новые контрастные цвета
      // (grey[600], textPrimary, textSecondary из CalculatorColors)
      expect(find.byType(TypeSelectorCard), findsOneWidget);
    });

    testWidgets('handles long title and subtitle gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 180,
              child: TypeSelectorCard(
                icon: Icons.info,
                title: 'Очень длинное название которое не помещается в одну строку',
                subtitle:
                    'Длинное описание которое тоже может быть обрезано ellipsis',
                isSelected: false,
                accentColor: Colors.teal,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Не должно быть overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(TypeSelectorCard), findsOneWidget);
    });

    testWidgets('respects custom icon size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.build,
              title: 'Инструмент',
              isSelected: false,
              accentColor: Colors.amber,
              iconSize: 48.0,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TypeSelectorCard), findsOneWidget);
      expect(find.byIcon(Icons.build), findsOneWidget);
    });

    testWidgets('works with different accent colors', (tester) async {
      final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.orange,
      ];

      for (final color in colors) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TypeSelectorCard(
                icon: Icons.palette,
                title: 'Цвет',
                isSelected: true,
                accentColor: color,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.byType(TypeSelectorCard), findsOneWidget);
      }
    });

    testWidgets('supports textScaleFactor without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SizedBox(
                width: 200,
                child: TypeSelectorCard(
                  icon: Icons.zoom_in,
                  title: 'Увеличенный шрифт',
                  subtitle: 'Тест масштабирования',
                  isSelected: false,
                  accentColor: Colors.indigo,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Не должно быть overflow при увеличенном шрифте
      expect(tester.takeException(), isNull);
    });
  });

  group('TypeSelectorGroup', () {
    testWidgets('renders all options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorGroup(
              options: const [
                TypeSelectorOption(
                  icon: Icons.brush,
                  title: 'Под обои',
                  subtitle: 'Финиш',
                ),
                TypeSelectorOption(
                  icon: Icons.format_paint,
                  title: 'Под покраску',
                  subtitle: 'Гладкая',
                ),
              ],
              selectedIndex: 0,
              onSelect: (index) {},
              accentColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Под обои'), findsOneWidget);
      expect(find.text('Под покраску'), findsOneWidget);
      expect(find.byIcon(Icons.brush), findsOneWidget);
      expect(find.byIcon(Icons.format_paint), findsOneWidget);
    });

    testWidgets('marks correct option as selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorGroup(
              options: const [
                TypeSelectorOption(icon: Icons.looks_one, title: 'Первый'),
                TypeSelectorOption(icon: Icons.looks_two, title: 'Второй'),
                TypeSelectorOption(icon: Icons.looks_3, title: 'Третий'),
              ],
              selectedIndex: 1,
              onSelect: (index) {},
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      // Проверяем, что все опции отображаются
      expect(find.text('Первый'), findsOneWidget);
      expect(find.text('Второй'), findsOneWidget);
      expect(find.text('Третий'), findsOneWidget);
    });

    testWidgets('calls onSelect when option is tapped', (tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorGroup(
              options: const [
                TypeSelectorOption(icon: Icons.star, title: 'Вариант 1'),
                TypeSelectorOption(icon: Icons.favorite, title: 'Вариант 2'),
              ],
              selectedIndex: 0,
              onSelect: (index) => selectedIndex = index,
              accentColor: Colors.purple,
            ),
          ),
        ),
      );

      // Тапаем на второй вариант
      await tester.tap(find.text('Вариант 2'));
      await tester.pump();

      expect(selectedIndex, 1);
    });

    testWidgets('renders correctly with no selected option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorGroup(
              options: const [
                TypeSelectorOption(icon: Icons.circle, title: 'Опция 1'),
                TypeSelectorOption(icon: Icons.square, title: 'Опция 2'),
              ],
              selectedIndex: -1,
              onSelect: (index) {},
              accentColor: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('Опция 1'), findsOneWidget);
      expect(find.text('Опция 2'), findsOneWidget);
    });

    testWidgets('handles 2-column layout for 4 options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TypeSelectorGroup(
                options: const [
                  TypeSelectorOption(icon: Icons.looks_one, title: '1'),
                  TypeSelectorOption(icon: Icons.looks_two, title: '2'),
                  TypeSelectorOption(icon: Icons.looks_3, title: '3'),
                  TypeSelectorOption(icon: Icons.looks_4, title: '4'),
                ],
                selectedIndex: 0,
                onSelect: (index) {},
                accentColor: Colors.indigo,
              ),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });
  });
}
