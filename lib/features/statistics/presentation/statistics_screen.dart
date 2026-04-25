import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../application/statistics_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(statisticsSummaryProvider);

    return AppScaffold(
      title: 'İstatistikler',
      child: summary.when(
        data: (data) => ListView(
          children: [
            _StatTile(
              label: 'Bugünkü sayım',
              value: '${data.todayPositiveCounts}',
            ),
            _StatTile(
              label: 'Toplam sayım',
              value: '${data.totalPositiveCounts}',
            ),
            _StatTile(
              label: 'Tamamlanan hedef',
              value: '${data.completedTargets}',
            ),
            _StatTile(label: 'En çok sayılan', value: data.topDhikrName),
          ],
        ),
        error: (error, stackTrace) =>
            Center(child: Text('İstatistikler yüklenemedi: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
