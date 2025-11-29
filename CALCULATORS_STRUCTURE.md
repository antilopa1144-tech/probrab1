# Структура калькуляторов приложения

## Общая информация

- **Всего калькуляторов:** 54
- **Категорий:** 4
- **Подкатегорий:** 21

## Категории и калькуляторы

### 1. Фундамент (2 калькулятора)

#### 1.1 Ленточный фундамент
- **ID:** `calculator.stripTitle`
- **Файл:** `calculate_strip_foundation.dart`
- **Поля:** perimeter, width, height
- **Результаты:** concreteVolume, rebarWeight

#### 1.2 Монолитная плита
- **ID:** `foundation_slab`
- **Файл:** `calculate_slab.dart`
- **Поля:** area, thickness, insulation, perimeter
- **Результаты:** concreteVolume, rebarWeight, sandVolume, gravelVolume, waterproofingArea, formworkArea, wireNeeded, plasticizerNeeded

---

### 2. Внутренняя отделка (42 калькулятора)

#### 2.1 Стены (10 калькуляторов)

##### 2.1.1 Покраска стен
- **ID:** `walls_paint`
- **Файл:** `calculate_wall_paint.dart`

##### 2.1.2 Обои
- **ID:** `walls_wallpaper`
- **Файл:** `calculate_wallpaper.dart`

##### 2.1.3 Декоративная штукатурка
- **ID:** `walls_decor_plaster`
- **Файл:** `calculate_decorative_plaster.dart`

##### 2.1.4 Декоративный камень
- **ID:** `walls_decor_stone`
- **Файл:** `calculate_decorative_stone.dart`

##### 2.1.5 ПВХ панели
- **ID:** `walls_pvc_panels`
- **Файл:** `calculate_pvc_panels.dart`

##### 2.1.6 МДФ панели
- **ID:** `walls_mdf_panels`
- **Файл:** `calculate_mdf_panels.dart`

##### 2.1.7 3D панели
- **ID:** `walls_3d_panels`
- **Файл:** `calculate_3d_panels.dart`

##### 2.1.8 Вагонка (дерево)
- **ID:** `walls_wood`
- **Файл:** `calculate_wood_wall.dart`

##### 2.1.9 ГВЛ стены
- **ID:** `walls_gvl`
- **Файл:** `calculate_gvl_wall.dart`

##### 2.1.10 Плитка на стены
- **ID:** `walls_tile`
- **Файл:** `calculate_wall_tile.dart`

#### 2.2 Полы (8 калькуляторов)

##### 2.2.1 Ламинат
- **ID:** `floors_laminate`
- **Файл:** `calculate_laminate.dart`

##### 2.2.2 Стяжка пола
- **ID:** `floors_screed`
- **Файл:** `calculate_screed.dart`

##### 2.2.3 Напольная плитка
- **ID:** `floors_tile`
- **Файл:** `calculate_tile.dart`

##### 2.2.4 Линолеум
- **ID:** `floors_linoleum`
- **Файл:** `calculate_linoleum.dart`

##### 2.2.5 Тёплый пол
- **ID:** `floors_warm`
- **Файл:** `calculate_warm_floor.dart`

##### 2.2.6 Паркет
- **ID:** `floors_parquet`
- **Файл:** `calculate_parquet.dart`

##### 2.2.7 Наливной пол
- **ID:** `floors_self_leveling`
- **Файл:** `calculate_self_leveling_floor.dart`

##### 2.2.8 Ковролин
- **ID:** `floors_carpet`
- **Файл:** `calculate_carpet.dart`

#### 2.3 Потолки (7 калькуляторов)

##### 2.3.1 Покраска потолка
- **ID:** `ceilings_paint`
- **Файл:** `calculate_ceiling_paint.dart`

##### 2.3.2 Натяжной потолок
- **ID:** `ceilings_stretch`
- **Файл:** `calculate_stretch_ceiling.dart`

##### 2.3.3 ГКЛ потолок
- **ID:** `ceilings_gkl`
- **Файл:** `calculate_gkl_ceiling.dart`

##### 2.3.4 Реечный потолок
- **ID:** `ceilings_rail`
- **Файл:** `calculate_rail_ceiling.dart`

##### 2.3.5 Кассетный потолок
- **ID:** `ceilings_cassette`
- **Файл:** `calculate_cassette_ceiling.dart`

##### 2.3.6 Потолочная плитка
- **ID:** `ceilings_tiles`
- **Файл:** `calculate_ceiling_tiles.dart`

##### 2.3.7 Утепление потолка
- **ID:** `ceilings_insulation`
- **Файл:** `calculate_ceiling_insulation.dart`

#### 2.4 Перегородки (3 калькулятора)

##### 2.4.1 ГКЛ перегородка
- **ID:** `partitions_gkl`
- **Файл:** `calculate_gkl_partition.dart`

##### 2.4.2 Газоблок
- **ID:** `partitions_blocks`
- **Файл:** `calculate_gasblock_partition.dart`

