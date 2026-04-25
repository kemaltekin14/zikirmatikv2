import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../counter/application/counter_controller.dart';
import '../data/esma_data.dart';
import '../domain/esma_item.dart';

class EsmaScreen extends ConsumerWidget {
  const EsmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Esmaül Hüsna',
      child: ListView.builder(
        itemCount: esmaItems.length,
        itemBuilder: (context, index) => _EsmaTile(item: esmaItems[index]),
      ),
    );
  }
}

class _EsmaTile extends ConsumerWidget {
  const _EsmaTile({required this.item});

  final EsmaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${item.number}')),
        title: Text(item.name),
        subtitle: Text(item.meaning),
        trailing: FilledButton(
          onPressed: () {
            final feedback = ref.read(interactionFeedbackServiceProvider);
            ref
                .read(counterControllerProvider.notifier)
                .startDhikr(item.toDhikr());
            context.go(AppRoutes.counter);
            feedback.primaryAction();
          },
          child: const Text('Başlat'),
        ),
      ),
    );
  }
}
