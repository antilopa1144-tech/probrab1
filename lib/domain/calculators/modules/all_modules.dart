/// Централизованный экспорт всех модулей калькуляторов
///
/// Этот файл служит точкой входа для всех модульных калькуляторов.
/// Каждый модуль содержит калькуляторы для определённой категории работ.
library;

// Фундаменты
export 'foundation/foundation_calculators.dart';

// Перегородки
export 'partitions/partition_calculators.dart';

// Утепление
export 'insulation/insulation_calculators.dart';

// Ванная / туалет
export 'bathroom/bathroom_calculators.dart';

// Потолки
export 'ceilings/ceiling_calculators.dart';

// Кровля
export 'roofing/roofing_calculators.dart';

// Инженерные работы
export 'engineering/engineering_calculators.dart';

// Смеси и ровнители
export 'mix/mix_calculators.dart';

// Окна и двери
export 'windows_doors/windows_doors_calculators.dart';

// Стены
export 'walls/wall_calculators.dart';

// Полы
export 'floors/floor_calculators.dart';

// Наружная отделка
export 'exterior/exterior_calculators.dart';

// Конструкции
export 'structure/structure_calculators.dart';
