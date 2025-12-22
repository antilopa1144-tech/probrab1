# 📋 ПОЛНЫЙ СПИСОК ИЗМЕНЕНИЙ ДЛЯ "ПРОРАБ AI"

> **Дата аудита:** 20 декабря 2025  
> **Версия проекта:** 1.0.0+1  
> **Общий объём кода:** ~51,580 строк Dart

---

# 🚨 ЧАСТЬ 1: КРИТИЧЕСКИЕ ПРОБЛЕМЫ (БЛОКЕРЫ РЕЛИЗА)

## 1.1 Сломанная локализация языков СНГ

### Проблема
Файлы локализации для языков СНГ практически пустые (28 строк из 1068 необходимых).

### Статистика
| Файл | Строк | Процент от ru.json |
|------|-------|-------------------|
| `assets/lang/ru.json` | 1068 | 100% ✅ |
| `assets/lang/en.json` | 530 | 49.6% ⚠️ |
| `assets/lang/kk.json` | 28 | 2.6% ❌ |
| `assets/lang/ky.json` | 28 | 2.6% ❌ |
| `assets/lang/tg.json` | 28 | 2.6% ❌ |
| `assets/lang/tk.json` | 28 | 2.6% ❌ |
| `assets/lang/uz.json` | 28 | 2.6% ❌ |

### Что нужно сделать

#### Шаг 1: Завершить en.json
```
Файл: assets/lang/en.json
Действие: Добавить ~538 недостающих ключей перевода
Приоритет: КРИТИЧЕСКИЙ
Оценка: 3-4 часа
```

#### Шаг 2: Создать полные переводы для СНГ
```
Файлы: assets/lang/kk.json, ky.json, tg.json, tk.json, uz.json
Действие: Перевести все 1068 ключей
Метод: AI-перевод (DeepL/Google) + ручная проверка носителем
Приоритет: КРИТИЧЕСКИЙ
Оценка: 8-12 часов на все языки
```

#### Шаг 3: Реализовать fallback-цепочку
```dart
// Файл: lib/core/localization/app_localizations.dart
// Добавить fallback: kk → ru → en

String translate(String key) {
  // Сначала ищем в текущей локали
  var value = _localizedStrings[key];
  if (value != null && value.isNotEmpty) return value;
  
  // Fallback на русский для СНГ языков
  if (['kk', 'ky', 'tg', 'tk', 'uz'].contains(_locale.languageCode)) {
    value = _fallbackStrings['ru']?[key];
    if (value != null && value.isNotEmpty) return value;
  }
  
  // Fallback на английский
  value = _fallbackStrings['en']?[key];
  if (value != null && value.isNotEmpty) return value;
  
  // Возвращаем ключ если ничего не найдено
  return key;
}
```

---

## 1.2 Захардкоженные русские строки в коде

### Проблема
Найдено **88+ мест** с русским текстом прямо в Dart-коде, что ломает локализацию.

### Полный список файлов для исправления

#### 1.2.1 Категории в каталоге калькуляторов
```
Файл: lib/presentation/views/calculator/modern_calculator_catalog_screen.dart
Строки: 27-33

БЫЛО:
final List<Map<String, String>> categories = [
  {'id': 'all', 'label': 'Все'},
  {'id': 'walls', 'label': 'Стены'},
  {'id': 'floor', 'label': 'Пол'},
  {'id': 'finish', 'label': 'Отделка'},
  {'id': 'wood', 'label': 'Дерево'},
];

НУЖНО:
final List<Map<String, String>> categories = [
  {'id': 'all', 'labelKey': 'category.all'},
  {'id': 'walls', 'labelKey': 'category.walls'},
  {'id': 'floor', 'labelKey': 'category.floor'},
  {'id': 'finish', 'labelKey': 'category.finish'},
  {'id': 'wood', 'labelKey': 'category.wood'},
];

// И в build методе:
Text(_loc.translate(category['labelKey']!))
```

#### 1.2.2 Туториал калькулятора
```
Файл: lib/presentation/widgets/calculator_tutorial.dart
Строка: 62

БЫЛО:
title: 'Нажмите "Рассчитать"',

НУЖНО:
title: _loc.translate('tutorial.press_calculate'),

// Добавить в ru.json:
"tutorial.press_calculate": "Нажмите \"Рассчитать\""
// Добавить в en.json:
"tutorial.press_calculate": "Press \"Calculate\""
```

#### 1.2.3 Поиск на главной
```
Файл: lib/presentation/app/home_main.dart
Строка: 204

БЫЛО:
'Попробуйте другой запрос. Например: "бетон", "обои", "плитка"'

НУЖНО:
_loc.translate('search.try_another_query')

// Добавить в ru.json:
"search.try_another_query": "Попробуйте другой запрос. Например: \"бетон\", \"обои\", \"плитка\""
```

#### 1.2.4 Ошибка "калькулятор не найден"
```
Файл: lib/presentation/utils/calculator_navigation_helper.dart
Строка: 127

БЫЛО:
SnackBar(content: Text('Калькулятор "$calculatorId" не найден'))

НУЖНО:
SnackBar(content: Text(_loc.translate('error.calculator_not_found', {'id': calculatorId})))

// С поддержкой параметров в переводе
```

#### 1.2.5 Заголовки типов подсказок
```
Файл: lib/presentation/widgets/hint_card.dart
Строки: 103-109

БЫЛО:
String _getTitleForType(HintType type) {
  return switch (type) {
    HintType.info => 'Информация',
    HintType.warning => 'Внимание',
    HintType.tip => 'Совет мастера',
    HintType.important => 'Важно',
  };
}

НУЖНО:
String _getTitleForType(HintType type, AppLocalizations loc) {
  return switch (type) {
    HintType.info => loc.translate('hint.type.info'),
    HintType.warning => loc.translate('hint.type.warning'),
    HintType.tip => loc.translate('hint.type.tip'),
    HintType.important => loc.translate('hint.type.important'),
  };
}
```

#### 1.2.6 Единицы измерения в результатах
```
Файл: lib/presentation/views/calculator/pro_calculator_screen.dart
Строки: 450-457

БЫЛО:
String _getUnit(String resultKey) {
  if (resultKey.contains('Kg') || resultKey.contains('kg')) return 'кг';
  if (resultKey.contains('Liter') || resultKey.contains('liter')) return 'л';
  if (resultKey.contains('Area') || resultKey.contains('area')) return 'м²';
  if (resultKey.contains('Size') || resultKey.contains('size')) return 'мм';
  return '';
}

НУЖНО:
String _getUnit(String resultKey) {
  if (resultKey.contains('Kg') || resultKey.contains('kg')) return _loc.translate('unit.kg');
  if (resultKey.contains('Liter') || resultKey.contains('liter')) return _loc.translate('unit.liter');
  if (resultKey.contains('Area') || resultKey.contains('area')) return _loc.translate('unit.sqm');
  if (resultKey.contains('Size') || resultKey.contains('size')) return _loc.translate('unit.mm');
  return '';
}
```

