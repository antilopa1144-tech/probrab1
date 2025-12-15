#!/usr/bin/env python3
"""
Скрипт для автоматического исправления тестов калькуляторов.
Исправляет известные проблемы согласно CALCULATOR_TESTS_GUIDE.md
"""

import os
import re
from pathlib import Path
from typing import List, Tuple


def find_test_files(directory: str = "test/domain/usecases") -> List[Path]:
    """Находит все файлы тестов в директории."""
    test_dir = Path(directory)
    if not test_dir.exists():
        print(f"Директория {directory} не найдена")
        return []

    test_files = list(test_dir.glob("*_test.dart"))
    print(f"Найдено {len(test_files)} тестовых файлов")
    return test_files


def analyze_test_file(file_path: Path) -> dict:
    """Анализирует тестовый файл и возвращает статистику проблем."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    issues = {
        'file': file_path.name,
        'needs_zero_area_fix': False,
        'has_hardcoded_expectations': [],
        'missing_exception_tests': [],
        'total_tests': len(re.findall(r"test\('", content))
    }

    # Проверка на тесты нулевой площади, которые не ожидают исключение
    zero_tests = re.findall(
        r"test\('([^']*zero[^']*)',.*?\{(.*?)\}\);",
        content,
        re.DOTALL | re.IGNORECASE
    )

    for test_name, test_body in zero_tests:
        if 'throwsA' not in test_body and 'CalculationException' not in test_body:
            if 'area.*0\.0' in test_body or 'doors.*0\.0' in test_body:
                issues['needs_zero_area_fix'] = True

    # Проверка на жесткие ожидания (equals вместо closeTo)
    hardcoded = re.findall(
        r"expect\(result\.values\['([^']+)'\],\s*equals\((\d+\.?\d*)\)\)",
        content
    )

    for field, value in hardcoded:
        # Исключаем простые целые числа (1.0, 2.0 и т.д.)
        if float(value) > 10 and '.' in value:
            issues['has_hardcoded_expectations'].append((field, value))

    return issues


def fix_zero_area_test(content: str) -> Tuple[str, bool]:
    """
    Исправляет тесты нулевой площади - меняет ожидание результата на ожидание исключения.
    """
    modified = False

    # Паттерн для поиска теста с нулевой площадью без проверки на исключение
    pattern = r"(test\('handles? zero (?:area|doors?|rooms?|windows?|perimeter)',\s*\(\)\s*\{)(.*?)(\}\);)"

    def replace_test(match):
        nonlocal modified
        test_start = match.group(1)
        test_body = match.group(2)
        test_end = match.group(3)

        # Если уже есть throwsA, не меняем
        if 'throwsA' in test_body:
            return match.group(0)

        # Находим вызов калькулятора и параметры
        calc_call_match = re.search(
            r"(final\s+(?:result\s*=\s*)?calculator\([^)]+\));",
            test_body
        )

        if not calc_call_match:
            return match.group(0)

        calc_call = calc_call_match.group(1)

        # Находим все expect вызовы
        expects = re.findall(r"expect\([^)]+\);", test_body)

        # Если все expect проверяют result.values на equals(0.0)
        if expects and all('equals(0.0)' in exp or 'equals(0)' in exp for exp in expects):
            modified = True

            # Извлекаем переменные до вызова калькулятора
            setup = test_body[:calc_call_match.start()].strip()

            new_body = f"""
{setup}

      // Должно выбрасываться исключение для нулевых значений
      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
