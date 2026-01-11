import 'checklist.dart';

/// Шаблон чек-листа с предопределенными задачами
class ChecklistTemplate {
  /// ID шаблона
  final String id;

  /// Название шаблона
  final String name;

  /// Описание шаблона
  final String description;

  /// Категория
  final ChecklistCategory category;

  /// Элементы шаблона
  final List<ChecklistTemplateItem> items;

  const ChecklistTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.items,
  });

  /// Создать чек-лист из шаблона
  RenovationChecklist toChecklist({int? projectId}) {
    return RenovationChecklist()
      ..name = name
      ..description = description
      ..category = category
      ..projectId = projectId
      ..isFromTemplate = true
      ..templateId = id
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }

  /// Создать элементы чек-листа из шаблона
  List<ChecklistItem> createItems() {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final templateItem = entry.value;

      return ChecklistItem()
        ..title = templateItem.title
        ..description = templateItem.description
        ..isCompleted = false
        ..order = index
        ..priority = templateItem.priority
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
    }).toList();
  }
}

/// Элемент шаблона чек-листа
class ChecklistTemplateItem {
  final String title;
  final String? description;
  final ChecklistPriority priority;

  const ChecklistTemplateItem({
    required this.title,
    this.description,
    this.priority = ChecklistPriority.normal,
  });
}

/// Предопределенные шаблоны чек-листов
class ChecklistTemplates {
  /// Все доступные шаблоны
  static List<ChecklistTemplate> get all => [
        roomRenovation,
        bathroomRenovation,
        kitchenRenovation,
        livingRoomRenovation,
        generalRenovation,
      ];

  /// Шаблон: Ремонт комнаты
  static ChecklistTemplate get roomRenovation => const ChecklistTemplate(
        id: 'room_renovation',
        name: 'Ремонт комнаты',
        description: 'Базовый чек-лист для ремонта спальни или детской комнаты',
        category: ChecklistCategory.room,
        items: [
          ChecklistTemplateItem(
            title: 'Освобождение помещения',
            description: 'Вынести мебель, снять шторы, демонтировать светильники',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Демонтаж старого покрытия',
            description: 'Снять обои, удалить старую краску',
          ),
          ChecklistTemplateItem(
            title: 'Электромонтажные работы',
            description: 'Провести новую проводку, установить розетки и выключатели',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Выравнивание стен',
            description: 'Штукатурка и шпаклевка стен',
          ),
          ChecklistTemplateItem(
            title: 'Грунтовка стен',
            description: 'Нанести грунтовку перед финишной отделкой',
          ),
          ChecklistTemplateItem(
            title: 'Ремонт потолка',
            description: 'Выравнивание, покраска или монтаж натяжного потолка',
          ),
          ChecklistTemplateItem(
            title: 'Напольное покрытие',
            description: 'Стяжка, утепление, укладка ламината/паркета',
          ),
          ChecklistTemplateItem(
            title: 'Финишная отделка стен',
            description: 'Поклейка обоев или покраска',
          ),
          ChecklistTemplateItem(
            title: 'Установка плинтусов',
            description: 'Монтаж напольных и потолочных плинтусов',
          ),
          ChecklistTemplateItem(
            title: 'Установка дверей',
            description: 'Монтаж межкомнатных дверей с фурнитурой',
          ),
          ChecklistTemplateItem(
            title: 'Установка светильников',
            description: 'Повесить люстру, установить бра',
          ),
          ChecklistTemplateItem(
            title: 'Уборка помещения',
            description: 'Генеральная уборка после ремонта',
          ),
        ],
      );

