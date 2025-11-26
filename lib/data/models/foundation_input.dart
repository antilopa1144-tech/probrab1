/// Модель входных данных для расчёта фундамента.
class FoundationInput {
  double perimeter;
  double width;
  double height;
  double thickness;
  double diameter;
  int rebarCount;

  FoundationInput({
    required this.perimeter,
    required this.width,
    required this.height,
    this.thickness = 0.0,
    this.diameter = 12.0,
    this.rebarCount = 4,
  });
}