#### 1.2.7 Режим ввода в калькуляторах
```
Файл: lib/presentation/views/calculator/universal_calculator_v2_screen.dart
Строки: 399-401

БЫЛО:
if (inputMode == 0) { // "По размерам"
} else { // "По площади"
}

НУЖНО:
// Комментарии на русском OK, но если есть UI текст - локализовать
```

#### 1.2.8 Шпатлёвка — подписи материалов
```
Файл: lib/presentation/views/calculator/putty_calculator_screen.dart
Строки: 36, 522

БЫЛО:
final String finishPackName; // "мешков" или "ведер"
"Финиш (${_finishType == FinishMaterialType.dryBag ? 'Сухой' : 'Паста'})"

НУЖНО:
final String finishPackNameKey; // 'unit.bags' или 'unit.buckets'
_loc.translate('putty.finish_type', {
  'type': _loc.translate(_finishType == FinishMaterialType.dryBag 
    ? 'material.dry' 
    : 'material.paste')
})
```

#### 1.2.9 Подсказка при пустых результатах
```
Файл: lib/presentation/views/improved_smart_project_page.dart
Строка: 313

БЫЛО:
const Text('Нажмите "Рассчитать" для получения результатов')

НУЖНО:
Text(_loc.translate('smart_project.press_calculate_hint'))
```

---

## 1.3 Захардкоженные subCategory в калькуляторах

### Проблема
59 калькуляторов имеют `subCategory` на русском языке.

### Полный список файлов

```
lib/domain/calculators/migrated_calculators_v2.dart:
  Строка 78:   subCategory: 'Мансарда'
  Строка 184:  subCategory: 'Балкон / Лоджия'
  Строка 272:  subCategory: 'Ванная / туалет'
  Строка 359:  subCategory: 'Ванная / туалет'
  Строка 409:  subCategory: 'Потолки'
  Строка 457:  subCategory: 'Потолки'
  Строка 523:  subCategory: 'Потолки'
  Строка 580:  subCategory: 'Потолки'
  Строка 637:  subCategory: 'Потолки'
  Строка 694:  subCategory: 'Потолки'
  Строка 742:  subCategory: 'Окна / двери'
  Строка 799:  subCategory: 'Электрика'
  Строка 875:  subCategory: 'Отопление'
  Строка 940:  subCategory: 'Сантехника'
  Строка 999:  subCategory: 'Вентиляция'
  Строка 1056: subCategory: 'Облицовочный кирпич'
  Строка 1142: subCategory: 'Фасадные панели'
  Строка 1209: subCategory: 'Сайдинг'
  Строка 1307: subCategory: 'Мокрый фасад'
  Строка 1367: subCategory: 'Дерево'
  Строка 1433: subCategory: 'Заборы'
  Строка 1512: subCategory: 'Полы'
  Строка 1562: subCategory: 'Полы'
  Строка 1623: subCategory: 'Полы'
  Строка 1688: subCategory: 'Полы'
  Строка 1754: subCategory: 'Полы'
  Строка 1811: subCategory: 'Полы'
  Строка 1876: subCategory: 'Полы'
  Строка 1927: subCategory: 'Полы'
  Строка 2003: subCategory: 'Полы'
  Строка 2079: subCategory: 'Цокольный этаж'
  ... и ещё ~28 мест

lib/domain/calculators/screed_calculator_v2.dart:16:     subCategory: 'Полы'
lib/domain/calculators/gkl_wall_calculator_v2.dart:23:   subCategory: 'Стены'
lib/domain/calculators/laminate_calculator_v2.dart:16:   subCategory: 'Полы'
lib/domain/calculators/linoleum_calculator_v2.dart:22:   subCategory: 'Полы'
lib/domain/calculators/tile_calculator_v2.dart:16:       subCategory: 'Полы'
lib/domain/calculators/concrete_universal_calculator_v2.dart:15: subCategory: 'Бетон'
lib/domain/calculators/plinth_calculator_v2.dart:14:     subCategory: 'Полы'
lib/domain/calculators/wallpaper_calculator_v2.dart:17:  subCategory: 'Стены'
lib/domain/calculators/sheeting_osb_plywood_calculator_v2.dart:14: subCategory: 'ОСБ/фанера'
```

### Решение

#### Шаг 1: Изменить модель CalculatorDefinitionV2
```dart
// Файл: lib/domain/models/calculator_definition_v2.dart

class CalculatorDefinitionV2 {
  // БЫЛО:
  final String subCategory;
  
  // НУЖНО:
  final String subCategoryKey;  // Ключ локализации
  
  // Геттер для получения переведённого названия
  String getSubCategory(AppLocalizations loc) {
    return loc.translate(subCategoryKey);
  }
}
```

#### Шаг 2: Обновить все определения калькуляторов
```dart
// БЫЛО:
subCategory: 'Полы',

// НУЖНО:
subCategoryKey: 'subcategory.floors',
```

#### Шаг 3: Добавить ключи в локализацию
```json
// assets/lang/ru.json
{
  "subcategory.floors": "Полы",
  "subcategory.walls": "Стены",
  "subcategory.ceilings": "Потолки",
  "subcategory.roofing": "Кровля",
  "subcategory.foundation": "Фундамент",
  "subcategory.facade": "Фасад",
  "subcategory.engineering": "Инженерия",
  "subcategory.bathroom": "Ванная / туалет",
  "subcategory.attic": "Мансарда",
  "subcategory.balcony": "Балкон / Лоджия",
  "subcategory.windows_doors": "Окна / двери",
  "subcategory.electrics": "Электрика",
  "subcategory.heating": "Отопление",
  "subcategory.plumbing": "Сантехника",
  "subcategory.ventilation": "Вентиляция",
  "subcategory.brick_facing": "Облицовочный кирпич",
  "subcategory.facade_panels": "Фасадные панели",
  "subcategory.siding": "Сайдинг",
  "subcategory.wet_facade": "Мокрый фасад",
  "subcategory.wood": "Дерево",
  "subcategory.fences": "Заборы",
  "subcategory.basement": "Цокольный этаж",
  "subcategory.concrete": "Бетон",
  "subcategory.osb_plywood": "ОСБ/фанера"
}
```

---

## 1.4 Файл-монстр migrated_calculators_v2.dart

