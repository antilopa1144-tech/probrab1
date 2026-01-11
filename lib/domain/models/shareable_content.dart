import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'project_v2.dart';

/// Базовый класс для контента, который можно расшарить через Deep Link / QR
abstract class ShareableContent {
  /// Тип контента
  String get type;

  /// Преобразовать в JSON
  Map<String, dynamic> toJson();

  /// Создать Deep Link URL
  String toDeepLink({String scheme = 'masterokapp'}) {
    final jsonData = toJson();
    final encodedData = base64Url.encode(utf8.encode(json.encode(jsonData)));
    return '$scheme://share/$type?data=$encodedData';
  }

  /// Создать короткий Deep Link с хэшем (для QR кодов)
  String toCompactDeepLink({String scheme = 'masterokapp'}) {
    final jsonData = toJson();
    final jsonString = json.encode(jsonData);
    final hash = sha256.convert(utf8.encode(jsonString)).toString().substring(0, 8);
    final encodedData = base64Url.encode(utf8.encode(jsonString));
    return '$scheme://s/$hash?d=$encodedData';
  }
}

/// Проект для расшаривания
class ShareableProject extends ShareableContent {
  final String name;
  final String? description;
  final ProjectStatus status;
  final List<ShareableCalculation> calculations;
  final List<String> tags;
  final String? notes;

  ShareableProject({
    required this.name,
    this.description,
    required this.status,
    required this.calculations,
    this.tags = const [],
    this.notes,
  });

  @override
  String get type => 'project';

  /// Создать из ProjectV2
  factory ShareableProject.fromProject(ProjectV2 project) {
    return ShareableProject(
      name: project.name,
      description: project.description,
      status: project.status,
      calculations: project.calculations.map((calc) {
        return ShareableCalculation(
          calculatorId: calc.calculatorId,
          name: calc.name,
          inputs: calc.inputsMap,
          results: calc.resultsMap,
          materialCost: calc.materialCost,
          laborCost: calc.laborCost,
          notes: calc.notes,
        );
      }).toList(),
      tags: project.tags,
      notes: project.notes,
    );
  }

  /// Преобразовать в ProjectV2
  ProjectV2 toProject() {
    final project = ProjectV2()
      ..name = name
      ..description = description
      ..status = status
      ..tags = tags
      ..notes = notes;

    for (final shareableCalc in calculations) {
      final calc = ProjectCalculation()
        ..calculatorId = shareableCalc.calculatorId
        ..name = shareableCalc.name
        ..materialCost = shareableCalc.materialCost
        ..laborCost = shareableCalc.laborCost
        ..notes = shareableCalc.notes;

      calc.setInputsFromMap(shareableCalc.inputs);
      calc.setResultsFromMap(shareableCalc.results);

      project.calculations.add(calc);
    }

    return project;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'status': status.name,
      'calculations': calculations.map((c) => c.toJson()).toList(),
      'tags': tags,
      'notes': notes,
    };
  }

  factory ShareableProject.fromJson(Map<String, dynamic> json) {
    return ShareableProject(
      name: json['name'] as String,
      description: json['description'] as String?,
      status: ProjectStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ProjectStatus.planning,
      ),
      calculations: (json['calculations'] as List?)
              ?.map((c) => ShareableCalculation.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
    );
  }
}

/// Расчёт для расшаривания (упрощённая версия ProjectCalculation)
class ShareableCalculation {
  final String calculatorId;
  final String name;
  final Map<String, double> inputs;
  final Map<String, double> results;
  final double? materialCost;
  final double? laborCost;
  final String? notes;

  ShareableCalculation({
    required this.calculatorId,
    required this.name,
    required this.inputs,
    required this.results,
    this.materialCost,
    this.laborCost,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'calculatorId': calculatorId,
      'name': name,
      'inputs': inputs,
      'results': results,
      'materialCost': materialCost,
      'laborCost': laborCost,
      'notes': notes,
    };
  }

  factory ShareableCalculation.fromJson(Map<String, dynamic> json) {
    return ShareableCalculation(
      calculatorId: json['calculatorId'] as String,
      name: json['name'] as String,
      inputs: (json['inputs'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      results: (json['results'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      materialCost: (json['materialCost'] as num?)?.toDouble(),
      laborCost: (json['laborCost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// Калькулятор с предзаполненными данными
class ShareableCalculator extends ShareableContent {
  final String calculatorId;
  final String? calculatorName;
  final Map<String, double> inputs;
  final String? notes;

  ShareableCalculator({
    required this.calculatorId,
    this.calculatorName,
    required this.inputs,
    this.notes,
  });

  @override
  String get type => 'calculator';

  @override
  Map<String, dynamic> toJson() {
    return {
      'calculatorId': calculatorId,
      'calculatorName': calculatorName,
      'inputs': inputs,
      'notes': notes,
    };
  }

  factory ShareableCalculator.fromJson(Map<String, dynamic> json) {
    return ShareableCalculator(
      calculatorId: json['calculatorId'] as String,
      calculatorName: json['calculatorName'] as String?,
      inputs: (json['inputs'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      notes: json['notes'] as String?,
    );
  }
}

/// Результат парсинга Deep Link
class DeepLinkData {
  final String type;
  final Map<String, dynamic> data;

  DeepLinkData({
    required this.type,
    required this.data,
  });

  /// Получить как ShareableProject
  ShareableProject? asProject() {
    if (type != 'project') return null;
    try {
      return ShareableProject.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Получить как ShareableCalculator
  ShareableCalculator? asCalculator() {
    if (type != 'calculator') return null;
    try {
      return ShareableCalculator.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
