import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/child.dart';
import '../storage/local_storage_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // SharedPreferences keys
  static const _keyEnabled = 'notif_enabled';
  static const _keyBirthday = 'notif_birthday';
  static const _keyMissingPhoto = 'notif_missing_photo';

  // Channel
  static const _channel = AndroidNotificationDetails(
    'seeme_grow_reminders',
    'Reminders',
    channelDescription: 'Birthday and photo reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _notificationDetails = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
  );

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      ),
    );
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    if (!value) {
      await cancelAll();
    } else {
      await scheduleAll();
    }
  }

  static Future<bool> isBirthdayEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBirthday) ?? true;
  }

  static Future<void> setBirthdayEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBirthday, value);
    await scheduleAll();
  }

  static Future<bool> isMissingPhotoEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMissingPhoto) ?? true;
  }

  static Future<void> setMissingPhotoEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMissingPhoto, value);
    await scheduleAll();
  }

  // ---------------------------------------------------------------------------
  // Schedule all notifications for every child
  // ---------------------------------------------------------------------------

  static Future<void> scheduleAll() async {
    await cancelAll();

    if (!await isEnabled()) return;

    final children = await LocalStorageService.loadChildren();
    final now = DateTime.now();

    for (final child in children) {
      final idSeed = child.localId.hashCode.abs();

      if (await isBirthdayEnabled()) {
        _scheduleBirthdayReminders(child, idSeed, now);
      }

      if (await isMissingPhotoEnabled()) {
        _scheduleMissingPhotoReminder(child, idSeed, now);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Birthday reminders: 1 week before, 1 day before, on the day
  // ---------------------------------------------------------------------------

  static Future<void> _scheduleBirthdayReminders(
    Child child,
    int idSeed,
    DateTime now,
  ) async {
    // Next birthday
    var birthday = DateTime(now.year, child.birthDate.month, child.birthDate.day);
    if (birthday.isBefore(now) || birthday.isAtSameMomentAs(now)) {
      birthday = DateTime(now.year + 1, child.birthDate.month, child.birthDate.day);
    }

    final age = birthday.year - child.birthDate.year;
    if (age > 18) return;

    final reminders = [
      (
        offset: const Duration(days: 7),
        title: '${child.name}\'s birthday in 1 week!',
        body: 'Get ready to capture year $age.',
        idOffset: 0,
      ),
      (
        offset: const Duration(days: 1),
        title: '${child.name}\'s birthday is tomorrow!',
        body: 'Don\'t forget to take a photo for year $age.',
        idOffset: 1,
      ),
      (
        offset: Duration.zero,
        title: 'Happy Birthday, ${child.name}!',
        body: 'Open SeeMeGrow to save a year $age memory.',
        idOffset: 2,
      ),
    ];

    for (final r in reminders) {
      final date = birthday.subtract(r.offset);
      if (date.isBefore(now)) continue;

      final scheduled = tz.TZDateTime.from(
        DateTime(date.year, date.month, date.day, 9, 0),
        tz.local,
      );

      await _plugin.zonedSchedule(
        _notifId(idSeed, r.idOffset),
        r.title,
        r.body,
        scheduled,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Missing photo reminder: if a year has no photo 1 month after birthday
  // ---------------------------------------------------------------------------

  static Future<void> _scheduleMissingPhotoReminder(
    Child child,
    int idSeed,
    DateTime now,
  ) async {
    final currentAge = _ageInYears(child.birthDate, now);
    if (currentAge > 18) return;

    final hasPhoto = child.yearPhotos[currentAge]?.trim().isNotEmpty ?? false;
    if (hasPhoto) return;

    // Trigger 1 month after the birthday of the current age
    final birthdayThisAge = DateTime(
      child.birthDate.year + currentAge,
      child.birthDate.month,
      child.birthDate.day,
    );
    final reminderDate = DateTime(
      birthdayThisAge.year,
      birthdayThisAge.month + 1,
      birthdayThisAge.day,
    );

    if (reminderDate.isBefore(now)) return;

    final scheduled = tz.TZDateTime.from(
      DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 10, 0),
      tz.local,
    );

    final label = currentAge == 0 ? 'birth' : 'year $currentAge';

    await _plugin.zonedSchedule(
      _notifId(idSeed, 10),
      '${child.name} is missing a photo!',
      'Add a $label memory before it\'s too late.',
      scheduled,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ---------------------------------------------------------------------------
  // Test (fires immediately)
  // ---------------------------------------------------------------------------

  static Future<void> testNotification() async {
    await _plugin.show(
      0,
      'SeeMeGrow',
      'Notifications are working!',
      const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cancel
  // ---------------------------------------------------------------------------

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> cancelForChild(String localId) async {
    final idSeed = localId.hashCode.abs();
    for (var i = 0; i < 15; i++) {
      await _plugin.cancel(_notifId(idSeed, i));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static int _notifId(int seed, int offset) => (seed + offset) % 2147483647;

  static int _ageInYears(DateTime birth, DateTime now) {
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age.clamp(0, 18);
  }
}