  /// Шаблон: Ремонт ванной комнаты
  static ChecklistTemplate get bathroomRenovation => const ChecklistTemplate(
        id: 'bathroom_renovation',
        name: 'Ремонт ванной комнаты',
        description: 'Полный чек-лист для ремонта ванной с учетом гидроизоляции и сантехники',
        category: ChecklistCategory.bathroom,
        items: [
          ChecklistTemplateItem(
            title: 'Демонтаж сантехники',
            description: 'Снять ванну, раковину, унитаз, полотенцесушитель',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Демонтаж старой плитки',
            description: 'Удалить старую плитку со стен и пола',
          ),
          ChecklistTemplateItem(
            title: 'Прокладка труб',
            description: 'Разводка водопровода и канализации',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Электромонтаж',
            description: 'Проводка, розетки (влагозащищенные), вентиляция',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Выравнивание стен',
            description: 'Штукатурка стен под плитку',
          ),
          ChecklistTemplateItem(
            title: 'Гидроизоляция',
            description: 'Нанести гидроизоляцию на пол и нижнюю часть стен',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Стяжка пола',
            description: 'Выравнивание пола под плитку',
          ),
          ChecklistTemplateItem(
            title: 'Укладка плитки на пол',
            description: 'Напольная плитка с учетом уклона к сливу',
          ),
          ChecklistTemplateItem(
            title: 'Укладка плитки на стены',
            description: 'Настенная плитка с декоративными элементами',
          ),
          ChecklistTemplateItem(
            title: 'Затирка швов',
            description: 'Затирка плитки влагостойкой затиркой',
          ),
          ChecklistTemplateItem(
            title: 'Монтаж сантехники',
            description: 'Установка ванны, раковины, унитаза, смесителей',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Установка зеркала и аксессуаров',
            description: 'Повесить зеркало, полки, крючки',
          ),
          ChecklistTemplateItem(
            title: 'Монтаж натяжного потолка',
            description: 'Установка влагостойкого потолка',
          ),
          ChecklistTemplateItem(
            title: 'Уборка и проверка',
            description: 'Уборка, проверка сантехники на протечки',
          ),
        ],
      );

  /// Шаблон: Ремонт кухни
  static ChecklistTemplate get kitchenRenovation => const ChecklistTemplate(
        id: 'kitchen_renovation',
        name: 'Ремонт кухни',
        description: 'Чек-лист для ремонта кухни с учетом коммуникаций и кухонного гарнитура',
        category: ChecklistCategory.kitchen,
        items: [
          ChecklistTemplateItem(
            title: 'Демонтаж старого гарнитура',
            description: 'Разобрать и вывезти старую кухню',
          ),
          ChecklistTemplateItem(
            title: 'Демонтаж плитки (фартук)',
            description: 'Снять старую плитку с рабочей зоны',
          ),
          ChecklistTemplateItem(
            title: 'Разводка коммуникаций',
            description: 'Водопровод, канализация, газ (если требуется)',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Электрика',
            description: 'Усиленная проводка для бытовой техники, розетки, освещение',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Вентиляция',
            description: 'Установка вытяжки, воздуховод',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Выравнивание стен',
            description: 'Штукатурка и шпаклевка стен',
          ),
          ChecklistTemplateItem(
            title: 'Стяжка пола',
            description: 'Выравнивание пола',
          ),
          ChecklistTemplateItem(
            title: 'Напольное покрытие',
            description: 'Укладка плитки или линолеума',
          ),
          ChecklistTemplateItem(
            title: 'Финишная отделка стен',
            description: 'Покраска или обои',
          ),
          ChecklistTemplateItem(
            title: 'Укладка фартука',
            description: 'Плитка или стеклянный фартук в рабочей зоне',
          ),
          ChecklistTemplateItem(
            title: 'Монтаж потолка',
            description: 'Натяжной или подвесной потолок',
          ),
          ChecklistTemplateItem(
            title: 'Установка кухонного гарнитура',
            description: 'Сборка и монтаж мебели',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Подключение техники',
            description: 'Установка и подключение плиты, холодильника, посудомойки',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Установка столешницы и мойки',
            description: 'Монтаж столешницы, врезка мойки, смеситель',
          ),
          ChecklistTemplateItem(
            title: 'Уборка и проверка',
            description: 'Генеральная уборка, проверка всех коммуникаций',
          ),
        ],
      );

