import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/labor/labor_cost_screen.dart';
import 'package:probrab_ai/presentation/providers/region_provider.dart';
import 'package:probrab_ai/presentation/providers/settings_provider.dart';

class _TestRegionNotifier extends StateNotifier<String> {
  _TestRegionNotifier(String region) : super(region);

  Future<void> setRegion(String region) async {
    state = region;
  }
}

class _TestSettingsNotifier extends StateNotifier<AppSettings> {
  _TestSettingsNotifier(AppSettings initial) : super(initial);

  Future<void> updateRegion(String region) async {
    state = state.copyWith(region: region);
  }

  // Other update methods are unused in this test but kept for compatibility.
  Future<void> updateDarkMode(bool _) async {}
  Future<void> updateLanguage(String _) async {}
  Future<void> updateAutoSave(bool _) async {}
  Future<void> updateNotifications(bool _) async {}
  Future<void> updateUnitSystem(String _) async {}
  Future<void> updateShowTips(bool _) async {}
}

void main() {
  testWidgets('LaborCostScreen syncs with region provider', (tester) async {
    final container = ProviderContainer(
      overrides: [
        regionProvider.overrideWith(() => _TestRegionNotifier('Краснодар')),
        settingsProvider.overrideWith(
          () => _TestSettingsNotifier(const AppSettings(region: 'Краснодар')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LaborCostScreen(
            calculatorId: 'walls_paint',
            quantity: 10,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dropdownFinder = find.byType(DropdownButton<String>);
    final dropdown =
        tester.widget<DropdownButton<String>>(dropdownFinder.first);
    expect(dropdown.value, 'Краснодар');

    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Москва').last);
    await tester.pumpAndSettle();

    expect(container.read(regionProvider), 'Москва');
    expect(container.read(settingsProvider).region, 'Москва');
  });
}
