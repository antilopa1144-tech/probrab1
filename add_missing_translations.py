#!/usr/bin/env python3
"""
Скрипт для автоматического добавления недостающих переводов.
Использует analysis JSON для определения отсутствующих ключей.
"""

import json
import re

ANALYSIS_FILE = r'c:\probrab1\migration_analysis.json'
TRANSLATIONS_FILE = r'c:\probrab1\assets\lang\ru.json'

# Словарь для автоматического перевода типичных ключей
AUTO_TRANSLATIONS = {
    # Calculator titles
    'bathroomTile': 'Плитка в ванной',
    'waterproofing': 'Гидроизоляция',
    'electrics': 'Электрика',
    'plumbing': 'Сантехника',
    'heating': 'Отопление',
    'ventilation': 'Вентиляция',
    'siding': 'Сайдинг',
    'facadePanels': 'Фасадные панели',
    'woodFacade': 'Деревянный фасад',
    'brickFacade': 'Облицовочный кирпич',
    'wetFacade': 'Мокрый фасад',
    'stripTitle': 'Ленточный фундамент',
    'mineralInsulation': 'Минеральная изоляция',
    'foamInsulation': 'Пенная изоляция',
    'putty': 'Шпаклевка',
    'primer': 'Грунтовка',
    'tileGlue': 'Плиточный клей',
    'plaster': 'Штукатурка',
    'metalRoofing': 'Металлическая кровля',
    'softRoofing': 'Мягкая кровля',
    'gutters': 'Водостоки',
    'stairs': 'Лестница',
    'fence': 'Забор',
    'blindArea': 'Отмостка',
    'basement': 'Подвал / Погреб',
    'balcony': 'Балкон / Лоджия',
    'attic': 'Мансарда',
    'terrace': 'Терраса',
    'windowsInstall': 'Установка окон',
    'doorsInstall': 'Установка дверей',
    'slopesFinishing': 'Отделка откосов',

    # Input fields (уже есть многие, добавляем недостающие)
    'wallArea': 'Площадь стен',
    'floorArea': 'Площадь пола',
    'tileWidth': 'Ширина плитки',
    'tileHeight': 'Высота плитки',
    'wallHeight': 'Высота стены',
    'cableLength': 'Длина кабеля',
    'outletsCount': 'Количество розеток',
    'switchesCount': 'Количество выключателей',
    'pipeDiameter': 'Диаметр трубы',
    'pipeLength': 'Длина труб',
    'radiatorPower': 'Мощность радиатора',
    'ductDiameter': 'Диаметр воздуховода',
    'sidingWidth': 'Ширина сайдинга',
    'sidingHeight': 'Высота сайдинга',
    'panelWidth': 'Ширина панели',
    'panelHeight': 'Высота панели',
    'thickness': 'Толщина',
    'insulationType': 'Тип утепления',
    'foundationLength': 'Длина фундамента',
    'foundationDepth': 'Глубина фундамента',
    'foundationWidth': 'Ширина фундамента',
    'stairsHeight': 'Высота лестницы',
    'stepsCount': 'Количество ступеней',
    'stepWidth': 'Ширина ступени',
    'fenceHeight': 'Высота забора',
    'postSpacing': 'Расстояние между столбами',
    'windowWidth': 'Ширина окна',
    'windowHeight': 'Высота окна',
    'doorWidth': 'Ширина двери',
    'doorHeight': 'Высота двери',
    'slopeDepth': 'Глубина откоса',

    # Result labels
    'totalArea': 'Общая площадь',
    'waterproofing': 'Гидроизоляция',
    'tape': 'Лента',
    'cable': 'Кабель',
    'outlets': 'Розетки',
    'switches': 'Выключатели',
    'pipes': 'Трубы',
    'fittings': 'Фитинги',
    'radiators': 'Радиаторы',
    'ducts': 'Воздуховоды',
    'panels': 'Панели',
    'profiles': 'Профили',
    'fasteners': 'Крепеж',
    'insulation': 'Утеплитель',
    'membrane': 'Мембрана',
    'posts': 'Столбы',
    'boards': 'Доски',
    'steps': 'Ступени',
    'handrails': 'Перила',
    'slopes': 'Откосы',
}

def load_analysis():
    """Загружает анализ калькуляторов."""
    with open(ANALYSIS_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def load_translations():
    """Загружает существующие переводы."""
    with open(TRANSLATIONS_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_translations(translations):
    """Сохраняет переводы в файл."""
    with open(TRANSLATIONS_FILE, 'w', encoding='utf-8') as f:
        json.dump(translations, f, ensure_ascii=False, indent=2)

def extract_key_from_path(key_path):
    """Извлекает последнюю часть ключа (calculator.bathroomTile -> bathroomTile)."""
    parts = key_path.split('.')
    return parts[-1] if len(parts) > 1 else key_path

def add_missing_translations(analysis, translations):
    """Добавляет недостающие переводы."""
    added_count = 0

    # Собираем все недостающие ключи
    missing_keys = set()
    for calc in analysis['calculators']:
        for missing in calc['translations']['missing']:
            missing_keys.add(missing)

    print(f"Found {len(missing_keys)} missing translation keys\n")

    # Добавляем переводы
    for key_path in sorted(missing_keys):
        parts = key_path.split('.')
        if len(parts) != 2:
            print(f"  [SKIP] Invalid key format: {key_path}")
            continue

        section, key = parts

        # Создаем секцию если не существует
        if section not in translations:
            translations[section] = {}

        # Пропускаем если уже существует
        if key in translations[section]:
            print(f"  [EXISTS] {key_path}")
            continue

        # Пытаемся автоматически перевести
        if key in AUTO_TRANSLATIONS:
            translations[section][key] = AUTO_TRANSLATIONS[key]
            print(f"  [AUTO] {key_path} = {AUTO_TRANSLATIONS[key]}")
            added_count += 1
        else:
            # Генерируем перевод из camelCase
            readable = re.sub(r'([a-z])([A-Z])', r'\1 \2', key)
            readable = readable.capitalize()
            translations[section][key] = readable
            print(f"  [GENERATED] {key_path} = {readable}")
            added_count += 1

    return added_count

def main():
    """Главная функция."""
    print("Adding missing translations...\n")

    analysis = load_analysis()
    translations = load_translations()

    added_count = add_missing_translations(analysis, translations)

    if added_count > 0:
        save_translations(translations)
        print(f"\n{'='*60}")
        print(f"Added {added_count} translations")
        print(f"Translations file updated: {TRANSLATIONS_FILE}")
        print(f"{'='*60}")
    else:
        print("\nNo translations needed - all keys already exist!")

if __name__ == '__main__':
    main()
