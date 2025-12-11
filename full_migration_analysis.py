#!/usr/bin/env python3
"""
Полный анализ калькуляторов для миграции V1→V2.
Генерирует JSON отчет со всеми полями, переводами и нормативами.
"""

import os
import re
import json
from pathlib import Path

MODULES_DIR = r'c:\probrab1\lib\domain\calculators\modules'
USECASES_DIR = r'c:\probrab1\lib\domain\usecases'
TRANSLATIONS_FILE = r'c:\probrab1\assets\lang\ru.json'

def extract_fields_from_calculator(calc_text):
    """Извлекает все поля из CalculatorDefinition."""
    fields = []

    # Находим блок fields: const [...]
    fields_match = re.search(r'fields:\s*const\s*\[(.*?)\]', calc_text, re.DOTALL)
    if not fields_match:
        return fields

    fields_text = fields_match.group(1)

    # Находим все InputFieldDefinition
    field_pattern = r'InputFieldDefinition\((.*?)\)(?=,?\s*(?:InputFieldDefinition|\]))'
    for match in re.finditer(field_pattern, fields_text, re.DOTALL):
        field_text = match.group(1)

        key_match = re.search(r"key:\s*'([^']+)'", field_text)
        label_match = re.search(r"labelKey:\s*'([^']+)'", field_text)
        default_match = re.search(r'defaultValue:\s*([0-9.]+)', field_text)
        min_match = re.search(r'minValue:\s*([0-9.]+)', field_text)
        max_match = re.search(r'maxValue:\s*([0-9.]+)', field_text)
        required_match = re.search(r'required:\s*(true|false)', field_text)

        if key_match and label_match:
            fields.append({
                'key': key_match.group(1),
                'labelKey': label_match.group(1),
                'defaultValue': float(default_match.group(1)) if default_match else 0.0,
                'minValue': float(min_match.group(1)) if min_match else None,
                'maxValue': float(max_match.group(1)) if max_match else None,
                'required': required_match.group(1) == 'true' if required_match else True,
            })

    return fields

def extract_result_labels(calc_text):
    """Извлекает resultLabels из калькулятора."""
    labels = {}

    # Находим блок resultLabels: const {...}
    labels_match = re.search(r'resultLabels:\s*const\s*\{(.*?)\}', calc_text, re.DOTALL)
    if not labels_match:
        return labels

    labels_text = labels_match.group(1)

    # Находим все пары 'key': 'value'
    for match in re.finditer(r"'([^']+)':\s*'([^']+)'", labels_text):
        labels[match.group(1)] = match.group(2)

    return labels

