import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  void Function(String? payload)? onSelectNotification;

  Future<void> init({void Function(String? payload)? onSelect}) async {
    onSelectNotification = onSelect;
  
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        onSelectNotification?.call(response.payload);
      },
    );
    const channel = AndroidNotificationChannel('hydration_reminders', 'Hydration Reminders', importance: Importance.defaultImportance, description: 'Reminders to drink water', playSound: true);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> showReminder({required int id, required String title, required String body, String? payload}) async {
    const android = AndroidNotificationDetails('hydration_reminders', 'Hydration Reminders', channelDescription: 'Reminders to drink water', importance: Importance.defaultImportance, priority: Priority.defaultPriority, visibility: NotificationVisibility.public);
    const ios = DarwinNotificationDetails();
    try {
      await _plugin.show(id, title, body, const NotificationDetails(android: android, iOS: ios), payload: payload);
    } catch (_) {}
  }

  Future<void> schedulePeriodicReminder({required int id, required String title, required String body, required int intervalMinutes, String? payload}) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(Duration(minutes: intervalMinutes));
    const android = AndroidNotificationDetails('hydration_reminders', 'Hydration Reminders', channelDescription: 'Reminders to drink water', importance: Importance.defaultImportance, priority: Priority.defaultPriority, visibility: NotificationVisibility.public);
    const ios = DarwinNotificationDetails();
    try {
      await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: android, iOS: ios),
      payload: payload,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      );
    } catch (_) {}
  }

  Future<void> showOngoingStatus({required int id, required String title, required String body, String? payload}) async {
    final android = AndroidNotificationDetails('hydration_status', 'Hydration Status', channelDescription: 'Ongoing hydration status', importance: Importance.low, priority: Priority.low, ongoing: true, visibility: NotificationVisibility.public);
    const ios = DarwinNotificationDetails();
    try {
      await _plugin.show(id, title, body, NotificationDetails(android: android, iOS: ios), payload: payload);
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

final notificationService = NotificationService();
