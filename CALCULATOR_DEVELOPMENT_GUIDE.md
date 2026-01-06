# 📐 Руководство по Созданию Новых Калькуляторов

## 🎯 Цель документа
Этот файл содержит reference для AI-ассистента при создании новых кастомных калькуляторов в проекте ПроРаб AI.

---

## ⭐ Эталонные Калькуляторы (Идеалы)

Используй эти калькуляторы как reference при создании новых:

### 1. **PuttyCalculatorScreen** (`lib/presentation/views/calculator/putty_calculator_screen.dart`)
**Почему идеален:**
- ✅ Использует отдельный State файл (`part of`)
- ✅ Поддержка Remote Config через `CalculatorConstants`
- ✅ Множественные режимы расчета (комната/стены)
- ✅ Динамические списки (стены, проемы)
- ✅ Продвинутая логика с условиями (обои vs покраска)
- ✅ Экспорт и шаринг результатов
- ✅ Подсказки (hints) с типами
- ✅ Полная локализация

**Структура:**
```dart
// 1. Helper class для констант
class _PuttyConstants {
  final CalculatorConstants? _data;
  _PuttyConstants(this._data);

  double _getDouble(String category, String key, double defaultValue) {...}
  int _getInt(String category, String key, int defaultValue) {...}

  // Геттеры для всех констант
  double get startConsumptionPerLayer => _getDouble('start_putty', 'consumption_per_layer', 1.0);
}

// 2. Enums для режимов
enum CalculationMode { room, walls }
enum FinishTarget { wallpaper, painting }

// 3. Модели данных
class Wall {
  String id;
  double length;
  double height;
}

class PuttyResult {
  final double netArea;
  final int startBags;
  // ... все результаты
}

// 4. StatefulWidget + отдельный State
class PuttyCalculatorScreen extends StatefulWidget {...}
part 'putty_calculator_screen_state.dart';
```

### 2. **PaintScreen** (`lib/presentation/views/paint/paint_screen.dart`)
**Почему идеален:**
- ✅ Простая и чистая структура
- ✅ Множественные типы поверхностей с факторами
- ✅ Переключение между типами (интерьер/фасад)
- ✅ Два режима ввода (комната/площадь)
- ✅ Генерация экспорта в текст

**Ключевые паттерны:**
```dart
// Данные с факторами
final List<List<Map<String, dynamic>>> _surfaces = [
  // Интерьер
  [
    {'name': 'Гладкая (х1.0)', 'factor': 1.0},
    {'name': 'Обои (х1.2)', 'factor': 1.2},
  ],
  // Фасад
  [...]
];

// Обработка изменения типа
void _onPaintTypeChanged(int newType) {
  setState(() {
    _paintType = newType;
    _surfaceIndex = 0;
    _coverage = newType == 0 ? 10.0 : 7.0;
  });
}
```

### 3. **GasblockalculatorScreen** (`lib/presentation/views/calculator/gasblock_calculator_screen.dart`)
**Почему идеален:**
- ✅ Пример использования дизайн-системы калькуляторов
- ✅ Modern UI components
- ✅ Type selector для выбора режимов

---

## 🏗️ Обязательная Структура Нового Калькулятора

### 📁 Файловая структура

```
lib/presentation/views/
  ├─ calculator/
  │   ├─ my_new_calculator_screen.dart          # Основной файл
  │   └─ my_new_calculator_screen_state.dart    # State (если сложный)
  └─ my_new_feature/                            # ИЛИ отдельная папка
      └─ my_new_screen.dart
```

### 📝 Шаблон кода

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

// 1. HELPER CLASS ДЛЯ КОНСТАНТ (если используются Remote Config)
class _MyCalculatorConstants {
  final CalculatorConstants? _data;

  _MyCalculatorConstants(this._data);

  double _getDouble(String category, String key, double defaultValue) {
    return _data?.getDouble(category, key, defaultValue: defaultValue) ?? defaultValue;
  }

  // Геттеры для всех констант
  double get myConstant => _getDouble('my_category', 'my_key', 10.0);
}

// 2. ENUMS ДЛЯ РЕЖИМОВ
enum MyCalculationMode { simple, advanced }

// 3. МОДЕЛИ ДАННЫХ
class MyInputData {
  String id;
  double value;

  MyInputData({required this.id, this.value = 0.0});
}

class MyResult {
  final double area;
  final int materials;
  final double cost;

  MyResult({
    required this.area,
    required this.materials,
    required this.cost,
  });
}

// 4. ОСНОВНОЙ ВИДЖЕТ
class MyCalculatorScreen extends StatefulWidget {
  const MyCalculatorScreen({super.key});

  @override
  State<MyCalculatorScreen> createState() => _MyCalculatorScreenState();
}

// 5. STATE
class _MyCalculatorScreenState extends State<MyCalculatorScreen> {
  // Состояние
  MyCalculationMode _mode = MyCalculationMode.simple;

  // Входные данные
  double _width = 4.0;
  double _height = 2.7;

  // Результат
  MyResult? _result;

