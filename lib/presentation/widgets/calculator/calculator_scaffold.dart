import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';

/// Базовый Scaffold для калькуляторов с эталонным дизайном
///
/// Автоматически создаёт структуру экрана:
/// - AppBar с цветным фоном
/// - Header с результатами (опционально)
/// - Прокручиваемое тело с полями ввода
/// - Стандартный фон
///
/// Пример использования:
/// ```dart
/// CalculatorScaffold(
///   title: 'Шпатлёвка',
///   accentColor: CalculatorColors.interior,
///   resultHeader: CalculatorResultHeader(
///     accentColor: CalculatorColors.interior,
///     results: [
///       ResultItem(label: 'ПЛОЩАДЬ', value: '35.9 м²'),
///       ResultItem(label: 'СТАРТ', value: '2 мешков'),
///     ],
///   ),
///   children: [
///     InputGroup(title: 'Геометрия', children: [...]),
///     SizedBox(height: 16),
///     InputGroup(title: 'Проемы', children: [...]),
///   ],
/// )
/// ```
class CalculatorScaffold extends StatelessWidget {
  /// Заголовок в AppBar
  final String title;

  /// Акцентный цвет (используется для AppBar)
  final Color accentColor;

  /// Header с результатами (опционально)
  final Widget? resultHeader;

  /// Список виджетов в теле экрана
  final List<Widget> children;

  /// Показывать ли кнопку "Назад"
  final bool showBackButton;

  /// Actions для AppBar
  final List<Widget>? actions;

  /// Padding для тела экрана
  final EdgeInsets? bodyPadding;

  /// Floating Action Button
  final Widget? floatingActionButton;

  /// Bottom Navigation Bar
  final Widget? bottomNavigationBar;

  const CalculatorScaffold({
    super.key,
    required this.title,
    required this.accentColor,
    this.resultHeader,
    required this.children,
    this.showBackButton = true,
    this.actions,
    this.bodyPadding,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth >= CalculatorDesignSystem.breakpointTablet;
    final maxWidth = CalculatorDesignSystem.getMaxContentWidth(screenWidth);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget bodyContent = Column(
      children: [
        // Header с результатами (если указан)
        if (resultHeader != null) resultHeader!,

        // Тело с прокруткой
        Expanded(
          child: SingleChildScrollView(
            padding: bodyPadding ?? CalculatorDesignSystem.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );

    // На широких экранах центрируем контент с ограничением ширины
    if (isWideScreen) {
      bodyContent = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: bodyContent,
        ),
      );
    }

    return Scaffold(
      backgroundColor: CalculatorColors.getBackgroundPrimary(isDark),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
        actions: actions,
      ),
      body: bodyContent,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Минимальная версия Scaffold без header
class CalculatorScaffoldSimple extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<Widget> children;
  final List<Widget>? actions;
  final EdgeInsets? bodyPadding;

  const CalculatorScaffoldSimple({
    super.key,
    required this.title,
    required this.accentColor,
    required this.children,
    this.actions,
    this.bodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: title,
      accentColor: accentColor,
      actions: actions,
      bodyPadding: bodyPadding,
      children: children,
    );
  }
}
