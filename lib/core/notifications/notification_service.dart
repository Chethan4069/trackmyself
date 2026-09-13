import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Central service for scheduling and cancelling local notifications.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  Future<void> initialise() async {
    if (_initialised) return;

    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      debugPrint('NotificationService: Local timezone set to ${timezoneInfo.identifier}');
    } catch (e) {
      debugPrint('NotificationService: Timezone initialization error: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Routine reminder channel
    const routineChannel = AndroidNotificationChannel(
      'routine_channel',
      'Daily Routine Reminders',
      description: 'Notifications for scheduled daily routines and habits',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await androidImplementation?.createNotificationChannel(routineChannel);

    // Calendar event reminder channel
    const calendarChannel = AndroidNotificationChannel(
      'calendar_channel',
      'Calendar Event Reminders',
      description: 'Notifications for scheduled appointments and calendar events',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await androidImplementation?.createNotificationChannel(calendarChannel);

    // Warranty expiration reminder channel
    const warrantyChannel = AndroidNotificationChannel(
      'warranty_channel',
      'Warranty Expiry Reminders',
      description: 'Notifications for expiring warranties and product guarantees',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidImplementation?.createNotificationChannel(warrantyChannel);

    _initialised = true;
  }

  /// Request notification permission on Android 13+.
  Future<bool> requestPermission() async {
    if (!_initialised) await initialise();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notifGranted =
        await android?.requestNotificationsPermission() ?? false;
    final exactGranted =
        await android?.requestExactAlarmsPermission() ?? true;

    return notifGranted && exactGranted;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ─── Routine Reminders ───────────────────────────────────────────────────

  /// Schedule a repeating daily notification for a routine.
  Future<void> scheduleDailyRoutineReminder({
    required int id,
    required String title,
    required String time, // 'HH:mm'
    required List<int> daysOfWeek,
  }) async {
    if (!_initialised) await initialise();

    try {
      final parts = time.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      const androidDetails = AndroidNotificationDetails(
        'routine_channel',
        'Daily Routine Reminders',
        channelDescription:
            'Notifications for scheduled daily routines and habits',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      await cancelRoutineReminder(id);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _plugin.zonedSchedule(
          id,
          'Routine: $title',
          'Time for your routine: $title ($time)',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'routine_$id',
        );
      } catch (e) {
        debugPrint('Exact alarm failed, falling back to inexact: $e');
        await _plugin.zonedSchedule(
          id,
          'Routine: $title',
          'Time for your routine: $title ($time)',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'routine_$id',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling routine reminder: $e');
    }
  }

  // ─── Calendar Event Reminders ─────────────────────────────────────────────

  /// Schedule a notification for a calendar event with a lead time.
  Future<void> scheduleCalendarEventReminder({
    required int id,
    required String title,
    required DateTime eventDateTime,
    required int reminderMinutes,
  }) async {
    if (!_initialised) await initialise();

    try {
      final notifId = 200000 + id;
      await cancel(notifId);

      final triggerTime =
          eventDateTime.subtract(Duration(minutes: reminderMinutes));
      final now = DateTime.now();

      if (triggerTime.isBefore(now)) {
        debugPrint('Calendar event trigger time is in the past: $triggerTime');
        return;
      }

      final scheduledDate = tz.TZDateTime(
        tz.local,
        triggerTime.year,
        triggerTime.month,
        triggerTime.day,
        triggerTime.hour,
        triggerTime.minute,
        0,
      );

      const androidDetails = AndroidNotificationDetails(
        'calendar_channel',
        'Calendar Event Reminders',
        channelDescription:
            'Notifications for scheduled appointments and calendar events',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      final reminderDesc = reminderMinutes == 0
          ? 'Event starting now!'
          : reminderMinutes < 60
              ? 'Starting in $reminderMinutes minutes'
              : reminderMinutes == 60
                  ? 'Starting in 1 hour'
                  : 'Starting in 1 day';

      final timeStr = DateFormat('hh:mm a').format(eventDateTime);

      try {
        await _plugin.zonedSchedule(
          notifId,
          'Event Reminder: $title',
          '$reminderDesc ($timeStr)',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'calendar_$id',
        );
      } catch (e) {
        debugPrint('Exact alarm failed for calendar, fallback to inexact: $e');
        await _plugin.zonedSchedule(
          notifId,
          'Event Reminder: $title',
          '$reminderDesc ($timeStr)',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'calendar_$id',
        );
      }
      debugPrint('Scheduled calendar reminder for $scheduledDate (ID: $notifId)');
    } catch (e) {
      debugPrint('Error scheduling calendar reminder: $e');
    }
  }

  Future<void> cancelCalendarEventReminder(int id) async {
    await cancel(200000 + id);
  }

  /// Show an instant test notification to verify reminders on this device.
  Future<void> showInstantTestNotification({
    String title = 'Routine Reminder: Drink Water',
    String body = 'Time for your routine! Stay hydrated today.',
  }) async {
    if (!_initialised) await initialise();

    const androidDetails = AndroidNotificationDetails(
      'routine_channel',
      'Daily Routine Reminders',
      channelDescription:
          'Notifications for scheduled daily routines and habits',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      99999,
      title,
      body,
      details,
    );
  }

  Future<void> cancelRoutineReminder(int id) async {
    await cancel(id);
    for (int day = 1; day <= 7; day++) {
      await cancel(id * 10 + day);
    }
  }


  // ─── Warranty Expiry Reminders ──────────────────────────────────────────

  /// Schedule a reminder notification before a warranty expires.
  Future<void> scheduleWarrantyReminder({
    required int id,
    required String productName,
    required DateTime expiryDate,
    int daysBefore = 7,
  }) async {
    if (!_initialised) await initialise();

    try {
      final notifId = 300000 + id;
      await cancel(notifId);

      final triggerTime = expiryDate.subtract(Duration(days: daysBefore));
      final now = DateTime.now();

      if (triggerTime.isBefore(now)) {
        debugPrint('Warranty reminder trigger time is in the past: $triggerTime');
        return;
      }

      final scheduledDate = tz.TZDateTime(
        tz.local,
        triggerTime.year,
        triggerTime.month,
        triggerTime.day,
        9, // 9:00 AM
        0,
        0,
      );

      const androidDetails = AndroidNotificationDetails(
        'warranty_channel',
        'Warranty Expiry Reminders',
        channelDescription:
            'Notifications for expiring warranties and product guarantees',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);
      final expiryStr = DateFormat('dd MMM yyyy').format(expiryDate);

      try {
        await _plugin.zonedSchedule(
          notifId,
          'Warranty Alert: $productName',
          'Warranty expires in $daysBefore days ($expiryStr)',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'warranty_$id',
        );
      } catch (e) {
        debugPrint('Exact alarm failed for warranty, fallback to inexact: $e');
        await _plugin.zonedSchedule(
          notifId,
          'Warranty Alert: $productName',
          'Warranty expires in $daysBefore days ($expiryStr)',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'warranty_$id',
        );
      }
      debugPrint('Scheduled warranty reminder for $scheduledDate (ID: $notifId)');
    } catch (e) {
      debugPrint('Error scheduling warranty reminder: $e');
    }
  }

  Future<void> cancelWarrantyReminder(int id) async {
    await cancel(300000 + id);
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}
