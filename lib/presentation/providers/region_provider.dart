import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/region_ids.dart';

/// Provider для выбранного региона. Значение сохраняется между сессиями.
final regionProvider = StateNotifierProvider<RegionNotifier, String>((ref) {
  return RegionNotifier();
});

class RegionNotifier extends StateNotifier<String> {
  static const _prefKey = 'region';

  RegionNotifier() : super(RegionCatalog.defaultId) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = RegionCatalog.normalize(prefs.getString(_prefKey));
  }

  Future<void> setRegion(String region) async {
    state = RegionCatalog.normalize(region);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, state);
  }
}
