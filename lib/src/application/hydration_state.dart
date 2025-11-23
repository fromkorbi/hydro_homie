import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/app_settings.dart';
import '../domain/models/drink_entry.dart';
import '../domain/models/drink_type.dart';
import '../domain/models/hydration_status.dart';
import '../domain/models/last_native_notification.dart';
import '../infrastructure/entries_repository.dart';
import '../infrastructure/settings_repository.dart';
import '../infrastructure/notification_service.dart';

class HydrationState extends ChangeNotifier {
  final SettingsRepository settingsRepository;
  final EntriesRepository entriesRepository;
  AppSettings _settings = AppSettings.defaultSettings();
  List<DrinkEntry> _entries = [];
  LastNativeNotification? _lastNativeNotification;
  final List<DrinkType> _defaultDrinkTypes = const [
    DrinkType(id: 'water', name: 'Water', defaultSizeMl: 250, favorite: true),
    DrinkType(id: 'tea', name: 'Tea', defaultSizeMl: 200),
    DrinkType(id: 'coffee', name: 'Coffee', defaultSizeMl: 150),
    DrinkType(id: 'juice', name: 'Juice', defaultSizeMl: 200),
  ];

  HydrationState({required this.settingsRepository, required this.entriesRepository}) {
    _setupNativeCallbacks();
  }

  static const int _reminderNotificationId = 1001;
  static const channel = MethodChannel('com.example.hydro_homie/notifications');

  static Future<HydrationState> create(SettingsRepository settingsRepository, EntriesRepository entriesRepository) async {
    final s = HydrationState(settingsRepository: settingsRepository, entriesRepository: entriesRepository);
    await s._load();
    return s;
  }

  void _setupNativeCallbacks() {
    if (Platform.isAndroid) {
      try {
        channel.setMethodCallHandler((call) async {
          if (call.method == 'onNativeNotification') {
            final args = call.arguments as Map<dynamic, dynamic>;
            _handleNativeNotification(args);
          }
        });
      } catch (e) {
        debugPrint('Error setting up native callbacks: $e');
      }
    }
  }

  void _handleNativeNotification(Map<dynamic, dynamic> data) {
    try {
      final notification = LastNativeNotification(
        id: data['id'] as int,
        title: data['title'] as String,
        body: data['body'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
      );
      _lastNativeNotification = notification;
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling native notification: $e');
    }
  }

  Timer? _midnightTimer;

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final duration = next.difference(now);
    _midnightTimer = Timer(duration, () async {
      await _onMidnight();
    });
  }

  Future<void> _onMidnight() async {
    final key = _todayKey();
    _entries = await entriesRepository.loadEntriesForDate(key);
    _scheduleMidnightTimer();
    notifyListeners();
  }

  Future<void> _load() async {
    _settings = await settingsRepository.load();
    final key = _todayKey();
    _entries = await entriesRepository.loadEntriesForDate(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('flutter.last_native_notification_v1');
      if (s != null) {
        final map = json.decode(s) as Map<String, dynamic>;
        _lastNativeNotification = LastNativeNotification.fromJson(map);
      }
    } catch (_) {}
    _applyReminderSetting();
    _updateOngoingNotification();
    _scheduleMidnightTimer();
    notifyListeners();
  }

  void _updateOngoingNotification() {
    final id = 2001;
    if (_settings.showOngoingNotification) {
      final stat = status;
      final title = '${stat.totalMl} / ${_settings.dailyTargetMl} ml';
      final pct = stat.percentage * 100.0;
      final level = stat.level == HydrationLevel.red
        ? 'red'
        : (stat.level == HydrationLevel.yellow ? 'yellow' : 'green');
      final body = '${pct.toStringAsFixed(0)}% • $level';
      notificationService.showOngoingStatus(id: id, title: title, body: body, payload: null);
    } else {
      notificationService.cancel(2001);
    }
  }