def analyze_usecase_file(usecase_name):
    """Анализирует файл UseCase на наличие норм и формул."""
    usecase_filename = camel_to_snake(usecase_name) + '.dart'
    usecase_path = os.path.join(USECASES_DIR, usecase_filename)

    if not os.path.exists(usecase_path):
        return {
            'exists': False,
            'hasNorms': False,
            'norms': [],
        }

    with open(usecase_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Ищем упоминания норм
    norms_found = []

    norm_patterns = [
        r'ГЭСН[- ]?\d*',
        r'ФЕР[- ]?\d*',
        r'СНиП[- ]?[\d.]*',
        r'СП[- ]?[\d.]*',
        r'ГОСТ[- ]?[\d-]*',
    ]

    for pattern in norm_patterns:
        matches = re.findall(pattern, content, re.IGNORECASE)
        norms_found.extend(matches)

    return {
        'exists': True,
        'hasNorms': len(norms_found) > 0,
        'norms': list(set(norms_found)),
        'fileSize': len(content),
    }

def camel_to_snake(name):
    """Конвертирует CamelCase в snake_case."""
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

def load_translations():
    """Загружает переводы из ru.json."""
    with open(TRANSLATIONS_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def analyze_module(module_path, module_name, translations):
    """Анализирует один модуль калькуляторов."""
    calculators_file = os.path.join(module_path, f'{module_name}_calculators.dart')

    if not os.path.exists(calculators_file):
        return []

    with open(calculators_file, 'r', encoding='utf-8') as f:
        content = f.read()

    calculators = []

    # Находим все CalculatorDefinition
    pattern = r'CalculatorDefinition\((.*?)\)(?=,?\s*(?:CalculatorDefinition|]\s*;))'
    for match in re.finditer(pattern, content, re.DOTALL):
        calc_text = match.group(1)

        # Извлекаем основные поля
        id_match = re.search(r"id:\s*'([^']+)'", calc_text)
        title_match = re.search(r"titleKey:\s*'([^']+)'", calc_text)
        category_match = re.search(r"category:\s*'([^']+)'", calc_text)
        subcategory_match = re.search(r"subCategory:\s*'([^']+)'", calc_text)
        usecase_match = re.search(r'useCase:\s*(\w+)\(\)', calc_text)

        if not id_match or not title_match:
            continue

        calc_id = id_match.group(1)
        title_key = title_match.group(1)
        usecase_class = usecase_match.group(1) if usecase_match else 'Unknown'

        # Извлекаем поля и resultLabels
        fields = extract_fields_from_calculator(calc_text)
        result_labels = extract_result_labels(calc_text)

        # Анализируем UseCase
        usecase_info = analyze_usecase_file(usecase_class)

        # Проверяем переводы
        title_translation = translations.get('calculator', {}).get(title_key.split('.')[-1], None)

        missing_translations = []
        if not title_translation:
            missing_translations.append(title_key)

        for field in fields:
            label_parts = field['labelKey'].split('.')
            if len(label_parts) == 2:
                section, key = label_parts
                if not translations.get(section, {}).get(key):
                    missing_translations.append(field['labelKey'])

        for result_key, result_label in result_labels.items():
            label_parts = result_label.split('.')
            if len(label_parts) == 2:
                section, key = label_parts
                if not translations.get(section, {}).get(key):
                    missing_translations.append(result_label)

        calculators.append({
            'id': calc_id,
            'titleKey': title_key,
            'category': category_match.group(1) if category_match else '',
            'subCategory': subcategory_match.group(1) if subcategory_match else '',
            'useCase': usecase_class,
            'fields': fields,
            'resultLabels': result_labels,
            'useCaseInfo': usecase_info,
            'translations': {
                'title': title_translation,
                'missing': missing_translations,
            },
            'module': module_name,
        })

    return calculators

def main():
    """Главная функция."""
    print("Analyzing all V1 calculators...\n")

    translations = load_translations()
    all_calculators = []

    # Сканируем все модули
    for module_dir in os.listdir(MODULES_DIR):
        module_path = os.path.join(MODULES_DIR, module_dir)

        if not os.path.isdir(module_path):
            continue

        print(f"Module: {module_dir}")
        calculators = analyze_module(module_path, module_dir, translations)

        if calculators:
            all_calculators.extend(calculators)
            print(f"  Found {len(calculators)} calculators")

            # Статистика по нормам
            with_norms = sum(1 for c in calculators if c['useCaseInfo']['hasNorms'])
            print(f"  With norms: {with_norms}/{len(calculators)}")

            # Статистика по переводам
            with_translations = sum(1 for c in calculators if c['translations']['title'])
            print(f"  Translated: {with_translations}/{len(calculators)}")

        print()

    # Сохраняем в JSON
    output_file = r'c:\probrab1\migration_analysis.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump({
            'totalCalculators': len(all_calculators),
            'calculators': all_calculators,
            'summary': {
                'withNorms': sum(1 for c in all_calculators if c['useCaseInfo']['hasNorms']),
                'withTranslations': sum(1 for c in all_calculators if c['translations']['title']),
                'missingTranslations': sum(len(c['translations']['missing']) for c in all_calculators),
            }
        }, f, ensure_ascii=False, indent=2)

    print(f"{'='*60}")
    print(f"Analysis complete!")
    print(f"Total calculators: {len(all_calculators)}")
    print(f"With ГЭСН/ФЕР norms: {sum(1 for c in all_calculators if c['useCaseInfo']['hasNorms'])}")
    print(f"With translations: {sum(1 for c in all_calculators if c['translations']['title'])}")
    print(f"Missing translation keys: {sum(len(c['translations']['missing']) for c in all_calculators)}")
    print(f"\nReport saved to: {output_file}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
