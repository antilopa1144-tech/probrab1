import 'package:flutter/material.dart';

enum CalculationMode { dimensions, walls }

class ProjectState extends ChangeNotifier {
  double roomL = 5.0;
  double roomW = 4.0;
  double roomH = 2.5;
  double netArea = 45.0; // (5+4)*2 * 2.5 = 45
  
  CalculationMode _mode = CalculationMode.dimensions;
  CalculationMode get mode => _mode;
  set mode(CalculationMode value) {
    _mode = value;
    notifyListeners();
  }

  void updateDimensions({double? l, double? w, double? h}) {
    roomL = l ?? roomL;
    roomW = w ?? roomW;
    roomH = h ?? roomH;
    notifyListeners();
  }

  void updateArea(double area) {
    netArea = area;
    notifyListeners();
  }

  double getPerimeter() => (roomL + roomW) * 2;
  double getNetArea() {
    // This is a simplification. A real implementation would subtract windows/doors.
    return (roomL + roomW) * 2 * roomH;
  }
}