### Проблема
Один файл содержит **3,936 строк** — это антипаттерн.

### Решение: Разбить на модули

```
lib/domain/calculators/
├── definitions/                      # НОВАЯ ПАПКА
│   ├── foundation_calculators.dart   # Фундамент (~300 строк)
│   ├── walls_calculators.dart        # Стены (~400 строк)
│   ├── flooring_calculators.dart     # Полы (~600 строк)
│   ├── ceiling_calculators.dart      # Потолки (~350 строк)
│   ├── roofing_calculators.dart      # Кровля (~300 строк)
│   ├── facade_calculators.dart       # Фасад (~400 строк)
│   ├── engineering_calculators.dart  # Инженерные системы (~500 строк)
│   ├── interior_calculators.dart     # Интерьер (~400 строк)
│   └── index.dart                    # Экспорт всех
├── calculator_registry.dart          # Обновить импорты
└── migrated_calculators_v2.dart      # УДАЛИТЬ после миграции
```

#### Пример foundation_calculators.dart:
```dart
// lib/domain/calculators/definitions/foundation_calculators.dart

import '../../../core/enums/calculator_category.dart';
import '../../../core/enums/field_input_type.dart';
import '../../../core/enums/unit_type.dart';
import '../../models/calculator_definition_v2.dart';
import '../../models/calculator_field.dart';
import '../../usecases/calculate_strip_foundation.dart';
import '../../usecases/calculate_slab.dart';
// ... другие импорты

/// Калькуляторы для фундамента
final List<CalculatorDefinitionV2> foundationCalculators = [
  // Ленточный фундамент
  CalculatorDefinitionV2(
    id: 'strip_foundation',
    titleKey: 'calculator.strip_foundation.title',
    descriptionKey: 'calculator.strip_foundation.description',
    category: CalculatorCategory.foundation,
    subCategoryKey: 'subcategory.strip',
    fields: [...],
    calculate: (inputs, prices) => CalculateStripFoundation().calculate(inputs, prices),
  ),
  
  // Плитный фундамент
  CalculatorDefinitionV2(
    id: 'slab_foundation',
    // ...
  ),
  
  // Свайный фундамент
  // ...
];
```

#### Обновлённый index.dart:
```dart
// lib/domain/calculators/definitions/index.dart

export 'foundation_calculators.dart';
export 'walls_calculators.dart';
export 'flooring_calculators.dart';
export 'ceiling_calculators.dart';
export 'roofing_calculators.dart';
export 'facade_calculators.dart';
export 'engineering_calculators.dart';
export 'interior_calculators.dart';
```

#### Обновлённый calculator_registry.dart:
```dart
// lib/domain/calculators/calculator_registry.dart

import 'definitions/index.dart';

class CalculatorRegistry {
  static List<CalculatorDefinitionV2> _buildAllCalculators() {
    return [
      ...foundationCalculators,
      ...wallsCalculators,
      ...flooringCalculators,
      ...ceilingCalculators,
      ...roofingCalculators,
      ...facadeCalculators,
      ...engineeringCalculators,
      ...interiorCalculators,
    ];
  }
}
```

---

# ⚠️ ЧАСТЬ 2: ВАЖНЫЕ ПРОБЛЕМЫ

## 2.1 Большие UI-файлы без декомпозиции

### Список файлов для рефакторинга

| Файл | Строк | Рекомендуемый размер |
|------|-------|---------------------|
| `project_details_screen.dart` | 1,133 | < 300 |
| `universal_calculator_v2_screen.dart` | 948 | < 300 |
| `new_home_screen.dart` | 915 | < 300 |
| `home_main.dart` | 810 | < 300 |
| `projects_list_screen.dart` | 790 | < 300 |
| `history_page.dart` | 673 | < 300 |
| `putty_calculator_screen.dart` | 591 | < 300 |
| `settings_page.dart` | 587 | < 300 |

### Пример декомпозиции project_details_screen.dart

```
lib/presentation/views/project/
├── project_details_screen.dart       # Основной экран (~200 строк)
├── widgets/
│   ├── project_header.dart           # Шапка проекта (~100 строк)
│   ├── project_calculations_list.dart # Список расчётов (~150 строк)
│   ├── project_summary_card.dart     # Итоговая карточка (~100 строк)
│   ├── project_actions_bar.dart      # Кнопки действий (~80 строк)
│   ├── project_notes_section.dart    # Секция заметок (~100 строк)
│   └── calculation_item_card.dart    # Карточка расчёта (~120 строк)
└── controllers/
    └── project_details_controller.dart # Логика (~150 строк)
```

### Пример декомпозиции putty_calculator_screen.dart

```
lib/presentation/views/putty/
├── putty_screen.dart                 # Основной экран (~180 строк)
├── widgets/
│   ├── putty_mode_selector.dart      # Выбор режима (~60 строк)
│   ├── room_dimensions_form.dart     # Форма размеров комнаты (~100 строк)
│   ├── walls_list_form.dart          # Динамический список стен (~120 строк)
│   ├── openings_list_form.dart       # Список проёмов (~100 строк)
│   ├── finish_type_selector.dart     # Выбор типа финиша (~80 строк)
│   └── putty_results_card.dart       # Карточка результатов (~100 строк)
├── models/
│   ├── wall.dart                     # Модель стены (~25 строк)
│   ├── opening.dart                  # Модель проёма (~25 строк)
│   └── putty_result.dart             # Результат расчёта (~40 строк)
└── logic/
    └── putty_calculator.dart         # Логика расчёта (~80 строк)
```

---

## 2.2 Недостаточно переиспользуемых виджетов

### Текущее состояние
```
lib/presentation/widgets/
├── calculator_tutorial.dart     # Туториал
├── draggable_project_list.dart  # Перетаскиваемый список
├── hint_card.dart               # Карточка подсказки
├── result_card.dart             # Карточка результата
├── result_charts.dart           # Графики
└── swipeable_card.dart          # Свайп-карточка
```

### Что нужно добавить

