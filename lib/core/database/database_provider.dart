import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/calculation.dart';
import '../../domain/models/project_v2.dart';

/// Единая точка инициализации Isar со всеми схемами.
final isarProvider = FutureProvider<Isar>((ref) async {
  // При hot-restart повторно используем уже открытую базу
  if (Isar.instanceNames.isNotEmpty) {
    final existing = Isar.getInstance(Isar.instanceNames.first);
    if (existing != null) {
      return existing;
    }
  }

  final dir = await getApplicationDocumentsDirectory();

  return Isar.open(
    [ProjectV2Schema, ProjectCalculationSchema, CalculationSchema],
    directory: dir.path,
    name: 'probrab_ai',
  );
});
