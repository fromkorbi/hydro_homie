import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydro_homie/src/infrastructure/entries_repository.dart';
import 'package:hydro_homie/src/domain/models/drink_entry.dart';

String dateKeyFor(DateTime dt) {
  final now = dt.toUtc();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

void main() {
  test('save and load entries for date', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPreferencesEntriesRepository(prefs);
    final key = dateKeyFor(DateTime.now());
    final entry = DrinkEntry(id: '1', drinkTypeId: 'water', sizeMl: 250, timestamp: DateTime.now());
    await repo.saveEntriesForDate(key, [entry]);
    final loaded = await repo.loadEntriesForDate(key);
    expect(loaded.length, 1);
    expect(loaded.first.id, '1');
    expect(loaded.first.sizeMl, 250);
  });
}
