import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider для выбранного региона. Значение сохраняется между сессиями.
final regionProvider = StateNotifierProvider<RegionNotifier, String>((ref) {
  return RegionNotifier();
});

class RegionNotifier extends StateNotifier<String> {
  static const _prefKey = 'region';

  RegionNotifier() : super('Москва') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_prefKey) ?? 'Москва';
  }

  Future<void> setRegion(String region) async {
    state = region;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, region);
  }
}