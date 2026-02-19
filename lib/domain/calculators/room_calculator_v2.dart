import '../../core/enums/calculator_category.dart';
import '../models/calculator_definition_v2.dart';
import '../usecases/calculate_room.dart';

/// Мета-калькулятор "Комната".
///
/// Позволяет задать размеры комнаты один раз и получить
/// сводный расчёт материалов для всех выбранных видов работ:
/// штукатурка, шпаклёвка, покраска, обои, ламинат, плитка, потолок.
///
/// Использует кастомный экран [RoomCalculatorScreen].
/// Поля намеренно пустые — UI формируется кастомным экраном.
final roomCalculatorV2 = CalculatorDefinitionV2(
  id: 'room',
  titleKey: 'calculator.room.title',
  descriptionKey: 'calculator.room.description',
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.room',
  fields: const [], // Кастомный экран — поля не нужны
  useCase: CalculateRoom(),
  iconName: 'meeting_room',
  complexity: 3,
  popularity: 95,
  tags: const ['комната', 'ремонт', 'комплексный', 'полный расчёт'],
);
