import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/workflow_step.dart';
import '../../core/errors/error_handler.dart';
import '../../core/localization/app_localizations.dart';

/// Провайдер для управления планами работ с персистентным хранением.
class WorkflowNotifier extends StateNotifier<AsyncValue<List<WorkflowPlan>>> {
  WorkflowNotifier() : super(const AsyncValue.loading()) {
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getStringList('workflow_plans') ?? [];
      
      final plans = plansJson
          .map((json) => WorkflowPlan.fromJson(jsonDecode(json)))
          .toList();
      
      state = AsyncValue.data(plans);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _savePlans(List<WorkflowPlan> plans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = plans.map((plan) => jsonEncode(plan.toJson())).toList();
      await prefs.setStringList('workflow_plans', plansJson);
    } catch (_) {
      // Игнорируем ошибки сохранения
    }
  }

  Future<void> addPlan(WorkflowPlan plan) async {
    state.whenData((plans) async {
      final updated = [...plans, plan];
      state = AsyncValue.data(updated);
      await _savePlans(updated);
    });
  }

  Future<void> updatePlan(String planId, WorkflowPlan updated) async {
    state.whenData((plans) async {
      final updatedPlans =
          plans.map((plan) => plan.id == planId ? updated : plan).toList();
      state = AsyncValue.data(updatedPlans);
      await _savePlans(updatedPlans);
    });
  }

  Future<void> deletePlan(String planId) async {
    state.whenData((plans) async {
      final updatedPlans =
          plans.where((plan) => plan.id != planId).toList();
      state = AsyncValue.data(updatedPlans);
      await _savePlans(updatedPlans);
    });
  }

  WorkflowPlan? getPlan(String planId) {
    return state.whenOrNull(
      data: (plans) {
        try {
          return plans.firstWhere((plan) => plan.id == planId);
        } catch (e, stackTrace) {
          ErrorHandler.logError(e, stackTrace, 'WorkflowNotifier.getPlan');
          return null;
        }
      },
    );
  }

  /// Обновить прогресс выполнения плана
  Future<void> updateProgress(String planId, Set<String> completedSteps) async {
    state.whenData((plans) async {
      final planIndex = plans.indexWhere((p) => p.id == planId);
      if (planIndex != -1) {
        final updated = plans[planIndex].copyWith(
          completedSteps: completedSteps.toList(),
        );
        final updatedPlans = List<WorkflowPlan>.from(plans);
        updatedPlans[planIndex] = updated;
        state = AsyncValue.data(updatedPlans);
        await _savePlans(updatedPlans);
      }
    });
  }

  Future<void> refresh() => _loadPlans();
}

final workflowProvider =
    StateNotifierProvider<WorkflowNotifier, AsyncValue<List<WorkflowPlan>>>(
  (ref) => WorkflowNotifier(),
);

