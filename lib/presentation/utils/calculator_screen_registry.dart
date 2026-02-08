import 'package:flutter/material.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../views/calculator/pro_calculator_screen.dart';
import '../views/calculator/plaster_calculator_screen.dart';
import '../views/calculator/putty_calculator_screen_v2.dart';
import '../views/calculator/gypsum_calculator_screen.dart';
import '../views/calculator/wallpaper_calculator_screen.dart';
import '../views/calculator/self_leveling_floor_calculator_screen.dart';
import '../views/calculator/tile_adhesive_calculator_screen.dart';
import '../views/calculator/tile_calculator_screen.dart';
import '../views/calculator/underfloor_heating_calculator_screen.dart';
import '../views/calculator/three_d_panels_calculator_screen.dart';
import '../views/calculator/terrace_calculator_screen.dart';
import '../views/calculator/wood_lining_calculator_screen.dart';
import '../views/calculator/gasblock_calculator_screen.dart';
import '../views/calculator/electrical_calculator_screen.dart';
import '../views/calculator/primer_calculator_screen.dart';
import '../views/calculator/laminate_calculator_screen.dart';
import '../views/calculator/brick_calculator_screen.dart';
import '../views/calculator/linoleum_calculator_screen.dart';
import '../views/calculator/parquet_calculator_screen.dart';
import '../views/calculator/screed_unified_calculator_screen.dart';
import '../views/calculator/stretch_ceiling_calculator_screen.dart';
import '../views/calculator/ceiling_insulation_calculator_screen.dart';
import '../views/calculator/cassette_ceiling_calculator_screen.dart';
import '../views/calculator/rail_ceiling_calculator_screen.dart';
import '../views/calculator/decor_plaster_calculator_screen.dart';
import '../views/calculator/decor_stone_calculator_screen.dart';
import '../views/calculator/mdf_panels_calculator_screen.dart';
import '../views/calculator/pvc_panels_calculator_screen.dart';
import '../views/calculator/attic_calculator_screen.dart';
import '../views/calculator/balcony_calculator_screen.dart';
import '../views/calculator/bathroom_waterproof_calculator_screen.dart';
import '../views/calculator/doors_install_calculator_screen.dart';
import '../views/calculator/sound_insulation_calculator_screen.dart';
import '../views/calculator/slopes_calculator_screen.dart';
import '../views/calculator/windows_install_calculator_screen.dart';
import '../views/calculator/facade_panels_calculator_screen.dart';
import '../views/calculator/tile_grout_calculator_screen.dart';
import '../views/calculator/fence_calculator_screen.dart';
import '../views/calculator/stairs_calculator_screen.dart';
// plumbing_calculator_screen.dart - удалён (engineering_plumbing не востребован)
import '../views/calculator/ventilation_calculator_screen.dart';
import '../views/calculator/basement_calculator_screen.dart';
import '../views/calculator/blind_area_calculator_screen.dart';
import '../views/calculator/slab_calculator_screen.dart';
import '../views/calculator/strip_foundation_calculator_screen.dart';
import '../views/calculator/gutters_calculator_screen.dart';
import '../views/calculator/roofing_unified_calculator_screen.dart';
import '../views/calculator/concrete_universal_calculator_screen.dart';
import '../views/paint/paint_screen.dart';
import '../views/wood/wood_screen.dart';
// dsp_screen.dart удалён - объединён с screed_unified_calculator_screen.dart
import '../views/osb/osb_calculator_screen.dart';

/// Функция-билдер для создания экрана калькулятора.
typedef CalculatorScreenBuilder = Widget Function(
  CalculatorDefinitionV2 definition,
  Map<String, double>? initialInputs,
);

/// Реестр экранов калькуляторов.
/// Заменяет 49 if-блоков на Map-based подход.
class CalculatorScreenRegistry {
  CalculatorScreenRegistry._();

  /// Маппинг ID калькулятора -> билдер экрана.
  static final Map<String, CalculatorScreenBuilder> _builders = {
    // Смеси
    'mixes_plaster': (def, inputs) => PlasterCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'mixes_putty': (_, _) => const PuttyCalculatorScreenV2(),
    'mixes_primer': (_, _) => const PrimerCalculatorScreen(),
    'mixes_tile_glue': (def, inputs) => TileAdhesiveCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),

