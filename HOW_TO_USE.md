# Как использовать новые калькуляторы

## 🎨 Новые экраны с iOS-дизайном

### 1. Калькулятор Краски (PaintScreen)

**Как открыть:**
- Запустите приложение
- Откройте каталог калькуляторов
- Найдите "Покраска" или "Краска стен"
- Калькулятор автоматически откроется с новым дизайном

**ID калькулятора:** `paint_universal`

**Функции:**
- Переключение Интерьер/Фасад
- Выбор типа поверхности (гладкая, обои, фактурная для интерьера; бетон, кирпич, короед для фасада)
- Настройка расхода и количества слоев
- Расчет банок краски и малярного скотча
- Темная панель результатов с iOS-стилем

### 2. Калькулятор Дерева (WoodScreen)

**Как открыть:**
Калькулятор дерева пока не зарегистрирован в основном каталоге. Есть два способа:

**Вариант А: Прямая ссылка (для тестирования)**
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const WoodScreen(),
  ),
);
```

**Вариант Б: Зарегистрировать в реестре**

1. Создайте use case файл `lib/domain/usecases/calculate_wood.dart`:
```dart
import 'calculator_usecase.dart';
import 'base_calculator.dart';
import '../../data/models/price_item.dart';

class CalculateWood extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Логика из WoodScreen
    return createResult(values: {}, totalPrice: 0);
  }
}
```

2. Создайте определение калькулятора `lib/domain/calculators/wood_calculator_v2.dart` по образцу `paint_universal_calculator_v2.dart`

3. Добавьте в `lib/domain/calculators/calculator_registry.dart`:
```dart
import 'wood_calculator_v2.dart';

// В списке _allCalculators:
woodCalculatorV2,
```

**Функции:**
- Выбор материала (Антисептик, Краска, Лак, Масло)
- Выбор основы (Водная/Алкидная)
- Выбор текстуры дерева (Строганое/Пиленое)
- Умный расчет с учетом впитываемости
- Советы по инструментам

### 3. Существующие калькуляторы с обновленным дизайном

Следующие калькуляторы уже используют новый iOS-дизайн:
- **ЦПС / Стяжка** (`dsp`) - DspScreen
- **Грунтовка** (`mixes_primer`) - PrimerScreen
- **Штукатурка** (`mixes_plaster`) - PlasterCalculatorScreen
- **Шпатлевка** (`mixes_putty`) - PuttyCalculatorScreen

## 🔧 Отладка

### Если калькулятор не открывается с новым дизайном:

1. **Проверьте ID калькулятора:**
```dart
print('Calculator ID: ${calc.id}');
```

2. **Убедитесь, что навигация настроена в:**
   - `lib/presentation/utils/calculator_navigation_helper.dart` (основной роутер)
   - `lib/presentation/views/calculator/calculator_catalog_screen.dart` (каталог)

3. **Перезапустите приложение:**
```bash
flutter clean
flutter pub get
flutter run
```

### Если видите старый ProCalculatorScreen:

Это означает, что калькулятор не попал в условия специальной навигации. Проверьте:

```dart
// В calculator_navigation_helper.dart
if (definition.id == 'paint_universal' || definition.id == 'paint') {
  // Должно открыть PaintScreen
}
```

## 📝 Создание собственного калькулятора с iOS-дизайном

1. Создайте новый экран, используя шаблон:
```dart
import 'package:flutter/material.dart';
import '../dsp/project_state.dart';
import '../dsp/widgets/custom_tab_selector.dart';
import '../dsp/widgets/geometry_widget.dart';
import '../dsp/widgets/results_sheet.dart';
import '../dsp/widgets/section_card.dart';

class MyCalculatorScreen extends StatefulWidget {
  const MyCalculatorScreen({super.key});

  @override
  State<MyCalculatorScreen> createState() => _MyCalculatorScreenState();
}

class _MyCalculatorScreenState extends State<MyCalculatorScreen> {
  final ProjectState _state = ProjectState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, child) {
        final area = _state.getNetArea();

        return Scaffold(
          appBar: AppBar(title: const Text('Мой калькулятор')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GeometryWidget(state: _state),

              SectionCard(
                title: 'Параметры',
                icon: Icons.settings,
                child: Column(
                  children: [
                    // Ваши виджеты
                  ],
                ),
              ),

              ResultsSheet(
                title: 'Результаты',
                rows: [
                  ResultRow('Площадь', '$area м²'),
                  // Другие строки
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
```

2. Добавьте навигацию в `calculator_navigation_helper.dart`

3. Наслаждайтесь iOS-дизайном! 🎉

## 🎨 Доступные компоненты

- **CustomTabSelector** - переключатель вкладок с анимацией
- **ResultsSheet** - темная панель результатов
- **ResultRow** - строка в результатах
- **SectionCard** - карточка секции
- **NumberInput** - числовое поле
- **GeometryWidget** - ввод геометрии (комната/стены)
- **ProjectState** - управление состоянием геометрии

Все компоненты автоматически адаптируются под светлую/темную тему!