```
lib/presentation/widgets/
├── common/
│   ├── app_text_field.dart           # Унифицированное текстовое поле
│   ├── app_number_field.dart         # Поле для чисел с +/- кнопками
│   ├── app_slider_field.dart         # Слайдер с min/max подписями
│   ├── app_select_field.dart         # Унифицированный dropdown
│   ├── app_button.dart               # Кнопки (primary, secondary, text)
│   ├── app_card.dart                 # Базовая карточка
│   ├── section_header.dart           # Заголовок секции
│   ├── loading_indicator.dart        # Индикатор загрузки
│   ├── error_message.dart            # Сообщение об ошибке
│   ├── empty_state.dart              # Пустое состояние
│   └── confirmation_dialog.dart      # Диалог подтверждения
├── calculator/
│   ├── calculator_header.dart        # Шапка калькулятора
│   ├── input_group_card.dart         # Карточка группы полей
│   ├── input_field_row.dart          # Строка поля ввода
│   ├── result_summary_card.dart      # Главный результат
│   ├── result_details_list.dart      # Детали результатов
│   ├── result_row.dart               # Строка результата
│   ├── materials_list.dart           # Список материалов
│   ├── measurement_diagram.dart      # Схема измерений
│   └── preset_chips.dart             # Чипы пресетов
├── project/
│   ├── project_card.dart             # Карточка проекта
│   ├── project_list_item.dart        # Элемент списка проектов
│   ├── calculation_item.dart         # Элемент расчёта
│   └── project_status_badge.dart     # Бейдж статуса
└── existing/                         # Существующие виджеты
    ├── calculator_tutorial.dart
    ├── hint_card.dart
    ├── result_card.dart
    └── ...
```

### Пример app_number_field.dart

```dart
// lib/presentation/widgets/common/app_number_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Унифицированное поле для ввода чисел с кнопками +/-
class AppNumberField extends StatelessWidget {
  final String label;
  final double value;
  final double? min;
  final double? max;
  final double step;
  final String? unit;
  final String? hint;
  final bool required;
  final ValueChanged<double> onChanged;
  final TextEditingController? controller;

  const AppNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1.0,
    this.unit,
    this.hint,
    this.required = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label с индикатором обязательности
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Поле ввода с кнопками
        Row(
          children: [
            // Кнопка минус
            _StepButton(
              icon: Icons.remove,
              onPressed: value > (min ?? double.negativeInfinity)
                  ? () => onChanged((value - step).clamp(min ?? double.negativeInfinity, max ?? double.infinity))
                  : null,
            ),
            
            // Поле ввода
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  suffixText: unit,
                  hintText: hint,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onChanged: (text) {
                  final parsed = double.tryParse(text.replaceAll(',', '.'));
                  if (parsed != null) {
                    onChanged(parsed.clamp(min ?? double.negativeInfinity, max ?? double.infinity));
                  }
                },
              ),
            ),
            
            // Кнопка плюс
            _StepButton(
              icon: Icons.add,
              onPressed: value < (max ?? double.infinity)
                  ? () => onChanged((value + step).clamp(min ?? double.negativeInfinity, max ?? double.infinity))
                  : null,
            ),
          ],
        ),
        
        // Min/Max подсказка
        if (min != null || max != null) ...[
          const SizedBox(height: 4),
          Text(
            '${min != null ? "от $min" : ""} ${max != null ? "до $max" : ""} ${unit ?? ""}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: onPressed != null 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
```

### Пример app_slider_field.dart

```dart
// lib/presentation/widgets/common/app_slider_field.dart

import 'package:flutter/material.dart';

/// Слайдер с подписями min/max и текущим значением
class AppSliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? unit;
  final ValueChanged<double> onChanged;

  const AppSliderField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label и текущее значение
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} ${unit ?? ""}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Слайдер
        Row(
          children: [
            // Min value
            Text(
              '$min',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            
            // Slider
            Expanded(
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions ?? (max - min).round(),
                onChanged: onChanged,
              ),
            ),
            
            // Max value
            Text(
              '$max ${unit ?? ""}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## 2.3 Избыточное использование setState

### Проблема
97 вызовов `setState` в views, хотя проект использует Riverpod.

### Файлы для рефакторинга

```bash
# Команда для поиска:
grep -rn "setState" lib/presentation/views/ | wc -l
# Результат: 97
```

### Что оставить как есть (OK использовать setState):
- Анимации и контроллеры анимаций
- Формы с TextEditingController
- Локальное UI-состояние (раскрытие/скрытие секции)

### Что нужно мигрировать на Riverpod:

#### Пример 1: Состояние калькулятора
```dart
// БЫЛО (pro_calculator_screen.dart):
class _ProCalculatorScreenState extends ConsumerState<ProCalculatorScreen> {
  final Map<String, double> _inputs = {};
  Map<String, double>? _results;
  
  void _calculate() {
    setState(() {
      _results = widget.definition.calculate(_inputs, priceList).values;
    });
  }
}

// НУЖНО:
// 1. Создать StateNotifier
class CalculatorState {
  final Map<String, double> inputs;
  final Map<String, double>? results;
  
  CalculatorState({required this.inputs, this.results});
  
  CalculatorState copyWith({
    Map<String, double>? inputs,
    Map<String, double>? results,
  }) {
    return CalculatorState(
      inputs: inputs ?? this.inputs,
      results: results ?? this.results,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  final CalculatorDefinitionV2 definition;
  final List<PriceItem> priceList;
  
  CalculatorNotifier(this.definition, this.priceList) 
      : super(CalculatorState(inputs: {})) {
    _initDefaults();
  }
  
  void _initDefaults() {
    final defaults = <String, double>{};
    for (final field in definition.fields) {
      defaults[field.key] = field.defaultValue;
    }
    state = state.copyWith(inputs: defaults);
    calculate();
  }
  
  void updateInput(String key, double value) {
    final newInputs = Map<String, double>.from(state.inputs);
    newInputs[key] = value;
    state = state.copyWith(inputs: newInputs);
    calculate();
  }
  
  void calculate() {
    final result = definition.calculate(state.inputs, priceList);
    state = state.copyWith(results: result.values);
  }
}

// 2. Создать provider
final calculatorProvider = StateNotifierProvider.family<
    CalculatorNotifier, CalculatorState, CalculatorDefinitionV2>(
  (ref, definition) {
    final priceList = ref.watch(priceListProvider).maybeWhen(
      data: (list) => list,
      orElse: () => <PriceItem>[],
    );
    return CalculatorNotifier(definition, priceList);
  },
);

// 3. Использовать в UI
class ProCalculatorScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorProvider(widget.definition));
    final notifier = ref.read(calculatorProvider(widget.definition).notifier);
    
    // Нет setState!
    return TextField(
      onChanged: (text) {
        final value = double.tryParse(text) ?? 0;
        notifier.updateInput('area', value);  // Автоматический пересчёт
      },
    );
  }
}
```

---

# 💡 ЧАСТЬ 3: UX/UI УЛУЧШЕНИЯ

## 3.1 Улучшения полей ввода калькуляторов

### 3.1.1 Добавить кнопки +/- к числовым полям

```
Файл: lib/presentation/views/calculator/pro_calculator_screen.dart
Метод: _buildNumberField()

БЫЛО:
Widget _buildNumberField(CalculatorField field) {
  return TextField(
    controller: _controllers[field.key],
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    ...
  );
}

