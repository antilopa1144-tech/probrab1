import 'project_v2.dart';

/// Payload returned from calculator screens to projects
/// Used to save calculation results back to the project
class CalculatorResultPayload {
  /// Calculator ID (e.g., 'gypsum', 'osb', 'brick')
  final String calculatorId;

  /// Human-readable calculator name (localized)
  final String calculatorName;

  /// Input parameters (e.g., {'area': 20.0, 'layers': 2.0})
  final Map<String, double> inputs;

  /// Calculation results (e.g., {'gkl_sheets': 10.0, 'screws': 500.0})
  final Map<String, double> results;

  /// Estimated material cost (optional)
  final double? materialCost;

  /// Estimated labor cost (optional)
  final double? laborCost;

  /// Detailed materials list (optional, NEW)
  final List<ProjectMaterial>? materials;

  /// Optional notes about the calculation
  final String? notes;

  const CalculatorResultPayload({
    required this.calculatorId,
    required this.calculatorName,
    required this.inputs,
    required this.results,
    this.materialCost,
    this.laborCost,
    this.materials, // NEW
    this.notes,
  });

  /// Convert this payload to a ProjectCalculation for database storage
  ProjectCalculation toProjectCalculation() {
    final calc = ProjectCalculation()
      ..calculatorId = calculatorId
      ..name = calculatorName
      ..materialCost = materialCost
      ..laborCost = laborCost
      ..materials = materials ?? []
      ..notes = notes;

    // Set inputs and results using the helper methods
    calc.setInputsFromMap(inputs);
    calc.setResultsFromMap(results);

    return calc;
  }
}
