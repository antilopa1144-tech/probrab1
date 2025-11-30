# 📂 Индекс новых файлов

## 🏗️ Архитектура (7 файлов)

### Константы
1. `lib/core/constants/app_constants.dart`
2. `lib/core/constants/material_constants.dart`
3. `lib/core/constants/region_constants.dart`

### Enum'ы
4. `lib/core/enums/unit_type.dart`
5. `lib/core/enums/work_type.dart`
6. `lib/core/enums/material_type.dart`
7. `lib/core/enums/calculator_category.dart`

## 🚨 Обработка ошибок (8 файлов)

### Исключения
8. `lib/core/exceptions/app_exception.dart`
9. `lib/core/exceptions/validation_exception.dart`
10. `lib/core/exceptions/calculation_exception.dart`
11. `lib/core/exceptions/storage_exception.dart`
12. `lib/core/exceptions/network_exception.dart`
13. `lib/core/exceptions/export_exception.dart`

### Обработчики
14. `lib/core/errors/error_category.dart`
15. `lib/core/errors/global_error_handler.dart`

## 🧮 Калькуляторы V2 (5 файлов)

### Модели
16. `lib/domain/models/calculator_field.dart`
17. `lib/domain/models/calculator_hint.dart`
18. `lib/domain/models/calculator_definition_v2.dart`

### Примеры и реестр
19. `lib/domain/calculators/paint_calculator_v2.dart`
20. `lib/domain/calculators/calculator_registry.dart`

## ✅ Валидация (2 файла)

21. `lib/core/validation/field_validator.dart`
22. `lib/core/validation/input_sanitizer.dart`

## 🎨 UI компоненты (2 файла)

23. `lib/presentation/widgets/hint_card.dart`
24. `lib/presentation/widgets/result_card.dart`

## 📱 UI экраны (3 файла)

25. `lib/presentation/views/calculator/universal_calculator_v2_screen.dart`
26. `lib/presentation/views/project/projects_list_screen.dart`
27. `lib/presentation/views/project/project_details_screen.dart`

## 💾 Проекты и БД (4 файла)

### Модели
28. `lib/domain/models/project_v2.dart`
29. `lib/domain/models/project_v2.g.dart` (сгенерирован)

### Репозиторий и Provider
30. `lib/data/repositories/project_repository_v2.dart`
31. `lib/presentation/providers/project_v2_provider.dart`

## 📤 Экспорт (2 файла)

32. `lib/domain/models/export_data.dart`
33. `lib/domain/services/csv_export_service.dart`

## 🌍 Локализация (2 файла)

34. `assets/lang/ru.json`
35. `assets/lang/en.json`

## 📄 Документация (2 файла)

36. `REFACTORING_SUMMARY.md`
37. `NEW_FILES_INDEX.md` (этот файл)

---

## 📊 Итого

- **Всего новых файлов**: 37
- **Обновлено файлов**: 4 (main.dart, constants.dart, theme.dart, project_v2.dart)
- **Сгенерировано**: 1 (project_v2.g.dart)

---

## 🔍 Быстрый поиск

### По функциональности:

**Константы и enum'ы:**
- Файлы 1-7

**Обработка ошибок:**
- Файлы 8-15

**Калькуляторы:**
- Файлы 16-20

**Валидация:**
- Файлы 21-22

**UI виджеты:**
- Файлы 23-24

**UI экраны:**
- Файлы 25-27

**База данных:**
- Файлы 28-31

**Экспорт:**
- Файлы 32-33

**Переводы:**
- Файлы 34-35

---

## 💡 Ключевые файлы для старта

1. **REFACTORING_SUMMARY.md** - начните отсюда
2. **lib/core/errors/global_error_handler.dart** - обработка ошибок
3. **lib/domain/models/calculator_definition_v2.dart** - новая модель
4. **lib/domain/calculators/paint_calculator_v2.dart** - пример
5. **lib/data/repositories/project_repository_v2.dart** - работа с БД
6. **lib/presentation/views/calculator/universal_calculator_v2_screen.dart** - универсальный калькулятор
7. **lib/presentation/views/project/projects_list_screen.dart** - список проектов
8. **lib/presentation/views/project/project_details_screen.dart** - детали проекта

---

**Создано**: 30 ноября 2025
