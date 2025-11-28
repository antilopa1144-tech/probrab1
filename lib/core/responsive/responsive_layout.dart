import 'package:flutter/material.dart';

/// Утилиты для адаптивного дизайна под разные размеры экранов.
/// 
/// Поддерживает:
/// - Телефоны (< 600dp)
/// - Планшеты (600-900dp)
/// - Большие планшеты / Десктоп (> 900dp)

/// Типы устройств по ширине экрана
enum DeviceType {
  phone,
  tablet,
  desktop,
}

/// Класс для определения размеров и точек перехода
class ResponsiveBreakpoints {
  static const double phoneMaxWidth = 600;
  static const double tabletMaxWidth = 900;

  /// Определить тип устройства по ширине
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneMaxWidth) return DeviceType.phone;
    if (width < tabletMaxWidth) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Проверка: телефон?
  static bool isPhone(BuildContext context) {
    return getDeviceType(context) == DeviceType.phone;
  }

  /// Проверка: планшет?
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Проверка: десктоп?
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Проверка: планшет или десктоп?
  static bool isTabletOrLarger(BuildContext context) {
    return !isPhone(context);
  }
}

/// Виджет для адаптивного макета
/// 
/// Автоматически выбирает layout в зависимости от размера экрана
class ResponsiveLayout extends StatelessWidget {
  /// Layout для телефонов (обязательный)
  final Widget phone;
  
  /// Layout для планшетов (опциональный, по умолчанию = phone)
  final Widget? tablet;
  
  /// Layout для десктопа (опциональный, по умолчанию = tablet ?? phone)
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tabletMaxWidth) {
          return desktop ?? tablet ?? phone;
        }
        if (constraints.maxWidth >= ResponsiveBreakpoints.phoneMaxWidth) {
          return tablet ?? phone;
        }
        return phone;
      },
    );
  }
}

/// Виджет-обёртка для адаптивной сетки
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: _getAspectRatio(constraints.maxWidth),
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width >= ResponsiveBreakpoints.tabletMaxWidth) return 4;
    if (width >= ResponsiveBreakpoints.phoneMaxWidth) return 3;
    return 2;
  }

  double _getAspectRatio(double width) {
    if (width >= ResponsiveBreakpoints.tabletMaxWidth) return 1.1;
    if (width >= ResponsiveBreakpoints.phoneMaxWidth) return 1.0;
    return 0.95;
  }
}

/// Адаптивный padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? phonePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.phonePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  static const EdgeInsets defaultPhonePadding = EdgeInsets.all(16);
  static const EdgeInsets defaultTabletPadding = EdgeInsets.all(24);
  static const EdgeInsets defaultDesktopPadding = EdgeInsets.all(32);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _getPadding(context),
      child: child,
    );
  }

  EdgeInsets _getPadding(BuildContext context) {
    final deviceType = ResponsiveBreakpoints.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return phonePadding ?? defaultPhonePadding;
      case DeviceType.tablet:
        return tabletPadding ?? defaultTabletPadding;
      case DeviceType.desktop:
        return desktopPadding ?? defaultDesktopPadding;
    }
  }
}

/// Адаптивное ограничение ширины контента
class ResponsiveConstrainedBox extends StatelessWidget {
  final Widget child;
  final double? phoneMaxWidth;
  final double? tabletMaxWidth;
  final double? desktopMaxWidth;

  const ResponsiveConstrainedBox({
    super.key,
    required this.child,
    this.phoneMaxWidth,
    this.tabletMaxWidth = 700,
    this.desktopMaxWidth = 900,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _getMaxWidth(context),
        ),
        child: child,
      ),
    );
  }

  double _getMaxWidth(BuildContext context) {
    final deviceType = ResponsiveBreakpoints.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return phoneMaxWidth ?? double.infinity;
      case DeviceType.tablet:
        return tabletMaxWidth ?? double.infinity;
      case DeviceType.desktop:
        return desktopMaxWidth ?? double.infinity;
    }
  }
}

/// Адаптивный размер текста
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? phoneSize;
  final double? tabletSize;
  final double? desktopSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.phoneSize,
    this.tabletSize,
    this.desktopSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final fontSize = _getFontSize(context);

    return Text(
      text,
      style: baseStyle?.copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  double? _getFontSize(BuildContext context) {
    final deviceType = ResponsiveBreakpoints.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return phoneSize;
      case DeviceType.tablet:
        return tabletSize ?? (phoneSize != null ? phoneSize! * 1.1 : null);
      case DeviceType.desktop:
        return desktopSize ?? (phoneSize != null ? phoneSize! * 1.2 : null);
    }
  }
}

/// Расширения для удобства использования
extension ResponsiveContext on BuildContext {
  /// Тип устройства
  DeviceType get deviceType => ResponsiveBreakpoints.getDeviceType(this);
  
  /// Телефон?
  bool get isPhone => ResponsiveBreakpoints.isPhone(this);
  
  /// Планшет?
  bool get isTablet => ResponsiveBreakpoints.isTablet(this);
  
  /// Десктоп?
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(this);
  
  /// Планшет или больше?
  bool get isTabletOrLarger => ResponsiveBreakpoints.isTabletOrLarger(this);
  
  /// Ширина экрана
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Высота экрана
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Ориентация
  Orientation get orientation => MediaQuery.of(this).orientation;
  
  /// Горизонтальная ориентация?
  bool get isLandscape => orientation == Orientation.landscape;
  
  /// Вертикальная ориентация?
  bool get isPortrait => orientation == Orientation.portrait;
}

/// Вспомогательные методы для размеров
class ResponsiveSizes {
  /// Получить адаптивный размер
  static double get(
    BuildContext context, {
    required double phone,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = ResponsiveBreakpoints.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return phone;
      case DeviceType.tablet:
        return tablet ?? phone * 1.2;
      case DeviceType.desktop:
        return desktop ?? tablet ?? phone * 1.4;
    }
  }

  /// Количество колонок для сетки
  static int getGridColumns(BuildContext context) {
    final deviceType = ResponsiveBreakpoints.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        return 4;
    }
  }

  /// Размер иконок
  static double getIconSize(BuildContext context) {
    return get(context, phone: 24, tablet: 28, desktop: 32);
  }

  /// Размер заголовка
  static double getTitleSize(BuildContext context) {
    return get(context, phone: 20, tablet: 24, desktop: 28);
  }

  /// Радиус скругления
  static double getBorderRadius(BuildContext context) {
    return get(context, phone: 16, tablet: 20, desktop: 24);
  }
}
