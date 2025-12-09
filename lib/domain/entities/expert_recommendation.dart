/// Экспертная рекомендация для типа работ.
class ExpertRecommendation {
  final String workType;
  final String title;
  final String description;
  final RecommendationLevel level;
  final List<String> commonMistakes;
  final List<String> bestPractices;
  final List<String> tools;
  final List<String> materials;

  const ExpertRecommendation({
    required this.workType,
    required this.title,
    required this.description,
    required this.level,
    this.commonMistakes = const [],
    this.bestPractices = const [],
    this.tools = const [],
    this.materials = const [],
  });
}

enum RecommendationLevel {
  beginner, // для новичков
  intermediate, // средний уровень
  advanced, // для опытных
  expert, // для профессионалов
}

/// База экспертных рекомендаций.
class ExpertRecommendationsDatabase {
  static List<ExpertRecommendation> getRecommendations(String workType) {
    final all = _getAllRecommendations();
    return all.where((r) => 
      r.workType.toLowerCase().contains(workType.toLowerCase()) ||
      workType.toLowerCase().contains(r.workType.toLowerCase())
    ).toList();
  }

  static List<ExpertRecommendation> _getAllRecommendations() {
    return [
      const ExpertRecommendation(
        workType: 'покраска',
        title: 'Покраска стен и потолков',
        description: 'Профессиональные советы по покраске',
        level: RecommendationLevel.beginner,
        commonMistakes: const [
          'Покраска без грунтовки приводит к неравномерному впитыванию',
          'Слишком толстый слой краски создаёт подтёки',
          'Игнорирование подготовки поверхности',
        ],
        bestPractices: const [
          'Всегда используйте грунтовку для улучшения адгезии',
          'Наносите краску тонкими слоями (2-3 слоя лучше чем 1 толстый)',
          'Используйте качественные валики и кисти',
          'Красьте при хорошем освещении для контроля качества',
        ],
        tools: const ['Валик', 'Кисти', 'Кювета', 'Малярный скотч', 'Плёнка'],
        materials: const ['Краска', 'Грунтовка', 'Шпаклёвка'],
      ),
      const ExpertRecommendation(
        workType: 'плитка',
        title: 'Укладка плитки',
        description: 'Секреты качественной укладки плитки',
        level: RecommendationLevel.intermediate,
        commonMistakes: const [
          'Неровное основание приводит к трещинам',
          'Неправильный выбор клея для типа плитки',
          'Игнорирование температурных швов',
        ],
        bestPractices: const [
          'Основание должно быть ровным (перепад не более 3 мм)',
          'Используйте уровень для каждого ряда',
          'Начинайте укладку от центра комнаты',
          'Используйте крестики для равномерных швов',
        ],
        tools: const ['Зубчатый шпатель', 'Уровень', 'Крестики', 'Плиткорез'],
        materials: const ['Плитка', 'Клей', 'Затирка'],
      ),
      const ExpertRecommendation(
        workType: 'стяжка',
        title: 'Заливка стяжки',
        description: 'Правильная заливка стяжки пола',
        level: RecommendationLevel.intermediate,
        commonMistakes: const [
          'Заливка на неподготовленное основание',
          'Игнорирование маяков',
          'Слишком быстрое высыхание',
        ],
        bestPractices: const [
          'Используйте маяки для контроля толщины',
          'Выдержите стяжку минимум 7 дней перед нагрузкой',
          'Защитите от сквозняков и прямых солнечных лучей',
          'Проверьте уровень перед заливкой',
        ],
        tools: const ['Маяки', 'Правило', 'Уровень', 'Игольчатый валик'],
        materials: const ['Цемент', 'Песок', 'Вода'],
      ),
      const ExpertRecommendation(
        workType: 'обои',
        title: 'Поклейка обоев',
        description: 'Как правильно клеить обои',
        level: RecommendationLevel.beginner,
        commonMistakes: const [
          'Неправильный подбор клея',
          'Игнорирование раппорта рисунка',
          'Поклейка на неровные стены',
        ],
        bestPractices: const [
          'Используйте лазерный уровень для первой полосы',
          'Проверьте совпадение рисунка перед поклейкой',
          'Добавьте 10% к площади для подрезки',
          'Клейте от окна к двери',
        ],
        tools: const ['Валик', 'Кисть', 'Резиновый валик', 'Нож', 'Уровень'],
        materials: const ['Обои', 'Клей'],
      ),
    ];
  }
}

// ignore_for_file: unnecessary_const