НУЖНО:
Widget _buildNumberField(CalculatorField field) {
  final value = _inputs[field.key] ?? field.defaultValue;
  final step = field.step ?? 1.0;
  
  return Row(
    children: [
      // Кнопка минус
      IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: () {
          final newValue = (value - step).clamp(field.minValue ?? 0, field.maxValue ?? double.infinity);
          _updateValue(field.key, newValue);
          _controllers[field.key]?.text = newValue.toStringAsFixed(newValue % 1 == 0 ? 0 : 1);
        },
      ),
      
      // Текстовое поле
      Expanded(
        child: TextField(
          controller: _controllers[field.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          ...
        ),
      ),
      
      // Кнопка плюс
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () {
          final newValue = (value + step).clamp(field.minValue ?? 0, field.maxValue ?? double.infinity);
          _updateValue(field.key, newValue);
          _controllers[field.key]?.text = newValue.toStringAsFixed(newValue % 1 == 0 ? 0 : 1);
        },
      ),
    ],
  );
}
```

### 3.1.2 Показать min/max у слайдеров

```
Файл: lib/presentation/views/calculator/pro_calculator_screen.dart
Метод: _buildSliderField()

БЫЛО:
Widget _buildSliderField(CalculatorField field) {
  return Column(
    children: [
      Row(...), // Label и значение
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: (v) => _updateValue(field.key, v),
      ),
    ],
  );
}

