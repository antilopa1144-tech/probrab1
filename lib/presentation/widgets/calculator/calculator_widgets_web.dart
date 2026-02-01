/// Веб-версия экспорта компонентов дизайн-системы калькуляторов
/// Без зависимостей от Isar (add_to_project_button отключён)
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

// Кнопка добавления в проект - ОТКЛЮЧЕНА на вебе (Isar зависимости)
// export 'add_to_project_button.dart';

// Константы
export '../../../core/constants/calculator_colors.dart';
export '../../../core/constants/calculator_design_system.dart';