  // Локализация
  AppLocalizations get _loc => AppLocalizations.of(context);

  // Константы (опционально)
  final _constants = _MyCalculatorConstants(null);

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  // ЛОГИКА РАСЧЕТА
  void _calculate() {
    final area = _width * _height;
    final materials = (area / 2).ceil();

    setState(() {
      _result = MyResult(
        area: area,
        materials: materials,
        cost: materials * 100.0,
      );
    });
  }

  // ЭКСПОРТ
  String _generateExportText() {
    final r = _result;
    if (r == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('📐 МОЙ КАЛЬКУЛЯТОР');
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln('Площадь: ${r.area.toStringAsFixed(1)} м²');
    buffer.writeln('Материалы: ${r.materials} шт');
    buffer.writeln();
    buffer.writeln('Создано в ПроРаб');

    return buffer.toString();
  }

  Future<void> _shareCalculation() async {
    final text = _generateExportText();
    await SharePlus.instance.share(ShareParams(text: text, subject: 'Расчет'));
  }

  void _copyToClipboard() {
    final text = _generateExportText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_loc.translate('common.copied_to_clipboard')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // UI BUILD
  @override
  Widget build(BuildContext context) {
    const accentColor = CalculatorColors.foundation; // Выбери категорию

    return CalculatorScaffold(
      title: _loc.translate('my_calc.title'),
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _copyToClipboard,
          tooltip: _loc.translate('common.copy'),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareCalculation,
          tooltip: _loc.translate('common.share'),
        ),
      ],
      resultHeader: _buildSummaryHeader(),
      children: [
        _buildInputSection(),
        const SizedBox(height: 16),
        _buildResultCard(),
        const SizedBox(height: 24),
        _buildTipsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    return CalculatorResultHeader(
      accentColor: CalculatorColors.foundation,
      results: [
        ResultItem(
          label: 'ПЛОЩАДЬ',
          value: '${_result?.area.toStringAsFixed(1) ?? 0} м²',
          icon: Icons.straighten,
        ),
        ResultItem(
          label: 'МАТЕРИАЛЫ',
          value: '${_result?.materials ?? 0} шт',
          icon: Icons.shopping_bag,
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return InputGroup(
      title: _loc.translate('my_calc.section.dimensions'),
      children: [
        Row(children: [
          Expanded(
            child: CalculatorTextField(
              label: _loc.translate('my_calc.input.width'),
              value: _width,
              onChanged: (v) {
                _width = v;
                _calculate();
              },
              suffix: 'м',
              accentColor: CalculatorColors.foundation,
              minValue: 0.1,
              maxValue: 50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CalculatorTextField(
              label: _loc.translate('my_calc.input.height'),
              value: _height,
              onChanged: (v) {
                _height = v;
                _calculate();
              },
              suffix: 'м',
              accentColor: CalculatorColors.foundation,
              minValue: 0.1,
              maxValue: 50,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildResultCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('my_calc.result.material_name'),
        value: '${_result?.materials ?? 0} шт',
        subtitle: 'Описание материала',
        icon: Icons.build,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('my_calc.section.materials'),
      titleIcon: Icons.check_circle,
      items: items,
      accentColor: CalculatorColors.foundation,
    );
  }

  Widget _buildTipsSection() {
    const hints = [
      CalculatorHint(
        type: HintType.important,
        messageKey: 'hint.my_calc.important_tip',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.my_calc.useful_tip',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _loc.translate('common.tips'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
        ),
        const HintsList(hints: hints),
      ],
    );
  }
}
```

---

## 🎨 Дизайн-система

### Цвета категорий (CalculatorColors)
```dart
CalculatorColors.foundation   // Фундамент (синий)
CalculatorColors.walls        // Стены (оранжевый)
CalculatorColors.roofing      // Кровля (красный)
CalculatorColors.flooring     // Полы (коричневый)
CalculatorColors.ceiling      // Потолки (фиолетовый)
CalculatorColors.facade       // Фасад (зеленый)
CalculatorColors.interior     // Интерьер (розовый)
CalculatorColors.engineering  // Инженерия (голубой)
```

### Компоненты дизайн-системы

```dart
// 1. Основной контейнер
CalculatorScaffold(
  title: 'Название',
  accentColor: CalculatorColors.foundation,
  actions: [...],
  resultHeader: ...,
  children: [...],
)

// 2. Хедер с результатами
CalculatorResultHeader(
  accentColor: color,
  results: [
    ResultItem(label: 'LABEL', value: 'value', icon: Icons.icon),
  ],
)

// 3. Группа полей ввода
InputGroup(
  title: 'Заголовок',
  children: [...],
)

// 4. Поле ввода
CalculatorTextField(
  label: 'Метка',
  value: _value,
  onChanged: (v) => setState(() => _value = v),
  suffix: 'м',
  accentColor: color,
  minValue: 0.1,
  maxValue: 50,
  isInteger: false, // true для целых чисел
)

// 5. Селектор режимов
ModeSelector(
  options: ['Режим 1', 'Режим 2'],
  selectedIndex: _mode,
  onSelect: (index) => setState(() => _mode = index),
  accentColor: color,
)

// 6. Селектор типов
TypeSelectorGroup(
  options: [
    TypeSelectorOption(
      icon: Icons.icon1,
      title: 'Тип 1',
      subtitle: 'Описание',
    ),
  ],
  selectedIndex: _selectedType,
  onSelect: (index) => {...},
  accentColor: color,
)

// 7. Карточка материалов (ОБЯЗАТЕЛЬНО для списков)
MaterialsCardModern(
  title: 'Материалы',
  titleIcon: Icons.check_circle,
  items: [
    MaterialItem(
      name: 'Название',
      value: '100 шт',
      subtitle: 'Описание',
      icon: Icons.build,
    ),
  ],
  accentColor: color,
)

// 8. Подсказки
const HintsList(hints: [
  CalculatorHint(
    type: HintType.important,
    messageKey: 'hint.key',
  ),
])
```

---

## 📋 Чек-лист для Нового Калькулятора

### ✅ Обязательные элементы:
- [ ] Использует `CalculatorScaffold` как основу
- [ ] Имеет `CalculatorResultHeader` с основными результатами
- [ ] Использует `InputGroup` для группировки полей
- [ ] Использует `CalculatorTextField` для всех числовых полей
- [ ] Использует `MaterialsCardModern` для списка материалов
- [ ] Имеет секцию с подсказками `HintsList`
- [ ] Поддерживает экспорт (copy + share)
- [ ] Все строки локализованы через `_loc.translate()`
- [ ] Имеет правильный accentColor из категории
- [ ] Расчет вызывается в `initState()` и при изменениях

### ✅ Дополнительные (по необходимости):
- [ ] Helper class для Remote Config констант
- [ ] Enums для режимов работы
- [ ] Модели данных для входных/выходных значений
- [ ] Отдельный State файл (если >200 строк)
- [ ] Динамические списки (если нужны)
- [ ] `ModeSelector` для переключения режимов
- [ ] `TypeSelectorGroup` для выбора типов

---

## 🚫 Что НЕ делать

1. ❌ **НЕ создавай** кастомные UI компоненты - используй дизайн-систему
2. ❌ **НЕ используй** прямые числа в коде - используй константы или Remote Config
3. ❌ **НЕ хардкодь** тексты - все через локализацию
4. ❌ **НЕ используй** `TextField` напрямую - только `CalculatorTextField`
5. ❌ **НЕ создавай** свои карточки - только `MaterialsCardModern`
6. ❌ **НЕ забывай** про hints - пользователи любят подсказки
7. ❌ **НЕ забывай** про экспорт и шаринг

---

## 📚 Примеры Использования

### Пример 1: Простой калькулятор площади
```dart
// См. paint_screen.dart - отличный пример простого калькулятора
```

### Пример 2: Калькулятор с динамическими списками
```dart
// См. putty_calculator_screen.dart - пример с списками стен и проемов
```

### Пример 3: Калькулятор с Remote Config
```dart
// См. putty_calculator_screen.dart - использует _PuttyConstants
```

---

## 🎓 Локализация

### Структура ключей:
```
my_calc.title                          // Название калькулятора
my_calc.section.dimensions             // Секция "Размеры"
my_calc.input.width                    // Поле "Ширина"
my_calc.result.material_name           // Название материала
my_calc.summary.area                   // Итог "Площадь"
hint.my_calc.important_tip             // Важная подсказка
hint.my_calc.useful_tip                // Полезная подсказка
```

### Добавление в JSON:
```json
{
  "my_calc": {
    "title": "Мой Калькулятор",
    "section": {
      "dimensions": "Размеры"
    },
    "input": {
      "width": "Ширина",
      "height": "Высота"
    }
  },
  "hint": {
    "my_calc": {
      "important_tip": "Важная подсказка",
      "useful_tip": "Полезная подсказка"
    }
  }
}
```

---

## 🧪 Тестирование

После создания калькулятора, создай тест:

```dart
// test/presentation/views/my_calc/my_calculator_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/my_calc/my_calculator_screen.dart';

void main() {
  group('MyCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MyCalculatorScreen()),
      );

      expect(find.byType(MyCalculatorScreen), findsOneWidget);
    });

    testWidgets('calculates correctly', (tester) async {
      // Тестируй логику расчета
    });
  });
}
```

---

## 📞 Регистрация Калькулятора

### 1. Добавь в CalculatorRegistry
```dart
// lib/domain/calculators/calculator_registry.dart
// Добавь определение в соответствующую категорию
```

### 2. Добавь маршрут (если нужен прямой доступ)
```dart
// Обычно не требуется, используется через pro_calculator_screen
```

---

## 🎯 Итоговая Формула Успеха

```
Идеальный Калькулятор =
  (PuttyCalculatorScreen ∪ PaintScreen)
  + CalculatorWidgets
  + Локализация
  + Remote Config (опционально)
  + Тесты
  - Хардкод
  - Кастомные UI
```

**Следуй эталонам, используй дизайн-систему, локализуй всё!** 🚀
