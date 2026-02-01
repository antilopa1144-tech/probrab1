// Веб-реализация провайдера базы данных (заглушка)
// На вебе Isar не используется, данные хранятся в SharedPreferences

import '../../data/repositories/interfaces/project_repository_interface.dart';
import '../../data/repositories/interfaces/checklist_repository_interface.dart';

/// На вебе Isar не используется.
Future<dynamic> openIsarDatabase() async {
  return null;
}

/// На вебе эта функция не вызывается (используется WebProjectRepository).
IProjectRepository createProjectRepository(dynamic isar) {
  throw UnsupportedError('Isar не поддерживается на веб-платформе');
}

/// На вебе эта функция не вызывается (используется WebChecklistRepository).
IChecklistRepository createChecklistRepository(dynamic isar) {
  throw UnsupportedError('Isar не поддерживается на веб-платформе');
}
