import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:probrab_ai/core/exceptions/storage_exception.dart';
import 'package:probrab_ai/data/repositories/project_repository_v2.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/domain/usecases/delete_project_usecase.dart';

void main() {
  late Isar isar;
  late ProjectRepositoryV2 repository;
  late DeleteProjectUseCase useCase;

  setUp(() async {
    // Создаём in-memory Isar для тестов
    isar = await Isar.open(
      [ProjectV2Schema, ProjectCalculationSchema],
      directory: '',
      name: 'test_delete_proj_${DateTime.now().millisecondsSinceEpoch}',
    );
    repository = ProjectRepositoryV2(isar);
    useCase = DeleteProjectUseCase(repository);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('DeleteProjectUseCase - execute', () {
    test('успешно удаляет проект', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Тестовый проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      // Act
      await useCase.execute(projectId: projectId);

      // Assert
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);
    });

    test('бросает ArgumentError при projectId == 0', () async {
      // Act & Assert
      expect(
        () => useCase.execute(projectId: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает ArgumentError при отрицательном projectId', () async {
      // Act & Assert
      expect(
        () => useCase.execute(projectId: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает StorageException при несуществующем projectId', () async {
      // Act & Assert
      expect(
        () => useCase.execute(projectId: 99999),
        throwsA(isA<StorageException>()),
      );
    });

    test('удаляет проект с расчётами (cascade delete)', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект с расчётами'
        ..status = ProjectStatus.inProgress;

      final projectId = await repository.createProject(project);

      final calculation = ProjectCalculation()
        ..calculatorId = 'gypsum'
        ..name = 'Гипсокартон';

      await repository.addCalculationToProject(projectId, calculation);

      // Проверяем что расчёт добавлен
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations.length, 1);

      // Act
      await useCase.execute(projectId: projectId);

      // Assert
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);

      // Проверяем что расчёт тоже удалён
      final calc = await isar.projectCalculations.get(calculation.id);
      expect(calc, isNull);
    });

    test('удаляет проект с множеством расчётов', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      // Добавляем 5 расчётов
      for (var i = 0; i < 5; i++) {
        final calc = ProjectCalculation()
          ..calculatorId = 'calc_$i'
          ..name = 'Расчёт $i';

        await repository.addCalculationToProject(projectId, calc);
      }

      // Проверяем что все добавлены
      final calculations = await repository.getProjectCalculations(projectId);
      expect(calculations.length, 5);

      // Act
      await useCase.execute(projectId: projectId);

      // Assert
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);
    });

    test('удаление одного проекта не влияет на другие', () async {
      // Arrange
      final project1 = ProjectV2()
        ..name = 'Проект 1'
        ..status = ProjectStatus.planning;

      final project2 = ProjectV2()
        ..name = 'Проект 2'
        ..status = ProjectStatus.planning;

      final projectId1 = await repository.createProject(project1);
      final projectId2 = await repository.createProject(project2);

      // Act - удаляем первый проект
      await useCase.execute(projectId: projectId1);

      // Assert
      final result1 = await repository.getProjectById(projectId1);
      final result2 = await repository.getProjectById(projectId2);

      expect(result1, isNull);
      expect(result2, isNotNull);
      expect(result2!.name, 'Проект 2');
    });

    test('удаляет проект со всеми полями', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Полный проект'
        ..description = 'Описание'
        ..status = ProjectStatus.inProgress
        ..isFavorite = true
        ..tags = ['тег1', 'тег2']
        ..notes = 'Заметки'
        ..color = 0xFF0000FF;

      final projectId = await repository.createProject(project);

      // Act
      await useCase.execute(projectId: projectId);

      // Assert
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);
    });
  });

  group('DeleteProjectUseCase - deleteMultiple', () {
    test('успешно удаляет несколько проектов', () async {
      // Arrange
      final project1 = ProjectV2()
        ..name = 'Проект 1'
        ..status = ProjectStatus.planning;

      final project2 = ProjectV2()
        ..name = 'Проект 2'
        ..status = ProjectStatus.planning;

      final project3 = ProjectV2()
        ..name = 'Проект 3'
        ..status = ProjectStatus.planning;

      final id1 = await repository.createProject(project1);
      final id2 = await repository.createProject(project2);
      final id3 = await repository.createProject(project3);

      // Act
      await useCase.deleteMultiple(projectIds: [id1, id2, id3]);

      // Assert
      final result1 = await repository.getProjectById(id1);
      final result2 = await repository.getProjectById(id2);
      final result3 = await repository.getProjectById(id3);

      expect(result1, isNull);
      expect(result2, isNull);
      expect(result3, isNull);
    });

    test('бросает ArgumentError при пустом списке', () async {
      // Act & Assert
      expect(
        () => useCase.deleteMultiple(projectIds: []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает ArgumentError если в списке есть 0', () async {
      // Act & Assert
      expect(
        () => useCase.deleteMultiple(projectIds: [1, 0, 3]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает ArgumentError если в списке есть отрицательное значение', () async {
      // Act & Assert
      expect(
        () => useCase.deleteMultiple(projectIds: [1, 2, -1]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('частичное удаление при ошибке в середине списка', () async {
      // Arrange
      final project1 = ProjectV2()
        ..name = 'Проект 1'
        ..status = ProjectStatus.planning;

      final project2 = ProjectV2()
        ..name = 'Проект 2'
        ..status = ProjectStatus.planning;

      final id1 = await repository.createProject(project1);
      final id2 = await repository.createProject(project2);

      // Act & Assert - пытаемся удалить 2 существующих и 1 несуществующий
      try {
        await useCase.deleteMultiple(projectIds: [id1, 99999, id2]);
      } catch (e) {
        expect(e, isA<StorageException>());
      }

      // Проверяем состояние - первый должен быть удалён
      final result1 = await repository.getProjectById(id1);
      expect(result1, isNull);

      // Второй не должен быть удалён т.к. ошибка произошла до него
      final result2 = await repository.getProjectById(id2);
      expect(result2, isNotNull);
    });

    test('удаляет все проекты в БД', () async {
      // Arrange
      final projects = List.generate(
        10,
        (i) => ProjectV2()
          ..name = 'Проект $i'
          ..status = ProjectStatus.planning,
      );

      final ids = <int>[];
      for (final project in projects) {
        ids.add(await repository.createProject(project));
      }

      // Act
      await useCase.deleteMultiple(projectIds: ids);

      // Assert
      final allProjects = await repository.getAllProjects();
      expect(allProjects, isEmpty);
    });

    test('удаляет проекты с разным статусом', () async {
      // Arrange
      final statuses = [
        ProjectStatus.planning,
        ProjectStatus.inProgress,
        ProjectStatus.onHold,
        ProjectStatus.completed,
        ProjectStatus.cancelled,
      ];

      final ids = <int>[];
      for (final status in statuses) {
        final project = ProjectV2()
          ..name = 'Проект ${status.name}'
          ..status = status;

        ids.add(await repository.createProject(project));
      }

      // Act
      await useCase.deleteMultiple(projectIds: ids);

      // Assert
      final allProjects = await repository.getAllProjects();
      expect(allProjects, isEmpty);
    });
  });

  group('DeleteProjectUseCase - Интеграционные сценарии', () {
    test('создание и немедленное удаление проекта', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Временный проект'
        ..status = ProjectStatus.planning;

      // Act
      final projectId = await repository.createProject(project);
      await useCase.execute(projectId: projectId);

      // Assert
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);
    });

    test('удаление проекта освобождает имя для нового проекта', () async {
      // Arrange
      final project1 = ProjectV2()
        ..name = 'Одинаковое название'
        ..status = ProjectStatus.planning;

      final projectId1 = await repository.createProject(project1);

      // Act - удаляем первый
      await useCase.execute(projectId: projectId1);

      // Создаём второй с тем же названием
      final project2 = ProjectV2()
        ..name = 'Одинаковое название'
        ..status = ProjectStatus.planning;

      final projectId2 = await repository.createProject(project2);

      // Assert
      expect(projectId2, isNot(projectId1));
      final result = await repository.getProjectById(projectId2);
      expect(result, isNotNull);
      expect(result!.name, 'Одинаковое название');
    });

    test('массовое удаление проектов', () async {
      // Arrange - создаём 50 проектов
      final ids = <int>[];
      for (var i = 0; i < 50; i++) {
        final project = ProjectV2()
          ..name = 'Проект $i'
          ..status = ProjectStatus.planning;

        ids.add(await repository.createProject(project));
      }

      // Act - удаляем все
      await useCase.deleteMultiple(projectIds: ids);

      // Assert
      final allProjects = await repository.getAllProjects();
      expect(allProjects, isEmpty);
    });

    test('удаление избранных и обычных проектов', () async {
      // Arrange
      final favorite = ProjectV2()
        ..name = 'Избранный'
        ..status = ProjectStatus.planning
        ..isFavorite = true;

      final regular = ProjectV2()
        ..name = 'Обычный'
        ..status = ProjectStatus.planning
        ..isFavorite = false;

      final favoriteId = await repository.createProject(favorite);
      final regularId = await repository.createProject(regular);

      // Act
      await useCase.deleteMultiple(projectIds: [favoriteId, regularId]);

      // Assert
      final allProjects = await repository.getAllProjects();
      expect(allProjects, isEmpty);
    });
  });

  group('DeleteProjectUseCase - Граничные случаи', () {
    test('удаление проекта с очень длинным названием', () async {
      // Arrange
      final longName = 'Очень ' * 100 + 'длинное название';

      final project = ProjectV2()
        ..name = longName
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      // Act
      await useCase.execute(projectId: projectId);

      // Assert
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);
    });

    test('удаление проекта с множеством тегов', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning
        ..tags = List.generate(50, (i) => 'тег$i');

      final projectId = await repository.createProject(project);

      // Act
      await useCase.execute(projectId: projectId);

      // Assert
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);
    });

    test('удаление проекта с очень длинными заметками', () async {
      // Arrange
      final longNotes = 'Очень ' * 1000 + 'длинные заметки';

      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning
        ..notes = longNotes;

      final projectId = await repository.createProject(project);

      // Act
      await useCase.execute(projectId: projectId);

      // Assert
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);
    });

    test('deleteMultiple с одним элементом', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Единственный проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      // Act
      await useCase.deleteMultiple(projectIds: [projectId]);

      // Assert
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);
    });

    test('deleteMultiple с дубликатами в списке', () async {
      // Arrange
      final project = ProjectV2()
        ..name = 'Проект'
        ..status = ProjectStatus.planning;

      final projectId = await repository.createProject(project);

      // Act - пытаемся удалить один проект дважды
      try {
        await useCase.deleteMultiple(projectIds: [projectId, projectId]);
      } catch (e) {
        // Второе удаление должно вызвать ошибку
        expect(e, isA<StorageException>());
      }

      // Assert - проект должен быть удалён после первой попытки
      final result = await repository.getProjectById(projectId);
      expect(result, isNull);
    });

    test('deleteMultiple с очень большим списком', () async {
      // Arrange - создаём 100 проектов
      final ids = <int>[];
      for (var i = 0; i < 100; i++) {
        final project = ProjectV2()
          ..name = 'Проект $i'
          ..status = ProjectStatus.planning;

        ids.add(await repository.createProject(project));
      }

      // Act
      await useCase.deleteMultiple(projectIds: ids);

      // Assert
      for (final id in ids) {
        final result = await repository.getProjectById(id);
        expect(result, isNull);
      }
    });
  });
}
