import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

const _counterSessionStatusActive = 'active';
const _counterSessionStatusCompleted = 'completed';
const _counterSessionStatusReset = 'reset';
const _defaultReminderRepeatDays = '1,2,3,4,5,6,7';

class DhikrRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get arabicText => text().nullable()();
  TextColumn get meaning => text().nullable()();
  TextColumn get category => text()();
  IntColumn get defaultTarget => integer().withDefault(const Constant(33))();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();
  TextColumn get userId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CounterStatBuckets extends Table {
  TextColumn get id => text()();
  TextColumn get dhikrId => text()();
  TextColumn get dhikrName => text()();
  DateTimeColumn get bucketStart => dateTime()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get day => integer()();
  IntColumn get hour => integer()();
  IntColumn get count => integer()();
  IntColumn get target => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pendingUpload'))();
  TextColumn get userId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CounterSessions extends Table {
  TextColumn get id => text()();
  TextColumn get dhikrId => text()();
  TextColumn get dhikrName => text()();
  IntColumn get count => integer()();
  IntColumn get target => integer()();
  TextColumn get status =>
      text().withDefault(const Constant(_counterSessionStatusActive))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pendingUpload'))();
  TextColumn get userId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReminderRecords extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  TextColumn get repeatDays =>
      text().withDefault(const Constant(_defaultReminderRepeatDays))();
  TextColumn get targetDhikrId => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();
  TextColumn get userId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VirdProgressRecords extends Table {
  TextColumn get id => text()();
  TextColumn get virdId => text()();
  IntColumn get stepIndex => integer()();
  IntColumn get count => integer()();
  IntColumn get target => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pendingUpload'))();
  TextColumn get userId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    DhikrRecords,
    CounterStatBuckets,
    CounterSessions,
    ReminderRecords,
    VirdProgressRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'zikirmatik_v2'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement('DROP TABLE IF EXISTS counter_events');
        await m.createTable(counterStatBuckets);
        await m.createTable(counterSessions);
      }
      if (from < 3) {
        await m.addColumn(reminderRecords, reminderRecords.repeatDays);
      }
      if (from < 4) {
        await m.addColumn(reminderRecords, reminderRecords.targetDhikrId);
      }
    },
  );

  Stream<List<DhikrRecord>> watchCustomDhikrs() {
    return (select(dhikrRecords)
          ..where(
            (table) => table.deletedAt.isNull() & table.isBuiltIn.equals(false),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Future<void> upsertCustomDhikr({
    required String name,
    required String category,
    required int defaultTarget,
    String? arabicText,
    String? meaning,
  }) {
    final now = DateTime.now();
    return into(dhikrRecords).insertOnConflictUpdate(
      DhikrRecordsCompanion.insert(
        id: _uuid.v4(),
        name: name,
        category: category,
        defaultTarget: Value(defaultTarget),
        arabicText: Value(arabicText),
        meaning: Value(meaning),
        isBuiltIn: const Value(false),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> setCustomDhikrFavorite({
    required String id,
    required bool isFavorite,
  }) {
    return (update(dhikrRecords)..where(
          (table) => table.id.equals(id) & table.isBuiltIn.equals(false),
        ))
        .write(
          DhikrRecordsCompanion(
            isFavorite: Value(isFavorite),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> recordCounterProgress({
    required String sessionId,
    required String dhikrId,
    required String dhikrName,
    required int delta,
    required int countAfter,
    required int target,
    required bool completed,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      if (delta != 0) {
        await _applyCounterStatDelta(
          dhikrId: dhikrId,
          dhikrName: dhikrName,
          delta: delta,
          target: target,
          now: now,
        );
      }

      await _upsertCounterSession(
        id: sessionId,
        dhikrId: dhikrId,
        dhikrName: dhikrName,
        count: countAfter,
        target: target,
        status: completed
            ? _counterSessionStatusCompleted
            : _counterSessionStatusActive,
        completedAt: completed ? now : null,
        now: now,
      );
    });
  }

  Future<void> updateCounterSessionTarget({
    required String sessionId,
    required String dhikrId,
    required String dhikrName,
    required int count,
    required int target,
    required bool completed,
  }) async {
    if (count <= 0) return;
    final now = DateTime.now();
    await _upsertCounterSession(
      id: sessionId,
      dhikrId: dhikrId,
      dhikrName: dhikrName,
      count: count,
      target: target,
      status: completed
          ? _counterSessionStatusCompleted
          : _counterSessionStatusActive,
      completedAt: completed ? now : null,
      now: now,
    );
  }

  Future<void> markCounterSessionReset(String sessionId) {
    return (update(
      counterSessions,
    )..where((table) => table.id.equals(sessionId))).write(
      CounterSessionsCompanion(
        count: const Value(0),
        status: const Value(_counterSessionStatusReset),
        completedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pendingUpload'),
      ),
    );
  }

  Stream<List<CounterStatBucket>> watchCounterStatBuckets() {
    return (select(counterStatBuckets)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([
            (table) => OrderingTerm.desc(table.bucketStart),
            (table) => OrderingTerm.desc(table.count),
          ]))
        .watch();
  }

  Stream<List<CounterSession>> watchCounterSessions() {
    return (select(counterSessions)
          ..where(
            (table) =>
                table.deletedAt.isNull() &
                table.status.isNotValue(_counterSessionStatusReset),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
        .watch();
  }

  Stream<List<ReminderRecord>> watchReminders() {
    return (select(reminderRecords)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([
            (table) => OrderingTerm.asc(table.hour),
            (table) => OrderingTerm.asc(table.minute),
          ]))
        .watch();
  }

  Future<ReminderRecord> addReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    String repeatDays = _defaultReminderRepeatDays,
    String? targetDhikrId,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await into(reminderRecords).insert(
      ReminderRecordsCompanion.insert(
        id: id,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        repeatDays: Value(repeatDays),
        targetDhikrId: Value(targetDhikrId),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (select(
      reminderRecords,
    )..where((table) => table.id.equals(id))).getSingle();
  }

  Future<ReminderRecord?> findReminderByTitle(String title) async {
    final reminders =
        await (select(reminderRecords)
              ..where(
                (table) => table.deletedAt.isNull() & table.title.equals(title),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.createdAt)])
              ..limit(1))
            .get();
    return reminders.isEmpty ? null : reminders.first;
  }

  Future<ReminderRecord> upsertReminderByTitle({
    required String title,
    required String body,
    required int hour,
    required int minute,
    String repeatDays = _defaultReminderRepeatDays,
    String? targetDhikrId,
  }) async {
    final existingReminder = await findReminderByTitle(title);
    if (existingReminder == null) {
      return addReminder(
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        repeatDays: repeatDays,
        targetDhikrId: targetDhikrId,
      );
    }

    await (update(
      reminderRecords,
    )..where((table) => table.id.equals(existingReminder.id))).write(
      ReminderRecordsCompanion(
        body: Value(body),
        hour: Value(hour),
        minute: Value(minute),
        repeatDays: Value(repeatDays),
        targetDhikrId: Value(targetDhikrId),
        enabled: const Value(true),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pendingUpload'),
      ),
    );

    return (select(
      reminderRecords,
    )..where((table) => table.id.equals(existingReminder.id))).getSingle();
  }

  Future<void> setReminderEnabled(String id, bool enabled) {
    return (update(
      reminderRecords,
    )..where((table) => table.id.equals(id))).write(
      ReminderRecordsCompanion(
        enabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pendingUpload'),
      ),
    );
  }

  Future<void> softDeleteReminder(String id) {
    return (update(
      reminderRecords,
    )..where((table) => table.id.equals(id))).write(
      ReminderRecordsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pendingUpload'),
      ),
    );
  }

  Future<void> upsertVirdProgress({
    required String virdId,
    required int stepIndex,
    required int count,
    required int target,
  }) async {
    final id = '$virdId-$stepIndex';
    final now = DateTime.now();
    await into(virdProgressRecords).insertOnConflictUpdate(
      VirdProgressRecordsCompanion.insert(
        id: id,
        virdId: virdId,
        stepIndex: stepIndex,
        count: count,
        target: target,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _applyCounterStatDelta({
    required String dhikrId,
    required String dhikrName,
    required int delta,
    required int target,
    required DateTime now,
  }) async {
    final bucketStart = DateTime(now.year, now.month, now.day, now.hour);
    final id = _counterStatBucketId(bucketStart, dhikrId);
    final existing = await (select(
      counterStatBuckets,
    )..where((table) => table.id.equals(id))).getSingleOrNull();

    if (existing == null) {
      if (delta <= 0) return;
      await into(counterStatBuckets).insert(
        CounterStatBucketsCompanion.insert(
          id: id,
          dhikrId: dhikrId,
          dhikrName: dhikrName,
          bucketStart: bucketStart,
          year: bucketStart.year,
          month: bucketStart.month,
          day: bucketStart.day,
          hour: bucketStart.hour,
          count: delta,
          target: target,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return;
    }

    final nextCount = existing.count + delta;
    if (nextCount <= 0) {
      await (delete(
        counterStatBuckets,
      )..where((table) => table.id.equals(id))).go();
      return;
    }

    await (update(
      counterStatBuckets,
    )..where((table) => table.id.equals(id))).write(
      CounterStatBucketsCompanion(
        dhikrName: Value(dhikrName),
        count: Value(nextCount),
        target: Value(target),
        updatedAt: Value(now),
        syncStatus: const Value('pendingUpload'),
      ),
    );
  }

  Future<void> _upsertCounterSession({
    required String id,
    required String dhikrId,
    required String dhikrName,
    required int count,
    required int target,
    required String status,
    required DateTime? completedAt,
    required DateTime now,
  }) async {
    final existing = await (select(
      counterSessions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();

    if (count <= 0) {
      if (existing == null) return;
      await (update(
        counterSessions,
      )..where((table) => table.id.equals(id))).write(
        CounterSessionsCompanion(
          count: const Value(0),
          status: const Value(_counterSessionStatusReset),
          completedAt: const Value(null),
          updatedAt: Value(now),
          syncStatus: const Value('pendingUpload'),
        ),
      );
      return;
    }

    if (existing == null) {
      await into(counterSessions).insert(
        CounterSessionsCompanion.insert(
          id: id,
          dhikrId: dhikrId,
          dhikrName: dhikrName,
          count: count,
          target: target,
          status: Value(status),
          startedAt: now,
          completedAt: Value(completedAt),
          updatedAt: now,
        ),
      );
      return;
    }

    await (update(
      counterSessions,
    )..where((table) => table.id.equals(id))).write(
      CounterSessionsCompanion(
        dhikrId: Value(dhikrId),
        dhikrName: Value(dhikrName),
        count: Value(count),
        target: Value(target),
        status: Value(status),
        completedAt: Value(completedAt),
        updatedAt: Value(now),
        syncStatus: const Value('pendingUpload'),
      ),
    );
  }
}

String _counterStatBucketId(DateTime bucketStart, String dhikrId) {
  final month = bucketStart.month.toString().padLeft(2, '0');
  final day = bucketStart.day.toString().padLeft(2, '0');
  final hour = bucketStart.hour.toString().padLeft(2, '0');
  return '${bucketStart.year}$month$day$hour-$dhikrId';
}
