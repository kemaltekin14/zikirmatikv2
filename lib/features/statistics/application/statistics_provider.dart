import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local/database_provider.dart';

class StatisticsSummary {
  const StatisticsSummary({
    required this.totalPositiveCounts,
    required this.completedTargets,
    required this.todayPositiveCounts,
    required this.topDhikrName,
  });

  final int totalPositiveCounts;
  final int completedTargets;
  final int todayPositiveCounts;
  final String topDhikrName;
}

final statisticsSummaryProvider = StreamProvider<StatisticsSummary>((ref) {
  return ref.watch(appDatabaseProvider).watchCounterEvents().map((events) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final positiveEvents = events.where((event) => event.delta > 0).toList();
    final byDhikr = <String, int>{};

    for (final event in positiveEvents) {
      byDhikr.update(
        event.dhikrName,
        (value) => value + event.delta,
        ifAbsent: () => event.delta,
      );
    }

    final top = byDhikr.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return StatisticsSummary(
      totalPositiveCounts: positiveEvents.fold(
        0,
        (sum, event) => sum + event.delta,
      ),
      completedTargets: events
          .where((event) => event.eventType == 'completed')
          .length,
      todayPositiveCounts: positiveEvents
          .where((event) => event.createdAt.isAfter(startOfDay))
          .fold(0, (sum, event) => sum + event.delta),
      topDhikrName: top.isEmpty ? '-' : top.first.key,
    );
  });
});
