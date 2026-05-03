import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zikirmatik_v2/core/data/local/app_database.dart';
import 'package:zikirmatik_v2/core/data/local/database_provider.dart';
import 'package:zikirmatik_v2/core/services/app_services.dart';
import 'package:zikirmatik_v2/core/services/interaction_feedback_service.dart';
import 'package:zikirmatik_v2/features/counter/application/counter_controller.dart';
import 'package:zikirmatik_v2/features/dhikr_library/data/builtin_dhikrs.dart';
import 'package:zikirmatik_v2/features/settings/application/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({ProviderContainer container, AppDatabase database})>
  createSubject() async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        analyticsServiceProvider.overrideWithValue(const _FakeAnalytics()),
        interactionFeedbackServiceProvider.overrideWithValue(
          InteractionFeedbackService(
            () => const SettingsState(
              vibrationEnabled: false,
              soundEnabled: false,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(database.close);
    return (container: container, database: database);
  }

  test('reset keeps an unfinished counted session in history', () async {
    final (:container, :database) = await createSubject();
    final dhikr = builtinDhikrs.firstWhere(
      (item) => item.id == 'estagfirullah',
    );
    final controller = container.read(counterControllerProvider.notifier);

    controller.startDhikr(dhikr);
    controller.increment();

    final beforeReset = await database.watchCounterSessions().firstWhere(
      (sessions) => sessions.any(
        (session) => session.dhikrId == dhikr.id && session.count == 1,
      ),
    );
    final sessionId = beforeReset
        .singleWhere((session) => session.dhikrId == dhikr.id)
        .id;

    controller.reset();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(container.read(counterControllerProvider).count, 0);
    final afterReset = await database.watchCounterSessions().first;
    final session = afterReset.singleWhere(
      (session) => session.id == sessionId,
    );
    expect(session.count, 1);
    expect(session.status, 'active');
  });

  test('reset keeps a completed session in history', () async {
    final (:container, :database) = await createSubject();
    final dhikr = builtinDhikrs.firstWhere(
      (item) => item.id == 'estagfirullah',
    );
    final controller = container.read(counterControllerProvider.notifier);

    controller.startDhikr(dhikr, target: 1);
    controller.increment();

    final beforeReset = await database.watchCounterSessions().firstWhere(
      (sessions) => sessions.any(
        (session) =>
            session.dhikrId == dhikr.id &&
            session.count == 1 &&
            session.status == 'completed',
      ),
    );
    final sessionId = beforeReset
        .singleWhere((session) => session.dhikrId == dhikr.id)
        .id;

    controller.reset();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(container.read(counterControllerProvider).count, 0);
    final afterReset = await database.watchCounterSessions().first;
    final session = afterReset.singleWhere(
      (session) => session.id == sessionId,
    );
    expect(session.count, 1);
    expect(session.status, 'completed');
  });

  test('undoing the only count removes the session and statistic', () async {
    final (:container, :database) = await createSubject();
    final dhikr = builtinDhikrs.firstWhere(
      (item) => item.id == 'estagfirullah',
    );
    final controller = container.read(counterControllerProvider.notifier);

    controller.startDhikr(dhikr);
    controller.increment();

    await database.watchCounterSessions().firstWhere(
      (sessions) => sessions.any(
        (session) => session.dhikrId == dhikr.id && session.count == 1,
      ),
    );
    await database.watchCounterStatBuckets().firstWhere(
      (buckets) => buckets.any(
        (bucket) => bucket.dhikrId == dhikr.id && bucket.count == 1,
      ),
    );

    controller.decrement();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(container.read(counterControllerProvider).count, 0);
    expect(await database.watchCounterSessions().first, isEmpty);
    expect(await database.watchCounterStatBuckets().first, isEmpty);
  });
}

class _FakeAnalytics implements AnalyticsService {
  const _FakeAnalytics();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {}

  @override
  Future<void> setCurrentScreen(String screenName) async {}
}
