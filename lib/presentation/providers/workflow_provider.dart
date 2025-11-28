import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workflow_step.dart';
import '../../core/errors/error_handler.dart';

/// Провайдер для управления планами работ.
class WorkflowNotifier extends StateNotifier<List<WorkflowPlan>> {
  WorkflowNotifier() : super([]);

  void addPlan(WorkflowPlan plan) {
    state = [...state, plan];
  }

  void updatePlan(String planId, WorkflowPlan updated) {
    state = state.map((plan) => plan.id == planId ? updated : plan).toList();
  }

  void deletePlan(String planId) {
    state = state.where((plan) => plan.id != planId).toList();
  }

  WorkflowPlan? getPlan(String planId) {
    try {
      return state.firstWhere((plan) => plan.id == planId);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'WorkflowNotifier.getPlan');
      return null;
    }
  }
}

final workflowProvider = StateNotifierProvider<WorkflowNotifier, List<WorkflowPlan>>(
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
  }
  
  return WorkflowPlan(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: 'План работ для $objectType',
    steps: steps,
    createdAt: DateTime.now(),
  );
}

