import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import '../application/hydration_state.dart';
import '../infrastructure/entries_repository.dart';
import '../infrastructure/settings_repository.dart';
import '../infrastructure/notification_service.dart';
import 'log_drink_page.dart';
import 'home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SharedPreferencesSettingsRepository(prefs);
  final entriesRepo = SharedPreferencesEntriesRepository(prefs);
  final hydrationState = await HydrationState.create(settingsRepo, entriesRepo);
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }
  await notificationService.init(onSelect: (payload) {
    navigatorKey.currentState?.pushNamed('/log');
  });
  runApp(MyApp(hydrationState: hydrationState));
}

class MyApp extends StatefulWidget {
  final HydrationState hydrationState;

  const MyApp({required this.hydrationState, super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.hydrationState.reloadLastNativeNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HydrationState>.value(
      value: widget.hydrationState,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Hydro Homie',
        theme: ThemeData(primarySwatch: Colors.blue),
        routes: {
          '/': (_) => const HomePage(),
          '/log': (_) => const LogDrinkPage(),
        },
      ),
    );
  }
}
