import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/labor/labor_cost_screen.dart';
import 'package:probrab_ai/presentation/providers/region_provider.dart';
import 'package:probrab_ai/presentation/providers/settings_provider.dart';

class _TestRegionNotifier extends RegionNotifier {
  _TestRegionNotifier(String region) : super() {
    state = region;
  }
}

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier(AppSettings initial) : super() {
    state = initial;
  }
}

void main() {
  testWidgets('LaborCostScreen syncs with region provider', (tester) async {
    final container = ProviderContainer(
      overrides: [
        regionProvider.overrideWith((ref) => _TestRegionNotifier('Краснодар')),
        settingsProvider.overrideWith(
          (ref) => _TestSettingsNotifier(const AppSettings(region: 'Краснодар')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LaborCostScreen(
            calculatorId: 'wall_paint',
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
