#!/usr/bin/env python3
"""
Скрипт для удаления поля 'perimeter' из калькуляторов V2.
"""

import os
import re

FILES = [
    r'c:\probrab1\lib\domain\calculators\strip_foundation_calculator_v2.dart',
    r'c:\probrab1\lib\domain\calculators\slab_foundation_calculator_v2.dart',
    r'c:\probrab1\lib\domain\calculators\parquet_calculator_v2.dart',
    r'c:\probrab1\lib\domain\calculators\metal_roofing_calculator_v2.dart',
    r'c:\probrab1\lib\domain\calculators\laminate_calculator_v2.dart',
    r'c:\probrab1\lib\domain\calculators\gkl_ceiling_calculator_v2.dart',
]

def remove_perimeter_field(content):
    """Удаляет блок CalculatorField с key: 'perimeter'."""
    # Паттерн для поиска всего блока CalculatorField с perimeter
    pattern = r',?\s*(?:const\s+)?CalculatorField\s*\(\s*key:\s*[\'"]perimeter[\'"],[^)]*\),?\s*'

    # Удаляем блок
    result = re.sub(pattern, '', content, flags=re.DOTALL)

    return result

def main():
    """Главная функция."""
    print("Removing 'perimeter' field from calculators...\n")

    for file_path in FILES:
        if not os.path.exists(file_path):
            print(f"[SKIP] {os.path.basename(file_path)} - file not found")
            continue

        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()

        new_content = remove_perimeter_field(original_content)

        if original_content != new_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"[OK] {os.path.basename(file_path)} - perimeter removed")
        else:
            print(f"[SKIP] {os.path.basename(file_path)} - no perimeter found")

    print("\nDone!")

if __name__ == '__main__':
    main()