    // Листовые материалы
    // 'dsp' перемещён в секцию "Полы" и объединён с floors_screed_unified
    'sheeting_osb_plywood': (def, inputs) => OsbCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'gypsum_board': (def, inputs) => GypsumCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),

    // Краска и дерево (из HTML)
    'paint_universal': (_, _) => const PaintScreen(),
    'paint': (_, _) => const PaintScreen(),
    'wood': (_, _) => const WoodScreen(),

    // Стены
    'walls_wallpaper': (def, inputs) => WallpaperCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'walls_3d_panels': (def, inputs) => ThreeDPanelsCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'walls_wood': (def, inputs) => WoodLiningCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'walls_decor_plaster': (_, _) => const DecorPlasterCalculatorScreen(),
    'walls_decor_stone': (_, _) => const DecorStoneCalculatorScreen(),
    'walls_mdf_panels': (_, _) => const MdfPanelsCalculatorScreen(),
    'walls_pvc_panels': (_, _) => const PvcPanelsCalculatorScreen(),

    // Перегородки
    'partitions_blocks': (def, inputs) => GasblockCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'partitions_brick': (_, _) => const BrickCalculatorScreen(),
    'exterior_brick': (_, _) => const BrickCalculatorScreen(),

    // Полы
    'floors_tile': (def, inputs) => TileCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'floors_self_leveling': (def, inputs) => SelfLevelingFloorCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'floors_laminate': (_, _) => const LaminateCalculatorScreen(),
    'floors_linoleum': (_, _) => const LinoleumCalculatorScreen(),
    'floors_parquet': (_, _) => const ParquetCalculatorScreen(),
    'floors_screed_unified': (_, _) => const ScreedUnifiedCalculatorScreen(),
    // Алиасы для обратной совместимости
    'floors_screed': (_, _) => const ScreedUnifiedCalculatorScreen(),
    'dsp': (_, _) => const ScreedUnifiedCalculatorScreen(),
    'floors_tile_grout': (_, _) => const TileGroutCalculatorScreen(),
    'floors_warm': (def, inputs) => UnderfloorHeatingCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),

    // Потолки
    'ceilings_stretch': (_, _) => const StretchCeilingCalculatorScreen(),
    'ceilings_insulation': (_, _) => const CeilingInsulationCalculatorScreen(),
    'ceilings_cassette': (_, _) => const CassetteCeilingCalculatorScreen(),
    'ceilings_rail': (_, _) => const RailCeilingCalculatorScreen(),

    // Инженерия
    'engineering_heating': (def, inputs) => UnderfloorHeatingCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'engineering_electrics': (def, inputs) => ElectricalCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    // engineering_plumbing удалён
    'engineering_ventilation': (_, _) => const VentilationCalculatorScreen(),

    // Специальные помещения
    'terrace': (def, inputs) => TerraceCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
    'attic': (_, _) => const AtticCalculatorScreen(),
    'balcony': (_, _) => const BalconyCalculatorScreen(),
    'bathroom_waterproof': (_, _) => const BathroomWaterproofCalculatorScreen(),

    // Двери и окна
    'doors_install': (_, _) => const DoorsInstallCalculatorScreen(),
    'windows_install': (_, _) => const WindowsInstallCalculatorScreen(),
    'slopes_finishing': (_, _) => const SlopesCalculatorScreen(),

    // Изоляция
    'insulation_sound': (_, _) => const SoundInsulationCalculatorScreen(),

    // Экстерьер
    'exterior_facade_panels': (_, _) => const FacadePanelsCalculatorScreen(),
    'fence': (_, _) => const FenceCalculatorScreen(),
    'stairs': (_, _) => const StairsCalculatorScreen(),

    // Фундамент
    'foundation_basement': (_, _) => const BasementCalculatorScreen(),
    'foundation_blind_area': (_, _) => const BlindAreaCalculatorScreen(),
    'foundation_slab': (_, _) => const SlabCalculatorScreen(),
    'foundation_strip': (_, _) => const StripFoundationCalculatorScreen(),

    // Бетон
    'concrete_universal': (def, inputs) => ConcreteUniversalCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),

    // Кровля
    'roofing_gutters': (_, _) => const GuttersCalculatorScreen(),
    'roofing_unified': (def, inputs) => RoofingUnifiedCalculatorScreen(
          definition: def,
          initialInputs: inputs,
        ),
  };

  /// Получить экран калькулятора по ID.
  /// Возвращает null, если специализированный экран не найден.
  static Widget? build(
    String id,
    CalculatorDefinitionV2 definition,
    Map<String, double>? initialInputs,
  ) {
    final builder = _builders[id];
    return builder?.call(definition, initialInputs);
  }

  /// Получить экран калькулятора с fallback на ProCalculatorScreen.
  static Widget buildWithFallback(
    CalculatorDefinitionV2 definition,
    Map<String, double>? initialInputs,
  ) {
    return build(definition.id, definition, initialInputs) ??
        ProCalculatorScreen(
          definition: definition,
          initialInputs: initialInputs,
        );
  }

  /// Проверить, есть ли специализированный экран для калькулятора.
  static bool hasCustomScreen(String id) => _builders.containsKey(id);
}
