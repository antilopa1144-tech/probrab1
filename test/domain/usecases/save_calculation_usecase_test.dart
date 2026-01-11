import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:probrab_ai/core/exceptions/storage_exception.dart';
import 'package:probrab_ai/data/repositories/project_repository_v2.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/domain/usecases/save_calculation_usecase.dart';

void main() {
  late Isar isar;
  late ProjectRepositoryV2 repository;
  late SaveCalculationUseCase useCase;

  setUp(() async {
    // Создаём in-memory Isar для тестов
    isar = await Isar.open(
      [ProjectV2Schema, ProjectCalculationSchema],
      directory: '',
      name: 'test_save_calc_${DateTime.now().millisecondsSinceEpoch}',
    );
    repository = ProjectRepositoryV2(isar);
    useCase = SaveCalculationUseCase(repository);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('SaveCalculationUseCase - execute', () {
    test('успешно сохраняет расчёт в проект', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Тестовый проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'gypsum'
        ..name = 'Гипсокартон'
        ..materialCost = 5000.0
        ..laborCost = 2500.0;

      // Act
      final result = await useCase.execute(
        projectId: projectId,
        calculation: calculation,
      );

      // Assert
      expect(result.id, isNot(0));
      expect(result.calculatorId, 'gypsum');
      expect(result.name, 'Гипсокартон');

      // Проверяем что сохранилось в БД
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations.length, 1);
      expect(calculations[0].calculatorId, 'gypsum');
    });

    test('бросает ArgumentError при projectId == 0', () async {
      // Arrange
      final calculation = ProjectCalculation()
        ..calculatorId = 'test'
        ..name = 'Test';

      // Act & Assert
      expect(
        () => useCase.execute(projectId: 0, calculation: calculation),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает ArgumentError при отрицательном projectId', () async {
      // Arrange
      final calculation = ProjectCalculation()
        ..calculatorId = 'test'
        ..name = 'Test';

      // Act & Assert
      expect(
        () => useCase.execute(projectId: -1, calculation: calculation),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает StorageException при несуществующем projectId', () async {
      // Arrange
      final calculation = ProjectCalculation()
        ..calculatorId = 'test'
        ..name = 'Test';

      // Act & Assert
      expect(
        () => useCase.execute(projectId: 99999, calculation: calculation),
        throwsA(isA<StorageException>()),
      );
    });

    test('сохраняет расчёт с inputs и results', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'tile'
        ..name = 'Плитка';

      calculation.setInputsFromMap({'area': 20.0, 'reserve': 10.0});
      calculation.setResultsFromMap({'tiles': 100.0});

      // Act
      final result = await useCase.execute(
        projectId: projectId,
        calculation: calculation,
      );

      // Assert
      expect(result.inputsMap['area'], 20.0);
      expect(result.inputsMap['reserve'], 10.0);
      expect(result.resultsMap['tiles'], 100.0);
    });

    test('сохраняет расчёт с materials', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'brick'
        ..name = 'Кирпич'
        ..materials = [
          ProjectMaterial()
            ..name = 'Кирпич красный'
            ..quantity = 1000.0
            ..unit = 'шт'
            ..pricePerUnit = 10.0,
        ];

      // Act
      final result = await useCase.execute(
        projectId: projectId,
        calculation: calculation,
      );

      // Assert
      expect(result.materials.length, 1);
      expect(result.materials[0].name, 'Кирпич красный');
      expect(result.materials[0].totalCost, 10000.0);
    });

    test('сохраняет несколько расчётов в один проект', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calc1 = ProjectCalculation()
        ..calculatorId = 'calc1'
        ..name = 'Расчёт 1';

      final calc2 = ProjectCalculation()
        ..calculatorId = 'calc2'
        ..name = 'Расчёт 2';

      // Act
      await useCase.execute(projectId: projectId, calculation: calc1);
      await useCase.execute(projectId: projectId, calculation: calc2);

      // Assert
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations.length, 2);
    });
  });

  group('SaveCalculationUseCase - update', () {
    test('успешно обновляет расчёт', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'test'
        ..name = 'Первоначальное название'
        ..materialCost = 1000.0;

      await useCase.execute(projectId: projectId, calculation: calculation);

      // Изменяем данные
      calculation.name = 'Обновлённое название';
      calculation.materialCost = 2000.0;

      // Act
      final result = await useCase.update(calculation: calculation);

      // Assert
      expect(result.name, 'Обновлённое название');
      expect(result.materialCost, 2000.0);

      // Проверяем в БД
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations[0].name, 'Обновлённое название');
      expect(calculations[0].materialCost, 2000.0);
    });

    test('бросает ArgumentError при calculation.id == 0', () async {
      // Arrange
      final calculation = ProjectCalculation()
        ..id = 0
        ..calculatorId = 'test'
        ..name = 'Test';

      // Act & Assert
      expect(
        () => useCase.update(calculation: calculation),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает ArgumentError если расчёт не связан с проектом', () async {
      // Arrange
      final calculation = ProjectCalculation()
        ..id = 10
        ..calculatorId = 'test'
        ..name = 'Test';
      // project.value останется null

      // Act & Assert
      expect(
        () => useCase.update(calculation: calculation),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('обновляет materials в расчёте', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'test'
        ..name = 'Test'
        ..materials = [
          ProjectMaterial()
            ..name = 'Материал 1'
            ..quantity = 10.0
            ..unit = 'шт'
            ..pricePerUnit = 100.0,
        ];

      await useCase.execute(projectId: projectId, calculation: calculation);

      // Добавляем новый материал
      calculation.materials.add(
        ProjectMaterial()
          ..name = 'Материал 2'
          ..quantity = 5.0
          ..unit = 'шт'
          ..pricePerUnit = 50.0,
      );

      // Act
      await useCase.update(calculation: calculation);

      // Assert
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations[0].materials.length, 2);
      expect(calculations[0].materials[1].name, 'Материал 2');
    });
  });

  group('SaveCalculationUseCase - delete', () {
    test('успешно удаляет расчёт', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'test'
        ..name = 'Test';

      await useCase.execute(projectId: projectId, calculation: calculation);
      final calculationId = calculation.id;

      // Act
      await useCase.delete(calculationId: calculationId);

      // Assert
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations, isEmpty);
    });

    test('бросает ArgumentError при calculationId == 0', () async {
      // Act & Assert
      expect(
        () => useCase.delete(calculationId: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает ArgumentError при отрицательном calculationId', () async {
      // Act & Assert
      expect(
        () => useCase.delete(calculationId: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('удаление несуществующего расчёта не вызывает ошибку', () async {
      // Act & Assert - не должно быть исключения
      await useCase.delete(calculationId: 99999);
    });

    test('удаляет один из нескольких расчётов', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calc1 = ProjectCalculation()
        ..calculatorId = 'calc1'
        ..name = 'Расчёт 1';

      final calc2 = ProjectCalculation()
        ..calculatorId = 'calc2'
        ..name = 'Расчёт 2';

      await useCase.execute(projectId: projectId, calculation: calc1);
      await useCase.execute(projectId: projectId, calculation: calc2);

      // Act - удаляем первый расчёт
      await useCase.delete(calculationId: calc1.id);

      // Assert
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations.length, 1);
      expect(calculations[0].calculatorId, 'calc2');
    });
  });

  group('SaveCalculationUseCase - Интеграционные сценарии', () {
    test('создание, обновление и удаление расчёта', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'test'
        ..name = 'Начальное название';

      // Act - Создание
      await useCase.execute(projectId: projectId, calculation: calculation);
      expect(calculation.id, isNot(0));

      // Act - Обновление
      calculation.name = 'Обновлённое название';
      await useCase.update(calculation: calculation);

      // Act - Удаление
      await useCase.delete(calculationId: calculation.id);

      // Assert
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations, isEmpty);
    });

    test('работа с расчётами в разных проектах', () async {
      // Arrange
      final project1 = ProjectV2()
        ..name = 'Проект 1'
        ..status = ProjectStatus.planning;

      final project2 = ProjectV2()
        ..name = 'Проект 2'
        ..status = ProjectStatus.planning;

      final projectId1 = await repository.createProject(project1);
      final projectId2 = await repository.createProject(project2);

      final calc1 = ProjectCalculation()
        ..calculatorId = 'calc1'
        ..name = 'Расчёт 1';

      final calc2 = ProjectCalculation()
        ..calculatorId = 'calc2'
        ..name = 'Расчёт 2';

      // Act
      await useCase.execute(projectId: projectId1, calculation: calc1);
      await useCase.execute(projectId: projectId2, calculation: calc2);

      // Assert
      final calculations1 = await repository.getProjectCalculations(projectId1);
      final calculations2 = await repository.getProjectCalculations(projectId2);

      expect(calculations1.length, 1);
      expect(calculations2.length, 1);
      expect(calculations1[0].calculatorId, 'calc1');
      expect(calculations2[0].calculatorId, 'calc2');
    });

    test('обновление расчёта несколько раз', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'test'
        ..name = 'Версия 1';

      await useCase.execute(projectId: projectId, calculation: calculation);

      // Act - Обновляем 3 раза
      calculation.name = 'Версия 2';
      await useCase.update(calculation: calculation);

      calculation.name = 'Версия 3';
      await useCase.update(calculation: calculation);

      calculation.name = 'Финальная версия';
      await useCase.update(calculation: calculation);

      // Assert
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations[0].name, 'Финальная версия');
    });
  });

  group('SaveCalculationUseCase - Граничные случаи', () {
    test('сохранение расчёта с пустым названием', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'test'
        ..name = '';

      // Act
      final result = await useCase.execute(
        projectId: projectId,
        calculation: calculation,
      );

      // Assert
      expect(result.name, '');
    });

    test('сохранение расчёта с нулевыми стоимостями', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'free'
        ..name = 'Бесплатный'
        ..materialCost = 0.0
        ..laborCost = 0.0;

      // Act
      final result = await useCase.execute(
        projectId: projectId,
        calculation: calculation,
      );

      // Assert
      expect(result.materialCost, 0.0);
      expect(result.laborCost, 0.0);
    });

    test('сохранение расчёта с пустыми inputs и results', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'empty'
        ..name = 'Empty';

      calculation.setInputsFromMap({});
      calculation.setResultsFromMap({});

      // Act
      final result = await useCase.execute(
        projectId: projectId,
        calculation: calculation,
      );

      // Assert
      expect(result.inputsMap, isEmpty);
      expect(result.resultsMap, isEmpty);
    });

    test('сохранение расчёта с очень длинным названием', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final longName = 'Очень ' * 50 + 'длинное название';

      final calculation = ProjectCalculation()
        ..calculatorId = 'long'
        ..name = longName;

      // Act
      final result = await useCase.execute(
        projectId: projectId,
        calculation: calculation,
      );

      // Assert
      expect(result.name, longName);
      expect(result.name.length, greaterThan(200));
    });

    test('сохранение расчёта с большим количеством materials', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      final materials = List.generate(
        20,
        (i) => ProjectMaterial()
          ..name = 'Материал $i'
          ..quantity = (i + 1).toDouble()
          ..unit = 'шт'
          ..pricePerUnit = 100.0,
      );

      final calculation = ProjectCalculation()
        ..calculatorId = 'many'
        ..name = 'Много материалов'
        ..materials = materials;

      // Act
      final result = await useCase.execute(
        projectId: projectId,
        calculation: calculation,
      );

      // Assert
      expect(result.materials.length, 20);
      expect(result.materials[0].name, 'Материал 0');
      expect(result.materials[19].name, 'Материал 19');
    });
  });
}
