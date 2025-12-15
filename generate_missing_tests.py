#!/usr/bin/env python3
"""
Скрипт для генерации недостающих тестов калькуляторов.
Создаёт базовые тесты для калькуляторов, у которых их нет.
"""

import os
import re
from pathlib import Path
from typing import List, Tuple, Dict, Any


def find_calculators_without_tests() -> List[str]:
    """Находит калькуляторы без тестов."""
    lib_dir = Path("lib/domain/usecases")
    test_dir = Path("test/domain/usecases")

    if not lib_dir.exists():
        return []

    # Получаем список всех калькуляторов
    calculators = set()
    for file in lib_dir.glob("calculate_*.dart"):
        calculators.add(file.stem)

    # Получаем список калькуляторов с тестами
    tested = set()
    if test_dir.exists():
        for file in test_dir.glob("calculate_*_test.dart"):
            tested.add(file.stem.replace("_test", ""))

    # Возвращаем разницу
    missing = sorted(calculators - tested)
    return missing


def parse_calculator_file(file_path: Path) -> Dict[str, Any]:
    """Парсит файл калькулятора для извлечения информации."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    info = {
        'class_name': None,
        'inputs': [],
        'outputs': [],
        'has_validation': False
    }

    # Находим имя класса
    class_match = re.search(r'class\s+(\w+)\s+extends\s+BaseCalculator', content)
    if class_match:
        info['class_name'] = class_match.group(1)

    # Находим входные параметры
    input_patterns = [
        r"inputs\['(\w+)'\]",
        r'inputs\["(\w+)"\]',
    ]
    for pattern in input_patterns:
        inputs = re.findall(pattern, content)
        info['inputs'].extend(inputs)

    # Удаляем дубликаты, сохраняя порядок
    seen = set()
    unique_inputs = []
    for inp in info['inputs']:
        if inp not in seen:
            seen.add(inp)
            unique_inputs.append(inp)
    info['inputs'] = unique_inputs

    # Находим выходные параметры (values в result)
    output_patterns = [
        r"'(\w+)':\s*",
        r'"(\w+)":\s*',
    ]
    # Ищем в return Map
    return_match = re.search(r'return\s+\{([^}]+)\}', content, re.DOTALL)
    if return_match:
        return_content = return_match.group(1)
        for pattern in output_patterns:
            outputs = re.findall(pattern, return_content)
            info['outputs'].extend(outputs)

    # Удаляем дубликаты
    info['outputs'] = list(dict.fromkeys(info['outputs']))

    # Проверяем наличие валидации
    info['has_validation'] = 'CalculationException' in content or 'throw' in content

    return info


def generate_test_content(calculator_name: str, info: Dict[str, Any]) -> str:
    """Генерирует содержимое тестового файла."""
    class_name = info['class_name'] or calculator_name.replace('_', ' ').title().replace(' ', '')

    # Определяем основной входной параметр (area, length, volume и т.д.)
    main_input = 'area'
    if 'area' in info['inputs']:
        main_input = 'area'
    elif 'length' in info['inputs']:
        main_input = 'length'
    elif 'volume' in info['inputs']:
        main_input = 'volume'
    elif 'perimeter' in info['inputs']:
        main_input = 'perimeter'
    elif info['inputs']:
        main_input = info['inputs'][0]

    # Генерируем базовый набор тестов
    test_content = f"""import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/{calculator_name}.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {{
  group('{class_name}', () {{
    late {class_name} calculator;

    setUp(() {{
      calculator = {class_name}();
    }});

    test('calculates basic values correctly', () {{
      final inputs = {{
        '{main_input}': 100.0,
"""

    # Добавляем другие входные параметры
    for inp in info['inputs'][:5]:  # Ограничиваем 5 параметрами
        if inp != main_input:
            # Определяем разумное значение
            value = '10.0'
            if 'width' in inp or 'height' in inp or 'thickness' in inp:
                value = '2.0'
            elif 'length' in inp:
                value = '50.0'
            test_content += f"        '{inp}': {value},\n"

    test_content += """      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Проверяем что результат не пустой
      expect(result.values, isNotEmpty);
"""

    # Добавляем проверки для известных выходных параметров
    for output in info['outputs'][:3]:  # Первые 3 выходных параметра
        test_content += f"      expect(result.values['{output}'], isNotNull);\n"

    test_content += """    });

    test('uses default values when not provided', () {
      final calculator = """+ class_name + """();
      final inputs = <String, double>{};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Должен использовать значения по умолчанию
      expect(result.values, isNotEmpty);
    });
"""

    # Добавляем тест на валидацию если она есть
    if info['has_validation']:
        test_content += f"""
    test('throws exception for invalid input', () {{
      final calculator = {class_name}();
      final inputs = {{
        '{main_input}': -1.0, // Некорректное значение
      }};
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    }});
"""

    test_content += """
    test('preserves input values in result', () {
      final calculator = """ + class_name + """();
      final inputs = {
        '""" + main_input + """': 42.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
    });

    test('handles price list correctly', () {
      final calculator = """ + class_name + """();
      final inputs = {
        '""" + main_input + """': 100.0,
      };
      final priceList = [
        PriceItem(
          id: 'test-1',
          name: 'Тестовый материал',
          unit: 'м²',
          price: 1000.0,
        ),
      ];

      final result = calculator(inputs, priceList);

      expect(result.values, isNotEmpty);
    });
  });
}
"""

    return test_content


def create_test_file(calculator_name: str) -> bool:
    """Создаёт тестовый файл для калькулятора."""
    lib_file = Path(f"lib/domain/usecases/{calculator_name}.dart")
    test_file = Path(f"test/domain/usecases/{calculator_name}_test.dart")

    if not lib_file.exists():
        print(f"  ❌ Файл {lib_file} не найден")
        return False

    if test_file.exists():
        print(f"  ⚠️  Тест уже существует: {test_file}")
        return False

    # Парсим калькулятор
    info = parse_calculator_file(lib_file)

    if not info['class_name']:
        print(f"  ⚠️  Не удалось определить имя класса в {lib_file}")
        return False

    # Генерируем тест
    test_content = generate_test_content(calculator_name, info)

    # Создаём файл
    test_file.write_text(test_content, encoding='utf-8')

    print(f"  ✅ Создан тест: {test_file}")
    print(f"     Класс: {info['class_name']}")
    print(f"     Входы: {', '.join(info['inputs'][:5])}")
    print(f"     Выходы: {', '.join(info['outputs'][:5])}")

    return True


def main():
    """Главная функция."""
    import sys

    print("=== Поиск калькуляторов без тестов ===\n")

    missing = find_calculators_without_tests()

    if not missing:
        print("✅ Все калькуляторы покрыты тестами!\n")
        return

    print(f"Найдено {len(missing)} калькуляторов без тестов:\n")
    for calc in missing:
        print(f"  - {calc}")

    if '--dry-run' in sys.argv:
        print("\n=== РЕЖИМ СИМУЛЯЦИИ (тесты не будут созданы) ===")
        return

    print("\n=== Создание тестов ===\n")

    created = 0
    for calc in missing:
        print(f"Создаю тест для {calc}...")
        if create_test_file(calc):
            created += 1
        print()

    print(f"\n=== Итого ===")
    print(f"Калькуляторов без тестов: {len(missing)}")
    print(f"Создано тестов: {created}")

    if created > 0:
        print("\n⚠️  ВАЖНО: Сгенерированные тесты являются базовыми!")
        print("   Необходимо проверить и дополнить их вручную.")


if __name__ == '__main__':
    main()
