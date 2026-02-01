// Веб-реализация фабрики репозиториев (заглушка)
// Используется только для веб-платформы
// Настоящие репозитории создаются через RepositoryFactory.createXxxRepository()

import '../../data/repositories/interfaces/project_repository_interface.dart';
import '../../data/repositories/interfaces/checklist_repository_interface.dart';

/// Заглушка - на вебе Isar не используется, поэтому эти функции не будут вызваны.
/// Реальные веб-репозитории создаются в RepositoryFactory напрямую.
IProjectRepository createNativeProjectRepository(dynamic isar) {
  throw UnsupportedError('Isar не поддерживается на веб-платформе');
}

IChecklistRepository createNativeChecklistRepository(dynamic isar) {
  throw UnsupportedError('Isar не поддерживается на веб-платформе');
}