  /// Шаблон: Ремонт гостиной
  static ChecklistTemplate get livingRoomRenovation => const ChecklistTemplate(
        id: 'living_room_renovation',
        name: 'Ремонт гостиной',
        description: 'Чек-лист для ремонта гостиной комнаты',
        category: ChecklistCategory.livingRoom,
        items: [
          ChecklistTemplateItem(
            title: 'Освобождение помещения',
            description: 'Вынести мебель и технику',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Демонтаж старого покрытия',
            description: 'Снять обои, удалить старую краску',
          ),
          ChecklistTemplateItem(
            title: 'Электромонтажные работы',
            description: 'Проводка для телевизора, освещения, дополнительные розетки',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Выравнивание стен',
            description: 'Штукатурка и шпаклевка',
          ),
          ChecklistTemplateItem(
            title: 'Монтаж потолка',
            description: 'Натяжной или многоуровневый потолок с подсветкой',
          ),
          ChecklistTemplateItem(
            title: 'Напольное покрытие',
            description: 'Стяжка, утепление, укладка паркета/ламината',
          ),
          ChecklistTemplateItem(
            title: 'Финишная отделка стен',
            description: 'Обои, декоративная штукатурка или покраска',
          ),
          ChecklistTemplateItem(
            title: 'Декоративные элементы',
            description: 'Молдинги, декоративные панели, акцентная стена',
          ),
          ChecklistTemplateItem(
            title: 'Плинтусы и наличники',
            description: 'Установка напольных и потолочных плинтусов',
          ),
          ChecklistTemplateItem(
            title: 'Освещение',
            description: 'Люстра, точечные светильники, бра',
          ),
          ChecklistTemplateItem(
            title: 'Уборка помещения',
            description: 'Генеральная уборка',
          ),
        ],
      );

  /// Шаблон: Общий ремонт квартиры
  static ChecklistTemplate get generalRenovation => const ChecklistTemplate(
        id: 'general_renovation',
        name: 'Общий ремонт квартиры',
        description: 'Полный чек-лист для комплексного ремонта всей квартиры',
        category: ChecklistCategory.general,
        items: [
          ChecklistTemplateItem(
            title: 'Разработка дизайн-проекта',
            description: 'Планировка, подбор материалов, смета',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Получение разрешений',
            description: 'Согласование перепланировки (если требуется)',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Демонтажные работы',
            description: 'Снос перегородок, демонтаж старой отделки',
          ),
          ChecklistTemplateItem(
            title: 'Возведение перегородок',
            description: 'Строительство новых стен по проекту',
          ),
          ChecklistTemplateItem(
            title: 'Замена окон',
            description: 'Установка новых окон и балконных блоков',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Сантехнические работы',
            description: 'Разводка труб водопровода и канализации',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Электромонтажные работы',
            description: 'Прокладка проводки, установка щитка, розетки, выключатели',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Стяжка полов',
            description: 'Выравнивание полов во всех помещениях',
          ),
          ChecklistTemplateItem(
            title: 'Штукатурка стен',
            description: 'Выравнивание стен',
          ),
          ChecklistTemplateItem(
            title: 'Монтаж потолков',
            description: 'Натяжные или подвесные потолки',
          ),
          ChecklistTemplateItem(
            title: 'Укладка напольных покрытий',
            description: 'Плитка, ламинат, паркет в разных комнатах',
          ),
          ChecklistTemplateItem(
            title: 'Укладка плитки',
            description: 'Плитка в ванной, туалете, на кухне (пол и стены)',
          ),
          ChecklistTemplateItem(
            title: 'Финишная отделка стен',
            description: 'Обои, покраска во всех комнатах',
          ),
          ChecklistTemplateItem(
            title: 'Установка дверей',
            description: 'Входная и межкомнатные двери',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Установка сантехники',
            description: 'Ванна, унитазы, раковины, смесители',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Установка кухонного гарнитура',
            description: 'Сборка и монтаж кухни',
            priority: ChecklistPriority.high,
          ),
          ChecklistTemplateItem(
            title: 'Установка встроенной техники',
            description: 'Духовка, посудомойка, холодильник',
          ),
          ChecklistTemplateItem(
            title: 'Плинтусы и наличники',
            description: 'Установка по всей квартире',
          ),
          ChecklistTemplateItem(
            title: 'Освещение',
            description: 'Люстры, бра, точечные светильники',
          ),
          ChecklistTemplateItem(
            title: 'Финальная уборка',
            description: 'Генеральная уборка после ремонта',
          ),
        ],
      );

  /// Найти шаблон по ID
  static ChecklistTemplate? findById(String id) {
    try {
      return all.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить шаблоны по категории
  static List<ChecklistTemplate> getByCategory(ChecklistCategory category) {
    return all.where((template) => template.category == category).toList();
  }
}
