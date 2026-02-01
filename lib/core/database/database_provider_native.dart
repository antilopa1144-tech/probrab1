// Нативная реализация провайдера базы данных (Android, iOS, Desktop)
// Использует Isar для хранения данных

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/calculation.dart';
import '../../domain/models/project_v2.dart';
import '../../domain/models/checklist.dart';
import '../../data/repositories/interfaces/project_repository_interface.dart';
import '../../data/repositories/interfaces/checklist_repository_interface.dart';
import '../../data/repositories/project_repository_v2.dart';
import '../../data/repositories/checklist_repository.dart';
import 'repository_factory_native.dart';

/// Открывает базу данных Isar для нативных платформ.
Future<Isar> openIsarDatabase() async {
  // При hot-restart повторно используем уже открытую базу
  if (Isar.instanceNames.isNotEmpty) {
    final existing = Isar.getInstance(Isar.instanceNames.first);
    if (existing != null) {
      return existing;
    }
  }

  final dir = await getApplicationDocumentsDirectory();

  return Isar.open(
    [
      ProjectV2Schema,
      ProjectCalculationSchema,
      CalculationSchema,
      RenovationChecklistSchema,
      ChecklistItemSchema,
    ],
    directory: dir.path,
    name: 'probrab_ai',
  );
}

/// Создаёт репозиторий проектов для нативной платформы.
IProjectRepository createProjectRepository(dynamic isar) {
  return NativeProjectRepositoryWrapper(ProjectRepositoryV2(isar as Isar));
}

/// Создаёт репозиторий чек-листов для нативной платформы.
IChecklistRepository createChecklistRepository(dynamic isar) {
  return NativeChecklistRepositoryWrapper(ChecklistRepository(isar as Isar));
}
