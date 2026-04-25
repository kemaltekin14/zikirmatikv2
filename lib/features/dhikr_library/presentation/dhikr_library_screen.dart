import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../counter/application/counter_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../application/dhikr_providers.dart';
import '../domain/dhikr_item.dart';

class DhikrLibraryScreen extends ConsumerStatefulWidget {
  const DhikrLibraryScreen({super.key});

  @override
  ConsumerState<DhikrLibraryScreen> createState() => _DhikrLibraryScreenState();
}

class _DhikrLibraryScreenState extends ConsumerState<DhikrLibraryScreen> {
  String _query = '';
  String _category = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(dhikrItemsProvider);

    return AppScaffold(
      title: 'Zikirler',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDhikrDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Özel zikir'),
      ),
      child: items.when(
        data: (dhikrs) {
          final categories = [
            'Tümü',
            ...{for (final item in dhikrs) item.category},
          ];
          final filtered = dhikrs.where((item) {
            final matchesCategory =
                _category == 'Tümü' || item.category == _category;
            final query = _query.trim().toLowerCase();
            final matchesQuery =
                query.isEmpty ||
                item.name.toLowerCase().contains(query) ||
                (item.meaning ?? '').toLowerCase().contains(query);
            return matchesCategory && matchesQuery;
          }).toList();

          return Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Zikir ara',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _DhikrTile(item: filtered[index]),
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) =>
            Center(child: Text('Zikirler yüklenemedi: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _DhikrTile extends ConsumerWidget {
  const _DhikrTile({required this.item});

  final DhikrItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text('${item.category} • hedef ${item.defaultTarget}'),
        leading: IconButton(
          tooltip: 'Favori',
          icon: Icon(item.isFavorite ? Icons.star : Icons.star_border),
          onPressed: item.isBuiltIn
              ? () => ref
                    .read(settingsControllerProvider.notifier)
                    .toggleFavorite(item.id)
              : null,
        ),
        trailing: FilledButton(
          key: Key('dhikr.start.${item.id}'),
          onPressed: () {
            final feedback = ref.read(interactionFeedbackServiceProvider);
            ref.read(counterControllerProvider.notifier).startDhikr(item);
            context.go(AppRoutes.counter);
            feedback.primaryAction();
          },
          child: const Text('Başlat'),
        ),
      ),
    );
  }
}

Future<void> _showAddDhikrDialog(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final targetController = TextEditingController(text: '33');
  final categoryController = TextEditingController(text: 'Özel');

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Özel zikir ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Zikir adı'),
              autofocus: true,
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Varsayılan hedef'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kaydet'),
          ),
        ],
      );
    },
  );

  if (shouldSave == true) {
    final target = int.tryParse(targetController.text) ?? 33;
    await ref
        .read(dhikrRepositoryProvider)
        .addCustomDhikr(
          name: nameController.text.trim(),
          category: categoryController.text.trim().isEmpty
              ? 'Özel'
              : categoryController.text.trim(),
          defaultTarget: target < 1 ? 33 : target,
        );
  }

  nameController.dispose();
  targetController.dispose();
  categoryController.dispose();
}