  void _applyReminderSetting() {
    final minutes = _settings.reminderIntervalMinutes;
    if (minutes == null) {
      notificationService.cancel(_reminderNotificationId);
      if (Platform.isAndroid) {
        try {
          channel.invokeMethod('cancelNativeReminders');
        } catch (_) {}
      }
      return;
    }
    if (Platform.isAndroid) {
      try {
        channel.invokeMethod('scheduleNativeReminder', {
          'minutes': minutes,
          'useWorkManager': _settings.useWorkManager,
          'useInexact': _settings.useInexact,
        });
      } catch (_) {
        try {
          notificationService.schedulePeriodicReminder(
            id: _reminderNotificationId,
            title: 'Time to drink',
            body: 'Take a sip to stay on track',
            intervalMinutes: minutes,
            payload: 'open_log',
          );
        } catch (_) {}
      }
    } else {
      notificationService.schedulePeriodicReminder(
        id: _reminderNotificationId,
        title: 'Time to drink',
        body: 'Take a sip to stay on track',
        intervalMinutes: minutes,
        payload: 'open_log',
      );
    }
  }

  String _todayKey() {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  AppSettings get settings => _settings;

  LastNativeNotification? get lastNativeNotification => _lastNativeNotification;

  List<DrinkEntry> get entries => List.unmodifiable(_entries);

  List<DrinkType> get drinkTypes => List.unmodifiable(_defaultDrinkTypes);

  List<DrinkType> get favorites => _defaultDrinkTypes.where((d) => d.favorite).toList();

  int get dailyTotal => _entries.fold(0, (p, e) => p + e.sizeMl);

  double get percentage => _settings.dailyTargetMl <= 0 ? 0.0 : (dailyTotal / _settings.dailyTargetMl).clamp(0.0, 1.0);

  HydrationStatus get status => HydrationStatus.fromValues(dailyTotal, _settings.dailyTargetMl);

  Future<void> addDrink(DrinkType type, {int? sizeMl}) async {
    final size = sizeMl ?? type.defaultSizeMl;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final entry = DrinkEntry(id: id, drinkTypeId: type.id, sizeMl: size, timestamp: DateTime.now());
    _entries = [..._entries, entry];
    await entriesRepository.saveEntriesForDate(_todayKey(), _entries);
    _updateOngoingNotification();
    notifyListeners();
  }

  Future<void> resetToday() async {
    _entries = [];
    await entriesRepository.saveEntriesForDate(_todayKey(), _entries);
    _updateOngoingNotification();
    notifyListeners();
  }

  Future<void> setDailyTarget(int ml) async {
    _settings = _settings.copyWith(dailyTargetMl: ml);
    await settingsRepository.save(_settings);
    _updateOngoingNotification();
    notifyListeners();
  }

  Future<void> setReminderInterval(int? minutes) async {
    _settings = _settings.copyWith(reminderIntervalMinutes: minutes);
    await settingsRepository.save(_settings);
    _applyReminderSetting();
    _updateOngoingNotification();
    notifyListeners();
  }

  Future<void> setUseWorkManager(bool v) async {
    _settings = _settings.copyWith(useWorkManager: v);
    await settingsRepository.save(_settings);
    _applyReminderSetting();
    notifyListeners();
  }

  Future<void> setUseInexact(bool v) async {
    _settings = _settings.copyWith(useInexact: v);
    await settingsRepository.save(_settings);
    _applyReminderSetting();
    notifyListeners();
  }

  Future<void> setShowOngoingNotification(bool v) async {
    _settings = _settings.copyWith(showOngoingNotification: v);
    await settingsRepository.save(_settings);
    _updateOngoingNotification();
    notifyListeners();
  }

  Future<void> reloadLastNativeNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('flutter.last_native_notification_v1');
      if (s != null) {
        final map = json.decode(s) as Map<String, dynamic>;
        final newNotif = LastNativeNotification.fromJson(map);
        if (newNotif != _lastNativeNotification) {
          _lastNativeNotification = newNotif;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}
