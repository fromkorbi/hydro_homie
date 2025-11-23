import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/drink_entry.dart';

abstract class EntriesRepository {
  Future<List<DrinkEntry>> loadEntriesForDate(String dateKey);
  Future<void> saveEntriesForDate(String dateKey, List<DrinkEntry> entries);
}

class SharedPreferencesEntriesRepository implements EntriesRepository {
  final SharedPreferences prefs;

  SharedPreferencesEntriesRepository(this.prefs);

  String _keyFor(String dateKey) => 'entries_$dateKey';

  @override
  Future<List<DrinkEntry>> loadEntriesForDate(String dateKey) async {
    final s = prefs.getString(_keyFor(dateKey));
    if (s == null) {
      return [];
    }
    final list = json.decode(s) as List<dynamic>;
    return list.map((e) => DrinkEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveEntriesForDate(String dateKey, List<DrinkEntry> entries) async {
    final s = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_keyFor(dateKey), s);
  }
}
