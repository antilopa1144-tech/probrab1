import 'package:isar/isar.dart';
import 'dart:convert';
import '../../domain/entities/project.dart';

part 'project.g.dart';

/// Хранит сохранённый проект расчёта в Isar.
/// Используется для оффлайн хранения.
@collection
class ProjectModel {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String projectId; // String ID для связи с доменной моделью
  
  late String name;
  late String description;
  late String objectType; // дом, квартира, гараж
  late DateTime createdAt;
  
  DateTime? startDate;
  DateTime? completionDate;
  late double totalBudget;
  late double spentAmount;
  
  // JSON поля для сложных данных
  late String calculationIdsJson; // List<String> как JSON
  late String metadataJson; // Map<String, dynamic> как JSON

  ProjectModel();

  // Мапперы для преобразования в/из доменной модели
  factory ProjectModel.fromDomain(Project domain) {
    return ProjectModel()
      ..projectId = domain.id
      ..name = domain.name
      ..description = domain.description
      ..objectType = domain.objectType
      ..createdAt = domain.createdAt
      ..startDate = domain.startDate
      ..completionDate = domain.completionDate
      ..totalBudget = domain.totalBudget
      ..spentAmount = domain.spentAmount
      ..calculationIdsJson = jsonEncode(domain.calculationIds)
      ..metadataJson = jsonEncode(domain.metadata);
  }

  Project toDomain() {
    return Project(
      id: projectId,
      name: name,
      description: description,
      objectType: objectType,
      calculationIds: (jsonDecode(calculationIdsJson) as List<dynamic>)
          .map((e) => e.toString()).toList(),
      createdAt: createdAt,
      startDate: startDate,
      completionDate: completionDate,
      totalBudget: totalBudget,
      spentAmount: spentAmount,
      metadata: jsonDecode(metadataJson) as Map<String, dynamic>,
    );
  }
}