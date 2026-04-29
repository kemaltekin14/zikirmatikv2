import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();
DateTime? _lastCounterEventCreatedAt;

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

class CounterEvents extends Table {
  TextColumn get id => text()();
  TextColumn get dhikrId => text()();
  TextColumn get dhikrName => text()();
  IntColumn get delta => integer()();
  IntColumn get countAfter => integer()();
  IntColumn get target => integer()();
  TextColumn get eventType => text()();
  DateTimeColumn get createdAt => dateTime()();
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
  tables: [DhikrRecords, CounterEvents, ReminderRecords, VirdProgressRecords],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'zikirmatik_v2'));

  @override
  int get schemaVersion => 1;

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

  Future<void> logCounterEvent({
    required String dhikrId,
    required String dhikrName,
    required int delta,
    required int countAfter,
    required int target,
    required String eventType,
  }) {
    final now = _nextCounterEventTimestamp();
    return into(counterEvents).insert(
      CounterEventsCompanion.insert(
        id: _uuid.v4(),
        dhikrId: dhikrId,
        dhikrName: dhikrName,
        delta: delta,
        countAfter: countAfter,
        target: target,
        eventType: eventType,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Stream<List<CounterEvent>> watchCounterEvents() {
    return (select(counterEvents)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([
            (table) => OrderingTerm.desc(table.createdAt),
            (table) => OrderingTerm.desc(table.countAfter),
          ]))
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
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (select(
      reminderRecords,
    )..where((table) => table.id.equals(id))).getSingle();
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
}

DateTime _nextCounterEventTimestamp() {
  final now = DateTime.now();
  final previous = _lastCounterEventCreatedAt;
  final timestamp = previous != null && !now.isAfter(previous)
      ? previous.add(const Duration(milliseconds: 1))
      : now;
  _lastCounterEventCreatedAt = timestamp;
  return timestamp;
}
