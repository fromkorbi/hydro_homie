import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydro_homie/src/infrastructure/settings_repository.dart';
import 'package:hydro_homie/src/infrastructure/entries_repository.dart';
import 'package:hydro_homie/src/application/hydration_state.dart';

void main() {
  test('hydration state add drink and set target', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsRepo = SharedPreferencesSettingsRepository(prefs);
    final entriesRepo = SharedPreferencesEntriesRepository(prefs);
    final state = await HydrationState.create(settingsRepo, entriesRepo);
    expect(state.dailyTotal, 0);
    final dt = state.drinkTypes.firstWhere((d) => d.id == 'water');
    await state.addDrink(dt);
    expect(state.entries.isNotEmpty, true);
    expect(state.dailyTotal, dt.defaultSizeMl);
    await state.setDailyTarget(2500);
    expect(state.settings.dailyTargetMl, 2500);
  });
}
