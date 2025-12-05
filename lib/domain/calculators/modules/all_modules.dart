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

// В будущем здесь будут экспортированы другие модули:
// export 'walls/wall_calculators.dart';
// export 'floors/floor_calculators.dart';
// export 'exterior/exterior_calculators.dart';
// export 'mix/mix_calculators.dart';
// export 'windows_doors/windows_doors_calculators.dart';
// export 'structure/structure_calculators.dart';
