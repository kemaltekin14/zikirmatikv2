import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firebase_push_service.dart';

const _notificationPromptPrimaryGreen = Color(0xFF13472F);
const _notificationPromptButtonGreen = Color(0xFF327653);
const _notificationPromptSurface = Color(0xFFFAFAF4);
const _notificationPromptMutedText = Color(0xFF69766E);
const _startupNotificationPromptSeenKey = 'notifications.startupPushPromptSeen';

Future<void> maybeShowStartupNotificationPermissionSheet({
  required BuildContext context,
}) async {
  if (await areFirebasePushNotificationsAllowed()) {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_startupNotificationPromptSeenKey) ?? false) {
    return;
  }

  if (!context.mounted) {
    return;
  }

  final shouldRequest = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _StartupNotificationPermissionSheet(),
  );

  await prefs.setBool(_startupNotificationPromptSeenKey, true);

  if (shouldRequest != true || !context.mounted) {
    return;
  }

  final granted = await requestFirebasePushNotificationPermission();
  if (!granted && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Bildirim izni kapalı kaldı. Dilersen daha sonra ayarlardan açabilirsin.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _StartupNotificationPermissionSheet extends StatelessWidget {
  const _StartupNotificationPermissionSheet();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).top -
        24;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(22, 18, 22, 18 + bottomInset),
        decoration: BoxDecoration(
          color: _notificationPromptSurface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9E0D6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE6EFE8),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: _notificationPromptPrimaryGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zikir vaktini kaçırma',
                            style: TextStyle(
                              color: _notificationPromptPrimaryGreen,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Günlük hedefini, hatırlatıcılarını ve önemli manevi notları zamanında iletebilmemiz için bildirim iznine ihtiyacımız var.',
                            style: TextStyle(
                              color: _notificationPromptMutedText,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _NotificationBenefitRow(
                  icon: Icons.schedule_rounded,
                  text: 'Seçtiğin vakitte nazik hatırlatmalar alırsın.',
                ),
                const SizedBox(height: 10),
                const _NotificationBenefitRow(
                  icon: Icons.flag_rounded,
                  text: 'Günlük hedefini unutmadan takip edebilirsin.',
                ),
                const SizedBox(height: 10),
                const _NotificationBenefitRow(
                  icon: Icons.tune_rounded,
                  text: 'İstediğin zaman bildirimleri kapatabilirsin.',
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.notifications_rounded, size: 19),
                  label: const Text('Bildirimleri aç'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _notificationPromptPrimaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Şimdi değil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBenefitRow extends StatelessWidget {
  const _NotificationBenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: _notificationPromptButtonGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _notificationPromptPrimaryGreen,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> ensureNotificationPermissionForReminder({
  required BuildContext context,
  required Future<bool> Function() areNotificationsAllowed,
  required Future<bool> Function() requestPermission,
}) async {
  if (await areNotificationsAllowed()) {
    return true;
  }

  if (!context.mounted) {
    return false;
  }

  final shouldRequest = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: _notificationPromptSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          Icons.notifications_active_rounded,
          color: _notificationPromptButtonGreen,
        ),
        title: const Text('Hatırlatma izni gerekli'),
        content: const Text(
          'Seçtiğin saat geldiğinde sana haber verebilmem için bildirim izni gerekiyor. '
          'İzin verirsen hatırlatıcın sadece planladığın vakitte çalışır.',
          style: TextStyle(
            color: _notificationPromptMutedText,
            height: 1.34,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Şimdi değil'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.notifications_rounded, size: 18),
            label: const Text('İzin ver'),
            style: FilledButton.styleFrom(
              backgroundColor: _notificationPromptPrimaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    },
  );

  if (shouldRequest != true || !context.mounted) {
    return false;
  }

  final granted = await requestPermission();
  if (!granted && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildirim izni açılmadan hatırlatıcı gönderemeyiz.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  return granted;
}
