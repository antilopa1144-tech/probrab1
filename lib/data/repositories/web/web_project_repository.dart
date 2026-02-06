import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/models/project_v2.dart';
import '../interfaces/project_repository_interface.dart';
import '../project_repository_v2.dart';

/// Веб-реализация репозитория проектов.
/// Использует SharedPreferences (localStorage в браузере) для хранения данных.
class WebProjectRepository implements IProjectRepository {
  final SharedPreferences _prefs;

  static const String _projectsKey = 'web_projects';
  static const String _calculationsKey = 'web_calculations';
  static const String _idCounterKey = 'web_id_counter';

  // Кэш для быстрого доступа
  List<ProjectV2>? _projectsCache;
  List<ProjectCalculation>? _calculationsCache;

  WebProjectRepository(this._prefs);

  int _getNextId() {
    final current = _prefs.getInt(_idCounterKey) ?? 0;
    _prefs.setInt(_idCounterKey, current + 1);
    return current + 1;
  }

  // ============================================================================
  // Сериализация/Десериализация
  // ============================================================================

  Map<String, dynamic> _projectToJson(ProjectV2 project) {
    return {
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'address': project.address,
      'status': project.status.index,
      'isFavorite': project.isFavorite,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'calculationIds': project.calculations.map((c) => c.id).toList(),
    };
  }

