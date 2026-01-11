import 'package:isar_community/isar.dart';

part 'checklist.g.dart';

/// Чек-лист для отслеживания этапов ремонта
@collection
class RenovationChecklist {
  /// ID чек-листа
  Id id = Isar.autoIncrement;

  /// Название чек-листа
  @Index()
  late String name;

  /// Описание чек-листа
  String? description;

  /// Категория чек-листа (комната, ванная, кухня, общий)
  @Index()
  @Enumerated(EnumType.name)
  late ChecklistCategory category;

  /// ID проекта, к которому привязан чек-лист (null = автономный)
  @Index()
  int? projectId;

  /// Создан ли из шаблона
  bool isFromTemplate = false;

  /// ID шаблона (если создан из шаблона)
  String? templateId;

  /// Дата создания
  @Index()
  late DateTime createdAt;

  /// Дата последнего обновления
  late DateTime updatedAt;

  /// Элементы чек-листа
  final items = IsarLinks<ChecklistItem>();

  // ============================================================================
  // Вычисляемые свойства (не сохраняются в БД)
  // ============================================================================

  /// Общее количество элементов
  @ignore
  int get totalItems => items.length;

  /// Количество выполненных элементов
  @ignore
  int get completedItems => items.where((item) => item.isCompleted).length;

  /// Прогресс выполнения (0.0 - 1.0)
  @ignore
  double get progress {
    if (totalItems == 0) return 0.0;
    return completedItems / totalItems;
  }

  /// Процент выполнения (0-100)
  @ignore
  int get progressPercent => (progress * 100).round();

  /// Завершён ли чек-лист полностью
  @ignore
  bool get isCompleted => totalItems > 0 && completedItems == totalItems;

  /// Начат ли чек-лист (есть хотя бы один выполненный элемент)
  @ignore
  bool get isStarted => completedItems > 0;

  @override
  String toString() => 'RenovationChecklist($name, $progressPercent%)';
}

/// Элемент чек-листа
@collection
class ChecklistItem {
  /// ID элемента
  Id id = Isar.autoIncrement;

  /// Название задачи
  late String title;

  /// Описание/заметки
  String? description;

  /// Выполнен ли элемент
  @Index()
  bool isCompleted = false;

  /// Порядковый номер в чек-листе
  @Index()
  late int order;

  /// Важность элемента
  @Enumerated(EnumType.ordinal)
  ChecklistPriority priority = ChecklistPriority.normal;

  /// Дата создания
  late DateTime createdAt;

  /// Дата выполнения (null если не выполнен)
  DateTime? completedAt;

  /// Дата последнего обновления
  late DateTime updatedAt;

  /// Чек-лист, к которому принадлежит элемент
  @Backlink(to: 'items')
  final checklist = IsarLink<RenovationChecklist>();

  @override
  String toString() => 'ChecklistItem($title, completed: $isCompleted)';
}

/// Категории чек-листов
enum ChecklistCategory {
  /// Общий ремонт
  general,

  /// Комната/спальня
  room,

  /// Ванная комната
  bathroom,

  /// Кухня
  kitchen,

  /// Гостиная
  livingRoom,

  /// Прихожая
  hallway,

  /// Балкон
  balcony,

  /// Фасад
  facade,
}

/// Приоритет элемента чек-листа
enum ChecklistPriority {
  /// Низкий приоритет
  low,

  /// Обычный приоритет
  normal,

  /// Высокий приоритет
  high,
}

/// Расширение для работы с категориями
extension ChecklistCategoryExtension on ChecklistCategory {
  /// Название категории для UI
  String get displayName {
    switch (this) {
      case ChecklistCategory.general:
        return 'Общий ремонт';
      case ChecklistCategory.room:
        return 'Комната';
      case ChecklistCategory.bathroom:
        return 'Ванная';
      case ChecklistCategory.kitchen:
        return 'Кухня';
      case ChecklistCategory.livingRoom:
        return 'Гостиная';
      case ChecklistCategory.hallway:
        return 'Прихожая';
      case ChecklistCategory.balcony:
        return 'Балкон';
      case ChecklistCategory.facade:
        return 'Фасад';
    }
  }

  /// Иконка категории
  String get icon {
    switch (this) {
      case ChecklistCategory.general:
        return '🏠';
      case ChecklistCategory.room:
        return '🛏️';
      case ChecklistCategory.bathroom:
        return '🚿';
      case ChecklistCategory.kitchen:
        return '🍳';
      case ChecklistCategory.livingRoom:
        return '🛋️';
      case ChecklistCategory.hallway:
        return '🚪';
      case ChecklistCategory.balcony:
        return '🪴';
      case ChecklistCategory.facade:
        return '🏛️';
    }
  }
}

/// Расширение для работы с приоритетами
extension ChecklistPriorityExtension on ChecklistPriority {
  /// Название приоритета
  String get displayName {
    switch (this) {
      case ChecklistPriority.low:
        return 'Низкий';
      case ChecklistPriority.normal:
        return 'Обычный';
      case ChecklistPriority.high:
        return 'Высокий';
    }
  }

  /// Иконка приоритета
  String get icon {
    switch (this) {
      case ChecklistPriority.low:
        return '⬇️';
      case ChecklistPriority.normal:
        return '➡️';
      case ChecklistPriority.high:
        return '⬆️';
    }
  }
}
