// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_homie/src/presentation/main.dart' as app;
import 'package:hydro_homie/src/application/hydration_state.dart';
import 'package:hydro_homie/src/infrastructure/settings_repository.dart';
import 'package:hydro_homie/src/infrastructure/entries_repository.dart';
import 'package:hydro_homie/src/domain/models/app_settings.dart';
import 'package:hydro_homie/src/domain/models/drink_entry.dart';

class _InMemorySettingsRepository implements SettingsRepository {
  AppSettings? _s;
  @override
  Future<AppSettings> load() async => _s ?? AppSettings.defaultSettings();
  @override
  Future<void> save(AppSettings settings) async { _s = settings; }
}

class _InMemoryEntriesRepository implements EntriesRepository {
  final Map<String, List<DrinkEntry>> _store = {};
  @override
  Future<List<DrinkEntry>> loadEntriesForDate(String dateKey) async => _store[dateKey] ?? [];
  @override
  Future<void> saveEntriesForDate(String dateKey, List<DrinkEntry> entries) async { _store[dateKey] = List.from(entries); }
}

void main() {
  testWidgets('App builds and shows progress', (WidgetTester tester) async {
    final settingsRepo = _InMemorySettingsRepository();
    final entriesRepo = _InMemoryEntriesRepository();
    final state = HydrationState(settingsRepository: settingsRepo, entriesRepository: entriesRepo);
    await tester.pumpWidget(app.MyApp(hydrationState: state));
    await tester.pumpAndSettle();
    expect(find.textContaining('/'), findsOneWidget);
  });
}
