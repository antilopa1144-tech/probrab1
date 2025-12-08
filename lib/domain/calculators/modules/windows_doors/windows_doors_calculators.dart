import '../../definitions.dart';
import '../../../usecases/calculate_window_installation.dart';
import '../../../usecases/calculate_door_installation.dart';
import '../../../usecases/calculate_slopes.dart';

/// Калькуляторы для окон и дверей
///
/// Содержит калькуляторы для расчёта материалов на установку и отделку:
/// - Установка окон (пена, подоконники, отливы, откосы)
/// - Установка дверей (коробки, наличники, петли, замки)
/// - Отделка откосов (шпаклёвка, грунтовка, покраска)
final List<CalculatorDefinition> windowsDoorsCalculators = [
  CalculatorDefinition(
    id: 'windows_install',
    titleKey: 'calculator.windowInstallation',
    category: 'Внутренняя отделка',
    subCategory: 'Окна / двери',
    fields: const [
      InputFieldDefinition(
        key: 'windows',
        labelKey: 'input.windows',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'windowWidth',
        labelKey: 'input.windowWidth',
        defaultValue: 1.5,
      ),
      InputFieldDefinition(
        key: 'windowHeight',
        labelKey: 'input.windowHeight',
        defaultValue: 1.4,
      ),
    ],
    resultLabels: const {
      'windows': 'result.windows',
      'windowArea': 'result.windowArea',
      'foamNeeded': 'result.foam',
      'sillsNeeded': 'result.sills',
      'sillLength': 'result.sillLength',
      'slopeArea': 'result.slopeArea',
      'dripLength': 'result.dripLength',
    },
    tips: const [
      'Используйте монтажную пену для герметизации.',
      'Установите отливы для защиты от воды.',
      'Проверьте вертикальность и горизонтальность.',
    ],
    useCase: CalculateWindowInstallation(),
  ),
  CalculatorDefinition(
    id: 'doors_install',
    titleKey: 'calculator.doorInstallation',
    category: 'Внутренняя отделка',
    subCategory: 'Окна / двери',
    fields: const [
      InputFieldDefinition(
        key: 'doors',
        labelKey: 'input.doors',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'doorWidth',
        labelKey: 'input.doorWidth',
        defaultValue: 0.9,
      ),
      InputFieldDefinition(
        key: 'doorHeight',
        labelKey: 'input.doorHeight',
        defaultValue: 2.1,
      ),
    ],
    resultLabels: const {
      'doors': 'result.doors',
      'foamNeeded': 'result.foam',
      'architraveLength': 'result.architrave',
      'framesNeeded': 'result.frames',
      'hingesNeeded': 'result.hinges',
      'locksNeeded': 'result.locks',
    },
    tips: const [
      'Проверьте вертикальность дверной коробки.',
      'Используйте монтажную пену для фиксации.',
      'Установите наличники для завершения.',
    ],
    useCase: CalculateDoorInstallation(),
  ),
  CalculatorDefinition(
    id: 'slopes_finishing',
    titleKey: 'calculator.slopes',
    category: 'Внутренняя отделка',
    subCategory: 'Окна / двери',
    fields: const [
      InputFieldDefinition(
        key: 'windows',
        labelKey: 'input.windows',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'windowWidth',
        labelKey: 'input.windowWidth',
        defaultValue: 1.5,
      ),
      InputFieldDefinition(
        key: 'windowHeight',
        labelKey: 'input.windowHeight',
        defaultValue: 1.4,
      ),
      InputFieldDefinition(
        key: 'slopeWidth',
        labelKey: 'input.slopeWidth',
        defaultValue: 0.3,
      ),
    ],
    resultLabels: const {
      'windows': 'result.windows',
      'slopeArea': 'result.slopeArea',
      'puttyNeeded': 'result.putty',
      'primerNeeded': 'result.primer',
      'paintNeeded': 'result.paint',
      'cornerLength': 'result.corner',
    },
    tips: const [
      'Используйте уголки для ровных углов.',
      'Шпаклёвку наносите тонким слоем.',
      'Красьте в 2 слоя для равномерного покрытия.',
    ],
    useCase: CalculateSlopes(),
  ),
];
