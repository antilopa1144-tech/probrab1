# Мастерок

**Калькулятор строительных материалов** для Android.

## О проекте

**Мастерок** — мобильное приложение для расчёта строительных материалов. Создано для строителей, прорабов и тех, кто делает ремонт своими руками.

### Возможности

- **54 калькулятора** по категориям:
  - Фундамент (2 калькулятора)
  - Внутренняя отделка (42 калькулятора) — стены, полы, потолки, перегородки, утепление, смеси
  - Наружная отделка (6 калькуляторов)
  - Инженерные работы (4 калькулятора)

- **Дополнительные функции**:
  - Чек-листы для ремонта
  - Конвертер единиц измерения
  - Избранные калькуляторы
  - История расчётов
  - Генерация PDF-отчётов

- **Интерфейс**:
  - Material You 3 дизайн
  - Тёмная и светлая темы
  - Работа офлайн

## Установка и запуск

### Требования

- Flutter SDK >= 3.10.0
- Dart >= 3.0.0
- Android Studio

### Клонирование и запуск

```bash
git clone https://github.com/antilopa1144-tech/probrab1.git
cd probrab1
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Сборка APK

```bash
# APK
flutter build apk --release

# App Bundle для RuStore/Google Play
flutter build appbundle --release
```

## Архитектура

Проект использует **Clean Architecture** с **Riverpod** для управления состоянием.

```
lib/
├── core/           # Инфраструктура (темы, виджеты, константы)
├── data/           # Слой данных (модели, репозитории)
├── domain/         # Бизнес-логика (калькуляторы, use cases)
├── presentation/   # UI (экраны, компоненты, провайдеры)
└── main.dart
```

## Основные зависимости

| Пакет | Назначение |
|-------|------------|
| `flutter_riverpod` | State management |
| `isar_community` | Локальная БД |
| `pdf` | Генерация PDF |
| `firebase_core` | Firebase SDK |
| `firebase_analytics` | Аналитика |
| `google_mobile_ads` | Реклама |

## Тестирование

```bash
# Все тесты
flutter test

# С покрытием
flutter test --coverage
```

## Документация

- [ARCHITECTURE.md](ARCHITECTURE.md) — архитектура проекта
- [CALCULATORS_STRUCTURE.md](CALCULATORS_STRUCTURE.md) — структура калькуляторов
- [CALCULATOR_DEVELOPMENT_GUIDE.md](CALCULATOR_DEVELOPMENT_GUIDE.md) — как добавить новый калькулятор
- [CHANGELOG.md](CHANGELOG.md) — история изменений

## Лицензия

MIT License
