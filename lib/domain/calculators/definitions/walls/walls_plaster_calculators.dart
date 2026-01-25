// Калькуляторы для штукатурки, грунтовки, шпатлёвки и смесей
// Часть walls_calculators, разделенного для улучшения поддержки

import '../../../../core/enums/calculator_category.dart';
import '../../../../core/enums/field_input_type.dart';
import '../../../../core/enums/unit_type.dart';
import '../../../models/calculator_definition_v2.dart';
import '../../../models/calculator_field.dart';
import '../../../models/calculator_hint.dart';
import '../../calculator_constants.dart';
import '../../../usecases/calculate_plaster.dart';
import '../../../usecases/calculate_primer.dart';
import '../../../usecases/calculate_putty.dart';
import '../../../usecases/calculate_tile_glue.dart';
import '../../../usecases/calculate_decorative_plaster.dart';
// calculate_wall_paint.dart больше не используется - walls_paint заменён на paint_universal

final List<CalculatorDefinitionV2> wallsPlasterCalculators = [
  // 1. mixes_plaster - Штукатурка
  CalculatorDefinitionV2(
      id: 'mixes_plaster',
      titleKey: 'calculator.mixes_plaster.title',
      descriptionKey: 'calculator.mixes_plaster.description',
      category: CalculatorCategory.interior,
      subCategoryKey: 'subcategory.leveling_mix',
      fields: [
        const CalculatorField(
          key: 'area',
          labelKey: 'input.wallArea',
          hintKey: 'input.wallArea.hint',
          unitType: UnitType.squareMeters,
          inputType: FieldInputType.number,
          defaultValue: 20.0,
          minValue: 1.0,
          maxValue: 1000.0,
          required: true,
          order: 1,
        ),
        const CalculatorField(
          key: 'thickness',
          labelKey: 'input.plaster_thickness',
          hintKey: 'input.plaster_thickness.hint',
          unitType: UnitType.millimeters,
          inputType: FieldInputType.number,
          defaultValue: 10.0,
          minValue: 5.0,
          maxValue: 50.0,
          required: true,
          order: 2,
        ),
        const CalculatorField(
          key: 'type',
          labelKey: 'input.plaster_type',
          unitType: UnitType.pieces,
          inputType: FieldInputType.select,
          defaultValue: 1.0,
          required: true,
          order: 3,
          options: [
            FieldOption(value: 1.0, labelKey: 'input.plaster_type.gypsum'),
            FieldOption(value: 2.0, labelKey: 'input.plaster_type.cement'),
          ],
        ),
      ],
      beforeHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.plaster.measure_walls'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.plaster.gypsum_for_interior'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.plaster.cement_for_wet'),
      ],
      afterHints: [],
      useCase: CalculatePlaster(),
      accentColor: kCalculatorAccentColor,
      complexity: 2,
      popularity: 10,
      showToolsSection: false,
      tags: [
        'tag.vnutrennyaya_otdelka',
        'tag.rovniteli_smesi',
        'plaster',
        'mixes',
        'mixes_plaster',
      ],
    ),

  // 2. mixes_primer - Грунтовка
  CalculatorDefinitionV2(
      id: 'mixes_primer',
      titleKey: 'calculator.mixes_primer.title',
      descriptionKey: 'calculator.mixes_primer.description',
      category: CalculatorCategory.interior,
      subCategoryKey: 'subcategory.leveling_mix',
      fields: [
        const CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
          inputType: FieldInputType.number,
          defaultValue: 20.0,
          required: true,
          order: 1,
        ),
        const CalculatorField(
          key: 'layers',
          labelKey: 'input.layers',
          unitType: UnitType.pieces,
          inputType: FieldInputType.number,
          defaultValue: 1.0,
          required: true,
          order: 2,
        ),
        const CalculatorField(
          key: 'type',
          labelKey: 'input.type',
          unitType: UnitType.pieces,
          inputType: FieldInputType.number,
          defaultValue: 1.0,
          required: true,
          order: 3,
        ),
        const CalculatorField(
          key: 'canSize',
          labelKey: 'input.canSize',
          hintKey: 'input.canSize.hint',
          unitType: UnitType.liters,
          inputType: FieldInputType.select,
          defaultValue: 10.0,
          required: false,
          order: 4,
          options: [
            FieldOption(value: 5, labelKey: 'input.canSize.5l'),
            FieldOption(value: 10, labelKey: 'input.canSize.10l'),
            FieldOption(value: 15, labelKey: 'input.canSize.15l'),
            FieldOption(value: 20, labelKey: 'input.canSize.20l'),
          ],
        ),
      ],
      beforeHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.gruntovka_uluchshaet_adgeziyu_materialov'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.gruntovka_glubokogo_proniknoveniya_dlya'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.nanosite_ravnomernym_sloem'),
      ],
      afterHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.gruntovka_uluchshaet_adgeziyu_materialov'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.gruntovka_glubokogo_proniknoveniya_dlya'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.nanosite_ravnomernym_sloem'),
      ],
      useCase: CalculatePrimer(),
      accentColor: kCalculatorAccentColor,
      complexity: 2,
      popularity: 10,
      tags: [
        'tag.vnutrennyaya_otdelka',
        'mixes_primer',
        'tag.rovniteli_smesi',
        'mixes',
        'primer',
      ],
    ),

  // 3. mixes_putty - Шпатлёвка
  CalculatorDefinitionV2(
      id: 'mixes_putty',
      titleKey: 'calculator.mixes_putty.title',
      descriptionKey: 'calculator.mixes_putty.description',
      category: CalculatorCategory.interior,
      subCategoryKey: 'subcategory.leveling_mix',
      fields: [
        const CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
          inputType: FieldInputType.number,
          defaultValue: 20.0,
          required: true,
          order: 1,
        ),
        const CalculatorField(
          key: 'layers',
          labelKey: 'input.layers',
          unitType: UnitType.pieces,
          inputType: FieldInputType.number,
          defaultValue: 2.0,
          required: true,
          order: 2,
        ),
        const CalculatorField(
          key: 'type',
          labelKey: 'input.putty_type',
          unitType: UnitType.pieces,
          inputType: FieldInputType.select,
          defaultValue: 1.0,
          required: true,
          order: 3,
          options: [
            FieldOption(value: 1.0, labelKey: 'input.putty_type.start'),
            FieldOption(value: 2.0, labelKey: 'input.putty_type.finish'),
          ],
        ),
      ],
      beforeHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.startovaya_shpaklevka_dlya_vyravnivaniya'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.nanosite_tonkimi_sloyami'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.shlifuyte_mezhdu_sloyami'),
      ],
      afterHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.startovaya_shpaklevka_dlya_vyravnivaniya'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.nanosite_tonkimi_sloyami'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.shlifuyte_mezhdu_sloyami'),
      ],
      useCase: CalculatePutty(),
      accentColor: kCalculatorAccentColor,
      complexity: 2,
      popularity: 10,
      tags: [
        'tag.vnutrennyaya_otdelka',
        'tag.rovniteli_smesi',
        'putty',
        'mixes',
        'mixes_putty',
      ],
    ),

  // 4. mixes_tile_glue - Плиточный клей
  CalculatorDefinitionV2(
      id: 'mixes_tile_glue',
      titleKey: 'calculator.mixes_tile_glue.title',
      descriptionKey: 'calculator.mixes_tile_glue.description',
      category: CalculatorCategory.interior,
      subCategoryKey: 'subcategory.leveling_mix',
      fields: [
        const CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
          inputType: FieldInputType.number,
          defaultValue: 20.0,
          required: true,
          order: 1,
        ),
        const CalculatorField(
          key: 'tileSize',
          labelKey: 'input.tileSize',
          unitType: UnitType.meters,
          inputType: FieldInputType.number,
          defaultValue: 30.0,
          required: true,
          order: 2,
        ),
        const CalculatorField(
          key: 'layerThickness',
          labelKey: 'input.layerThickness',
          unitType: UnitType.millimeters,
          inputType: FieldInputType.number,
          defaultValue: 5.0,
          required: true,
          order: 3,
        ),
      ],
      beforeHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.rashod_zavisit_ot_razmera'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_zubchatyy_shpatel'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.nanosite_kley_na_osnovanie'),
      ],
      afterHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.rashod_zavisit_ot_razmera'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_zubchatyy_shpatel'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.nanosite_kley_na_osnovanie'),
      ],
      useCase: CalculateTileGlue(),
      accentColor: kCalculatorAccentColor,
      complexity: 2,
      popularity: 10,
      tags: [
        'tag.vnutrennyaya_otdelka',
        'tile',
        'tag.rovniteli_smesi',
        'mixes_tile_glue',
        'mixes',
        'glue',
      ],
    ),

  // 5. walls_decor_plaster - Декоративная штукатурка
  CalculatorDefinitionV2(
      id: 'walls_decor_plaster',
      titleKey: 'calculator.walls_decor_plaster.title',
      descriptionKey: 'calculator.walls_decor_plaster.description',
      category: CalculatorCategory.interior,
      subCategoryKey: 'subcategory.walls',
      fields: [
        const CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
          inputType: FieldInputType.number,
          defaultValue: 20.0,
          required: true,
          order: 1,
        ),
        const CalculatorField(
          key: 'thickness',
          labelKey: 'input.thickness',
          unitType: UnitType.millimeters,
          inputType: FieldInputType.number,
          defaultValue: 2.0,
          minValue: 0.5,
          maxValue: 10.0,
          required: true,
          order: 2,
        ),
        const CalculatorField(
          key: 'windowsArea',
          labelKey: 'input.windowsArea',
          unitType: UnitType.squareMeters,
          inputType: FieldInputType.number,
          defaultValue: 0.0,
          required: false,
          order: 3,
        ),
        const CalculatorField(
          key: 'doorsArea',
          labelKey: 'input.doorsArea',
          unitType: UnitType.squareMeters,
          inputType: FieldInputType.number,
          defaultValue: 0.0,
          required: false,
          order: 4,
        ),
      ],
      beforeHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_gruntovku_glubokogo_proniknoveniya'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.vozmite_shpateli_i_kelmy'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.dlya_venetsianskoy_shtukaturki_nuzhna'),
      ],
      afterHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_gruntovku_glubokogo_proniknoveniya'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.vozmite_shpateli_i_kelmy'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.dlya_venetsianskoy_shtukaturki_nuzhna'),
      ],
      useCase: CalculateDecorativePlaster(),
      accentColor: kCalculatorAccentColor,
      complexity: 2,
      popularity: 10,
      tags: [
        'tag.vnutrennyaya_otdelka',
        'decor',
        'walls',
        'walls_decor_plaster',
        'plaster',
        'tag.steny',
      ],
    ),

  // walls_paint удалён - используйте paint_universal (см. calculator_id_migration.dart)
];
