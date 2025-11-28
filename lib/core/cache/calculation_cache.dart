import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Кэш результатов расчётов для оптимизации производительности.
/// 
/// Хранит последние расчёты в памяти для быстрого доступа
/// при повторном вводе тех же параметров.
class CalculationCache {
  static final CalculationCache _instance = CalculationCache._internal();
  factory CalculationCache() => _instance;
  CalculationCache._internal();

  /// Максимальный размер кэша (количество записей)
  static const int _maxCacheSize = 50;

  /// Время жизни записи в кэше (5 минут)
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Кэш: ключ -> (значение, время создания)
  final Map<String, _CacheEntry> _cache = {};

  /// Генерация уникального ключа для расчёта
  String _generateKey(String calculatorId, Map<String, double> inputs) {
    final sortedInputs = Map.fromEntries(
      inputs.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final inputsJson = jsonEncode(sortedInputs);
    return '$calculatorId:$inputsJson';
  }

  /// Получить результат из кэша
  Map<String, double>? get(String calculatorId, Map<String, double> inputs) {
    final key = _generateKey(calculatorId, inputs);
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    // Проверка TTL
    if (DateTime.now().difference(entry.createdAt) > _cacheTTL) {
      _cache.remove(key);
      debugPrint('[CalculationCache] Cache expired for $calculatorId');
      return null;
    }

    debugPrint('[CalculationCache] Cache hit for $calculatorId');
    return Map.from(entry.values);
  }

  /// Сохранить результат в кэш
  void set(
    String calculatorId,
    Map<String, double> inputs,
    Map<String, double> result,
  ) {
    final key = _generateKey(calculatorId, inputs);

    // Очистка кэша если превышен лимит
    if (_cache.length >= _maxCacheSize) {
      _evictOldest();
    }

    _cache[key] = _CacheEntry(
      values: Map.from(result),
      createdAt: DateTime.now(),
    );

    debugPrint('[CalculationCache] Cached result for $calculatorId');
  }

  /// Удалить самую старую запись
  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.createdAt;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      debugPrint('[CalculationCache] Evicted oldest entry');
    }
  }

  /// Очистить весь кэш
  void clear() {
    _cache.clear();
    debugPrint('[CalculationCache] Cache cleared');
  }

  /// Очистить кэш для конкретного калькулятора
  void clearForCalculator(String calculatorId) {
    _cache.removeWhere((key, _) => key.startsWith('$calculatorId:'));
    debugPrint('[CalculationCache] Cache cleared for $calculatorId');
  }

  /// Получить статистику кэша
  CacheStats getStats() {
    int validEntries = 0;
    int expiredEntries = 0;
    final now = DateTime.now();

    for (final entry in _cache.values) {
      if (now.difference(entry.createdAt) > _cacheTTL) {
        expiredEntries++;
      } else {
        validEntries++;
      }
    }

    return CacheStats(
      totalEntries: _cache.length,
      validEntries: validEntries,
      expiredEntries: expiredEntries,
      maxSize: _maxCacheSize,
    );
  }

  /// Очистить просроченные записи
  void cleanupExpired() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      if (now.difference(entry.value.createdAt) > _cacheTTL) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint('[CalculationCache] Cleaned up ${keysToRemove.length} expired entries');
    }
  }
}

/// Запись в кэше
class _CacheEntry {
  final Map<String, double> values;
  final DateTime createdAt;

  _CacheEntry({
    required this.values,
    required this.createdAt,
  });
}

/// Статистика кэша
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int maxSize;

  const CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.maxSize,
  });

  double get utilizationPercent => (totalEntries / maxSize) * 100;

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, valid: $validEntries, '
           'expired: $expiredEntries, maxSize: $maxSize, '
           'utilization: ${utilizationPercent.toStringAsFixed(1)}%)';
  }
}
