# Copilot Instructions for BuildCalc (Прораб AI)

## Project Overview

**BuildCalc** is a Flutter mobile app for construction material calculators targeting both novices and professionals. It features 47+ calculators across 4 categories (Foundation, Walls, Roofing, Finishing), with regional Russian pricing, dual language support (Russian/English), Material You 3 theming, and offline project management via Isar database.

### Architecture: Clean Architecture + Riverpod

```
lib/
├── core/           # App-wide constants, theme, localization, animations, widgets
├── data/           # Models, repositories, datasources (Isar DB, price JSON)
├── domain/         # Entities, calculator usecases (business logic), definitions
└── presentation/   # Riverpod providers, screens (novice/pro modes), components
```

## Key Architectural Patterns

### 1. Calculator Definition System

Calculators are **declaratively defined**, not individually coded UI. Core pattern in `lib/domain/calculators/definitions.dart`:

```dart
// Each calculator defines: fields → usecase → results
class CalculatorDefinition {
  final String id;              // 'calculator.wallPaint'
  final String titleKey;        // Localization key
  final List<InputFieldDefinition> fields;  // Form fields with defaults
  final Map<String, String> resultLabels;   // Result field labels
  final CalculatorUseCase useCase;          // Math implementation
  final List<String> category;              // Path: ['Dom', 'Wall', 'Paint']
}
```

**Each calculator usecase** implements `CalculatorUseCase`:
- **Input**: `Map<String, double> inputs` + `List<PriceItem> priceList`
- **Output**: `CalculatorResult` with values dict + optional totalPrice
- **Files**: `lib/domain/usecases/calculate_*.dart` (47 files)

**Key pattern**: Calculators handle **deduction for openings** (okna/dveri) automatically:
```dart
final usefulArea = (area - windowsArea - doorsArea).clamp(0.0, double.infinity);
```

### 2. State Management: Riverpod FutureProvider Pattern

All state flows through `lib/presentation/providers/*.dart`:

```dart
// Repository → Provider → UI
final priceProvider = FutureProvider<List<PriceItem>>((ref) async {
  return await PriceRepository().getPricesByRegion(selectedRegion);
});

// Watch in ConsumerWidget
final prices = ref.watch(priceProvider);
```

**Key providers**:
- `settingsProvider` - Theme, language, region (SharedPreferences backed)
- `calculationProvider` - History from Isar DB
- `priceProvider` - Regional prices from JSON assets
- `projectProvider` - Smart Master projects
- `accentColorProvider` - Dynamic Material You accent color

### 3. Data Persistence: Isar + JSON

**Isar Database** (`lib/data/repositories/calculation_repository.dart`):
- Stores calculation history with title, inputs/outputs (JSON), cost, notes
- Auto-increment IDs, timestamps
- **Must run**: `flutter pub run build_runner build --delete-conflicting-outputs` after model changes

**Price Data** (`assets/json/prices_*.json`):
- Region-specific JSON files (Moscow, SPB, Ekaterinburg, Krasnodar, Regions)
- Loaded via `LocalPriceDataSource` into `List<PriceItem>`
- Price lookups use SKU matching: `_findPrice(priceList, ['sku1', 'sku2'])`

### 4. Localization: Intl + Asset JSON

**Flutter Localizations**:
- `lib/core/localization/app_localizations.dart` - Custom delegate
- Supports: Russian, English, Kyrgyz, Kazakh, Tajik, Turkmen, Uzbek
- Activate with: `flutter gen-l10n` (Flutter built-in)

**Custom JSON translations** (`assets/lang/*.json`):
- Fallback for non-standard strings
- Access: `AppLocalizations.of(context)?.translate('key')`

### 5. UI Patterns: Material You 3 + Animation

**Theme** (`lib/core/theme.dart`):
- Dynamic accent color from `accentColorProvider`
- Material You 3 ColorScheme
- Dark/light mode support
- Glassmorphism cards with blur, modern elevation

**Animations** (`lib/core/animations/staggered_animation.dart`):
- Reusable staggered list animations
- Applied to calculator results, history cards

**Screens structure**:
- `lib/presentation/views/novice/` - Simplified mode (10 common tasks + wizards)
- `lib/presentation/views/pro/` - Expert mode (all 47 calculators)
- `lib/presentation/views/calculator/universal_calculator_screen.dart` - Dynamic form builder

## Developer Workflows

### Adding a New Calculator

