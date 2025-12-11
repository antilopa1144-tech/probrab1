#!/usr/bin/env python3
"""
Скрипт для автоматической генерации V2 калькуляторов из V1 модулей.
Анализирует модули V1 и создает соответствующие *_v2.dart файлы.
"""

import os
import re
from pathlib import Path

MODULES_DIR = r'c:\probrab1\lib\domain\calculators\modules'
CALCULATORS_DIR = r'c:\probrab1\lib\domain\calculators'
USECASES_DIR = r'c:\probrab1\lib\domain\usecases'

# Маппинг категорий V1 -> V2
CATEGORY_MAP = {
    'Фундамент': 'exterior',
    'Внутренняя отделка': 'interior',
    'Наружная отделка': 'exterior',
    'Инженерные работы': 'interior',
    'Конструкции': 'exterior',
}

# Маппинг подкатегорий на человекочитаемые имена
SUBCATEGORY_MAP = {
    'Стены': 'walls',
    'Полы': 'flooring',
    'Потолки': 'ceilings',
    'Фундамент': 'foundation',
    'Кровля': 'roofing',
    'Перегородки': 'partitions',
    'Утепление': 'insulation',
    'Ванная / туалет': 'bathroom',
    'Окна / двери': 'windows_doors',
    'Ровнители / смеси': 'mix',
    'Фасад': 'facade',
}

def extract_calculator_info(dart_content):
    """Извлекает информацию о калькуляторах из содержимого Dart файла."""
    calculators = []

    # Находим все CalculatorDefinition блоки
    pattern = r'CalculatorDefinition\((.*?)\)(?=,?\s*(?:CalculatorDefinition|]\s*;))'
    matches = re.finditer(pattern, dart_content, re.DOTALL)

    for match in matches:
        calc_text = match.group(1)

        # Извлекаем поля
        id_match = re.search(r"id:\s*'([^']+)'", calc_text)
        title_match = re.search(r"titleKey:\s*'([^']+)'", calc_text)
        category_match = re.search(r"category:\s*'([^']+)'", calc_text)
        subcategory_match = re.search(r"subCategory:\s*'([^']+)'", calc_text)
        usecase_match = re.search(r'useCase:\s*(\w+)\(\)', calc_text)

        if id_match and title_match:
            calculators.append({
                'id': id_match.group(1),
                'titleKey': title_match.group(1),
                'category': category_match.group(1) if category_match else '',
                'subCategory': subcategory_match.group(1) if subcategory_match else '',
                'useCase': usecase_match.group(1) if usecase_match else '',
            })

    return calculators

def generate_v2_file(calc_info, module_name):
    """Генерирует V2 файл калькулятора."""
    calc_id = calc_info['id']
    title_key = calc_info['titleKey']
    v1_category = calc_info['category']
    v1_subcategory = calc_info['subCategory']
    usecase_class = calc_info['useCase']

    # Определяем V2 категорию
    v2_category = CATEGORY_MAP.get(v1_category, 'interior')

    # Определяем подкатегорию
    subcategory = SUBCATEGORY_MAP.get(v1_subcategory, module_name)

    # Имя файла
    filename = f"{calc_id}_v2.dart"
    filepath = os.path.join(CALCULATORS_DIR, filename)

    # Проверяем, существует ли уже файл
    if os.path.exists(filepath):
        print(f"  [SKIP] {filename} already exists")
        return False

    # Определяем UseCase импорт
    usecase_filename = camel_to_snake(usecase_class)

    # Генерируем содержимое
    content = f'''import '../core/enums/calculator_category.dart';
import '../usecases/{usecase_filename}.dart';
import 'calculator_constants.dart';
import 'models/calculator_definition_v2.dart';
import 'models/calculator_field.dart';

/// V2 калькулятор: {title_key}
///
/// Автоматически сгенерирован из V1 модуля: {module_name}
final {calc_id}V2 = CalculatorDefinitionV2(
  id: '{calc_id}',
  titleKey: '{title_key}',
  descriptionKey: '{title_key}.description',
  category: CalculatorCategory.{v2_category},
  subCategory: '{subcategory}',
  fields: [
    // TODO: Добавить поля из V1 калькулятора
  ],
  useCase: {usecase_class}(),
  complexity: 2,
  popularity: 10,
  tags: ['{v1_category}', '{v1_subcategory}', '{module_name}'],
);
'''

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"  [OK] Created {filename}")
    return True

def camel_to_snake(name):
    """Конвертирует CamelCase в snake_case."""
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

def main():
    """Главная функция."""
    print("Analyzing V1 calculator modules...\n")

    total_calculators = 0
    created_files = 0

    # Сканируем все модули
    for module_dir in os.listdir(MODULES_DIR):
        module_path = os.path.join(MODULES_DIR, module_dir)

        if not os.path.isdir(module_path):
            continue

        # Ищем *_calculators.dart файлы
        for file in os.listdir(module_path):
            if file.endswith('_calculators.dart'):
                filepath = os.path.join(module_path, file)
                module_name = file.replace('_calculators.dart', '')

                print(f"Module: {module_name}")

                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                calculators = extract_calculator_info(content)
                total_calculators += len(calculators)

                print(f"  Found {len(calculators)} calculators")

                for calc_info in calculators:
                    if generate_v2_file(calc_info, module_name):
                        created_files += 1

                print()

    print(f"{'='*60}")
    print(f"Analysis complete!")
    print(f"Total calculators found: {total_calculators}")
    print(f"New V2 files created: {created_files}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
