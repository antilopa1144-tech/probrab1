# Localization Entries for DSP Calculator

This document contains all the localization entries that need to be added to the language files for the DSP (Cement-Sand Mortar) calculator.

## Files to Update

- `assets/lang/ru.json` - Russian (primary)
- `assets/lang/en.json` - English
- `assets/lang/kk.json` - Kazakh
- `assets/lang/ky.json` - Kyrgyz
- `assets/lang/tg.json` - Tajik
- `assets/lang/tk.json` - Turkmen
- `assets/lang/uz.json` - Uzbek

## JSON Entries

### 1. Calculator Title and Description

Add to the `"calculator"` section:

```json
"dsp": {
  "title": "ЦПС / Стяжка",
  "description": "Расчёт материалов для цементно-песчаной смеси и стяжки пола"
}
```

### 2. Input Fields

Add to the `"input"` section:

```json
"application_type": "Тип работ",
"application_type.floor": "Стяжка (Пол)",
"application_type.walls": "Штукатурка (Стены)",

"mix_type": "Марка смеси",
"mix_type.hint": "Выберите марку смеси в зависимости от типа работ",
"mix_type.m300": "М300 (Пескобетон)",
"mix_type.m150": "М150 (Универсальная)",

"thickness": "Толщина слоя",
"thickness.hint": "Толщина слоя в миллиметрах",

"bag_weight": "Вес мешка",
"bag_weight.hint": "Вес одного мешка смеси в килограммах (обычно 25, 40 или 50 кг)"
```

### 3. Hints

Add to the `"hint"` section:

```json
"dsp": {
  "before": {
    "measure": "Тщательно измерьте площадь поверхности для точного расчёта",
    "mix_choice": "М300 (Пескобетон) - для пола, М150 - для стен",
    "thin_screed": "⚠ Стяжка тоньше 30мм может потрескаться. Используйте наливной пол для тонких слоёв"
  },
  "after": {
    "curing": "Стяжка набирает прочность 28 дней. Первые 7 дней увлажняйте поверхность",
    "temperature": "Работы проводите при температуре +5°C до +30°C",
    "crack_warning": "⚠ Внимание: слишком тонкий слой может привести к трещинам",
    "reinforcement": "Для пола рекомендуется армирующая сетка 100х100мм"
  }
}
```

## English Translations (en.json)

```json
"calculator": {
  "dsp": {
    "title": "Cement-Sand Mortar / Screed",
    "description": "Material calculation for cement-sand mortar and floor screed"
  }
}

"input": {
  "application_type": "Work Type",
  "application_type.floor": "Floor Screed",
  "application_type.walls": "Wall Plaster",

  "mix_type": "Mix Grade",
  "mix_type.hint": "Choose mix grade depending on work type",
  "mix_type.m300": "M300 (Sand-Concrete)",
  "mix_type.m150": "M150 (Universal)",

  "thickness": "Layer Thickness",
  "thickness.hint": "Layer thickness in millimeters",

  "bag_weight": "Bag Weight",
  "bag_weight.hint": "Weight of one bag in kilograms (usually 25, 40 or 50 kg)"
}

"hint": {
  "dsp": {
    "before": {
      "measure": "Carefully measure the surface area for accurate calculation",
      "mix_choice": "M300 (Sand-Concrete) - for floors, M150 - for walls",
      "thin_screed": "⚠ Screed thinner than 30mm may crack. Use self-leveling compound for thin layers"
    },
    "after": {
      "curing": "Screed gains strength for 28 days. Moisten surface for first 7 days",
      "temperature": "Work at temperature +5°C to +30°C",
      "crack_warning": "⚠ Warning: too thin layer may lead to cracks",
      "reinforcement": "Reinforcement mesh 100x100mm recommended for floors"
    }
  }
}
```

## Implementation Notes

1. **Calculator ID**: `dsp`
2. **Category**: Interior (floors)
3. **Subcategory**: flooring
4. **Complexity**: 2
5. **Popularity**: 85

## Field Keys Used

- `inputMode` - Mode selection (by dimensions / by area)
- `length`, `width`, `height` - Room dimensions
- `area`, `perimeter` - Direct area input
- `applicationType` - Floor or walls (0 = floor, 1 = walls)
- `mixType` - Mix grade (0 = M300, 1 = M150)
- `thickness` - Layer thickness in mm
- `bagWeight` - Bag weight in kg
- `windowsArea`, `doorsArea` - Openings (for walls only)

## Result Keys

- `area` - Working area (m²)
- `totalWeightKg` - Total dry mix weight (kg)
- `totalWeightTonnes` - Total dry mix weight (tonnes)
- `bagsNeeded` - Number of bags
- `meshArea` - Reinforcement mesh area (m²) - floor only
- `tapeMeters` - Damper tape length (m) - floor only
- `beaconsNeeded` - Number of beacons - floor only
- `primerCanisters` - Primer canisters (10L) - walls only
- `primerLiters` - Primer volume (L) - walls only
- `thicknessWarning` - Warning flag for thin screed
- `applicationType` - Application type for conditional hints

## Integration Complete

The DSP calculator has been successfully integrated with:

✅ Use case implementation ([calculate_dsp.dart](lib/domain/usecases/calculate_dsp.dart))
✅ V2 calculator definition ([dsp_calculator_v2.dart](lib/domain/calculators/dsp_calculator_v2.dart))
✅ Registry registration ([calculator_registry.dart](lib/domain/calculators/calculator_registry.dart))
✅ Comprehensive tests ([calculate_dsp_test.dart](test/domain/usecases/calculate_dsp_test.dart))
📝 Localization entries documented (this file)

**Next Step**: Add the localization entries above to the appropriate JSON files in `assets/lang/` directory.