##### 2.4.3 Кирпич
- **ID:** `partitions_brick`
- **Файл:** `calculate_brick_partition.dart`

#### 2.5 Утепление (2 калькулятора)

##### 2.5.1 Минеральная вата
- **ID:** `insulation_mineral`
- **Файл:** `calculate_insulation_mineral_wool.dart`

##### 2.5.2 Пенополистирол
- **ID:** `insulation_foam`
- **Файл:** `calculate_insulation_foam.dart`

#### 2.6 Шумоизоляция (1 калькулятор)

##### 2.6.1 Шумоизоляция
- **ID:** `insulation_sound`
- **Файл:** `calculate_sound_insulation.dart`

#### 2.7 Ванная / туалет (2 калькулятора)

##### 2.7.1 Плитка для ванной
- **ID:** `bathroom_tile`
- **Файл:** `calculate_bathroom_tile.dart`

##### 2.7.2 Гидроизоляция
- **ID:** `bathroom_waterproof`
- **Файл:** `calculate_waterproofing.dart`

#### 2.8 Ровнители / смеси (4 калькулятора)

##### 2.8.1 Шпаклёвка
- **ID:** `mixes_putty`
- **Файл:** `calculate_putty.dart`

##### 2.8.2 Грунтовка
- **ID:** `mixes_primer`
- **Файл:** `calculate_primer.dart`

##### 2.8.3 Плиточный клей
- **ID:** `mixes_tile_glue`
- **Файл:** `calculate_tile_glue.dart`

##### 2.8.4 Штукатурка
- **ID:** `mixes_plaster`
- **Файл:** `calculate_plaster.dart`

#### 2.9 Окна / двери (3 калькулятора)

##### 2.9.1 Установка окон
- **ID:** `windows_install`
- **Файл:** `calculate_window_installation.dart`

##### 2.9.2 Установка дверей
- **ID:** `doors_install`
- **Файл:** `calculate_door_installation.dart`

##### 2.9.3 Откосы
- **ID:** `slopes_finishing`
- **Файл:** `calculate_slopes.dart`

---

### 3. Наружная отделка (6 калькуляторов)

#### 3.1 Сайдинг
- **ID:** `exterior_siding`
- **Файл:** `calculate_siding.dart`

#### 3.2 Фасадные панели
- **ID:** `exterior_facade_panels`
- **Файл:** `calculate_facade_panels.dart`

#### 3.3 Деревянный фасад
- **ID:** `exterior_wood`
- **Файл:** `calculate_wood_facade.dart`

#### 3.4 Облицовочный кирпич
- **ID:** `exterior_brick`
- **Файл:** `calculate_brick_facing.dart`

#### 3.5 Мокрый фасад
- **ID:** `exterior_wet_facade`
- **Файл:** `calculate_wet_facade.dart`

#### 3.6 Кровля (3 подтипа)

##### 3.6.1 Металлическая кровля
- **ID:** `roofing_metal`
- **Файл:** `calculate_roofing_metal.dart`

##### 3.6.2 Мягкая кровля
- **ID:** `roofing_soft`
- **Файл:** `calculate_soft_roofing.dart`

##### 3.6.3 Водостоки
- **ID:** `roofing_gutters`
- **Файл:** `calculate_gutters.dart`

---

### 4. Инженерные работы (4 калькулятора)

#### 4.1 Электрика
- **ID:** `engineering_electrics`
- **Файл:** `calculate_electrics.dart`

#### 4.2 Сантехника
- **ID:** `engineering_plumbing`
- **Файл:** `calculate_plumbing.dart`

#### 4.3 Отопление
- **ID:** `engineering_heating`
- **Файл:** `calculate_heating.dart`

#### 4.4 Вентиляция
- **ID:** `engineering_ventilation`
- **Файл:** `calculate_ventilation.dart`

---

## Технические особенности

### Базовый класс
Все калькуляторы наследуются от `BaseCalculator`, который предоставляет:

- **Методы получения данных:** `getInput()`, `getIntInput()`
- **Геометрические расчёты:** `calculateVolume()`, `calculateTileArea()`, `estimatePerimeter()`
- **Расчёт материалов:** `calculateUnitsNeeded()`, `addMargin()`
- **Работа с ценами:** `findPrice()`, `calculateCost()`, `sumCosts()`
- **Формирование результата:** `createResult()`
- **Безопасные операции:** `safeDivide()`, `ceilToInt()`
- **Валидация:** `validateInputs()`

### Структура калькулятора

```dart
class CalculateExample extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    // Валидация входных данных
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Расчёты с использованием методов BaseCalculator
    return createResult(values: {...}, totalPrice: ...);
  }
}
```

### Подсказки (Tips)

Каждый калькулятор содержит 3-5 практических советов:
- Технические рекомендации
- Особенности монтажа
- Требования к материалам
- Нормы и стандарты

---

*Документ создан автоматически 27.11.2025*
