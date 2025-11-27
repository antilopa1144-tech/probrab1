import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/workflow_step.dart';

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
      final updatedPlans = plans.map((plan) => plan.id == planId ? updated : plan).toList();
      state = AsyncValue.data(updatedPlans);
      await _savePlans(updatedPlans);
    });
  }

  Future<void> deletePlan(String planId) async {
    state.whenData((plans) async {
      final updatedPlans = plans.where((plan) => plan.id != planId).toList();
      state = AsyncValue.data(updatedPlans);
      await _savePlans(updatedPlans);
    });
  }

  WorkflowPlan? getPlan(String planId) {
    return state.whenOrNull(
      data: (plans) {
        try {
          return plans.firstWhere((plan) => plan.id == planId);
        } catch (_) {
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

final workflowProvider = StateNotifierProvider<WorkflowNotifier, AsyncValue<List<WorkflowPlan>>>(
  (ref) => WorkflowNotifier(),
);

/// Создать стандартный план работ для объекта.
WorkflowPlan createStandardWorkflow(String objectType) {
  final steps = <WorkflowStep>[];
  
  if (objectType == 'дом' || objectType == 'home') {
    steps.addAll([
      const WorkflowStep(
        id: 'foundation',
        title: 'Фундамент',
        description: 'Заливка фундамента',
        category: 'Фундамент',
        order: 1,
        estimatedDays: 7,
        requiredMaterials: ['Бетон', 'Арматура', 'Опалубка'],
        requiredTools: ['Бетономешалка', 'Виброуплотнитель'],
        checklist: [
          'Подготовить площадку',
          'Установить опалубку',
          'Уложить арматуру',
          'Залить бетон',
          'Выдержать 7 дней',
        ],
        isCritical: true,
      ),
      const WorkflowStep(
        id: 'walls',
        title: 'Стены',
        description: 'Возведение стен',
        category: 'Стены',
        order: 2,
        prerequisites: ['foundation'],
        estimatedDays: 14,
        requiredMaterials: ['Кирпич/блоки', 'Раствор'],
        requiredTools: ['Кельма', 'Уровень'],
        checklist: [
          'Проверить фундамент',
          'Начать кладку',
          'Контролировать вертикальность',
        ],
        isCritical: true,
      ),
      const WorkflowStep(
        id: 'roof',
        title: 'Кровля',
        description: 'Устройство кровли',
        category: 'Кровля',
        order: 3,
        prerequisites: ['walls'],
        estimatedDays: 5,
        requiredMaterials: ['Кровельный материал', 'Утеплитель'],
        requiredTools: ['Лестница', 'Инструменты для кровли'],
        checklist: [
          'Установить стропила',
          'Уложить утеплитель',
          'Смонтировать кровельный материал',
        ],
        isCritical: true,
      ),
      const WorkflowStep(
        id: 'interior',
        title: 'Внутренняя отделка',
        description: 'Отделочные работы',
        category: 'Отделка',
        order: 4,
        prerequisites: ['roof'],
        estimatedDays: 21,
        requiredMaterials: ['Штукатурка', 'Шпаклёвка', 'Краска', 'Обои'],
        requiredTools: ['Шпатели', 'Валики'],
        checklist: [
          'Штукатурка стен',
          'Шпаклёвка',
          'Грунтовка',
          'Покраска/обои',
        ],
        isCritical: false,
      ),
    ]);
  } else if (objectType == 'квартира' || objectType == 'flat') {
    steps.addAll([
      const WorkflowStep(
        id: 'prep',
        title: 'Подготовка',
        description: 'Подготовительные работы',
        category: 'Подготовка',
        order: 1,
        estimatedDays: 2,
        requiredMaterials: ['Защитная плёнка'],
        requiredTools: ['Скотч'],
        checklist: [
          'Защитить мебель',
          'Демонтировать старую отделку',
          'Подготовить поверхности',
        ],
        isCritical: true,
      ),
      const WorkflowStep(
        id: 'walls_finish',
        title: 'Отделка стен',
        description: 'Штукатурка и покраска стен',
        category: 'Стены',
        order: 2,
        prerequisites: ['prep'],
        estimatedDays: 7,
        requiredMaterials: ['Штукатурка', 'Шпаклёвка', 'Краска'],
        requiredTools: ['Шпатели', 'Валики'],
        checklist: [
          'Выровнять стены',
          'Зашпаклевать',
          'Покрасить',
        ],
        isCritical: true,
      ),
      const WorkflowStep(
        id: 'floors_finish',
        title: 'Отделка полов',
        description: 'Укладка напольного покрытия',
        category: 'Полы',
        order: 3,
        prerequisites: ['walls_finish'],
        estimatedDays: 5,
        requiredMaterials: ['Напольное покрытие', 'Подложка'],
        requiredTools: ['Нож', 'Молоток'],
        checklist: [
          'Выровнять пол',
          'Уложить подложку',
          'Уложить покрытие',
        ],
        isCritical: true,
      ),
    ]);
  } else if (objectType == 'гараж' || objectType == 'garage') {
    steps.addAll([
      const WorkflowStep(
        id: 'foundation_garage',
        title: 'Плита основания',
        description: 'Бетонная плита для гаража',
        category: 'Фундамент',
        order: 1,
        estimatedDays: 5,
        requiredMaterials: ['Бетон', 'Арматурная сетка', 'Песок', 'Щебень'],
        requiredTools: ['Бетономешалка', 'Виброрейка'],
        checklist: [
          'Подготовить основание',
          'Уложить песчаную подушку',
          'Установить арматуру',
          'Залить бетон',
        ],
        isCritical: true,
      ),
      const WorkflowStep(
        id: 'walls_garage',
        title: 'Стены гаража',
        description: 'Возведение стен',
        category: 'Стены',
        order: 2,
        prerequisites: ['foundation_garage'],
        estimatedDays: 7,
        requiredMaterials: ['Блоки/кирпич', 'Раствор'],
        requiredTools: ['Кельма', 'Уровень'],
        checklist: [
          'Кладка стен',
          'Контроль вертикальности',
          'Подготовка под ворота',
        ],
        isCritical: true,
      ),
      const WorkflowStep(
        id: 'roof_garage',
        title: 'Крыша гаража',
        description: 'Устройство кровли',
        category: 'Кровля',
        order: 3,
        prerequisites: ['walls_garage'],
        estimatedDays: 3,
        requiredMaterials: ['Профнастил', 'Брус', 'Гидроизоляция'],
        requiredTools: ['Шуруповёрт', 'Ножницы по металлу'],
        checklist: [
          'Установить балки перекрытия',
          'Уложить гидроизоляцию',
          'Смонтировать кровлю',
        ],
        isCritical: true,
      ),
    ]);
  }
  
  return WorkflowPlan(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: 'План работ: $objectType',
    steps: steps,
    createdAt: DateTime.now(),
  );
}

