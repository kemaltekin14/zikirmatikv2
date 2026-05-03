import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool? _notificationsAllowedCache;
  DateTime? _notificationsAllowedCheckedAt;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<bool> areNotificationsAllowed({bool forceRefresh = false}) async {
    await initialize();

    final cached = _notificationsAllowedCache;
    final checkedAt = _notificationsAllowedCheckedAt;
    final cacheStillFresh =
        checkedAt != null &&
        DateTime.now().difference(checkedAt) < _permissionCacheDuration;
    if (!forceRefresh && cached != null && cacheStillFresh) {
      return cached;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return _cacheNotificationsAllowed(
        await android.areNotificationsEnabled() ?? true,
      );
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final permissions = await ios.checkPermissions();
      return _cacheNotificationsAllowed(permissions?.isEnabled ?? false);
    }

    return _cacheNotificationsAllowed(true);
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return _cacheNotificationsAllowed(
        granted ?? await areNotificationsAllowed(forceRefresh: true),
      );
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return _cacheNotificationsAllowed(
        await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false,
      );
    }

    return _cacheNotificationsAllowed(true);
  }

  bool _cacheNotificationsAllowed(bool allowed) {
    _notificationsAllowedCache = allowed;
    _notificationsAllowedCheckedAt = DateTime.now();
    return allowed;
  }

  Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required Set<int> repeatDays,
  }) async {
    await initialize();
    await cancelReminder(reminderId);

    final selectedDays = repeatDays.isEmpty ? _allWeekdays : repeatDays;

    if (selectedDays.length == DateTime.daysPerWeek) {
      await _scheduleDaily(
        id: _notificationIdFor(reminderId),
        title: title,
        body: body,
        hour: hour,
        minute: minute,
      );
      return;
    }

    for (final weekday in selectedDays.toList()..sort()) {
      await _plugin.zonedSchedule(
        id: _notificationIdFor(reminderId, weekday),
        title: title,
        body: body,
        scheduledDate: _nextWeekdayTime(
          weekday: weekday,
          hour: hour,
          minute: minute,
        ),
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    await _plugin.cancel(id: _notificationIdFor(reminderId));
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(id: _notificationIdFor(reminderId, weekday));
    }
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }
}

const _notificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    'daily_reminders',
    'Gunluk hatirlaticilar',
    channelDescription: 'Zikir ve vird hatirlaticilari',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  iOS: DarwinNotificationDetails(),
);

const _allWeekdays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
};

int _notificationIdFor(String reminderId, [int weekday = 0]) {
  return (reminderId.hashCode ^ (weekday * 100003)) & 0x7fffffff;
}

tz.TZDateTime _nextWeekdayTime({
  required int weekday,
  required int hour,
  required int minute,
}) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  return LocalNotificationService();
});

const _permissionCacheDuration = Duration(seconds: 20);
