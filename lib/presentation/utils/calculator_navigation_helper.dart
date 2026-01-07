import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/calculators/calculator_id_migration.dart';
import '../../domain/calculators/calculator_registry.dart';
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
import '../views/calculator/screed_calculator_screen.dart';
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
import '../views/calculator/fence_calculator_screen.dart';
import '../views/calculator/stairs_calculator_screen.dart';
import '../views/calculator/plumbing_calculator_screen.dart';
import '../views/calculator/ventilation_calculator_screen.dart';
import '../views/calculator/basement_calculator_screen.dart';
import '../views/calculator/blind_area_calculator_screen.dart';
import '../views/calculator/slab_calculator_screen.dart';
import '../views/calculator/gutters_calculator_screen.dart';
import '../views/paint/paint_screen.dart';
import '../views/wood/wood_screen.dart';
import '../views/dsp/dsp_screen.dart';
import '../views/osb/osb_calculator_screen.dart';
import '../../core/animations/page_transitions.dart';

/// Помощник для навигации к калькуляторам.
/// Автоматически выбирает V2 или старый экран в зависимости от наличия V2 версии.
class CalculatorNavigationHelper {
  /// Открыть калькулятор по старому определению.
  /// Автоматически использует V2 версию, если она доступна.
  static void navigateToCalculator(
    BuildContext context,
    CalculatorDefinitionV2 definition, {
    Map<String, double>? initialInputs,
  }) {
    // Специальные экраны с iOS-дизайном
    if (definition.id == 'mixes_plaster') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          PlasterCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'mixes_putty') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const PuttyCalculatorScreenV2(),
        ),
      );
      return;
    }

    if (definition.id == 'mixes_primer') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const PrimerCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'dsp') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const DspScreen(),
        ),
      );
      return;
    }

    // Новые калькуляторы с iOS-дизайном из HTML
    if (definition.id == 'paint_universal' || definition.id == 'paint') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const PaintScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'wood') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const WoodScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'sheeting_osb_plywood') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          OsbCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'gypsum_board') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          GypsumCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'walls_wallpaper') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          WallpaperCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'floors_self_leveling') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          SelfLevelingFloorCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'mixes_tile_glue') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          TileAdhesiveCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'engineering_heating' || definition.id == 'floors_warm') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          UnderfloorHeatingCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'walls_3d_panels') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          ThreeDPanelsCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'terrace') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          TerraceCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'walls_wood') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          WoodLiningCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'partitions_blocks') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          GasblockCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'floors_tile') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          TileCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'engineering_electrics') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          ElectricalCalculatorScreen(
            definition: definition,
            initialInputs: initialInputs,
          ),
        ),
      );
      return;
    }

    if (definition.id == 'floors_laminate') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const LaminateCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'partitions_brick' || definition.id == 'exterior_brick') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const BrickCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'floors_linoleum') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const LinoleumCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'floors_parquet') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const ParquetCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'floors_screed') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const ScreedCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'ceilings_stretch') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const StretchCeilingCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'ceilings_insulation') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const CeilingInsulationCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'ceilings_cassette') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const CassetteCeilingCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'ceilings_rail') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const RailCeilingCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'walls_decor_plaster') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const DecorPlasterCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'walls_decor_stone') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const DecorStoneCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'walls_mdf_panels') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const MdfPanelsCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'walls_pvc_panels') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const PvcPanelsCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'attic') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const AtticCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'balcony') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const BalconyCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'bathroom_waterproof') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const BathroomWaterproofCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'doors_install') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const DoorsInstallCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'insulation_sound') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const SoundInsulationCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'slopes_finishing') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const SlopesCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'windows_install') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const WindowsInstallCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'exterior_facade_panels') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const FacadePanelsCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'fence') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const FenceCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'stairs') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const StairsCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'engineering_plumbing') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const PlumbingCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'engineering_ventilation') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const VentilationCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'foundation_basement') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const BasementCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'foundation_blind_area') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const BlindAreaCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'foundation_slab') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const SlabCalculatorScreen(),
        ),
      );
      return;
    }

    if (definition.id == 'roofing_gutters') {
      Navigator.of(context).push(
        ModernPageTransitions.scale(
          const GuttersCalculatorScreen(),
        ),
      );
      return;
    }

    // Используем новый PRO UI для всех остальных калькуляторов
    Navigator.of(context).push(
      ModernPageTransitions.scale(
        ProCalculatorScreen(
          definition: definition,
          initialInputs: initialInputs,
        ),
      ),
    );
  }

  /// Открыть калькулятор по ID.
  /// Сначала пытается найти V2 версию, затем старую.
  static void navigateToCalculatorById(
    BuildContext context,
    String calculatorId,
  ) {
    final canonicalId = CalculatorIdMigration.canonicalize(calculatorId);
    final definition = CalculatorRegistry.getById(canonicalId);
    if (definition != null) {
      navigateToCalculator(context, definition);
      return;
    }

    // Калькулятор не найден
    // Логируем ошибку в Crashlytics
    try {
      FirebaseCrashlytics.instance.recordError(
        Exception('Calculator not found: $calculatorId'),
        StackTrace.current,
        reason: 'User attempted to open non-existent calculator',
        information: [
          'calculatorId: $calculatorId',
          'canonicalId: $canonicalId',
        ],
      );
    } catch (e) {
      // Игнорируем ошибки Firebase, если сервис недоступен
    }

    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.translate(
            'error.calculator_not_found',
            {'id': calculatorId},
          ),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Проверить, есть ли V2 версия для калькулятора
  static bool hasV2Version(String calculatorId) {
    final canonicalId = CalculatorIdMigration.canonicalize(calculatorId);
    return CalculatorRegistry.exists(canonicalId);
  }
}
