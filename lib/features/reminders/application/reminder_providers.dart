import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/database_provider.dart';
import '../../../core/services/app_services.dart';
import 'local_notification_service.dart';

final remindersProvider = StreamProvider<List<ReminderRecord>>((ref) {
  return ref.watch(appDatabaseProvider).watchReminders();
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(
    database: ref.watch(appDatabaseProvider),
    notifications: ref.watch(localNotificationServiceProvider),
    analytics: ref.watch(analyticsServiceProvider),
  );
});

class ReminderRepository {
  const ReminderRepository({
    required AppDatabase database,
    required LocalNotificationService notifications,
    required AnalyticsService analytics,
  }) : _database = database,
       _notifications = notifications,
       _analytics = analytics;

  static const dailyTargetReminderTitle = 'Günlük hedef';
  static const dailyTargetReminderHour = 21;
  static const dailyTargetReminderMinute = 15;
  static String get dailyTargetReminderTimeLabel =>
      _timeLabel(dailyTargetReminderHour, dailyTargetReminderMinute);

  final AppDatabase _database;
  final LocalNotificationService _notifications;
  final AnalyticsService _analytics;

  Future<void> addReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    required Set<int> repeatDays,
    String? targetDhikrId,
  }) async {
    final encodedRepeatDays = _encodeRepeatDays(repeatDays);
    final reminder = await _database.addReminder(
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      repeatDays: encodedRepeatDays,
      targetDhikrId: targetDhikrId,
    );
    await _notifications.scheduleReminder(
      reminderId: reminder.id,
      title: reminder.title,
      body: reminder.body,
      hour: reminder.hour,
      minute: reminder.minute,
      repeatDays: _decodeRepeatDays(reminder.repeatDays),
    );
    unawaited(
      _analytics.logEvent(
        'reminder_created',
        parameters: {
          'reminder_type': targetDhikrId == null ? 'general' : 'dhikr',
          'hour': hour,
          'minute': minute,
          'repeat_type': _repeatType(repeatDays),
          'repeat_days_count': repeatDays.length,
          'has_target_dhikr': targetDhikrId != null,
        },
      ),
    );
  }

  Future<void> addDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? targetDhikrId,
  }) async {
    await addReminder(
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      repeatDays: _allWeekdays,
      targetDhikrId: targetDhikrId,
    );
  }

  Future<void> upsertDailyTargetReminder({
    required int target,
    required int hour,
    required int minute,
  }) async {
    final reminder = await _database.upsertReminderByTitle(
      title: dailyTargetReminderTitle,
      body: _dailyTargetReminderBody(target),
      hour: hour,
      minute: minute,
      repeatDays: _encodeRepeatDays(_allWeekdays),
    );
    await _notifications.scheduleReminder(
      reminderId: reminder.id,
      title: reminder.title,
      body: reminder.body,
      hour: reminder.hour,
      minute: reminder.minute,
      repeatDays: _decodeRepeatDays(reminder.repeatDays),
    );
    unawaited(
      _analytics.logEvent(
        'reminder_created',
        parameters: {
          'reminder_type': 'daily_target',
          'hour': hour,
          'minute': minute,
          'repeat_type': 'daily',
          'repeat_days_count': _allWeekdays.length,
          'target_count': target,
          'has_target_dhikr': false,
        },
      ),
    );
  }

  Future<void> setEnabled(ReminderRecord reminder, bool enabled) async {
    await _database.setReminderEnabled(reminder.id, enabled);
    if (enabled) {
      await _notifications.scheduleReminder(
        reminderId: reminder.id,
        title: reminder.title,
        body: reminder.body,
        hour: reminder.hour,
        minute: reminder.minute,
        repeatDays: _decodeRepeatDays(reminder.repeatDays),
      );
    } else {
      await _notifications.cancelReminder(reminder.id);
      await _notifications.cancel(reminder.id.hashCode);
    }
  }

  Future<void> delete(ReminderRecord reminder) async {
    await _database.softDeleteReminder(reminder.id);
    await _notifications.cancelReminder(reminder.id);
    await _notifications.cancel(reminder.id.hashCode);
  }
}

String _dailyTargetReminderBody(int target) {
  return 'Bugünkü ${_formatReminderNumber(target)} zikir hedefin seni bekliyor. Küçük bir adım, güçlü bir istikrar.';
}

String _formatReminderNumber(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
}

String _timeLabel(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

const _allWeekdays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
};

String _encodeRepeatDays(Set<int> repeatDays) {
  final days = repeatDays.isEmpty ? _allWeekdays : repeatDays;
  final sorted = days.toList()..sort();
  return sorted.join(',');
}

Set<int> _decodeRepeatDays(String value) {
  final days = value
      .split(',')
      .map((part) => int.tryParse(part.trim()))
      .whereType<int>()
      .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
      .toSet();
  return days.isEmpty ? _allWeekdays : days;
}

String _repeatType(Set<int> repeatDays) {
  if (repeatDays.containsAll(_allWeekdays) &&
      repeatDays.length == _allWeekdays.length) {
    return 'daily';
  }
  if (repeatDays.containsAll(_weekdays) &&
      repeatDays.length == _weekdays.length) {
    return 'weekdays';
  }
  if (repeatDays.containsAll(_weekendDays) &&
      repeatDays.length == _weekendDays.length) {
    return 'weekend';
  }
  return 'custom';
}

const _weekdays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
};

const _weekendDays = {DateTime.saturday, DateTime.sunday};
