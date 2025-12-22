import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorMemoryService {
  static const _prefix = 'calc_last_';

  final SharedPreferences? _prefs;
  final Map<String, String> _memory = {};

  CalculatorMemoryService([this._prefs]);

  Future<void> saveLastInputs(
    String calculatorId,
    Map<String, double> inputs,
  ) async {
    final key = '$_prefix$calculatorId';
    final payload = jsonEncode(inputs);
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(key, payload);
    } else {
      _memory[key] = payload;
    }
  }

  Map<String, double>? loadLastInputs(String calculatorId) {
    final key = '$_prefix$calculatorId';
    final json = _prefs?.getString(key) ?? _memory[key];
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearMemory(String calculatorId) async {
    final key = '$_prefix$calculatorId';
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.remove(key);
    } else {
      _memory.remove(key);
    }
  }

  Future<void> clearAllMemory() async {
    final prefs = _prefs;
    if (prefs != null) {
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } else {
      _memory.removeWhere((key, _) => key.startsWith(_prefix));
    }
  }
}

final calculatorMemoryProvider = Provider<CalculatorMemoryService>((ref) {
  return CalculatorMemoryService();
});
