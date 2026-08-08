import '../../data/models/price_item.dart';
import '../calculators/calculator_id_migration.dart';
import '../calculators/calculator_registry.dart';
import '../usecases/calculate_3d_panels.dart';
import '../usecases/calculate_attic_v2.dart';
import '../usecases/calculate_balcony_v2.dart';
import '../usecases/calculate_basement_v2.dart';
import '../usecases/calculate_bathroom_waterproof_v2.dart';
import '../usecases/calculate_blind_area_v2.dart';
import '../usecases/calculate_brick.dart';
import '../usecases/calculate_cassette_ceiling_v2.dart';
import '../usecases/calculate_ceiling_insulation_v2.dart';
import '../usecases/calculate_concrete_universal.dart';
import '../usecases/calculate_decor_plaster_v2.dart';
import '../usecases/calculate_decor_stone_v2.dart';
import '../usecases/calculate_doors_install_v2.dart';
import '../usecases/calculate_electrical_v2.dart';
import '../usecases/calculate_facade_panels_v2.dart';
import '../usecases/calculate_fence_v2.dart';
import '../usecases/calculate_gasblock_v2.dart';
import '../usecases/calculate_gutters_v2.dart';
import '../usecases/calculate_gypsum_v2.dart';
import '../usecases/calculate_laminate.dart';
import '../usecases/calculate_linoleum_v2.dart';
import '../usecases/calculate_mdf_panels_v2.dart';
import '../usecases/calculate_paint.dart';
import '../usecases/calculate_parquet.dart';
import '../usecases/calculate_plaster.dart';
import '../usecases/calculate_primer.dart';
import '../usecases/calculate_pvc_panels_v2.dart';
import '../usecases/calculate_putty.dart';
import '../usecases/calculate_rail_ceiling_v2.dart';
import '../usecases/calculate_room.dart';
import '../usecases/calculate_screed_unified.dart';
import '../usecases/calculate_self_leveling_floor.dart';
import '../usecases/calculate_slab_v2.dart';
import '../usecases/calculate_slopes_v2.dart';
import '../usecases/calculate_stairs_v2.dart';
import '../usecases/calculate_stretch_ceiling_v2.dart';
import '../usecases/calculate_strip_foundation.dart';
import '../usecases/calculate_terrace.dart';
import '../usecases/calculate_tile.dart';
import '../usecases/calculate_tile_glue.dart';
import '../usecases/calculate_tile_grout.dart';
import '../usecases/warm_floor_unified_usecase.dart';
import '../usecases/calculate_unified_roofing.dart';
import '../usecases/calculate_ventilation_v2.dart';
import '../usecases/calculate_wallpaper.dart';
import '../usecases/calculate_window_installation.dart';
import '../usecases/calculate_wood_lining.dart';
import '../usecases/calculator_usecase.dart';

/// Единая точка расчёта для кастомных экранов и V2-каталога.
///
/// Для калькуляторов с кастомным UI здесь зарегистрирован «экранный» движок —
/// тот же экземпляр подставляется в [CalculatorRegistry] при сборке каталога.
/// ProCalculator и кастомный экран всегда считают одинаково.
class CalculatorEngine {
  CalculatorEngine._();

  static final Map<String, CalculatorUseCase> _screenEngines =
      _buildScreenEngines();

  /// Движки кастомных экранов (read-only).
  static Map<String, CalculatorUseCase> get screenEngines =>
      Map.unmodifiable(_screenEngines);

  static Map<String, CalculatorUseCase> _buildScreenEngines() {
    final brick = CalculateBrick();
    final paint = CalculatePaint();
    final screed = CalculateScreedUnified();

    return <String, CalculatorUseCase>{
      'attic': CalculateAtticV2(),
      'balcony': CalculateBalconyV2(),
      'bathroom_waterproof': CalculateBathroomWaterproofV2(),
      'ceilings_cassette': CalculateCassetteCeilingV2(),
      'ceilings_insulation': CalculateCeilingInsulationV2(),
      'ceilings_rail': CalculateRailCeilingV2(),
      'ceilings_stretch': CalculateStretchCeilingV2(),
      'concrete_universal': CalculateConcreteUniversal(),
      'doors_install': CalculateDoorsInstallV2(),
      'engineering_electrics': CalculateElectricalV2(),
      'engineering_ventilation': CalculateVentilationV2(),
      'exterior_brick': brick,
      'exterior_facade_panels': CalculateFacadePanelsV2(),
      'fence': CalculateFenceV2(),
      'floors_laminate': CalculateLaminate(),
      'floors_linoleum': CalculateLinoleumV2(),
      'floors_parquet': CalculateParquet(),
      'floors_screed_unified': screed,
      'floors_self_leveling': CalculateSelfLevelingFloor(),
      'floors_tile': CalculateTile(),
      'floors_tile_grout': CalculateTileGrout(),
      'floors_warm': const WarmFloorUnifiedUseCase(),
      'foundation_basement': CalculateBasementV2(),
      'foundation_blind_area': CalculateBlindAreaV2(),
      'foundation_slab': CalculateSlabV2(),
      'foundation_strip': CalculateStripFoundation(),
      'gypsum_board': CalculateGypsumV2(),
      'mixes_plaster': CalculatePlaster(),
      'mixes_primer': CalculatePrimer(),
      'mixes_putty': CalculatePutty(),
      'mixes_tile_glue': CalculateTileGlue(),
      'paint_universal': paint,
      'partitions_blocks': CalculateGasblockV2(),
      'partitions_brick': brick,
      'roofing_gutters': CalculateGuttersV2(),
      'roofing_unified': CalculateUnifiedRoofing(),
      'room': CalculateRoom(),
      'slopes_finishing': CalculateSlopesV2(),
      'stairs': CalculateStairsV2(),
      'terrace': CalculateTerrace(),
      'walls_3d_panels': Calculate3dPanels(),
      'walls_decor_plaster': CalculateDecorPlasterV2(),
      'walls_decor_stone': CalculateDecorStoneV2(),
      'walls_mdf_panels': CalculateMdfPanelsV2(),
      'walls_pvc_panels': CalculatePvcPanelsV2(),
      'walls_wallpaper': CalculateWallpaper(),
      'walls_wood': CalculateWoodLining(),
      'windows_install': CalculateWindowInstallation(),
    };
  }

  static String _normalizeId(String calculatorId) =>
      CalculatorIdMigration.canonicalize(calculatorId);

  /// Возвращает движок для id: сначала экранный, иначе из каталога V2.
  static CalculatorUseCase resolve(String calculatorId) {
    final id = _normalizeId(calculatorId);
    final screenEngine = _screenEngines[id];
    if (screenEngine != null) {
      return screenEngine;
    }

    final definition = CalculatorRegistry.getById(id);
    if (definition == null) {
      throw ArgumentError('Unknown calculator id: $calculatorId');
    }
    return definition.useCase;
  }

  /// Выполняет расчёт через единый движок.
  static CalculatorResult calculate(
    String calculatorId,
    Map<String, double> inputs, {
    List<PriceItem> priceList = const [],
  }) {
    return resolve(calculatorId)(inputs, priceList);
  }

  /// Подменяет useCase в определении на экранный движок, если он зарегистрирован.
  static CalculatorUseCase alignUseCase(String id, CalculatorUseCase current) {
    return _screenEngines[id] ?? current;
  }
}