1. **Create usecase** in `lib/domain/usecases/calculate_[name].dart`:
   ```dart
   class CalculateTileName implements CalculatorUseCase {
     @override
     CalculatorResult call(Map<String, double> inputs, List<PriceItem> priceList) {
       final area = inputs['area'] ?? 0;
       // ... math logic
       return CalculatorResult(
         values: {'qty': result},
         totalPrice: result * price,
       );
     }
   }
   ```

2. **Add to definitions** in `lib/domain/calculators/definitions.dart`:
   ```dart
   CalculatorDefinition(
     id: 'calculator.tileName',
     titleKey: 'title.tileName',
     fields: [InputFieldDefinition(key: 'area', labelKey: 'input.area')],
     resultLabels: {'qty': 'output.quantity'},
     useCase: CalculateTileName(),
     category: ['Dom', 'Wall', 'Tile'],
   ),
   ```

3. **Add translations**: Update `assets/lang/ru.json`, `assets/lang/en.json` with `title.tileName`, `input.area`, `output.quantity` keys.

### Build & Code Generation

**Required commands** (in order):
```powershell
flutter pub get                 # Get dependencies
flutter pub run build_runner build --delete-conflicting-outputs  # Generate Isar + i18n
flutter run                     # Launch app
```

**For Android**:
- Gradle sync happens automatically
- Check `android/app/build.gradle.kts` for version/SDK settings
- `local.properties` must point to Android SDK path

### Testing & Linting

```powershell
flutter analyze                 # Lint with flutter_lints (strict)
flutter test test/              # Run widget tests
```

**Linter config**: `analysis_options.yaml` extends `package:flutter_lints/flutter.yaml`

## Project-Specific Conventions

### Naming
- **Calculator ID**: `calculator.[camelCase]` (lowercase first letter)
- **Translation keys**: Hierarchical with dots (`title.*`, `input.*`, `output.*`)
- **Input field keys**: Match map keys in `Map<String, double> inputs`
- **Price SKUs**: lowercase with underscores (`concrete_m3`, `paint_wall`)

### Constants & Defaults
- **App name**: `'Прораб AI'` (via `AppConstants.appName`)
- **Default consumption values** from SNiP/GOST (e.g., paint: 0.15 kg/m²)
- **Default layers**: Usually 2 for paints, 1 for primers
- **Waste buffer**: Typically 10% margin (`* 1.1`) per SNiP regulations

### Calculator Math Notes
- **Area deductions**: Automatically subtract `windowsArea` + `doorsArea` for wall calculations
- **Volume formulas**: Always cross-check against Russian construction standards (SNiP)
- **Price fallbacks**: Use `_findPrice(priceList, ['primary_sku', 'fallback_sku'])` pattern
- **Unit handling**: All inputs in meters (m), not cm; outputs in kg, m³, pcs as appropriate

### Riverpod Usage
- Use `StateNotifierProvider` for mutable state (projects, settings)
- Use `FutureProvider` for async data (calculations, prices)
- Watch providers in `ConsumerWidget` via `ref.watch()`
- Read (non-reactive) via `ref.read()` for one-time operations
- **Invalidate** providers after DB updates: `ref.invalidate(calculationProvider)`

## Integration Points & Dependencies

### External Services
- **Google AdMob** - Integrated (banners + interstitials)
- **In-App Purchases** - For PRO version (ad-free)
- **Deep Links** - `url_launcher` for material supplier links (e.g., Leroy Merlin)

### Key Packages
- **flutter_riverpod**: State management (v2.6.1+)
- **isar**: Offline DB for calculations (v3.1.0+)
- **pdf**: Report generation (v3.11.3)
- **speech_to_text**: Voice input (v7.3.0)
- **camera**: Photo capture for references (v0.11.3)
- **flutter_cube**: 3D visualization (v0.1.1)

### Asset Structure
```
assets/
├── icons/           → App icons (adaptive launcher icons)
├── json/
│   ├── prices_*.json    → Regional pricing (5 regions)
│   └── (old pricing removed)
├── lang/
│   ├── ru.json, en.json, kk.json, ky.json, tg.json, tk.json, uz.json
│   └── (7 languages total)
├── obj/cube/        → 3D cube models
└── videos/          → Tutorial videos
```

## Critical Notes

1. **Always run code generation** after modifying Isar models or adding calculators
2. **Price lookups** must handle missing SKUs gracefully (return null, show warning)
3. **Localization keys** must exist in ALL supported language JSON files (or app crashes)
4. **Regional prices** are loaded on startup; filtering happens via `priceProvider.select()`
5. **Calculation history** is stored locally; no cloud sync (by design)
6. **Material You accent** persists in SharedPreferences; theme updates require hot reload
