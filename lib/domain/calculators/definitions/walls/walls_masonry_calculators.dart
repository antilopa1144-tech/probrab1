// Калькуляторы для кирпичной кладки, блоков и декоративного камня
// Часть walls_calculators, разделенного для улучшения поддержки

import '../../../../core/enums/calculator_category.dart';
import '../../../../core/enums/field_input_type.dart';
import '../../../../core/enums/unit_type.dart';
import '../../../models/calculator_definition_v2.dart';
import '../../../models/calculator_field.dart';
import '../../../models/calculator_hint.dart';
import '../../calculator_constants.dart';
import '../../../usecases/calculate_brick_partition.dart';
import '../../../usecases/calculate_gasblock_partition.dart';
import '../../../usecases/calculate_decorative_stone.dart';

final List<CalculatorDefinitionV2> wallsMasonryCalculators = [
  // 1. partitions_blocks - Перегородки из блоков
  CalculatorDefinitionV2(
      id: 'partitions_blocks',
      titleKey: 'calculator.partitions_blocks.title',
      descriptionKey: 'calculator.partitions_blocks.description',
      category: CalculatorCategory.interior,
      subCategoryKey: 'subcategory.partitions',
      fields: [
        const CalculatorField(
          key: 'length',
          labelKey: 'input.length',
          unitType: UnitType.meters,
          inputType: FieldInputType.number,
          defaultValue: 0.0,
          required: true,
          order: 1,
        ),
        const CalculatorField(
          key: 'height',
          labelKey: 'input.height',
          unitType: UnitType.meters,
          inputType: FieldInputType.number,
          defaultValue: 2.7,
          required: true,
          order: 2,
        ),
        const CalculatorField(
          key: 'thickness',
          labelKey: 'input.thickness',
          unitType: UnitType.millimeters,
          inputType: FieldInputType.number,
          defaultValue: 100.0,
          required: true,
          order: 3,
        ),
      ],
      beforeHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_spetsialnyy_kley_dlya'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.armiruyte_kazhdyy_3_4'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.pervyy_ryad_ukladyvayte_na'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.proveryayte_geometriyu_urovnem'),
      ],
      afterHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_spetsialnyy_kley_dlya'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.armiruyte_kazhdyy_3_4'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.pervyy_ryad_ukladyvayte_na'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.proveryayte_geometriyu_urovnem'),
      ],
      useCase: CalculateGasblockPartition(),
      accentColor: kCalculatorAccentColor,
      complexity: 2,
      popularity: 10,
      tags: [
        'tag.vnutrennyaya_otdelka',
        'tag.peregorodki',
        'partitions',
        'blocks',
        'partitions_blocks',
      ],
    ),

  // 2. partitions_brick - Перегородки из кирпича
  CalculatorDefinitionV2(
      id: 'partitions_brick',
      titleKey: 'calculator.partitions_brick.title',
      descriptionKey: 'calculator.partitions_brick.description',
      category: CalculatorCategory.interior,
      subCategoryKey: 'subcategory.partitions',
      fields: [
        const CalculatorField(
          key: 'length',
          labelKey: 'input.length',
          unitType: UnitType.meters,
          inputType: FieldInputType.number,
          defaultValue: 0.0,
          required: true,
          order: 1,
        ),
        const CalculatorField(
          key: 'height',
          labelKey: 'input.height',
          unitType: UnitType.meters,
          inputType: FieldInputType.number,
          defaultValue: 2.7,
          required: true,
          order: 2,
        ),
        const CalculatorField(
          key: 'brickType',
          labelKey: 'input.type',
          unitType: UnitType.pieces,
          inputType: FieldInputType.number,
          defaultValue: 0.5,
          required: true,
          order: 3,
        ),
      ],
      beforeHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.kladku_v_polkirpicha_armiruyte'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_tsementno_peschanyy_rastvor'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.proveryayte_vertikalnost_otvesom'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.svyazyvayte_s_nesuschimi_stenami'),
      ],
      afterHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.kladku_v_polkirpicha_armiruyte'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_tsementno_peschanyy_rastvor'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.proveryayte_vertikalnost_otvesom'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.svyazyvayte_s_nesuschimi_stenami'),
      ],
      useCase: CalculateBrickPartition(),
      accentColor: kCalculatorAccentColor,
      complexity: 2,
      popularity: 10,
      tags: [
        'tag.vnutrennyaya_otdelka',
        'tag.peregorodki',
        'partitions',
        'partitions_brick',
        'brick',
      ],
    ),

  // 3. walls_decor_stone - Декоративный камень
  CalculatorDefinitionV2(
      id: 'walls_decor_stone',
      titleKey: 'calculator.walls_decor_stone.title',
      descriptionKey: 'calculator.walls_decor_stone.description',
      category: CalculatorCategory.interior,
      subCategoryKey: 'subcategory.walls',
      fields: [
        const CalculatorField(
          key: 'area',
          labelKey: 'input.wallArea',
          unitType: UnitType.squareMeters,
          inputType: FieldInputType.number,
          defaultValue: 0.0,
          required: true,
          order: 1,
        ),
        const CalculatorField(
          key: 'thickness',
          labelKey: 'input.thickness',
          unitType: UnitType.millimeters,
          inputType: FieldInputType.number,
          defaultValue: 15.0,
          required: true,
          order: 2,
        ),
      ],
      beforeHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.dobavte_10_zapas_na'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_spetsialnyy_kley_dlya_3'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.obrabotayte_kamen_gidrofobizatorom'),
      ],
      afterHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.dobavte_10_zapas_na'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.ispolzuyte_spetsialnyy_kley_dlya_3'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.walls.obrabotayte_kamen_gidrofobizatorom'),
      ],
      useCase: CalculateDecorativeStone(),
      accentColor: kCalculatorAccentColor,
      complexity: 2,
      popularity: 10,
      tags: [
        'tag.vnutrennyaya_otdelka',
        'decor',
        'stone',
        'walls',
        'tag.steny',
        'walls_decor_stone',
      ],
    ),
];