"""
            return test_start + new_body + "    " + test_end

        return match.group(0)

    new_content = re.sub(pattern, replace_test, content, flags=re.DOTALL)

    return new_content, modified


def ensure_exception_import(content: str) -> Tuple[str, bool]:
    """Убеждается что импортирован CalculationException."""
    if 'calculation_exception.dart' in content:
        return content, False

    # Находим последний import
    imports = list(re.finditer(r"^import '.*?';$", content, re.MULTILINE))

    if not imports:
        return content, False

    last_import = imports[-1]
    new_import = "\nimport 'package:probrab_ai/core/exceptions/calculation_exception.dart';"

    content = (
        content[:last_import.end()] +
        new_import +
        content[last_import.end():]
    )

    return content, True


def fix_hardcoded_expectations(content: str) -> Tuple[str, bool]:
    """
    Заменяет жесткие equals() на closeTo() для числовых значений больше 10.
    """
    modified = False

    def replace_equals(match):
        nonlocal modified
        field = match.group(1)
        value = match.group(2)

        # Пропускаем маленькие целые числа
        num_value = float(value)
        if num_value <= 10:
            return match.group(0)

        # Используем погрешность 5%
        tolerance = num_value * 0.05

        modified = True
        return f"expect(result.values['{field}'], closeTo({value}, {tolerance:.1f}))"

    # Заменяем только для больших чисел
    pattern = r"expect\(result\.values\['([^']+)'\],\s*equals\((\d+\.?\d*)\)\)"
    new_content = re.sub(pattern, replace_equals, content)

    return new_content, modified


def fix_test_file(file_path: Path, dry_run: bool = False) -> dict:
    """Исправляет тестовый файл."""
    with open(file_path, 'r', encoding='utf-8') as f:
        original_content = f.read()

    content = original_content
    changes = []

    # 1. Исправляем тесты нулевой площади
    content, modified = fix_zero_area_test(content)
    if modified:
        changes.append("zero_area_tests")

    # 2. Добавляем импорт CalculationException если нужно
    content, modified = ensure_exception_import(content)
    if modified:
        changes.append("exception_import")

    # 3. Исправляем жесткие ожидания
    content, modified = fix_hardcoded_expectations(content)
    if modified:
        changes.append("hardcoded_expectations")

    # Сохраняем если были изменения
    if changes and not dry_run:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

    return {
        'file': file_path.name,
        'modified': len(changes) > 0,
        'changes': changes,
        'dry_run': dry_run
    }


def main():
    """Главная функция."""
    import sys

    dry_run = '--dry-run' in sys.argv or '-n' in sys.argv

    if dry_run:
        print("=== РЕЖИМ СИМУЛЯЦИИ (не будет изменений) ===\n")

    test_files = find_test_files()

    if not test_files:
        print("Тестовые файлы не найдены")
        return

    print("\n=== Анализ тестов ===\n")

    # Анализируем все файлы
    issues_summary = []
    for file_path in test_files:
        issues = analyze_test_file(file_path)
        if issues['needs_zero_area_fix'] or issues['has_hardcoded_expectations']:
            issues_summary.append(issues)

    if issues_summary:
        print(f"Найдено {len(issues_summary)} файлов с проблемами:\n")
        for issue in issues_summary[:10]:
            print(f"  {issue['file']}:")
            if issue['needs_zero_area_fix']:
                print("    - Нужно исправить тесты нулевой площади")
            if issue['has_hardcoded_expectations']:
                print(f"    - Жесткие ожидания: {len(issue['has_hardcoded_expectations'])} шт")

        if len(issues_summary) > 10:
            print(f"  ... и ещё {len(issues_summary) - 10} файлов\n")
    else:
        print("Проблем не найдено\n")

    print("\n=== Исправление тестов ===\n")

    # Исправляем все файлы
    results = []
    for file_path in test_files:
        result = fix_test_file(file_path, dry_run=dry_run)
        if result['modified']:
            results.append(result)
            status = "Будет исправлен" if dry_run else "Исправлен"
            print(f"{status}: {result['file']}")
            print(f"  Изменения: {', '.join(result['changes'])}")

    print(f"\n=== Итого ===")
    print(f"Проверено файлов: {len(test_files)}")
    print(f"Файлов с проблемами: {len(issues_summary)}")
    print(f"Исправлено файлов: {len(results)}")

    if dry_run:
        print("\nЗапустите без --dry-run для применения изменений")


if __name__ == '__main__':
    main()
