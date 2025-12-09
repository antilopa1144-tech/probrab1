# 🏗️ АРХИТЕКТУРА ПРОЕКТА "ПРОРАБ AI"

## 📋 Оглавление

1. [Обзор архитектуры](#обзор-архитектуры)
2. [Структура проекта](#структура-проекта)
3. [Слои приложения](#слои-приложения)
4. [Паттерны проектирования](#паттерны-проектирования)
5. [State Management](#state-management)
6. [Работа с данными](#работа-с-данными)
7. [Калькуляторы](#калькуляторы)
8. [Обработка ошибок](#обработка-ошибок)
9. [Тестирование](#тестирование)

---

## 🎯 Обзор архитектуры

Проект использует **Clean Architecture** с разделением на три основных слоя:

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│  (UI, Widgets, Providers)           │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Domain Layer                  │
│  (Entities, Use Cases, Business)    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        Data Layer                   │
│  (Repositories, Data Sources)      │
└─────────────────────────────────────┘
```

### Принципы

- **Разделение ответственности**: Каждый слой имеет чётко определённую роль
- **Инверсия зависимостей**: Domain не зависит от Data и Presentation
- **Тестируемость**: Бизнес-логика изолирована от UI и данных
- **Расширяемость**: Легко добавлять новые калькуляторы и функции

---

## 📁 Структура проекта

```
lib/
├── core/                    # Ядро приложения
│   ├── animations/         # Анимации переходов
│   ├── constants.dart      # Константы
│   ├── errors/             # Обработка ошибок
│   ├── localization/       # Локализация
│   ├── theme.dart          # Темы Material You 3
│   └── widgets/            # Переиспользуемые виджеты
│
├── domain/                 # Бизнес-логика
│   ├── calculators/        # Определения калькуляторов
│   ├── entities/           # Доменные сущности
│   └── usecases/           # Use cases (калькуляторы)
│
├── data/                   # Работа с данными
│   ├── datasources/        # Источники данных
│   ├── models/             # Модели данных (Isar)
│   └── repositories/        # Репозитории
│
└── presentation/           # UI слой
    ├── app/                # Главные экраны
    ├── components/         # UI компоненты
    ├── providers/          # Riverpod провайдеры
    ├── services/          # Сервисы (PDF и т.д.)
    └── views/              # Экраны приложения
```

---

## 🏛️ Слои приложения

### 1. Domain Layer (Бизнес-логика)

**Назначение**: Содержит бизнес-логику приложения, независимую от UI и данных.

#### Entities
Доменные сущности, описывающие бизнес-объекты:
- `Project` - проект пользователя
- `FoundationResult` - результат расчёта фундамента
- `MaterialComparison` - сравнение материалов
- И другие...

#### Use Cases
Бизнес-операции, реализующие конкретные сценарии:
- `CalculatePlaster` - расчёт штукатурки
- `CalculateTile` - расчёт плитки
- `CalculateScreed` - расчёт стяжки
- И ещё 50+ калькуляторов...

**Интерфейс Use Case:**
```dart
abstract class CalculatorUseCase {
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  );
}
```

#### Calculators Definitions
Метаданные для калькуляторов:
- `CalculatorDefinition` - описание калькулятора
- `InputFieldDefinition` - описание поля ввода
- `calculators` - список всех калькуляторов

### 2. Data Layer (Работа с данными)

**Назначение**: Управление данными (локальное хранение, загрузка).

#### Data Sources
- `LocalPriceDataSource` - загрузка цен из JSON файлов
- В будущем: `RemotePriceDataSource` - загрузка из API

#### Models
Модели данных для Isar (база данных):
- `ProjectModel` - модель проекта
- `CalculationModel` - модель расчёта
- `PriceItem` - элемент прайс-листа

#### Repositories
Абстракция над источниками данных:
- `ProjectRepository` - работа с проектами
- `PriceRepository` - работа с ценами (с кешированием)
- `CalculationRepository` - работа с расчётами

### 3. Presentation Layer (UI)

**Назначение**: Пользовательский интерфейс и управление состоянием.

#### Providers (Riverpod)
Управление состоянием:
- `priceProvider` - список цен
- `projectProvider` - проекты пользователя
- `settingsProvider` - настройки приложения
- И другие...

#### Views
Экраны приложения:
- `UniversalCalculatorV2Screen` - универсальный экран калькулятора (второе поколение)
- `ProjectHistoryScreen` - история проектов
- `SettingsPage` - настройки
- И другие...

#### Components
Переиспользуемые UI компоненты:
- `MatCard` - карточка Material Design
- `ModernCard` - современная карточка
- `GlassmorphismContainer` - эффект стекла
- И другие...

---

## 🎨 Паттерны проектирования

### 1. Repository Pattern
Абстракция над источниками данных:
```dart
class PriceRepository {
  Future<List<PriceItem>> getPrices(String region);
  void clearCache([String? region]);
}
```

### 2. Use Case Pattern
Изолированная бизнес-логика:
```dart
class CalculatePlaster implements CalculatorUseCase {
  @override
  CalculatorResult call(Map<String, double> inputs, List<PriceItem> priceList) {
    // Логика расчёта
  }
}
```

### 3. Provider Pattern (Riverpod)
Управление состоянием:
```dart
final priceListProvider = FutureProvider<List<PriceItem>>((ref) async {
  // Загрузка данных
});
```

### 4. Factory Pattern
Создание калькуляторов:
```dart
static Widget? fromId(String calculatorId) {
  final definition = CalculatorRegistry.getById(calculatorId);
  return definition != null
      ? UniversalCalculatorV2Screen(definition: definition)
      : null;
}
```

### 5. Strategy Pattern
Разные алгоритмы расчёта через единый интерфейс:
```dart
abstract class CalculatorUseCase {
  CalculatorResult call(...);
}
```

---

## 🔄 State Management

### Riverpod 2.6.1

Проект использует **Riverpod** для управления состоянием.

#### Типы провайдеров:

1. **Provider** - простые значения
```dart
final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepository(LocalPriceDataSource());
});
```

2. **FutureProvider** - асинхронные данные
```dart
final priceListProvider = FutureProvider<List<PriceItem>>((ref) async {
  final region = ref.watch(regionProvider);
  return await repo.getPrices(region);
});
```

3. **StateNotifierProvider** - изменяемое состояние
```dart
final projectProvider = StateNotifierProvider<ProjectNotifier, AsyncValue<List<Project>>>((ref) {
  return ProjectNotifier(ref.watch(projectRepositoryProvider));
});
```

#### Использование в виджетах:
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prices = ref.watch(priceListProvider);
    return prices.when(
      data: (prices) => Text('${prices.length} items'),
      loading: () => CircularProgressIndicator(),
      error: (e, s) => Text('Error: $e'),
    );
  }
}
```

---

## 💾 Работа с данными

### Локальное хранение

#### Isar Database
Быстрая NoSQL база данных для локального хранения:
- Проекты пользователя
- История расчётов
- Настройки

**Пример:**
```dart
class ProjectRepository {
  Future<void> saveProject(Project project) async {
    final db = await _getDb();
    final model = ProjectModel.fromDomain(project);
    await db.writeTxn(() async {
      await db.projectModels.put(model);
    });
  }
}
```

#### SharedPreferences
Простые настройки:
- Тёмная тема
- Язык интерфейса
- Режим (Новичок/Профи)

### Кеширование

#### PriceRepository с кешированием
```dart
class PriceRepository {
  final Map<String, List<PriceItem>> _cache = {};
  static const Duration _cacheLifetime = Duration(hours: 1);
  
  Future<List<PriceItem>> getPrices(String region) async {
    // Проверка кеша
    if (_cache.containsKey(code)) {
      return _cache[code]!;
    }
    // Загрузка и сохранение в кеш
  }
}
```

---

## 🧮 Калькуляторы

### Архитектура калькулятора

Каждый калькулятор:
1. Реализует интерфейс `CalculatorUseCase`
2. Принимает `Map<String, double>` входных данных
3. Принимает `List<PriceItem>` прайс-лист
4. Возвращает `CalculatorResult`

### Пример калькулятора

```dart
class CalculatePlaster implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 10.0;
    
    // Расчёт
    final plasterNeeded = area * consumption * thickness * 1.1;
    
    // Поиск цены
    final price = _findPrice(priceList, ['plaster']);
    final totalPrice = price != null ? plasterNeeded * price.price : null;
    
    return CalculatorResult(
      values: {'plasterNeeded': plasterNeeded},
      totalPrice: totalPrice,
    );
  }
}
```

### Универсальный экран

`UniversalCalculatorV2Screen` динамически строит форму из `CalculatorDefinitionV2`:
- Автоматически создаёт поля ввода
- Валидирует данные
- Выполняет расчёт
- Показывает результаты

---

## ⚠️ Обработка ошибок

### ErrorHandler

Централизованная обработка ошибок:

```dart
class ErrorHandler {
  // Категоризация ошибок
  static ErrorCategory getErrorCategory(Object error);
  
  // Понятные сообщения для пользователя
  static String getUserFriendlyMessage(Object error);
  
  // Логирование с категоризацией
  static void logError(Object error, StackTrace? stackTrace, String? context);
  
  // Критические ошибки
  static void logFatalError(Object error, StackTrace stackTrace, String? context);
}
```

### Категории ошибок

- `network` - сетевые ошибки
- `database` - ошибки БД
- `parsing` - ошибки парсинга
- `fileSystem` - ошибки файловой системы
- `validation` - ошибки валидации
- `unknown` - неизвестные ошибки

### Использование

```dart
try {
  // операция
} catch (e, stackTrace) {
  ErrorHandler.logError(e, stackTrace, 'Context');
  final message = ErrorHandler.getUserFriendlyMessage(e);
  // показать пользователю
}
```

---

## 🧪 Тестирование

### Структура тестов

```
test/
└── domain/
    └── usecases/
        ├── calculate_plaster_test.dart
        ├── calculate_tile_test.dart
        ├── calculate_screed_test.dart
        └── ...
```

### Пример теста

```dart
void main() {
  group('CalculatePlaster', () {
    test('calculates plaster needed correctly', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 100.0, 'thickness': 10.0};
      final result = calculator(inputs, []);
      
      expect(result.values['plasterNeeded'], closeTo(935, 10));
    });
  });
}
```

### Покрытие тестами

- **Текущее**: ~10% (5 тестов из 55 калькуляторов)
- **Целевое**: 60-70%

---

## 🔧 Настройка и конфигурация

### Зависимости

Основные пакеты:
- `flutter_riverpod: ^2.6.1` - state management
- `isar: ^3.1.0+1` - локальная БД
- `intl: ^0.20.2` - локализация
- `pdf: ^3.11.3` - генерация PDF

### Локализация

Файлы локализации в `assets/lang/`:
- Поддержка нескольких языков
- Динамическое переключение

### Темы

Material You 3:
- Светлая и тёмная темы
- Настраиваемый акцентный цвет
- Адаптивные цвета

---

## 🚀 Расширение проекта

### Добавление нового калькулятора

1. Создать use case в `lib/domain/usecases/`:
```dart
class CalculateNewMaterial implements CalculatorUseCase {
  @override
  CalculatorResult call(...) { ... }
}
```

2. Добавить определение в `lib/domain/calculators/definitions.dart`:
```dart
CalculatorDefinition(
  id: 'calculator.new_material',
  titleKey: 'calculator.new_material.title',
  fields: [...],
  resultLabels: {...},
  useCase: CalculateNewMaterial(),
  category: 'Категория',
  subCategory: 'Подкатегория',
  tips: ['Совет 1', 'Совет 2'],
)
```

3. Добавить тесты в `test/domain/usecases/`

### Добавление нового экрана

1. Создать виджет в `lib/presentation/views/`
2. Добавить провайдеры при необходимости
3. Добавить навигацию в `lib/presentation/app/`

---

## 📚 Дополнительные ресурсы

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Isar Documentation](https://isar.dev)
- [Material You 3](https://m3.material.io)

---

**Последнее обновление**: 2025-01-XX
