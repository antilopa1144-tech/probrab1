import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/material_comparison.dart';

/// Репозиторий материалов (пока мок-реализация без бэкенда).
class MaterialRepository {
  MaterialRepository();

  static final List<MaterialOption> _defaultOptions = [
    const MaterialOption(
      id: 'default_economy',
      name: 'Эконом',
      category: 'Базовый',
      pricePerUnit: 450,
      unit: 'm2',
      properties: {'плотность': '850 кг/м3'},
      durabilityYears: 5,
    ),
    const MaterialOption(
      id: 'default_standard',
      name: 'Стандарт',
      category: 'Средний',
      pricePerUnit: 750,
      unit: 'm2',
      properties: {'плотность': '920 кг/м3'},
      durabilityYears: 10,
    ),
    const MaterialOption(
      id: 'default_premium',
      name: 'Премиум',
      category: 'Высокий',
      pricePerUnit: 1200,
      unit: 'm2',
      properties: {'плотность': '980 кг/м3'},
      durabilityYears: 18,
    ),
  ];

  final Map<String, List<MaterialOption>> _materialsByCalculator = {
    'plaster': const [
      MaterialOption(
        id: 'plaster_basic',
        name: 'Штукатурка базовая',
        category: 'Бюджет',
        pricePerUnit: 520,
        unit: 'kg',
        properties: {'тип': 'гипсовая', 'рекомендованная толщина': '10 мм'},
        durabilityYears: 7,
      ),
      MaterialOption(
        id: 'plaster_pro',
        name: 'Штукатурка про',
        category: 'Стандарт',
        pricePerUnit: 780,
        unit: 'kg',
        properties: {'тип': 'цементная', 'рекомендованная толщина': '8 мм'},
        durabilityYears: 12,
      ),
    ],
    'tile': const [
      MaterialOption(
        id: 'tile_wall',
        name: 'Плитка настенная',
        category: 'Стандарт',
        pricePerUnit: 1100,
        unit: 'm2',
        properties: {'износостойкость': 'PEI III'},
        durabilityYears: 15,
      ),
      MaterialOption(
        id: 'tile_floor',
        name: 'Плитка напольная',
        category: 'Премиум',
        pricePerUnit: 1450,
        unit: 'm2',
        properties: {'износостойкость': 'PEI IV'},
        durabilityYears: 20,
      ),
    ],
  };

  /// Получить все доступные материалы.
  Future<List<MaterialOption>> getAllMaterials() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return [
      ..._materialsByCalculator.values.expand((options) => options),
      ..._defaultOptions,
    ];
  }

  /// Получить материалы для конкретного калькулятора.
  Future<List<MaterialOption>> getMaterialsForCalculator(
    String calculatorId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _materialsByCalculator[calculatorId] ?? _defaultOptions;
  }
}

/// Провайдер репозитория материалов.
final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository();
});

/// Провайдер материалов для конкретного калькулятора.
final materialsForCalculatorProvider =
    FutureProvider.family<List<MaterialOption>, String>((ref, calculatorId) {
  final repository = ref.watch(materialRepositoryProvider);
  return repository.getMaterialsForCalculator(calculatorId);
});
