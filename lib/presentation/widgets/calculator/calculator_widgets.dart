/// Экспорт всех компонентов дизайн-системы калькуляторов
///
/// Удобный способ импортировать все необходимые компоненты одной строкой:
/// ```dart
/// import 'package:prorab/presentation/widgets/calculator/calculator_widgets.dart';
/// ```
library;

// Основные компоненты
export 'calculator_scaffold.dart';
export 'calculator_result_header.dart';
export 'type_selector_card.dart';
export 'input_group.dart';
export 'mode_selector.dart';

// Компоненты для ввода данных
export 'calculator_text_field.dart';
export 'dynamic_list.dart';

// Компоненты для результатов
export 'result_card.dart';

// Константы
export '../../../core/constants/calculator_colors.dart';
export '../../../core/constants/calculator_design_system.dart';
