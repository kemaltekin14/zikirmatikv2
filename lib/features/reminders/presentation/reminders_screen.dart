import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../application/reminder_providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);

    return AppScaffold(
      title: 'Hatırlatıcılar',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ekle'),
      ),
      child: reminders.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Henüz hatırlatıcı yok.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final reminder = items[index];
              return Card(
                child: ListTile(
                  title: Text(reminder.title),
                  subtitle: Text(
                    '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}',
                  ),
                  leading: Switch(
                    value: reminder.enabled,
                    onChanged: (value) => ref
                        .read(reminderRepositoryProvider)
                        .setEnabled(reminder, value),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(reminderRepositoryProvider).delete(reminder),
                  ),
                ),
              );
            },
          );
        },
        error: (error, stackTrace) =>
            Center(child: Text('Hatırlatıcılar yüklenemedi: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

Future<void> _showAddReminderDialog(BuildContext context, WidgetRef ref) async {
  final titleController = TextEditingController(text: 'Zikir zamanı');
  TimeOfDay selectedTime = TimeOfDay.now();

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Hatırlatıcı ekle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
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
    },
  );

  if (shouldSave == true) {
    await ref
        .read(reminderRepositoryProvider)
        .addDailyReminder(
          title: titleController.text.trim().isEmpty
              ? 'Zikir zamanı'
              : titleController.text.trim(),
          body: 'Günlük zikrini tamamlamayı unutma.',
          hour: selectedTime.hour,
          minute: selectedTime.minute,
        );
  }

  titleController.dispose();
}
