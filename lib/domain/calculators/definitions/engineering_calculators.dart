// GENERATED FILE - do not edit by hand.
// CalculatorDefinitionV2 entries used by the app.

import '../../../core/enums/calculator_category.dart';
import '../../../core/enums/field_input_type.dart';
import '../../../core/enums/unit_type.dart';
import '../../models/calculator_definition_v2.dart';
import '../../models/calculator_field.dart';
import '../../models/calculator_hint.dart';
import '../calculator_constants.dart';
import '../../usecases/canonical_bridge.dart';
import '../../usecases/electric_canonical_adapter.dart';
// heating_canonical_adapter.dart — больше не используется (engineering_heating удалён)
// calculate_plumbing.dart — удалён (engineering_plumbing не востребован)
import '../../usecases/ventilation_canonical_adapter.dart';

final List<CalculatorDefinitionV2> engineeringCalculators = [
  const CalculatorDefinitionV2(
    id: 'engineering_electrics',
    titleKey: 'calculator.engineering_electrics.title',
    descriptionKey: 'calculator.engineering_electrics.description',
    category: CalculatorCategory.interior,
    subCategoryKey: 'subcategory.electrics',
    fields: [
      CalculatorField(
        key: 'apartmentArea',
        labelKey: 'input.apartmentArea',
        unitType: UnitType.squareMeters,
        inputType: FieldInputType.slider,
        defaultValue: 60.0,
        minValue: 20.0,
        maxValue: 500.0,
        step: 5.0,
        iconName: 'square_foot',
        group: 'dimensions',
        required: true,
        order: 1,
      ),
      CalculatorField(
        key: 'roomsCount',
        labelKey: 'input.roomsCount',
        unitType: UnitType.pieces,
        inputType: FieldInputType.slider,
        defaultValue: 3.0,
        minValue: 1.0,
        maxValue: 10.0,
        step: 1.0,
        iconName: 'meeting_room',
        group: 'dimensions',
        required: true,
        order: 2,
      ),
      CalculatorField(
        key: 'ceilingHeight',
        labelKey: 'input.ceilingHeight',
        unitType: UnitType.meters,
        inputType: FieldInputType.slider,
        defaultValue: 2.7,
        minValue: 2.4,
        maxValue: 4.0,
        step: 0.1,
        iconName: 'height',
        group: 'dimensions',
        required: true,
        order: 3,
      ),
      CalculatorField(
        key: 'wiringType',
        labelKey: 'input.wiringType',
        unitType: UnitType.pieces,
        inputType: FieldInputType.select,
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 1.0,
        iconName: 'cable',
        group: 'options',
        required: true,
        order: 4,
        options: [
          FieldOption(value: 0, labelKey: 'electrical.wiring.hidden'),
          FieldOption(value: 1, labelKey: 'electrical.wiring.open'),
        ],
      ),
      CalculatorField(
        key: 'hasKitchen',
        labelKey: 'input.hasKitchen',
        unitType: UnitType.pieces,
        inputType: FieldInputType.switch_,
        defaultValue: 1.0,
        minValue: 0.0,
        maxValue: 1.0,
        iconName: 'electric_bolt',
        group: 'options',
        required: false,
        order: 5,
      ),
      CalculatorField(
        key: 'cablePurchaseMode',
        labelKey: 'input.cablePurchaseMode',
        hintKey: 'input.cablePurchaseModeHint',
        unitType: UnitType.pieces,
        inputType: FieldInputType.select,
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 1.0,
        iconName: 'inventory_2',
        group: 'options',
        required: true,
        order: 6,
        options: [
          FieldOption(value: 0, labelKey: 'input.cablePurchasePerMeter'),
          FieldOption(value: 1, labelKey: 'input.cablePurchaseSpool50m'),
        ],
      ),
      CalculatorField(
        key: 'reserve',
        labelKey: 'input.reserve',
        hintKey: 'input.electricReserveHint',
        unitType: UnitType.percent,
        inputType: FieldInputType.slider,
        defaultValue: 15.0,
        minValue: 5.0,
        maxValue: 30.0,
        step: 5.0,
        iconName: 'add_chart',
        group: 'options',
        required: true,
        order: 7,
      ),
    ],
    beforeHints: [
      CalculatorHint(
        type: HintType.tip,
        messageKey:
            'hint.engineering.raboty_dolzhen_vypolnyat_kvalifitsirovannyy',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.ispolzuyte_kabel_secheniem_ne',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.ustanovite_uzo_dlya_zaschity',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.proverte_vse_soedineniya_pered',
      ),
    ],
    afterHints: [
      CalculatorHint(
        type: HintType.tip,
        messageKey:
            'hint.engineering.raboty_dolzhen_vypolnyat_kvalifitsirovannyy',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.ispolzuyte_kabel_secheniem_ne',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.ustanovite_uzo_dlya_zaschity',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.proverte_vse_soedineniya_pered',
      ),
    ],
    useCase: CanonicalBridgeUseCase(calculateCanonicalElectric),
    accentColor: kCalculatorAccentColor,
    complexity: 2,
    popularity: 10,
    tags: [
      'engineering_electrics',
      'engineering',
      'tag.inzhenernye_raboty',
      'tag.elektrika',
      'electrics',
    ],
  ),
  // engineering_heating удалён — дубль floors_warm (тёплый пол)
  // engineering_plumbing удалён — слишком общий, не востребован
  const CalculatorDefinitionV2(
    id: 'engineering_ventilation',
    titleKey: 'calculator.engineering_ventilation.title',
    descriptionKey: 'calculator.engineering_ventilation.description',
    category: CalculatorCategory.interior,
    subCategoryKey: 'subcategory.ventilation',
    fields: [
      CalculatorField(
        key: 'area',
        labelKey: 'input.area',
        unitType: UnitType.squareMeters,
        inputType: FieldInputType.slider,
        defaultValue: 50.0,
        minValue: 5.0,
        maxValue: 500.0,
        step: 1.0,
        iconName: 'square_foot',
        group: 'dimensions',
        required: true,
        order: 1,
      ),
      CalculatorField(
        key: 'rooms',
        labelKey: 'input.rooms',
        unitType: UnitType.pieces,
        inputType: FieldInputType.slider,
        defaultValue: 1.0,
        minValue: 1.0,
        maxValue: 30.0,
        step: 1.0,
        iconName: 'meeting_room',
        group: 'dimensions',
        required: true,
        order: 2,
      ),
      CalculatorField(
        key: 'ceilingHeight',
        labelKey: 'input.ceilingHeight',
        unitType: UnitType.meters,
        inputType: FieldInputType.slider,
        defaultValue: 2.5,
        minValue: 2.2,
        maxValue: 5.0,
        step: 1.0,
        iconName: 'height',
        group: 'dimensions',
        required: true,
        order: 3,
      ),
    ],
    beforeHints: [
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.vozduhoobmen_minimum_3_m',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.ustanavlivayte_reshetki_vverhu_dlya',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.proverte_tyagu_pered_montazhom',
      ),
    ],
    afterHints: [
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.vozduhoobmen_minimum_3_m',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.ustanavlivayte_reshetki_vverhu_dlya',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.proverte_tyagu_pered_montazhom',
      ),
    ],
    useCase: CanonicalBridgeUseCase(calculateCanonicalVentilation),
    accentColor: kCalculatorAccentColor,
    complexity: 2,
    popularity: 10,
    tags: [
      'ventilation',
      'engineering',
      'tag.inzhenernye_raboty',
      'tag.ventilyatsiya',
      'engineering_ventilation',
    ],
  ),
];
