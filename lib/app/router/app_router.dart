import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/counter/presentation/zikr_counter_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dhikr_library/presentation/dhikr_detail_screen.dart';
import '../../features/dhikr_library/presentation/dhikr_library_screen.dart';
import '../../features/esma/presentation/esma_screen.dart';
import '../../features/namaz_tesbihati/presentation/namaz_tesbihati_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/vird/presentation/vird_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/ios_edge_back_gesture.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRouteNames.splash,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRouteNames.dashboard,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/sayac',
        name: AppRouteNames.counter,
        pageBuilder: (context, state) => _counterPage(state),
      ),
      GoRoute(
        path: '/zikirler',
        name: AppRouteNames.dhikrLibrary,
        pageBuilder: (context, state) =>
            _platformPage(context, state, const DhikrLibraryScreen()),
      ),
      GoRoute(
        path: '/zikirler/:dhikrId',
        name: AppRouteNames.dhikrDetail,
        pageBuilder: (context, state) => _platformPage(
          context,
          state,
          DhikrDetailScreen(dhikrId: state.pathParameters['dhikrId'] ?? ''),
          addIosEdgeBackGesture: true,
        ),
      ),
      GoRoute(
        path: '/esma',
        name: AppRouteNames.esma,
        pageBuilder: (context, state) =>
            _platformPage(context, state, const EsmaScreen()),
      ),
      GoRoute(
        path: '/namaz-tesbihati',
        name: AppRouteNames.namazTesbihati,
        pageBuilder: (context, state) =>
            _platformPage(context, state, const NamazTesbihatiScreen()),
      ),
      GoRoute(
        path: '/vird',
        name: AppRouteNames.vird,
        pageBuilder: (context, state) =>
            _platformPage(context, state, const VirdScreen()),
      ),
      GoRoute(
        path: '/hatirlaticilar',
        name: AppRouteNames.reminders,
        pageBuilder: (context, state) => _platformPage(
          context,
          state,
          const RemindersScreen(),
          addIosEdgeBackGesture: true,
        ),
      ),
      GoRoute(
        path: '/istatistikler',
        name: AppRouteNames.statistics,
        pageBuilder: (context, state) => _platformPage(
          context,
          state,
          const StatisticsScreen(),
          addIosEdgeBackGesture: true,
        ),
      ),
      GoRoute(
        path: '/ayarlar',
        name: AppRouteNames.settings,
        pageBuilder: (context, state) => _platformPage(
          context,
          state,
          const SettingsScreen(),
          addIosEdgeBackGesture: true,
        ),
      ),
    ],
    errorBuilder: (context, state) => AppScaffold(
      title: 'Sayfa bulunamadi',
      child: Center(
        child: FilledButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Ana ekrana don'),
        ),
      ),
    ),
  );
});

Page<void> _counterPage(GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 480),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    child: const IosEdgeBackGesture(
      enableOnAllPlatforms: true,
      child: ZikrCounterScreen(),
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

Page<void> _platformPage(
  BuildContext context,
  GoRouterState state,
  Widget child, {
  bool addIosEdgeBackGesture = false,
}) {
  final platform = Theme.of(context).platform;
  final isCupertinoPlatform =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  if (!isCupertinoPlatform) {
    return MaterialPage<void>(key: state.pageKey, child: child);
  }

  return CupertinoPage<void>(
    key: state.pageKey,
    child: addIosEdgeBackGesture ? IosEdgeBackGesture(child: child) : child,
  );
}

class AppRouteNames {
  const AppRouteNames._();

  static const splash = 'splash';
  static const dashboard = 'dashboard';
  static const counter = 'counter';
  static const dhikrLibrary = 'dhikrLibrary';
  static const dhikrDetail = 'dhikrDetail';
  static const esma = 'esma';
  static const namazTesbihati = 'namazTesbihati';
  static const vird = 'vird';
  static const reminders = 'reminders';
  static const statistics = 'statistics';
  static const settings = 'settings';
}

class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const dashboard = '/';
  static const counter = '/sayac';
  static const dhikrLibrary = '/zikirler';
  static String dhikrDetail(String dhikrId) => '/zikirler/$dhikrId';
  static const esma = '/esma';
  static const namazTesbihati = '/namaz-tesbihati';
  static const vird = '/vird';
  static const reminders = '/hatirlaticilar';
  static const statistics = '/istatistikler';
  static const settings = '/ayarlar';
}
