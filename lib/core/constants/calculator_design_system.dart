import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

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

  // === ТИПОГРАФИКА (из AppTypography) ===

  static const headlineLarge = AppTypography.headlineLarge;
  static const headlineMedium = AppTypography.headlineMedium;
  static const titleLarge = AppTypography.titleLarge;
  static const titleMedium = AppTypography.titleMedium;
  static const titleSmall = AppTypography.titleSmall;
  static const bodyLarge = AppTypography.bodyLarge;
  static const bodyMedium = AppTypography.bodyMedium;
  static const bodySmall = AppTypography.bodySmall;
  static const labelLarge = AppTypography.labelLarge;
  static const labelMedium = AppTypography.labelMedium;
  static const labelSmall = AppTypography.labelSmall;
  static const headerLabel = AppTypography.headerLabel;
  static const headerValue = AppTypography.headerValue;

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
    final c = AppColors.of(context);
    return BoxDecoration(
      color: color ?? c.cardBackground,
      borderRadius: cardBorderRadius,
      boxShadow: [
        BoxShadow(
          color: c.shadowColorMedium,
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
    final c = AppColors.of(context);
    return BoxDecoration(
      color: color ?? c.cardBackground,
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
    final c = AppColors.resolve(isDark);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor ?? c.inputBackground,
      border: OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: isDark
            ? BorderSide(color: c.borderDefault, width: 1)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(
          color: c.borderFocused,
          width: borderWidthMedium,
        ),
      ),
      contentPadding: inputPadding,
      labelStyle: TextStyle(
        fontSize: 14,
        color: c.textSecondary,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: c.textSecondary,
      ),
      hintStyle: TextStyle(
        fontSize: 14,
        color: c.textSecondary.withValues(alpha: 0.7),
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
