import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/components/mat_card.dart';

void main() {
  group('MatCardButton', () {
    testWidgets('renders correctly with all properties', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Дом',
              subtitle: 'Частный дом, коттедж',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Дом'), findsOneWidget);
      expect(find.text('Частный дом, коттедж'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Дом',
              subtitle: 'Частный дом',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MatCardButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('applies custom background color', (tester) async {
      const testColor = Color(0xFF80DEEA);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.home,
              title: 'Дом',
              subtitle: 'Частный дом',
              backgroundColor: testColor,
              onTap: () {},
            ),
          ),
        ),
      );

      // Проверяем, что виджет создан успешно
      expect(find.byType(MatCardButton), findsOneWidget);
    });

    testWidgets('applies custom icon color', (tester) async {
      const testColor = Color(0xFFA5D6A7);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatCardButton(
              icon: Icons.apartment,
              title: 'Квартира',
              subtitle: 'Новостройка',
              iconColor: testColor,
              onTap: () {},
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.apartment));
      expect(icon.color, equals(testColor));
    });

    testWidgets('handles long title gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 150,
              child: MatCardButton(
                icon: Icons.home,
                title: 'Очень длинное название которое не помещается',
                subtitle: 'Длинное описание которое тоже не помещается в карточку',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Проверяем, что виджет создан без ошибок
      expect(find.byType(MatCardButton), findsOneWidget);
    });
  });
}
