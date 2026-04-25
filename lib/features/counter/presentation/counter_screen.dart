import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../application/counter_controller.dart';

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterControllerProvider);
    final controller = ref.read(counterControllerProvider.notifier);

    return AppScaffold(
      title: 'Sayaç',
      leading: IconButton(
        tooltip: 'Ana sayfaya dön',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.go(AppRoutes.dashboard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            counter.activeDhikr.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (counter.activeDhikr.arabicText != null) ...[
            const SizedBox(height: 8),
            Text(
              counter.activeDhikr.arabicText!,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TargetChip(
                label: '33',
                value: 33,
                selected: counter.target == 33,
              ),
              _TargetChip(
                label: '99',
                value: 99,
                selected: counter.target == 99,
              ),
              _TargetChip(
                label: '100',
                value: 100,
                selected: counter.target == 100,
              ),
              _TargetChip(
                label: 'Sonsuz',
                value: 0,
                selected: counter.target == 0,
              ),
              ActionChip(
                avatar: const Icon(Icons.edit_outlined),
                label: const Text('Özel'),
                onPressed: () => _showCustomTargetDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Semantics(
                button: true,
                label: 'Sayacı artır',
                child: InkResponse(
                  key: const Key('counter.increment'),
                  onTap: controller.increment,
                  radius: 132,
                  child: SizedBox.square(
                    dimension: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: counter.isInfinite ? null : counter.progress,
                          strokeWidth: 10,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${counter.count}',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            Text(
                              counter.isInfinite
                                  ? 'Sonsuz hedef'
                                  : '/ ${counter.target}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (counter.completed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Hedef tamamlandı'),
                  trailing: TextButton(
                    onPressed: controller.dismissCompletion,
                    child: const Text('Kapat'),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.decrement,
                  icon: const Icon(Icons.undo),
                  label: const Text('Geri al'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Sıfırla'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends ConsumerWidget {
  const _TargetChip({
    required this.label,
    required this.value,
    required this.selected,
  });

  final String label;
  final int value;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          ref.read(counterControllerProvider.notifier).setTarget(value),
    );
  }
}

Future<void> _showCustomTargetDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  final value = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Özel hedef'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Hedef sayısı'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed == null || parsed < 1) return;
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Uygula'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (value != null) {
    ref.read(counterControllerProvider.notifier).setTarget(value);
  }
}
