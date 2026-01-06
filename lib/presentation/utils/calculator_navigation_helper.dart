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
import '../views/primer/primer_screen.dart';
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
          const PrimerScreen(),
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
