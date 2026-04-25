import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/database_provider.dart';
import 'local_notification_service.dart';

final remindersProvider = StreamProvider<List<ReminderRecord>>((ref) {
  return ref.watch(appDatabaseProvider).watchReminders();
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(
    database: ref.watch(appDatabaseProvider),
    notifications: ref.watch(localNotificationServiceProvider),
  );
});

class ReminderRepository {
  const ReminderRepository({
    required AppDatabase database,
    required LocalNotificationService notifications,
  }) : _database = database,
       _notifications = notifications;

  final AppDatabase _database;
  final LocalNotificationService _notifications;

  Future<void> addDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final reminder = await _database.addReminder(
      title: title,
      body: body,
      hour: hour,
      minute: minute,
    );
    await _notifications.scheduleDaily(
      id: reminder.id.hashCode,
      title: reminder.title,
      body: reminder.body,
      hour: reminder.hour,
      minute: reminder.minute,
    );
  }

  Future<void> setEnabled(ReminderRecord reminder, bool enabled) async {
    await _database.setReminderEnabled(reminder.id, enabled);
    if (enabled) {
      await _notifications.scheduleDaily(
        id: reminder.id.hashCode,
        title: reminder.title,
        body: reminder.body,
        hour: reminder.hour,
        minute: reminder.minute,
      );
    } else {
      await _notifications.cancel(reminder.id.hashCode);
    }
  }

  Future<void> delete(ReminderRecord reminder) async {
    await _database.softDeleteReminder(reminder.id);
    await _notifications.cancel(reminder.id.hashCode);
  }
}
