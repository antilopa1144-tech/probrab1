#!/usr/bin/env python3
"""
Скрипт для автоматической миграции категорий калькуляторов V2.
Заменяет старые категории на новые: interior/exterior.
"""

import os
import re

# Маппинг старых категорий на новые
CATEGORY_MAPPING = {
    'foundation': 'exterior',        # Фундамент → Наружная
    'walls': 'exterior',             # Стены (конструкция) → Наружная
    'roofing': 'exterior',           # Кровля → Наружная
    'flooring': 'interior',          # Полы → Внутренняя
    'ceilings': 'interior',          # Потолки → Внутренняя
    'wallFinishing': 'interior',     # Отделка стен → Внутренняя
    'insulation': 'exterior',        # Утепление → Наружная
    'engineering': 'interior',       # Инженерные системы → Внутренняя
    'windowsDoors': 'interior',      # Окна и двери → Внутренняя
    'facade': 'exterior',            # Фасад → Наружная
    'auxiliary': 'exterior',         # Вспомогательные → Наружная
    'other': 'interior',             # Прочее → Внутренняя
}

def migrate_file(file_path):
    """Мигрирует категории в одном файле."""
    print(f"Processing: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    changes = []

    # Ищем паттерн: category: CalculatorCategory.XXXX
    pattern = r'category:\s*CalculatorCategory\.(\w+)'

    def replacer(match):
        old_category = match.group(1)
        new_category = CATEGORY_MAPPING.get(old_category, old_category)

        if old_category != new_category:
            changes.append(f"  {old_category} -> {new_category}")

        return f'category: CalculatorCategory.{new_category}'

    content = re.sub(pattern, replacer, content)

    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"  [OK] Updated {len(changes)} categories:")
        for change in changes:
            print(change)
        return True
    else:
        print(f"  [SKIP] No changes needed")
        return False

def main():
    """Главная функция - мигрирует все V2 калькуляторы."""
    calculators_dir = r'c:\probrab1\lib\domain\calculators'

    # Находим все файлы *_v2.dart
    v2_files = []
    for file in os.listdir(calculators_dir):
        if file.endswith('_v2.dart') and file != 'calculator_definition_v2.dart':
            v2_files.append(os.path.join(calculators_dir, file))

    print(f"Found {len(v2_files)} V2 calculator files\n")

    updated_count = 0
    for file_path in v2_files:
        if migrate_file(file_path):
            updated_count += 1
        print()

    print(f"\n{'='*60}")
    print(f"Migration complete!")
    print(f"Updated: {updated_count}/{len(v2_files)} files")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
