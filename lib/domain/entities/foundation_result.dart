/// Результат расчёта ленточного фундамента.
class FoundationResult {
  final double concreteVolume; // м^3
  final double rebarWeight; // кг
  final double cost; // руб

  FoundationResult({
    required this.concreteVolume,
    required this.rebarWeight,
    required this.cost,
  });
}