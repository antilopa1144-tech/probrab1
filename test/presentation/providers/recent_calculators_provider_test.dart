import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/recent_calculators_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Реальные ID калькуляторов из CalculatorRegistry
const _id1 = 'paint_universal';
const _id2 = 'floors_tile';
const _id3 = 'floors_laminate';
const _id4 = 'floors_linoleum';
const _id5 = 'floors_parquet';
const _id6 = 'floors_warm';
const _id7 = 'exterior_brick';
const _id8 = 'foundation_basement';
const _id9 = 'foundation_slab';
const _id10 = 'fence';
const _id11 = 'stairs';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecentCalculatorsNotifier', () {
    test('начальное состояние - пустой список', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(recentCalculatorsProvider);

      expect(state, isEmpty);
    });

    test(
      'загружает сохранённые калькуляторы при инициализации',
      () async {
        SharedPreferences.setMockInitialValues({
          'recent_calculators': [_id1, _id2, _id3],
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        final state = container.read(recentCalculatorsProvider);

        expect(state.length, 3);
        expect(state, contains(_id1));
        expect(state, contains(_id2));
        expect(state, contains(_id3));
      },
    );

    test(
      'addRecent добавляет калькулятор в начало списка',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        await notifier.addRecent(_id1);

        final state = container.read(recentCalculatorsProvider);

        expect(state.length, 1);
        expect(state.first, _id1);
      },
    );

    test(
      'addRecent перемещает существующий калькулятор в начало',
      () async {
        SharedPreferences.setMockInitialValues({
          'recent_calculators': [_id2, _id1, _id3],
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        await notifier.addRecent(_id1);

        final state = container.read(recentCalculatorsProvider);

        expect(state.first, _id1);
        expect(state[1], _id2);
        expect(state[2], _id3);
        expect(state.length, 3);
      },
    );

    test(
      'addRecent ограничивает список до 10 элементов',
      () async {
        final initialList = [
          _id1, _id2, _id3, _id4, _id5,
          _id6, _id7, _id8, _id9, _id10,
        ];
        SharedPreferences.setMockInitialValues({
          'recent_calculators': initialList,
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        await notifier.addRecent(_id11);

        final state = container.read(recentCalculatorsProvider);

        expect(state.length, 10);
        expect(state.first, _id11);
        expect(state, isNot(contains(_id10))); // Последний элемент удалён
      },
    );

    test(
      'addRecent канонизирует legacy ID',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        // Добавляем legacy ID
        await notifier.addRecent('walls_paint');

        final state = container.read(recentCalculatorsProvider);

        // Должен быть преобразован в canonical
        expect(state, contains('paint_universal'));
        expect(state, isNot(contains('walls_paint')));
      },
    );

    test(
      'addRecent игнорирует несуществующие калькуляторы',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        await notifier.addRecent('nonexistent_calculator_12345');

        final state = container.read(recentCalculatorsProvider);

        expect(state, isEmpty);
      },
    );

    test(
      'clearRecent очищает весь список',
      () async {
        SharedPreferences.setMockInitialValues({
          'recent_calculators': [_id1, _id2, _id3],
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        await notifier.clearRecent();

        final state = container.read(recentCalculatorsProvider);

        expect(state, isEmpty);
      },
    );

    test(
      'removeRecent удаляет конкретный калькулятор',
      () async {
        SharedPreferences.setMockInitialValues({
          'recent_calculators': [_id1, _id2, _id3],
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        await notifier.removeRecent(_id2);

        final state = container.read(recentCalculatorsProvider);

        expect(state.length, 2);
        expect(state, contains(_id1));
        expect(state, contains(_id3));
        expect(state, isNot(contains(_id2)));
      },
    );

    test(
      'removeRecent канонизирует legacy ID перед удалением',
      () async {
        SharedPreferences.setMockInitialValues({
          'recent_calculators': [_id1, 'paint_universal', _id2],
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        // Удаляем по legacy ID
        await notifier.removeRecent('walls_paint');

        final state = container.read(recentCalculatorsProvider);

        expect(state, isNot(contains('paint_universal')));
        expect(state.length, 1); // _id1 == paint_universal too, so only _id2 remains
      },
    );

    test(
      'сохраняет изменения в SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        await notifier.addRecent(_id1);
        await notifier.addRecent(_id2);

        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getStringList('recent_calculators');

        expect(saved, isNotNull);
        expect(saved!.length, 2);
        expect(saved.first, _id2); // Последний добавленный
        expect(saved[1], _id1);
      },
    );

    test(
      'фильтрует несуществующие калькуляторы при загрузке',
      () async {
        SharedPreferences.setMockInitialValues({
          'recent_calculators': [
            _id1,
            'nonexistent_calc',
            _id2,
            'another_fake',
          ],
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        final state = container.read(recentCalculatorsProvider);

        expect(state.length, 2);
        expect(state, contains(_id1));
        expect(state, contains(_id2));
        expect(state, isNot(contains('nonexistent_calc')));
        expect(state, isNot(contains('another_fake')));
      },
    );

    test(
      'мигрирует legacy ID при загрузке',
      () async {
        SharedPreferences.setMockInitialValues({
          'recent_calculators': [
            _id2,
            'walls_paint', // legacy → paint_universal
            'warm_floor', // legacy → floors_warm
          ],
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        final state = container.read(recentCalculatorsProvider);

        expect(state, contains(_id2));
        expect(state, contains('paint_universal')); // канонический
        expect(state, contains('floors_warm')); // канонический
        expect(state, isNot(contains('walls_paint')));
        expect(state, isNot(contains('warm_floor')));
      },
    );

    test(
      'удаляет дубликаты при миграции',
      () async {
        SharedPreferences.setMockInitialValues({
          'recent_calculators': [
            'walls_paint', // legacy -> paint_universal
            'paint_universal', // canonical
            'wall_paint', // другой legacy -> paint_universal
          ],
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        final state = container.read(recentCalculatorsProvider);

        expect(state.length, 1);
        expect(state, contains('paint_universal'));
      },
    );

    test(
      'сохраняет порядок элементов',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        await notifier.addRecent(_id1);
        await notifier.addRecent(_id2);
        await notifier.addRecent(_id3);

        final state = container.read(recentCalculatorsProvider);

        expect(state[0], _id3);
        expect(state[1], _id2);
        expect(state[2], _id1);
      },
    );

    test(
      'обрабатывает пустые сохранённые данные',
      () async {
        SharedPreferences.setMockInitialValues({
          'recent_calculators': <String>[],
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        final state = container.read(recentCalculatorsProvider);

        expect(state, isEmpty);
      },
    );

    test(
      'множественные операции работают последовательно',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recentCalculatorsProvider.notifier);
        await notifier.initialized;

        await notifier.addRecent(_id1);
        await notifier.addRecent(_id2);
        await notifier.removeRecent(_id1);
        await notifier.addRecent(_id3);

        final state = container.read(recentCalculatorsProvider);

        expect(state.length, 2);
        expect(state[0], _id3);
        expect(state[1], _id2);
        expect(state, isNot(contains(_id1)));
      },
    );
  });
}
