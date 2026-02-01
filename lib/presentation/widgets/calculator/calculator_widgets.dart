/// Экспорт всех компонентов дизайн-системы калькуляторов
///
/// Удобный способ импортировать все необходимые компоненты одной строкой:
/// ```dart
/// import 'package:prorab/presentation/widgets/calculator/calculator_widgets.dart';
/// ```
///
/// ## Создание нового кастомного калькулятора
///
/// При создании нового калькулятора используйте следующие компоненты:
///
/// 1. **CalculatorScaffold** - основной контейнер экрана
/// 2. **CalculatorResultHeader** - шапка с основными результатами
/// 3. **MaterialsCardModern** - карточка материалов (ОБЯЗАТЕЛЬНО для списков)
/// 4. **InputGroup** - группа полей ввода
/// 5. **CalculatorTextField** - поле ввода числа
///
/// ### Пример карточки материалов:
/// ```dart
/// MaterialsCardModern(
///   title: 'Материалы',
///   titleIcon: Icons.construction,
///   items: [
///     MaterialItem(name: 'Плитка', value: '120 шт', icon: Icons.grid_on),
///     MaterialItem(name: 'Клей', value: '5 меш.', subtitle: '25 кг', icon: Icons.shopping_bag),
///   ],
///   accentColor: CalculatorColors.interior,
/// )
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
export 'calculator_slider_field.dart';
export 'dynamic_list.dart';

// Компоненты для результатов
// Включает: ResultCard, ResultCardLight, MaterialsCardModern, MaterialItem
export 'result_card.dart';

// Полезные советы
// Включает: TipsCard, TipsSection
export 'tips_card.dart';

// Кнопка добавления в проект
// На вебе используется заглушка без Isar-зависимостей
// dart.library.io существует на нативных платформах (Android, iOS, desktop)
export 'add_to_project_button_stub.dart'
    if (dart.library.io) 'add_to_project_button.dart';

// Константы
export '../../../core/constants/calculator_colors.dart';
export '../../../core/constants/calculator_design_system.dart';
