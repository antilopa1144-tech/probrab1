import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/core/services/calculator_memory_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalculatorMemoryService', () {
    group('without SharedPreferences (in-memory)', () {
      late CalculatorMemoryService service;

      setUp(() {
        service = CalculatorMemoryService();
      });

      test('saves and loads inputs from memory', () async {
        const calculatorId = 'foundation';
        final inputs = {'length': 10.0, 'width': 5.0, 'height': 0.3};

        await service.saveLastInputs(calculatorId, inputs);
        final loaded = service.loadLastInputs(calculatorId);

        expect(loaded, isNotNull);
        expect(loaded!['length'], 10.0);
        expect(loaded['width'], 5.0);
        expect(loaded['height'], 0.3);
      });

      test('returns null for non-existent calculator', () {
        final loaded = service.loadLastInputs('non_existent');
        expect(loaded, isNull);
      });

      test('clears memory for specific calculator', () async {
        const calculatorId = 'foundation';
        final inputs = {'length': 10.0, 'width': 5.0};

        await service.saveLastInputs(calculatorId, inputs);
        expect(service.loadLastInputs(calculatorId), isNotNull);

        await service.clearMemory(calculatorId);
        expect(service.loadLastInputs(calculatorId), isNull);
      });

      test('clears all memory', () async {
        await service.saveLastInputs('foundation', {'length': 10.0});
        await service.saveLastInputs('concrete', {'volume': 5.0});
        await service.saveLastInputs('brick', {'count': 100.0});

        expect(service.loadLastInputs('foundation'), isNotNull);
        expect(service.loadLastInputs('concrete'), isNotNull);
        expect(service.loadLastInputs('brick'), isNotNull);

        await service.clearAllMemory();

        expect(service.loadLastInputs('foundation'), isNull);
        expect(service.loadLastInputs('concrete'), isNull);
        expect(service.loadLastInputs('brick'), isNull);
      });

      test('overwrites existing inputs', () async {
        const calculatorId = 'foundation';

        await service.saveLastInputs(calculatorId, {'length': 10.0});
        expect(service.loadLastInputs(calculatorId)!['length'], 10.0);

        await service.saveLastInputs(calculatorId, {'length': 20.0});
        expect(service.loadLastInputs(calculatorId)!['length'], 20.0);
      });

      test('handles empty inputs map', () async {
        const calculatorId = 'foundation';
        final inputs = <String, double>{};

        await service.saveLastInputs(calculatorId, inputs);
        final loaded = service.loadLastInputs(calculatorId);

        expect(loaded, isNotNull);
        expect(loaded, isEmpty);
      });

      test('handles inputs with special characters in keys', () async {
        const calculatorId = 'foundation';
        final inputs = {'length_m': 10.0, 'width-cm': 500.0, 'height.mm': 300.0};

        await service.saveLastInputs(calculatorId, inputs);
        final loaded = service.loadLastInputs(calculatorId);

        expect(loaded, isNotNull);
        expect(loaded!['length_m'], 10.0);
        expect(loaded['width-cm'], 500.0);
        expect(loaded['height.mm'], 300.0);
      });

      test('handles negative values', () async {
        const calculatorId = 'test';
        final inputs = {'offset': -5.0, 'delta': -0.5};

        await service.saveLastInputs(calculatorId, inputs);
        final loaded = service.loadLastInputs(calculatorId);

        expect(loaded, isNotNull);
        expect(loaded!['offset'], -5.0);
        expect(loaded['delta'], -0.5);
      });

      test('handles very large values', () async {
        const calculatorId = 'test';
        final inputs = {'large': 999999999.99, 'small': 0.000001};

        await service.saveLastInputs(calculatorId, inputs);
        final loaded = service.loadLastInputs(calculatorId);

        expect(loaded, isNotNull);
        expect(loaded!['large'], 999999999.99);
        expect(loaded['small'], 0.000001);
      });
    });

    group('with SharedPreferences', () {
      late CalculatorMemoryService service;
      late SharedPreferences prefs;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
        service = CalculatorMemoryService(prefs);
      });

      test('saves and loads inputs from SharedPreferences', () async {
        const calculatorId = 'foundation';
        final inputs = {'length': 10.0, 'width': 5.0, 'height': 0.3};

        await service.saveLastInputs(calculatorId, inputs);
        final loaded = service.loadLastInputs(calculatorId);

        expect(loaded, isNotNull);
        expect(loaded!['length'], 10.0);
        expect(loaded['width'], 5.0);
        expect(loaded['height'], 0.3);
      });

      test('persists data in SharedPreferences', () async {
        const calculatorId = 'foundation';
        final inputs = {'length': 10.0};

        await service.saveLastInputs(calculatorId, inputs);

        // Verify data is in SharedPreferences
        final storedValue = prefs.getString('calc_last_$calculatorId');
        expect(storedValue, isNotNull);
        expect(storedValue, contains('length'));
        expect(storedValue, contains('10'));
      });

      test('clears memory from SharedPreferences', () async {
        const calculatorId = 'foundation';
        final inputs = {'length': 10.0};

        await service.saveLastInputs(calculatorId, inputs);
        expect(prefs.getString('calc_last_$calculatorId'), isNotNull);

        await service.clearMemory(calculatorId);
        expect(prefs.getString('calc_last_$calculatorId'), isNull);
      });

      test('clears all calculator memory from SharedPreferences', () async {
        await service.saveLastInputs('foundation', {'length': 10.0});
        await service.saveLastInputs('concrete', {'volume': 5.0});

        expect(prefs.getString('calc_last_foundation'), isNotNull);
        expect(prefs.getString('calc_last_concrete'), isNotNull);

        await service.clearAllMemory();

        expect(prefs.getString('calc_last_foundation'), isNull);
        expect(prefs.getString('calc_last_concrete'), isNull);
      });

      test('returns null for corrupted JSON', () async {
        const calculatorId = 'corrupted';
        await prefs.setString('calc_last_$calculatorId', 'not valid json');

        final loaded = service.loadLastInputs(calculatorId);
        expect(loaded, isNull);
      });

      test('handles integer values converted to double', () async {
        const calculatorId = 'test';
        // Manually set JSON with integer
        await prefs.setString('calc_last_$calculatorId', '{"count": 5}');

        final loaded = service.loadLastInputs(calculatorId);

        expect(loaded, isNotNull);
        expect(loaded!['count'], 5.0);
        expect(loaded['count'], isA<double>());
      });
    });
  });
}
