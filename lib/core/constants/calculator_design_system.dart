import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'calculator_colors.dart';

/// Константы дизайн-системы для калькуляторов
///
/// Основано на эталонном дизайне калькулятора "Шпатлёвка"
class CalculatorDesignSystem {
  // === RESPONSIVE BREAKPOINTS ===

  /// Максимальная ширина контента для мобильного вида
  static const maxContentWidthMobile = 480.0;

  /// Максимальная ширина контента для планшета
  static const maxContentWidthTablet = 600.0;

  /// Максимальная ширина контента для десктопа
  static const maxContentWidthDesktop = 800.0;

  /// Breakpoint для планшета
  static const breakpointTablet = 600.0;

  /// Breakpoint для десктопа
  static const breakpointDesktop = 1024.0;

  /// Получить максимальную ширину контента в зависимости от ширины экрана
  static double getMaxContentWidth(double screenWidth) {
    if (screenWidth >= breakpointDesktop) {
      return maxContentWidthDesktop;
    } else if (screenWidth >= breakpointTablet) {
      return maxContentWidthTablet;
    }
    return double.infinity; // На мобильных - без ограничений
  }

  /// Является ли текущий экран широким (веб/десктоп)
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointTablet;
  }

  /// Обёртка для адаптивного контента (центрирует на широких экранах)
  static Widget responsiveWrapper({
    required Widget child,
    required BuildContext context,
    double? maxWidth,
  }) {
    if (!kIsWeb) return child;

    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveMaxWidth = maxWidth ?? getMaxContentWidth(screenWidth);

    if (screenWidth <= effectiveMaxWidth) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }

  // === ТИПОГРАФИКА ===

  /// Заголовки экранов
  static const headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Заголовки секций
  static const titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Основной текст
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Метки и подписи
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Текст в результатах header (верхняя панель)
  static const headerLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  );

  static const headerValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  // === ОТСТУПЫ ===

  static const spacingXS = 4.0;
  static const spacingS = 8.0;
  static const spacingM = 16.0;
  static const spacingL = 24.0;
  static const spacingXL = 32.0;
  static const spacingXXL = 40.0;

  // === РАДИУСЫ СКРУГЛЕНИЯ ===

  static const radiusXS = 4.0;
  static const radiusS = 8.0;
  static const radiusM = 12.0;
  static const radiusL = 16.0;
  static const radiusXL = 20.0;
  static const radiusXXL = 24.0;

  /// Радиус для header с результатами (округлённый снизу)
  static const headerBorderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(radiusXXL),
    bottomRight: Radius.circular(radiusXXL),
  );

  /// Радиус для карточек
  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusL);

  /// Радиус для полей ввода
  static BorderRadius get inputBorderRadius => BorderRadius.circular(radiusS);

  /// Радиус для карточек выбора типа
  static BorderRadius get selectorBorderRadius => BorderRadius.circular(radiusM);

  // === РАЗМЕРЫ ===

  /// Высота полей ввода
  static const inputHeight = 48.0;

  /// Высота кнопок
  static const buttonHeight = 48.0;
  static const buttonHeightSmall = 36.0;

  /// Толщина границ
  static const borderWidthThin = 1.0;
  static const borderWidthMedium = 2.0;

  /// Размеры иконок
  static const iconSizeSmall = 16.0;
  static const iconSizeMedium = 24.0;
  static const iconSizeLarge = 32.0;

  // === PADDING ===

  /// Padding для карточек
  static const cardPadding = EdgeInsets.all(spacingM);
  static const cardPaddingLarge = EdgeInsets.all(spacingL);

  /// Padding для экрана
  static const screenPadding = EdgeInsets.all(spacingM);
  static const screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: spacingM);
  static const screenPaddingVertical = EdgeInsets.symmetric(vertical: spacingM);

  /// Padding для полей ввода
  static const inputPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  /// Padding для секций
  static const sectionPadding = EdgeInsets.symmetric(
    vertical: spacingM,
  );

  // === ДЕКОРАЦИИ ===

  /// Декорация для карточки с тенью
  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: cardBorderRadius,
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.05),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  );

  /// Декорация для карточки с автоопределением темы
  static BoxDecoration cardDecorationThemed(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? CalculatorColors.getCardBackground(isDark),
      borderRadius: cardBorderRadius,
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, isDark ? 0.3 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Декорация для карточки без тени
  static BoxDecoration cardDecorationFlat({Color? color, Color? borderColor}) => BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: cardBorderRadius,
    border: borderColor != null ? Border.all(color: borderColor) : null,
  );

  /// Декорация для карточки без тени с автоопределением темы
  static BoxDecoration cardDecorationFlatThemed(BuildContext context, {Color? color, Color? borderColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? CalculatorColors.getCardBackground(isDark),
      borderRadius: cardBorderRadius,
      border: borderColor != null ? Border.all(color: borderColor) : null,
    );
  }

  /// Декорация для поля ввода (светлая тема по умолчанию)
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
    Color? fillColor,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: fillColor ?? const Color(0xFFF1F5F9),
    border: OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: inputBorderRadius,
      borderSide: const BorderSide(
        color: Color(0xFF94A3B8),
        width: borderWidthMedium,
      ),
    ),
    contentPadding: inputPadding,
    labelStyle: const TextStyle(
      fontSize: 14,
      color: Color(0xFF64748B),
    ),
    floatingLabelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF64748B),
    ),
  );

  /// Декорация для поля ввода с поддержкой тёмной темы
  static InputDecoration inputDecorationThemed({
    required String label,
    required bool isDark,
    String? hint,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    final defaultFillColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF1F5F9);
    final labelColor = isDark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF64748B);
    final focusBorderColor = isDark
        ? const Color(0xFF6A6A6A)
        : const Color(0xFF94A3B8);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor ?? defaultFillColor,
      border: OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: isDark
            ? const BorderSide(color: Color(0xFF3A3A3A), width: 1)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(
          color: focusBorderColor,
          width: borderWidthMedium,
        ),
      ),
      contentPadding: inputPadding,
      labelStyle: TextStyle(
        fontSize: 14,
        color: labelColor,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: labelColor,
      ),
      hintStyle: TextStyle(
        fontSize: 14,
        color: labelColor.withValues(alpha: 0.7),
      ),
    );
  }

  // === АНИМАЦИИ ===

  static const animationDurationFast = Duration(milliseconds: 150);
  static const animationDurationMedium = Duration(milliseconds: 250);
  static const animationDurationSlow = Duration(milliseconds: 350);

  static const animationCurve = Curves.easeInOut;
  static const animationCurveFastOut = Curves.easeOut;
  static const animationCurveSlowIn = Curves.easeIn;

  // === ХЕЛПЕРЫ ===

  /// Создать разделитель между элементами
  static Widget get verticalSpacingS => const SizedBox(height: spacingS);
  static Widget get verticalSpacingM => const SizedBox(height: spacingM);
  static Widget get verticalSpacingL => const SizedBox(height: spacingL);
  static Widget get verticalSpacingXL => const SizedBox(height: spacingXL);

  static Widget get horizontalSpacingS => const SizedBox(width: spacingS);
  static Widget get horizontalSpacingM => const SizedBox(width: spacingM);
  static Widget get horizontalSpacingL => const SizedBox(width: spacingL);

  /// Создать Divider с стандартным стилем
  static Widget divider({double? height, Color? color}) => Divider(
    height: height ?? spacingL,
    color: color ?? const Color(0xFFE2E8F0),
    thickness: 1,
  );
}
