import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment_provider.dart';
import '../../../core/monetization/monetization.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final env = ref.watch(appEnvironmentProvider);
    final entitlement = ref.watch(entitlementProvider);

    return AppScaffold(
      title: 'Ayarlar',
      child: ListView(
        children: [
          SwitchListTile(
            value: settings.vibrationEnabled,
            onChanged: (_) =>
                ref.read(settingsControllerProvider.notifier).toggleVibration(),
            title: const Text('Titreşim'),
          ),
          SwitchListTile(
            value: settings.soundEnabled,
            onChanged: (_) =>
                ref.read(settingsControllerProvider.notifier).toggleSound(),
            title: const Text('Ses'),
          ),
          SwitchListTile(
            value: settings.largeTextMode,
            onChanged: (_) =>
                ref.read(settingsControllerProvider.notifier).toggleLargeText(),
            title: const Text('Büyük metin modu'),
          ),
          SwitchListTile(
            value: settings.easyReadMode,
            onChanged: (_) =>
                ref.read(settingsControllerProvider.notifier).toggleEasyRead(),
            title: const Text('Kolay okuma modu'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Store kanalı'),
            subtitle: Text(env.storeChannel.name),
          ),
          ListTile(
            title: const Text('Monetization modu'),
            subtitle: Text(entitlement.mode.name),
          ),
          const ListTile(
            title: Text('Premium hazırlığı'),
            subtitle: Text(
              'İlk sürümde görünmez/no-op. Sonraki fazda store IAP adaptörleri açılacak.',
            ),
          ),
        ],
      ),
    );
  }
}