НУЖНО:
Widget _buildSliderField(CalculatorField field) {
  return Column(
    children: [
      Row(...), // Label и значение
      
      // Слайдер с подписями min/max
      Row(
        children: [
          // Минимальное значение
          SizedBox(
            width: 40,
            child: Text(
              '${min.toInt()}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          
          // Слайдер
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) / (field.step ?? 1)).round(),
              onChanged: (v) => _updateValue(field.key, v),
            ),
          ),
          
          // Максимальное значение
          SizedBox(
            width: 50,
            child: Text(
              '${max.toInt()} ${_loc.translate('unit.${field.unitType.name}')}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    ],
  );
}
```

### 3.1.3 Индикация обязательных полей

```dart
// В _buildNumberField, _buildSelectField и других:

Row(
  children: [
    Text(
      _loc.translate(field.labelKey),
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    ),
    if (field.required) ...[
      const SizedBox(width: 4),
      const Text(
        '*',
        style: TextStyle(color: Colors.redAccent, fontSize: 14),
      ),
    ],
  ],
)
```

---

## 3.2 Улучшения отображения результатов

### 3.2.1 Группировка результатов по категориям

```dart
// lib/presentation/widgets/calculator/grouped_results_card.dart

class GroupedResultsCard extends StatelessWidget {
  final Map<String, double> results;
  final AppLocalizations loc;

  // Группировка по типу результата
  static const Map<String, List<String>> groups = {
    'materials': ['cementBags', 'sandVolume', 'plasterBags', 'paintLiters', 'wallpaperRolls'],
    'consumables': ['meshArea', 'beaconsLength', 'damperTapeLength', 'plasticizerNeeded'],
    'additional': ['waterproofingArea', 'primerLiters', 'underlayArea'],
    'summary': ['area', 'volume', 'perimeter', 'totalPrice'],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Итого (главный результат)
        _buildSummaryCard(context),
        
        const SizedBox(height: 16),
        
        // Материалы
        _buildGroupCard(
          context,
          icon: Icons.inventory_2_outlined,
          title: loc.translate('result.group.materials'),
          keys: groups['materials']!,
        ),
        
        const SizedBox(height: 12),
        
        // Расходники
        _buildGroupCard(
          context,
          icon: Icons.build_outlined,
          title: loc.translate('result.group.consumables'),
          keys: groups['consumables']!,
        ),
        
        const SizedBox(height: 12),
        
        // Дополнительно
        _buildGroupCard(
          context,
          icon: Icons.add_circle_outline,
          title: loc.translate('result.group.additional'),
          keys: groups['additional']!,
        ),
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, {
    required IconData icon,
    required String title,
    required List<String> keys,
  }) {
    final groupResults = results.entries
        .where((e) => keys.contains(e.key) && e.value > 0)
        .toList();
    
    if (groupResults.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок группы
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Элементы группы
          ...groupResults.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('result.${entry.key}'),
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  '${entry.value.toStringAsFixed(1)} ${_getUnit(entry.key)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
```

### 3.2.2 Добавить визуальные диаграммы

```dart
// Использовать существующий result_charts.dart
// Добавить круговую диаграмму распределения затрат

import 'package:fl_chart/fl_chart.dart';

class CostDistributionChart extends StatelessWidget {
  final Map<String, double> costs; // {'cement': 5000, 'sand': 2000, ...}

  @override
  Widget build(BuildContext context) {
    final total = costs.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return const SizedBox();

    final sections = costs.entries
        .where((e) => e.value > 0)
        .map((e) => PieChartSectionData(
              value: e.value,
              title: '${(e.value / total * 100).toStringAsFixed(0)}%',
              color: _getColorForKey(e.key),
              radius: 60,
            ))
        .toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}
```

---

## 3.3 Добавить схемы измерений

### Концепция

```dart
// lib/presentation/widgets/calculator/measurement_diagram.dart

class MeasurementDiagram extends StatelessWidget {
  final DiagramType type;
  final Map<String, double> values;
  final Map<String, String>? highlights; // Какие поля подсветить

  const MeasurementDiagram({
    super.key,
    required this.type,
    required this.values,
    this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      DiagramType.room => _RoomDiagram(values: values, highlights: highlights),
      DiagramType.wall => _WallDiagram(values: values, highlights: highlights),
      DiagramType.floor => _FloorDiagram(values: values, highlights: highlights),
      DiagramType.roof => _RoofDiagram(values: values, highlights: highlights),
    };
  }
}

enum DiagramType { room, wall, floor, roof }

class _RoomDiagram extends StatelessWidget {
  final Map<String, double> values;
  final Map<String, String>? highlights;

  const _RoomDiagram({required this.values, this.highlights});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 150),
      painter: _RoomPainter(
        length: values['length'] ?? 4,
        width: values['width'] ?? 3,
        height: values['height'] ?? 2.7,
        highlightField: highlights?.keys.firstOrNull,
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  final double length;
  final double width;
  final double height;
  final String? highlightField;

  _RoomPainter({
    required this.length,
    required this.width,
    required this.height,
    this.highlightField,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Изометрическая проекция комнаты
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = 15.0;

    // Точки комнаты
    final p1 = Offset(centerX - length * scale / 2, centerY + width * scale / 4);
    final p2 = Offset(centerX + length * scale / 2, centerY + width * scale / 4);
    final p3 = Offset(centerX + length * scale / 2, centerY - width * scale / 4);
    final p4 = Offset(centerX - length * scale / 2, centerY - width * scale / 4);

    // Пол
    final floorPath = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..lineTo(p4.dx, p4.dy)..close();
    canvas.drawPath(floorPath, paint);

    // Стены (подсветка если нужно)
    if (highlightField == 'length') {
      canvas.drawLine(p1, p2, highlightPaint);
      _drawDimension(canvas, p1, p2, '$length м', highlightPaint.color);
    } else {
      canvas.drawLine(p1, p2, paint);
    }

    // ... аналогично для width и height
  }

  void _drawDimension(Canvas canvas, Offset start, Offset end, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 + 15);
    textPainter.paint(canvas, midPoint - Offset(textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

---

## 3.4 Добавить пресеты типовых размеров

```dart
// lib/presentation/widgets/calculator/preset_chips.dart

class PresetChips extends StatelessWidget {
  final List<Preset> presets;
  final ValueChanged<Map<String, double>> onPresetSelected;

  const PresetChips({
    super.key,
    required this.presets,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((preset) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            avatar: Icon(preset.icon, size: 18),
            label: Text(preset.name),
            onPressed: () => onPresetSelected(preset.values),
          ),
        )).toList(),
      ),
    );
  }
}

class Preset {
  final String name;
  final IconData icon;
  final Map<String, double> values;

  const Preset({
    required this.name,
    required this.icon,
    required this.values,
  });
}

// Пресеты для разных калькуляторов
const roomPresets = [
  Preset(
    name: 'Комната 3×4',
    icon: Icons.bed_outlined,
    values: {'length': 4.0, 'width': 3.0, 'height': 2.7},
  ),
  Preset(
    name: 'Санузел 2×2',
    icon: Icons.bathroom_outlined,
    values: {'length': 2.0, 'width': 2.0, 'height': 2.5},
  ),
  Preset(
    name: 'Кухня 3×3',
    icon: Icons.kitchen_outlined,
    values: {'length': 3.0, 'width': 3.0, 'height': 2.7},
  ),
  Preset(
    name: 'Гостиная 5×4',
    icon: Icons.living_outlined,
    values: {'length': 5.0, 'width': 4.0, 'height': 2.7},
  ),
  Preset(
    name: 'Коридор 4×1.5',
    icon: Icons.door_front_door_outlined,
    values: {'length': 4.0, 'width': 1.5, 'height': 2.7},
  ),
];

const foundationPresets = [
  Preset(
    name: 'Дом 6×8',
    icon: Icons.home_outlined,
    values: {'length': 8.0, 'width': 6.0, 'depth': 0.8, 'thickness': 0.4},
  ),
  Preset(
    name: 'Баня 4×5',
    icon: Icons.hot_tub_outlined,
    values: {'length': 5.0, 'width': 4.0, 'depth': 0.6, 'thickness': 0.3},
  ),
  Preset(
    name: 'Гараж 4×6',
    icon: Icons.garage_outlined,
    values: {'length': 6.0, 'width': 4.0, 'depth': 0.5, 'thickness': 0.3},
  ),
];
```

---

## 3.5 Запоминание последних значений

```dart
// lib/core/services/calculator_memory_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorMemoryService {
  static const _prefix = 'calc_last_';
  
  final SharedPreferences _prefs;
  
  CalculatorMemoryService(this._prefs);
  
  /// Сохранить последние введённые значения
  Future<void> saveLastInputs(String calculatorId, Map<String, double> inputs) async {
    final key = '$_prefix$calculatorId';
    await _prefs.setString(key, jsonEncode(inputs));
  }
  
  /// Загрузить последние введённые значения
  Map<String, double>? loadLastInputs(String calculatorId) {
    final key = '$_prefix$calculatorId';
    final json = _prefs.getString(key);
    if (json == null) return null;
    
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (e) {
      return null;
    }
  }
  
  /// Очистить память калькулятора
  Future<void> clearMemory(String calculatorId) async {
    final key = '$_prefix$calculatorId';
    await _prefs.remove(key);
  }
  
  /// Очистить всю память
  Future<void> clearAllMemory() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}

// Provider
final calculatorMemoryProvider = Provider<CalculatorMemoryService>((ref) {
  throw UnimplementedError('Must be overridden');
});

// Использование в калькуляторе:
@override
void initState() {
  super.initState();
  _loadLastInputs();
}

Future<void> _loadLastInputs() async {
  final memory = ref.read(calculatorMemoryProvider);
  final lastInputs = memory.loadLastInputs(widget.definition.id);
  
  if (lastInputs != null) {
    setState(() {
      _inputs.addAll(lastInputs);
      // Обновить контроллеры
      for (final entry in lastInputs.entries) {
        _controllers[entry.key]?.text = entry.value.toStringAsFixed(
          entry.value % 1 == 0 ? 0 : 1
        );
      }
    });
    _calculate();
  }
}

@override
void dispose() {
  // Сохранить при закрытии
  ref.read(calculatorMemoryProvider).saveLastInputs(widget.definition.id, _inputs);
  super.dispose();
}
```

---

## 3.6 Режим Новичок / Профи

### Реализация

```dart
// lib/domain/models/calculator_field.dart
// Добавить поле:

class CalculatorField {
  // ... существующие поля ...
  
  /// Уровень сложности поля (1 = новичок, 2 = профи)
  final int complexityLevel;
  
  const CalculatorField({
    // ...
    this.complexityLevel = 1, // По умолчанию показывать всем
  });
}
```

```dart
// lib/domain/models/calculator_definition_v2.dart
// Добавить метод:

class CalculatorDefinitionV2 {
  // ...
  
  /// Получить поля для режима новичка
  List<CalculatorField> getBeginnerFields() {
    return fields.where((f) => f.complexityLevel == 1).toList();
  }
  
  /// Получить все поля (режим профи)
  List<CalculatorField> getProFields() {
    return fields;
  }
  
  /// Получить видимые поля с учётом режима
  List<CalculatorField> getVisibleFieldsForMode(
    Map<String, double> inputs,
    bool isProMode,
  ) {
    final modeFields = isProMode ? getProFields() : getBeginnerFields();
    return modeFields.where((f) => f.shouldDisplay(inputs)).toList();
  }
}
```

```dart
// lib/presentation/providers/settings_provider.dart
// Добавить:

class AppSettings {
  // ... существующие поля ...
  final bool isProMode;
  
  AppSettings({
    // ...
    this.isProMode = false,
  });
}
```

```dart
// Использование в калькуляторе:

@override
Widget build(BuildContext context) {
  final settings = ref.watch(settingsProvider);
  final visibleFields = widget.definition.getVisibleFieldsForMode(
    _inputs, 
    settings.isProMode,
  );
  
  return Column(
    children: [
      // Переключатель режима
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: Text(_loc.translate('mode.beginner')),
            selected: !settings.isProMode,
            onSelected: (_) => ref.read(settingsProvider.notifier).setProMode(false),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(_loc.translate('mode.pro')),
            selected: settings.isProMode,
            onSelected: (_) => ref.read(settingsProvider.notifier).setProMode(true),
          ),
        ],
      ),
      
      // Поля калькулятора
      ...visibleFields.map((field) => _buildField(field)),
    ],
  );
}
```

### Пример разметки полей по сложности

```dart
// Калькулятор стяжки:
final screedCalculatorV2 = CalculatorDefinitionV2(
  // ...
  fields: [
    // Базовые поля (для всех)
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      complexityLevel: 1, // Новичок
    ),
    CalculatorField(
      key: 'thickness',
      labelKey: 'input.thickness',
      complexityLevel: 1, // Новичок
      defaultValue: 50.0, // Значение по умолчанию для новичков
    ),
    
    // Расширенные поля (только профи)
    CalculatorField(
      key: 'cementGrade',
      labelKey: 'input.cement_grade',
      complexityLevel: 2, // Профи
      inputType: FieldInputType.select,
      options: [
        FieldOption(value: 400, labelKey: 'cement.m400'),
        FieldOption(value: 500, labelKey: 'cement.m500'),
      ],
    ),
    CalculatorField(
      key: 'useMesh',
      labelKey: 'input.use_mesh',
      complexityLevel: 2, // Профи
      inputType: FieldInputType.switch_,
    ),
    CalculatorField(
      key: 'plasticizerPercent',
      labelKey: 'input.plasticizer_percent',
      complexityLevel: 2, // Профи
    ),
  ],
);
```

---

# 🔧 ЧАСТЬ 4: ОПТИМИЗАЦИИ КОДА

## 4.1 Ленивая инициализация реестра

```dart
// lib/domain/calculators/calculator_registry.dart

class CalculatorRegistry {
  // БЫЛО:
  static final List<CalculatorDefinitionV2> allCalculators = _buildAllCalculators();
  static final Map<String, CalculatorDefinitionV2> _idCache = _buildIdCache();

  // НУЖНО:
  static List<CalculatorDefinitionV2>? _allCalculators;
  static Map<String, CalculatorDefinitionV2>? _idCache;
  
  static List<CalculatorDefinitionV2> get allCalculators {
    return _allCalculators ??= _buildAllCalculators();
  }
  
  static Map<String, CalculatorDefinitionV2> get _idCacheLazy {
    return _idCache ??= _buildIdCache();
  }
  
  static CalculatorDefinitionV2? getById(String id) {
    return _idCacheLazy[id];
  }
}
```

---

## 4.2 Индексы для быстрого поиска

```dart
// lib/domain/calculators/calculator_search_index.dart

class CalculatorSearchIndex {
  // Индекс слов → калькуляторы
  final Map<String, Set<String>> _wordIndex = {};
  
  // Индекс категорий → калькуляторы
  final Map<CalculatorCategory, List<String>> _categoryIndex = {};
  
  // Индекс тегов → калькуляторы
  final Map<String, Set<String>> _tagIndex = {};

  void buildIndex(List<CalculatorDefinitionV2> calculators) {
    for (final calc in calculators) {
      // Индексируем слова из названия
      final words = _tokenize(calc.titleKey);
      for (final word in words) {
        _wordIndex.putIfAbsent(word, () => {}).add(calc.id);
      }
      
      // Индексируем категорию
      _categoryIndex.putIfAbsent(calc.category, () => []).add(calc.id);
      
      // Индексируем теги
      for (final tag in calc.tags) {
        _tagIndex.putIfAbsent(tag.toLowerCase(), () => {}).add(calc.id);
      }
    }
  }

  List<String> search(String query) {
    final words = _tokenize(query);
    if (words.isEmpty) return [];
    
    // Пересечение результатов по всем словам
    Set<String>? result;
    for (final word in words) {
      final matches = _wordIndex[word] ?? _tagIndex[word] ?? {};
      if (result == null) {
        result = Set.from(matches);
      } else {
        result = result.intersection(matches);
      }
    }
    
    return result?.toList() ?? [];
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sа-яё]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
  }
}
```

---

## 4.3 Мемоизация расчётов

```dart
// lib/domain/usecases/base_calculator.dart
// Добавить кэширование результатов

abstract class BaseCalculator implements CalculatorUseCase {
  // Кэш последнего расчёта
  Map<String, double>? _lastInputs;
  CalculatorResult? _lastResult;

  @override
  CalculatorResult calculate(Map<String, double> inputs, List<PriceItem> priceList) {
    // Проверяем кэш
    if (_lastResult != null && _areInputsEqual(inputs, _lastInputs)) {
      return _lastResult!;
    }
    
    // Выполняем расчёт
    final result = doCalculate(inputs, priceList);
    
    // Сохраняем в кэш
    _lastInputs = Map.from(inputs);
    _lastResult = result;
    
    return result;
  }
  
  /// Реализовать в наследниках
  CalculatorResult doCalculate(Map<String, double> inputs, List<PriceItem> priceList);
  
  bool _areInputsEqual(Map<String, double> a, Map<String, double>? b) {
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
  
  /// Сбросить кэш
  void invalidateCache() {
    _lastInputs = null;
    _lastResult = null;
  }
}
```

---

# 📊 ЧАСТЬ 5: ТЕСТИРОВАНИЕ

## 5.1 Добавить тесты локализации

```dart
// test/core/localization/localization_coverage_test.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization Coverage', () {
    late Map<String, dynamic> ruJson;
    late Map<String, dynamic> enJson;
    
    setUpAll(() {
      ruJson = jsonDecode(File('assets/lang/ru.json').readAsStringSync());
      enJson = jsonDecode(File('assets/lang/en.json').readAsStringSync());
    });
    
    test('en.json должен содержать все ключи из ru.json', () {
      final ruKeys = _flattenKeys(ruJson);
      final enKeys = _flattenKeys(enJson);
      
      final missingInEn = ruKeys.difference(enKeys);
      
      expect(
        missingInEn,
        isEmpty,
        reason: 'Отсутствуют в en.json: ${missingInEn.take(10).join(", ")}... '
            '(всего ${missingInEn.length})',
      );
    });
    
    test('en.json не должен содержать пустых значений', () {
      final emptyKeys = <String>[];
      _checkEmptyValues(enJson, '', emptyKeys);
      
      expect(
        emptyKeys,
        isEmpty,
        reason: 'Пустые значения в en.json: ${emptyKeys.take(10).join(", ")}',
      );
    });
    
    for (final lang in ['kk', 'ky', 'tg', 'tk', 'uz']) {
      test('$lang.json должен содержать минимум 90% ключей', () {
        final langJson = jsonDecode(
          File('assets/lang/$lang.json').readAsStringSync(),
        );
        final ruKeys = _flattenKeys(ruJson);
        final langKeys = _flattenKeys(langJson);
        
        final coverage = langKeys.length / ruKeys.length;
        
        expect(
          coverage,
          greaterThanOrEqualTo(0.9),
          reason: '$lang.json покрытие: ${(coverage * 100).toStringAsFixed(1)}%',
        );
      });
    }
  });
}

Set<String> _flattenKeys(Map<String, dynamic> map, [String prefix = '']) {
  final keys = <String>{};
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      keys.addAll(_flattenKeys(entry.value, key));
    } else {
      keys.add(key);
    }
  }
  return keys;
}

void _checkEmptyValues(Map<String, dynamic> map, String prefix, List<String> emptyKeys) {
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      _checkEmptyValues(entry.value, key, emptyKeys);
    } else if (entry.value is String && entry.value.isEmpty) {
      emptyKeys.add(key);
    }
  }
}
```

## 5.2 Добавить тест на хардкод

```dart
// test/code_quality/hardcoded_strings_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Не должно быть захардкоженного русского текста в UI файлах', () {
    final libDir = Directory('lib');
    final russianPattern = RegExp(r"'[а-яА-ЯёЁ][^']*'|\"[а-яА-ЯёЁ][^\"]*\"");
    
    final violations = <String>[];
    
    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('.g.dart')) continue; // Пропускаем сгенерированные
      if (file.path.contains('localization')) continue; // Пропускаем локализацию
      
      final content = file.readAsStringSync();
      final lines = content.split('\n');
      
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        // Пропускаем комментарии
        if (line.trim().startsWith('//') || line.trim().startsWith('///')) {
          continue;
        }
        
        final matches = russianPattern.allMatches(line);
        for (final match in matches) {
          violations.add('${file.path}:${i + 1}: ${match.group(0)}');
        }
      }
    }
    
    expect(
      violations,
      isEmpty,
      reason: 'Найдены захардкоженные русские строки:\n${violations.take(20).join("\n")}',
    );
  });
}
```

---

# ✅ ЧАСТЬ 6: ЧЕКЛИСТ ВЫПОЛНЕНИЯ

## Критические (перед релизом)
- [ ] 1.1 Завершить en.json (538 строк)
- [ ] 1.2 Исправить захардкоженные строки (88+ мест)
- [ ] 1.3 Заменить subCategory на subCategoryKey (59 калькуляторов)
- [ ] 1.4 Разбить migrated_calculators_v2.dart на модули

## Важные (после релиза v1)
- [ ] 2.1 Декомпозиция больших UI-файлов (8 файлов)
- [ ] 2.2 Создать библиотеку переиспользуемых виджетов
- [ ] 2.3 Мигрировать setState на Riverpod (выборочно)

## UX улучшения (v1.1+)
- [ ] 3.1 Кнопки +/- для числовых полей
- [ ] 3.2 Min/max подписи у слайдеров
- [ ] 3.3 Группировка результатов
- [ ] 3.4 Схемы измерений
- [ ] 3.5 Пресеты типовых размеров
- [ ] 3.6 Запоминание последних значений
- [ ] 3.7 Режим Новичок/Профи

## Оптимизации (v1.2+)
- [ ] 4.1 Ленивая инициализация реестра
- [ ] 4.2 Поисковые индексы
- [ ] 4.3 Мемоизация расчётов

## Тестирование
- [ ] 5.1 Тесты покрытия локализации
- [ ] 5.2 Тест на хардкод

---

# 📎 ПРИЛОЖЕНИЯ

## A. Полный список ключей для добавления в локализацию

```json
{
  "category.all": "Все",
  "category.walls": "Стены",
  "category.floor": "Пол",
  "category.finish": "Отделка",
  "category.wood": "Дерево",
  
  "tutorial.press_calculate": "Нажмите \"Рассчитать\"",
  
  "search.try_another_query": "Попробуйте другой запрос. Например: \"бетон\", \"обои\", \"плитка\"",
  
  "error.calculator_not_found": "Калькулятор \"{id}\" не найден",
  
  "hint.type.info": "Информация",
  "hint.type.warning": "Внимание",
  "hint.type.tip": "Совет мастера",
  "hint.type.important": "Важно",
  
  "unit.kg": "кг",
  "unit.liter": "л",
  "unit.sqm": "м²",
  "unit.mm": "мм",
  "unit.bags": "мешков",
  "unit.buckets": "вёдер",
  
  "material.dry": "Сухой",
  "material.paste": "Паста",
  
  "smart_project.press_calculate_hint": "Нажмите \"Рассчитать\" для получения результатов",
  
  "mode.beginner": "Новичок",
  "mode.pro": "Профи",
  
  "result.group.materials": "Материалы",
  "result.group.consumables": "Расходники",
  "result.group.additional": "Дополнительно",
  
  "subcategory.floors": "Полы",
  "subcategory.walls": "Стены",
  "subcategory.ceilings": "Потолки",
  "subcategory.roofing": "Кровля",
  "subcategory.foundation": "Фундамент",
  "subcategory.facade": "Фасад",
  "subcategory.engineering": "Инженерия",
  "subcategory.bathroom": "Ванная / туалет",
  "subcategory.attic": "Мансарда",
  "subcategory.balcony": "Балкон / Лоджия",
  "subcategory.windows_doors": "Окна / двери",
  "subcategory.electrics": "Электрика",
  "subcategory.heating": "Отопление",
  "subcategory.plumbing": "Сантехника",
  "subcategory.ventilation": "Вентиляция",
  "subcategory.brick_facing": "Облицовочный кирпич",
  "subcategory.facade_panels": "Фасадные панели",
  "subcategory.siding": "Сайдинг",
  "subcategory.wet_facade": "Мокрый фасад",
  "subcategory.wood": "Дерево",
  "subcategory.fences": "Заборы",
  "subcategory.basement": "Цокольный этаж",
  "subcategory.concrete": "Бетон",
  "subcategory.osb_plywood": "ОСБ/фанера"
}
```

---

**Конец документа**

*Общая оценка времени на все изменения: 80-120 часов*
