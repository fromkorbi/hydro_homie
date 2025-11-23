import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  final SharedPreferences prefs;

  SharedPreferencesSettingsRepository(this.prefs);

  static const _key = 'app_settings_v1';

  @override
  Future<AppSettings> load() async {
    final s = prefs.getString(_key);
    if (s == null) {
      return AppSettings.defaultSettings();
    }
    final map = json.decode(s) as Map<String, dynamic>;
    return AppSettings.fromJson(map);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final s = json.encode(settings.toJson());
    await prefs.setString(_key, s);
  }
}
