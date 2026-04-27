import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/counter/presentation/counter_screen.dart';
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
        pageBuilder: (context, state) =>
            _platformPage(context, state, const CounterScreen()),
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
        pageBuilder: (context, state) =>
            _platformPage(context, state, const RemindersScreen()),
      ),
      GoRoute(
        path: '/istatistikler',
        name: AppRouteNames.statistics,
        pageBuilder: (context, state) =>
            _platformPage(context, state, const StatisticsScreen()),
      ),
      GoRoute(
        path: '/ayarlar',
        name: AppRouteNames.settings,
        pageBuilder: (context, state) =>
            _platformPage(context, state, const SettingsScreen()),
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

Page<void> _platformPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final platform = Theme.of(context).platform;
  final isCupertinoPlatform =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  if (!isCupertinoPlatform) {
    return MaterialPage<void>(
      key: state.pageKey,
      child: _EdgeSwipeBackPage(child: child),
    );
  }

  return CupertinoPage<void>(key: state.pageKey, child: child);
}

class _EdgeSwipeBackPage extends StatefulWidget {
  const _EdgeSwipeBackPage({required this.child});

  final Widget child;

  @override
  State<_EdgeSwipeBackPage> createState() => _EdgeSwipeBackPageState();
}

class _EdgeSwipeBackPageState extends State<_EdgeSwipeBackPage> {
  static const _edgeWidth = 28.0;
  static const _popDistance = 72.0;
  static const _popVelocity = 520.0;

  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: _edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _dragDistance = 0,
            onHorizontalDragUpdate: (details) {
              _dragDistance += details.primaryDelta ?? 0;
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              final shouldPop =
                  _dragDistance > _popDistance || velocity > _popVelocity;
              if (shouldPop && context.canPop()) {
                context.pop();
              }
              _dragDistance = 0;
            },
          ),
        ),
      ],
    );
  }
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
