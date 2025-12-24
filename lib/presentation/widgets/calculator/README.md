# 🎨 Дизайн-система калькуляторов "Прораб AI"

Единая дизайн-система для всех калькуляторов в приложении, основанная на эталонном дизайне калькулятора "Шпатлёвка".

## 📋 Содержание

- [Принципы дизайна](#принципы-дизайна)
- [Компоненты](#компоненты)
- [Цвета](#цвета)
- [Константы](#константы)
- [Примеры использования](#примеры-использования)

---

## 🎯 Принципы дизайна

### 1. Светлая тема с цветными акцентами
- Фон экрана: светло-серый (`#F8FAFC`)
- Карточки: белый фон с тенями
- Акцентный цвет по категории калькулятора

### 2. Результаты сверху экрана
- Header с ключевыми результатами в верхней части
- Пользователь видит результаты без прокрутки
- 2-4 основных значения в компактном формате

### 3. Визуальная группировка
- Логические секции: Геометрия, Проемы, Параметры
- Карточки с тенями и скругленными углами
- Collapsible секции для сложных калькуляторов

### 4. Интуитивный выбор типов
- Визуальные карточки вместо dropdown
- Иконки для быстрого распознавания
- Чёткое выделение выбранного элемента

---

## 🧩 Компоненты

### 1. CalculatorScaffold

Базовая структура экрана калькулятора.

```dart
import 'package:prorab/presentation/widgets/calculator/calculator_scaffold.dart';
import 'package:prorab/core/constants/calculator_colors.dart';

CalculatorScaffold(
  title: 'Шпатлёвка',
  accentColor: CalculatorColors.interior,
  resultHeader: CalculatorResultHeader(
    accentColor: CalculatorColors.interior,
    results: [
      ResultItem(label: 'ПЛОЩАДЬ', value: '35.9 м²'),
      ResultItem(label: 'СТАРТ', value: '2 мешков'),
      ResultItem(label: 'ФИНИШ', value: '3 шт'),
    ],
  ),
  children: [
    // Содержимое калькулятора
  ],
)
```

### 2. CalculatorResultHeader

Header с результатами расчёта в верхней части экрана.

```dart
import 'package:prorab/presentation/widgets/calculator/calculator_result_header.dart';

CalculatorResultHeader(
  accentColor: CalculatorColors.interior,
  results: [
    ResultItem(label: 'ПЛОЩАДЬ', value: '35.9 м²'),
    ResultItem(label: 'МАТЕРИАЛ', value: '10 мешков', icon: Icons.shopping_bag),
    ResultItem(label: 'СТОИМОСТЬ', value: '15 000 ₽'),
  ],
)

// Вариант без белой карточки (цветной фон)
CalculatorResultHeaderColored(
  accentColor: CalculatorColors.roofing,
  results: [...],
)
```

### 3. TypeSelectorCard

Визуальная карточка для выбора типа материала/опции.

```dart
import 'package:prorab/presentation/widgets/calculator/type_selector_card.dart';

Row(
  children: [
    Expanded(
      child: TypeSelectorCard(
        icon: Icons.wallpaper,
        title: 'Под обои',
        subtitle: '1 слой старт + 1 слой финиш',
        isSelected: selectedType == 0,
        accentColor: CalculatorColors.interior,
        onTap: () => setState(() => selectedType = 0),
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: TypeSelectorCard(
        icon: Icons.format_paint,
        title: 'Под покраску',
        subtitle: '2 слоя старт + 2 слоя финиш',
        isSelected: selectedType == 1,
        accentColor: CalculatorColors.interior,
        onTap: () => setState(() => selectedType = 1),
      ),
    ),
  ],
)

// Или используйте группу
TypeSelectorGroup(
  options: [
    TypeSelectorOption(icon: Icons.wallpaper, title: 'Под обои', subtitle: '1 слой'),
    TypeSelectorOption(icon: Icons.format_paint, title: 'Под покраску', subtitle: '2 слоя'),
  ],
  selectedIndex: selectedType,
  onSelect: (index) => setState(() => selectedType = index),
  accentColor: CalculatorColors.interior,
)
```

### 4. InputGroup

Группа полей ввода с заголовком.

```dart
import 'package:prorab/presentation/widgets/calculator/input_group.dart';

// Простая группа
InputGroup(
  title: 'Геометрия',
  icon: Icons.straighten,
  accentColor: CalculatorColors.interior,
  children: [
    Row(
      children: [
        Expanded(child: TextField(/* ... */)),
        SizedBox(width: 12),
        Expanded(child: TextField(/* ... */)),
      ],
    ),
    SizedBox(height: 12),
    TextField(/* ... */),
  ],
)

// Collapsible группа
InputGroup(
  title: 'Проемы',
  icon: Icons.door_front_door,
  accentColor: CalculatorColors.interior,
  isCollapsible: true,
  initiallyExpanded: false,
  children: [
    // Поля ввода
  ],
)

// Цветная группа (с фоном)
InputGroupColored(
  title: 'Геометрия комнаты',
  icon: Icons.straighten,
  accentColor: CalculatorColors.interior,
  children: [
    // Поля ввода
  ],
)

// Простая группа без карточки
InputGroupSimple(
  title: 'Параметры',
  icon: Icons.settings,
  children: [
    // Поля ввода
  ],
)
```

### 5. ModeSelector

Переключатель режимов (табы).

```dart
import 'package:prorab/presentation/widgets/calculator/mode_selector.dart';

// Простой переключатель
ModeSelector(
  options: ['Комната', 'Список стен'],
  selectedIndex: mode,
  onSelect: (index) => setState(() => mode = index),
  accentColor: CalculatorColors.interior,
)

// С иконками
ModeSelectorWithIcons(
  options: [
    ModeSelectorIconOption(label: 'Комната', icon: Icons.home),
    ModeSelectorIconOption(label: 'Список', icon: Icons.list),
  ],
  selectedIndex: mode,
  onSelect: (index) => setState(() => mode = index),
  accentColor: CalculatorColors.interior,
)

// Вертикальный вариант
ModeSelectorVertical(
  options: ['Вариант 1', 'Вариант 2', 'Вариант 3'],
  selectedIndex: selected,
  onSelect: (index) => setState(() => selected = index),
  accentColor: CalculatorColors.flooring,
)
```

---

## 🎨 Цвета

### Акцентные цвета по категориям

```dart
import 'package:prorab/core/constants/calculator_colors.dart';

// Интерьерные работы (шпатлёвка, штукатурка)
CalculatorColors.interior         // #10B981 (зелёный)
CalculatorColors.interiorLight    // светло-зелёный
CalculatorColors.interiorDark     // тёмно-зелёный

// Напольные покрытия
CalculatorColors.flooring         // #F59E0B (жёлтый)

// Кровля
CalculatorColors.roofing          // #EF4444 (красный)

// Фундамент и бетон
CalculatorColors.foundation       // #6366F1 (синий)

// Фасадные работы
CalculatorColors.facade           // #8B5CF6 (фиолетовый)

// Инженерные системы
CalculatorColors.engineering      // #06B6D4 (бирюзовый)

// Стены
CalculatorColors.walls            // #14B8A6 (teal)

// Потолочные работы
CalculatorColors.ceiling          // #3B82F6 (голубой)

// Хелперы
Color color = CalculatorColors.getColorByCategory('interior');
Color light = CalculatorColors.getLightColorByCategory('flooring');
Color dark = CalculatorColors.getDarkColorByCategory('roofing');
```

### Общие цвета

```dart
// Фон
CalculatorColors.backgroundPrimary    // Светло-серый фон
CalculatorColors.cardBackground       // Белый фон карточек

// Текст
CalculatorColors.textPrimary          // Основной текст
CalculatorColors.textSecondary        // Вторичный текст
CalculatorColors.textTertiary         // Подсказки

// Границы
CalculatorColors.borderDefault
CalculatorColors.borderFocused

// Тени
CalculatorColors.shadowSmall
CalculatorColors.shadowMedium
CalculatorColors.shadowLarge
```

---

## 📐 Константы

### Типографика

```dart
import 'package:prorab/core/constants/calculator_design_system.dart';

// Заголовки
CalculatorDesignSystem.headlineLarge    // 24sp, w600
CalculatorDesignSystem.headlineMedium   // 20sp, w600
CalculatorDesignSystem.titleLarge       // 18sp, w600
CalculatorDesignSystem.titleMedium      // 16sp, w500

// Основной текст
CalculatorDesignSystem.bodyLarge        // 16sp, w400
CalculatorDesignSystem.bodyMedium       // 14sp, w400
CalculatorDesignSystem.bodySmall        // 12sp, w400

// Метки
CalculatorDesignSystem.labelLarge       // 14sp, w500
CalculatorDesignSystem.labelMedium      // 12sp, w500
CalculatorDesignSystem.labelSmall       // 10sp, w500

// Header результатов
CalculatorDesignSystem.headerLabel      // 10sp, w700, uppercase
CalculatorDesignSystem.headerValue      // 18sp, w700
```

### Отступы

```dart
CalculatorDesignSystem.spacingXS     // 4
CalculatorDesignSystem.spacingS      // 8
CalculatorDesignSystem.spacingM      // 16
CalculatorDesignSystem.spacingL      // 24
CalculatorDesignSystem.spacingXL     // 32
CalculatorDesignSystem.spacingXXL    // 40

// Хелперы
CalculatorDesignSystem.verticalSpacingM    // SizedBox(height: 16)
CalculatorDesignSystem.horizontalSpacingS  // SizedBox(width: 8)
```

### Радиусы скругления

```dart
CalculatorDesignSystem.radiusS      // 8
CalculatorDesignSystem.radiusM      // 12
CalculatorDesignSystem.radiusL      // 16
CalculatorDesignSystem.radiusXL     // 20
CalculatorDesignSystem.radiusXXL    // 24

CalculatorDesignSystem.cardBorderRadius       // BorderRadius.circular(16)
CalculatorDesignSystem.inputBorderRadius      // BorderRadius.circular(8)
CalculatorDesignSystem.selectorBorderRadius   // BorderRadius.circular(12)
```

### Декорации

```dart
// Карточка с тенью
Container(
  decoration: CalculatorDesignSystem.cardDecoration(),
  child: ...,
)

// Карточка без тени
Container(
  decoration: CalculatorDesignSystem.cardDecorationFlat(),
  child: ...,
)

// Поле ввода
TextField(
  decoration: CalculatorDesignSystem.inputDecoration(
    label: 'Длина',
    hint: 'Введите длину в метрах',
  ),
)

// Divider
CalculatorDesignSystem.divider()
```

---

## 📝 Примеры использования

### Полный пример калькулятора

```dart
import 'package:flutter/material.dart';
import 'package:prorab/core/constants/calculator_colors.dart';
import 'package:prorab/presentation/widgets/calculator/calculator_scaffold.dart';
import 'package:prorab/presentation/widgets/calculator/calculator_result_header.dart';
import 'package:prorab/presentation/widgets/calculator/type_selector_card.dart';
import 'package:prorab/presentation/widgets/calculator/input_group.dart';
import 'package:prorab/presentation/widgets/calculator/mode_selector.dart';

class MyCalculatorScreen extends StatefulWidget {
  @override
  State<MyCalculatorScreen> createState() => _MyCalculatorScreenState();
}

class _MyCalculatorScreenState extends State<MyCalculatorScreen> {
  int _mode = 0;
  int _selectedType = 0;
  double _area = 0;
  int _bags = 0;

  void _calculate() {
    // Логика расчёта
    setState(() {
      _area = 35.9;
      _bags = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'Мой калькулятор',
      accentColor: CalculatorColors.interior,
      resultHeader: CalculatorResultHeader(
        accentColor: CalculatorColors.interior,
        results: [
          ResultItem(label: 'ПЛОЩАДЬ', value: '$_area м²'),
          ResultItem(label: 'МАТЕРИАЛ', value: '$_bags мешков'),
          ResultItem(label: 'СТОИМОСТЬ', value: '${_bags * 500} ₽'),
        ],
      ),
      children: [
        // Выбор типа
        TypeSelectorGroup(
          options: [
            TypeSelectorOption(icon: Icons.home, title: 'Вариант 1'),
            TypeSelectorOption(icon: Icons.business, title: 'Вариант 2'),
          ],
          selectedIndex: _selectedType,
          onSelect: (i) => setState(() => _selectedType = i),
          accentColor: CalculatorColors.interior,
        ),

        SizedBox(height: 16),

        // Переключатель режима
        ModeSelector(
          options: ['Комната', 'Список стен'],
          selectedIndex: _mode,
          onSelect: (i) => setState(() => _mode = i),
          accentColor: CalculatorColors.interior,
        ),

        SizedBox(height: 16),

        // Группа полей ввода
        InputGroup(
          title: 'Геометрия',
          icon: Icons.straighten,
          accentColor: CalculatorColors.interior,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Длина'),
              onChanged: (v) => _calculate(),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: 'Ширина'),
              onChanged: (v) => _calculate(),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## ✅ Чеклист для нового калькулятора

При создании нового калькулятора убедитесь, что:

- [ ] Используется `CalculatorScaffold` с правильным акцентным цветом
- [ ] Header с результатами (`CalculatorResultHeader`) показывает 2-4 ключевых значения
- [ ] Выбор типа материала реализован через `TypeSelectorCard`
- [ ] Поля сгруппированы в `InputGroup` по логическим секциям
- [ ] Переключение режимов использует `ModeSelector`
- [ ] Цвета соответствуют категории калькулятора
- [ ] Все отступы, радиусы и шрифты из `CalculatorDesignSystem`
- [ ] Фон экрана светлый (`CalculatorColors.backgroundPrimary`)
- [ ] Результаты видны сразу без прокрутки

---

## 🔄 Миграция существующих калькуляторов

Если у вас есть старый калькулятор с тёмной темой или другим стилем:

1. Замените `Scaffold` на `CalculatorScaffold`
2. Добавьте `CalculatorResultHeader` в начало
3. Оберните группы полей в `InputGroup`
4. Замените dropdown на `TypeSelectorCard` где возможно
5. Используйте `ModeSelector` вместо кастомных табов
6. Обновите цвета на соответствующие категории

---

*Дизайн-система создана: 23.12.2025*
*Эталон: калькулятор "Шпатлёвка" (putty_calculator_screen.dart)*