/// Создать стандартный план работ для объекта.
WorkflowPlan createStandardWorkflow(String objectType, AppLocalizations loc) {
  String t(String key, [Map<String, String>? params]) {
    return loc.translate(key, params);
  }

  String normalizeType(String value) {
    if (value == 'home' || value == t('workflow.object.home')) {
      return 'home';
    }
    if (value == 'flat' || value == t('workflow.object.flat')) {
      return 'flat';
    }
    if (value == 'garage' || value == t('workflow.object.garage')) {
      return 'garage';
    }
    return value;
  }

  final normalizedType = normalizeType(objectType);
  final objectKey = switch (normalizedType) {
    'home' => 'workflow.object.home',
    'flat' => 'workflow.object.flat',
    'garage' => 'workflow.object.garage',
    _ => 'workflow.object.home',
  };
  final steps = <WorkflowStep>[];
  
  if (normalizedType == 'home') {
    steps.addAll([
      WorkflowStep(
        id: 'foundation',
        title: t('workflow.step.foundation.title'),
        description: t('workflow.step.foundation.description'),
        category: t('workflow.category.foundation'),
        order: 1,
        estimatedDays: 7,
        requiredMaterials: [
          t('workflow.material.concrete'),
          t('workflow.material.rebar'),
          t('workflow.material.formwork'),
        ],
        requiredTools: [
          t('workflow.tool.concrete_mixer'),
          t('workflow.tool.vibration_compactor'),
        ],
        checklist: [
          t('workflow.checklist.prepare_site'),
          t('workflow.checklist.install_formwork'),
          t('workflow.checklist.place_rebar'),
          t('workflow.checklist.pour_concrete'),
          t('workflow.checklist.cure_7_days'),
        ],
        isCritical: true,
      ),
      WorkflowStep(
        id: 'walls',
        title: t('workflow.step.walls.title'),
        description: t('workflow.step.walls.description'),
        category: t('workflow.category.walls'),
        order: 2,
        prerequisites: ['foundation'],
        estimatedDays: 14,
        requiredMaterials: [
          t('workflow.material.brick_blocks'),
          t('workflow.material.mortar'),
        ],
        requiredTools: [
          t('workflow.tool.trowel'),
          t('workflow.tool.level'),
        ],
        checklist: [
          t('workflow.checklist.check_foundation'),
          t('workflow.checklist.start_masonry'),
          t('workflow.checklist.control_vertical'),
        ],
        isCritical: true,
      ),
      WorkflowStep(
        id: 'roof',
        title: t('workflow.step.roof.title'),
        description: t('workflow.step.roof.description'),
        category: t('workflow.category.roofing'),
        order: 3,
        prerequisites: ['walls'],
        estimatedDays: 5,
        requiredMaterials: [
          t('workflow.material.roofing_material'),
          t('workflow.material.insulation'),
        ],
        requiredTools: [
          t('workflow.tool.ladder'),
          t('workflow.tool.roofing_tools'),
        ],
        checklist: [
          t('workflow.checklist.install_rafters'),
          t('workflow.checklist.lay_insulation'),
          t('workflow.checklist.install_roofing'),
        ],
        isCritical: true,
      ),
      WorkflowStep(
        id: 'interior',
        title: t('workflow.step.interior.title'),
        description: t('workflow.step.interior.description'),
        category: t('workflow.category.finishing'),
        order: 4,
        prerequisites: ['roof'],
        estimatedDays: 21,
        requiredMaterials: [
          t('workflow.material.plaster'),
          t('workflow.material.putty'),
          t('workflow.material.paint'),
          t('workflow.material.wallpaper'),
        ],
        requiredTools: [
          t('workflow.tool.spatulas'),
          t('workflow.tool.rollers'),
        ],
        checklist: [
          t('workflow.checklist.plaster_walls'),
          t('workflow.checklist.putty'),
          t('workflow.checklist.prime'),
          t('workflow.checklist.paint_wallpaper'),
        ],
        isCritical: false,
      ),
    ]);
  } else if (normalizedType == 'flat') {
    steps.addAll([
      WorkflowStep(
        id: 'prep',
        title: t('workflow.step.prep.title'),
        description: t('workflow.step.prep.description'),
        category: t('workflow.category.preparation'),
        order: 1,
        estimatedDays: 2,
        requiredMaterials: [
          t('workflow.material.protective_film'),
        ],
        requiredTools: [
          t('workflow.tool.tape'),
        ],
        checklist: [
          t('workflow.checklist.protect_furniture'),
          t('workflow.checklist.remove_old_finish'),
          t('workflow.checklist.prepare_surfaces'),
        ],
        isCritical: true,
      ),
      WorkflowStep(
        id: 'walls_finish',
        title: t('workflow.step.walls_finish.title'),
        description: t('workflow.step.walls_finish.description'),
        category: t('workflow.category.walls'),
        order: 2,
        prerequisites: ['prep'],
        estimatedDays: 7,
        requiredMaterials: [
          t('workflow.material.plaster'),
          t('workflow.material.putty'),
          t('workflow.material.paint'),
        ],
        requiredTools: [
          t('workflow.tool.spatulas'),
          t('workflow.tool.rollers'),
        ],
        checklist: [
          t('workflow.checklist.level_walls'),
          t('workflow.checklist.apply_putty'),
          t('workflow.checklist.paint'),
        ],
        isCritical: true,
      ),
      WorkflowStep(
        id: 'floors_finish',
        title: t('workflow.step.floors_finish.title'),
        description: t('workflow.step.floors_finish.description'),
        category: t('workflow.category.floors'),
        order: 3,
        prerequisites: ['walls_finish'],
        estimatedDays: 5,
        requiredMaterials: [
          t('workflow.material.flooring'),
          t('workflow.material.underlay'),
        ],
        requiredTools: [
          t('workflow.tool.knife'),
          t('workflow.tool.hammer'),
        ],
        checklist: [
          t('workflow.checklist.level_floor'),
          t('workflow.checklist.lay_underlay'),
          t('workflow.checklist.lay_flooring'),
        ],
        isCritical: true,
      ),
    ]);
  } else if (normalizedType == 'garage') {
    steps.addAll([
      WorkflowStep(
        id: 'foundation_garage',
        title: t('workflow.step.foundation_garage.title'),
        description: t('workflow.step.foundation_garage.description'),
        category: t('workflow.category.foundation'),
        order: 1,
        estimatedDays: 5,
        requiredMaterials: [
          t('workflow.material.concrete'),
          t('workflow.material.rebar_mesh'),
          t('workflow.material.sand'),
          t('workflow.material.crushed_stone'),
        ],
        requiredTools: [
          t('workflow.tool.concrete_mixer'),
          t('workflow.tool.vibrating_screed'),
        ],
        checklist: [
          t('workflow.checklist.prepare_base'),
          t('workflow.checklist.lay_sand_bed'),
          t('workflow.checklist.install_rebar'),
          t('workflow.checklist.pour_concrete'),
        ],
        isCritical: true,
      ),
      WorkflowStep(
        id: 'walls_garage',
        title: t('workflow.step.walls_garage.title'),
        description: t('workflow.step.walls.description'),
        category: t('workflow.category.walls'),
        order: 2,
        prerequisites: ['foundation_garage'],
        estimatedDays: 7,
        requiredMaterials: [
          t('workflow.material.blocks_brick'),
          t('workflow.material.mortar'),
        ],
        requiredTools: [
          t('workflow.tool.trowel'),
          t('workflow.tool.level'),
        ],
        checklist: [
          t('workflow.checklist.lay_walls'),
          t('workflow.checklist.control_vertical'),
          t('workflow.checklist.prepare_gate_opening'),
        ],
        isCritical: true,
      ),
      WorkflowStep(
        id: 'roof_garage',
        title: t('workflow.step.roof_garage.title'),
        description: t('workflow.step.roof.description'),
        category: t('workflow.category.roofing'),
        order: 3,
        prerequisites: ['walls_garage'],
        estimatedDays: 3,
        requiredMaterials: [
          t('workflow.material.corrugated_sheet'),
          t('workflow.material.timber'),
          t('workflow.material.waterproofing'),
        ],
        requiredTools: [
          t('workflow.tool.screwdriver'),
          t('workflow.tool.metal_shears'),
        ],
        checklist: [
          t('workflow.checklist.install_floor_beams'),
          t('workflow.checklist.lay_waterproofing'),
          t('workflow.checklist.install_roof'),
        ],
        isCritical: true,
      ),
    ]);
  }
  
  return WorkflowPlan(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: t('workflow.plan.title', {'object': t(objectKey)}),
    steps: steps,
    createdAt: DateTime.now(),
  );
}