  ProjectV2 _projectFromJson(Map<String, dynamic> json) {
    final project = ProjectV2()
      ..id = json['id'] as int
      ..name = json['name'] as String
      ..description = json['description'] as String?
      ..address = json['address'] as String?
      ..status = ProjectStatus.values[json['status'] as int]
      ..isFavorite = json['isFavorite'] as bool? ?? false
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String);
    return project;
  }

  Map<String, dynamic> _calculationToJson(ProjectCalculation calc) {
    return {
      'id': calc.id,
      'projectId': calc.project.value?.id,
      'calculatorId': calc.calculatorId,
      'inputs': calc.inputsMap,
      'results': calc.resultsMap,
      'notes': calc.notes,
      'createdAt': calc.createdAt.toIso8601String(),
      'updatedAt': calc.updatedAt.toIso8601String(),
      'materials': calc.materials.map((m) => {
        'name': m.name,
        'quantity': m.quantity,
        'unit': m.unit,
        'purchased': m.purchased,
        'purchasedAt': m.purchasedAt?.toIso8601String(),
      }).toList(),
    };
  }

  ProjectCalculation _calculationFromJson(Map<String, dynamic> json) {
    final calc = ProjectCalculation()
      ..id = json['id'] as int
      ..calculatorId = json['calculatorId'] as String
      ..notes = json['notes'] as String?
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String);

    if (json['inputs'] is Map) {
      calc.setInputsFromMap(Map<String, double>.from(json['inputs'] as Map));
    }
    if (json['results'] is Map) {
      calc.setResultsFromMap(Map<String, double>.from(json['results'] as Map));
    }

    // Парсим материалы
    final materialsJson = json['materials'] as List<Map<String, dynamic>>?;
    if (materialsJson != null) {
      for (final mJson in materialsJson) {
        final material = ProjectMaterial()
          ..name = mJson['name'] as String
          ..quantity = (mJson['quantity'] as num).toDouble()
          ..unit = mJson['unit'] as String
          ..purchased = mJson['purchased'] as bool? ?? false;
        if (mJson['purchasedAt'] != null) {
          material.purchasedAt = DateTime.parse(mJson['purchasedAt'] as String);
        }
        calc.materials.add(material);
      }
    }

    return calc;
  }

  // ============================================================================
  // Загрузка/Сохранение
  // ============================================================================

  Future<List<ProjectV2>> _loadProjects() async {
    if (_projectsCache != null) return _projectsCache!;

    final jsonStr = _prefs.getString(_projectsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      _projectsCache = [];
      return _projectsCache!;
    }

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    _projectsCache = jsonList.map((j) => _projectFromJson(j as Map<String, dynamic>)).toList();

    // Загружаем расчёты и связываем с проектами
    final calculations = await _loadCalculations();
    for (final project in _projectsCache!) {
      final projectCalcs = calculations.where((c) =>
        c.project.value?.id == project.id
      ).toList();
      project.calculations.addAll(projectCalcs);
    }

    return _projectsCache!;
  }

  Future<void> _saveProjects() async {
    final jsonList = _projectsCache!.map(_projectToJson).toList();
    await _prefs.setString(_projectsKey, jsonEncode(jsonList));
  }

  Future<List<ProjectCalculation>> _loadCalculations() async {
    if (_calculationsCache != null) return _calculationsCache!;

    final jsonStr = _prefs.getString(_calculationsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      _calculationsCache = [];
      return _calculationsCache!;
    }

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    _calculationsCache = jsonList.map((j) => _calculationFromJson(j as Map<String, dynamic>)).toList();
    return _calculationsCache!;
  }

  Future<void> _saveCalculations() async {
    final jsonList = _calculationsCache!.map(_calculationToJson).toList();
    await _prefs.setString(_calculationsKey, jsonEncode(jsonList));
  }

  void _invalidateCache() {
    _projectsCache = null;
    _calculationsCache = null;
  }

  // ============================================================================
  // Реализация интерфейса
  // ============================================================================

  @override
  Future<List<ProjectV2>> getAllProjects() async {
    final projects = await _loadProjects();
    return projects.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<ProjectV2?> getProjectById(int id) async {
    final projects = await _loadProjects();
    try {
      return projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> createProject(ProjectV2 project) async {
    await _loadProjects();
    project.id = _getNextId();
    project.createdAt = DateTime.now();
    project.updatedAt = DateTime.now();
    _projectsCache!.add(project);
    await _saveProjects();
    return project.id;
  }

  @override
  Future<void> updateProject(ProjectV2 project) async {
    await _loadProjects();
    final index = _projectsCache!.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      project.updatedAt = DateTime.now();
      _projectsCache![index] = project;
      await _saveProjects();
    }
  }

  @override
  Future<void> deleteProject(int id) async {
    await _loadProjects();
    await _loadCalculations();

    // Удаляем связанные расчёты
    _calculationsCache!.removeWhere((c) => c.project.value?.id == id);
    await _saveCalculations();

    // Удаляем проект
    _projectsCache!.removeWhere((p) => p.id == id);
    await _saveProjects();
  }

  @override
  Future<List<ProjectV2>> getFavoriteProjects() async {
    final projects = await _loadProjects();
    return projects.where((p) => p.isFavorite).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<ProjectV2>> getProjectsByStatus(ProjectStatus status) async {
    final projects = await _loadProjects();
    return projects.where((p) => p.status == status).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<ProjectV2>> searchProjects(String query) async {
    final projects = await _loadProjects();
    final lowerQuery = query.toLowerCase();
    return projects.where((p) =>
      p.name.toLowerCase().contains(lowerQuery) ||
      (p.description?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> toggleFavorite(int id) async {
    await _loadProjects();
    final project = _projectsCache!.firstWhere((p) => p.id == id);
    project.isFavorite = !project.isFavorite;
    project.updatedAt = DateTime.now();
    await _saveProjects();
  }

  @override
  Future<void> addCalculationToProject(
    int projectId,
    ProjectCalculation calculation,
  ) async {
    await _loadProjects();
    await _loadCalculations();

    final project = _projectsCache!.firstWhere((p) => p.id == projectId);

    calculation.id = _getNextId();
    calculation.createdAt = DateTime.now();
    calculation.updatedAt = DateTime.now();
    calculation.project.value = project;

    _calculationsCache!.add(calculation);
    project.calculations.add(calculation);
    project.updatedAt = DateTime.now();

    await _saveCalculations();
    await _saveProjects();
  }

  @override
  Future<void> removeCalculationFromProject(int calculationId) async {
    await _loadProjects();
    await _loadCalculations();

    final calc = _calculationsCache!.firstWhere((c) => c.id == calculationId);
    final project = calc.project.value;

    _calculationsCache!.removeWhere((c) => c.id == calculationId);

    if (project != null) {
      project.calculations.removeWhere((c) => c.id == calculationId);
      project.updatedAt = DateTime.now();
      await _saveProjects();
    }

    await _saveCalculations();
  }

  @override
  Future<void> toggleMaterialPurchased(int calculationId, int materialIndex) async {
    await _loadCalculations();

    final calc = _calculationsCache!.firstWhere((c) => c.id == calculationId);
    if (materialIndex >= 0 && materialIndex < calc.materials.length) {
      final material = calc.materials[materialIndex];
      material.purchased = !material.purchased;
      material.purchasedAt = material.purchased ? DateTime.now() : null;
      calc.updatedAt = DateTime.now();
      await _saveCalculations();
    }
  }

  @override
  Future<List<ProjectCalculation>> getProjectCalculations(int projectId) async {
    await _loadCalculations();
    return _calculationsCache!.where((c) => c.project.value?.id == projectId).toList();
  }

  @override
  Future<ProjectStatistics> getStatistics() async {
    final projects = await _loadProjects();
    return ProjectStatistics(
      total: projects.length,
      favorites: projects.where((p) => p.isFavorite).length,
      planning: projects.where((p) => p.status == ProjectStatus.planning).length,
      inProgress: projects.where((p) => p.status == ProjectStatus.inProgress).length,
      completed: projects.where((p) => p.status == ProjectStatus.completed).length,
    );
  }

  @override
  Future<void> clearAllProjects() async {
    _invalidateCache();
    await _prefs.remove(_projectsKey);
    await _prefs.remove(_calculationsKey);
  }
}
