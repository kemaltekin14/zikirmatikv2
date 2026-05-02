import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/settings/application/settings_controller.dart';

class ZikirmatikApp extends ConsumerWidget {
  const ZikirmatikApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider);
    final themeMode = settings.themeMode;

    return MaterialApp.router(
      title: 'Zikirmatik',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      builder: (context, child) {
        final media = MediaQuery.of(context);
        var textScale = media.textScaler.scale(1);
        if (settings.largeTextMode && textScale < 1.12) {
          textScale = 1.12;
        } else if (settings.easyReadMode && textScale < 1.06) {
          textScale = 1.06;
        }

        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
