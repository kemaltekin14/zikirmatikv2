import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../core/services/interaction_feedback_service.dart';
import '../../features/counter/application/counter_controller.dart';
import '../layout/proportional_layout.dart';

const _menuSurface = Color(0xFFFAF7EE);
const _menuSurfaceLight = Color(0xFFFAF7EE);
const _menuSurfaceWarm = Color(0xFFFAF7EE);
const _menuGreen = Color(0xFF13472F);
const _menuGreenSoft = Color(0xFF327653);
const _menuText = Color(0xFF17392B);
const _menuMuted = Color(0xFF6E7D73);
const _menuDivider = Color(0xFFDDE4D9);
const _wordmarkSuffixGreen = Color(0xFF828C6F);
const _logoAsset = 'assets/images/menu_logo.png';
const _bottomMotifAsset = 'assets/images/menu_bottom_motif.webp';
const _cupertinoDrawerCloseNavigationDelay = Duration(milliseconds: 280);

void openAppMenu(BuildContext context) {
  Scaffold.maybeOf(context)?.openDrawer();
}

class AppMenuDrawer extends ConsumerWidget {
  const AppMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final scale = proportionalLayoutScaleFor(screenWidth);
    final drawerWidth = math.min(screenWidth * 0.74, 294 * scale);
    final radius = 38 * scale;
    final currentPath = GoRouterState.of(context).uri.path;
    final counterState = ref.watch(counterControllerProvider);
    final bottomMotifHeight = 168 * scale;
    final motifBlendHeight = 82 * scale;
    final motifBlendLift = 10 * scale;

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      backgroundColor: Colors.transparent,
      shadowColor: _menuGreen.withValues(alpha: 0.20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(radius)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(radius)),
        child: Material(
          color: _menuSurface,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _menuSurfaceLight,
                        _menuSurface,
                        _menuSurfaceWarm.withValues(alpha: 0.96),
                      ],
                      stops: const [0.0, 0.58, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -18 * scale,
                right: -18 * scale,
                bottom: 0,
                height: bottomMotifHeight,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.54,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0x18FFFFFF),
                            Color(0xB8FFFFFF),
                            Color(0xFFFFFFFF),
                            Color(0xFFFFFFFF),
                          ],
                          stops: [0.0, 0.12, 0.38, 0.58, 1.0],
                        ).createShader(bounds);
                      },
                      child: Image.asset(
                        _bottomMotifAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomMotifHeight - motifBlendHeight,
                height: motifBlendHeight + motifBlendLift,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _menuSurfaceWarm.withValues(alpha: 0),
                          _menuSurfaceWarm.withValues(alpha: 0.48),
                          _menuSurface.withValues(alpha: 0.16),
                          _menuSurface.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.30, 0.62, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 226 * scale,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _menuSurface.withValues(alpha: 0),
                          _menuSurface.withValues(alpha: 0.20),
                          _menuSurface.withValues(alpha: 0.58),
                        ],
                        stops: const [0.0, 0.50, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    17 * scale,
                    14 * scale,
                    12 * scale,
                    17 * scale,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MenuBrandHeader(scale: scale),
                      SizedBox(height: 13 * scale),
                      _JourneyCard(
                        scale: scale,
                        state: counterState,
                        onTap: () {
                          ref
                              .read(interactionFeedbackServiceProvider)
                              .primaryAction();
                          unawaited(_navigateTo(context, AppRoutes.counter));
                        },
                      ),
                      SizedBox(height: 10 * scale),
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(vertical: 2 * scale),
                          itemCount: _menuItems.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 3 * scale),
                          itemBuilder: (context, index) {
                            final item = _menuItems[index];
                            return _MenuDestinationTile(
                              scale: scale,
                              item: item,
                              active: currentPath == item.route,
                              onTap: () {
                                ref
                                    .read(interactionFeedbackServiceProvider)
                                    .selection();
                                unawaited(_navigateTo(context, item.route));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuBrandHeader extends StatelessWidget {
  const _MenuBrandHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 60 * scale,
          child: Padding(
            padding: EdgeInsets.all(2 * scale),
            child: Image.asset(
              _logoAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        SizedBox(width: 11 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  text: TextSpan(
                    style: TextStyle(
                      color: _menuGreen,
                      fontFamily: 'EB Garamond',
                      fontSize: 28 * scale,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                    children: const [
                      TextSpan(text: 'Zikirmatik'),
                      TextSpan(
                        text: '.pro',
                        style: TextStyle(
                          color: _wordmarkSuffixGreen,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                'Zikirle huzur bul',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _menuMuted,
                  fontSize: 10.8 * scale,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.scale,
    required this.state,
    required this.onTap,
  });

  final double scale;
  final CounterState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = state.isInfinite ? 0.0 : state.progress;
    final progressLabel = state.isInfinite
        ? 'Sınırsız'
        : '%${(progress * 100).round()}';

    final borderRadius = BorderRadius.circular(22 * scale);

    return Semantics(
      button: true,
      label: 'Aktif zikir, ${state.activeDhikr.name}',
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: Colors.white.withValues(alpha: 0.54),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.82),
                  width: 0.8 * scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _menuGreen.withValues(alpha: 0.06),
                    blurRadius: 18 * scale,
                    offset: Offset(0, 9 * scale),
                  ),
                ],
              ),
              child: InkWell(
                key: const Key('menu.activeDhikrCard'),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    13 * scale,
                    10 * scale,
                    12 * scale,
                    10 * scale,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38 * scale,
                        height: 38 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _menuGreen.withValues(alpha: 0.10),
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          color: _menuGreen,
                          size: 20 * scale,
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Aktif zikir',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _menuText,
                                      fontSize: 12.8 * scale,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                Text(
                                  progressLabel,
                                  style: TextStyle(
                                    color: _menuGreenSoft,
                                    fontSize: state.isInfinite
                                        ? 10.2 * scale
                                        : 11.6 * scale,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              key: const Key('menu.activeDhikrName'),
                              state.activeDhikr.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _menuMuted,
                                fontSize: 10.8 * scale,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5 * scale,
                                backgroundColor: _menuDivider,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  _menuGreenSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuDestinationTile extends StatelessWidget {
  const _MenuDestinationTile({
    required this.scale,
    required this.item,
    required this.active,
    required this.onTap,
  });

  final double scale;
  final _MenuItemData item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18 * scale);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 42 * scale,
          padding: EdgeInsets.symmetric(horizontal: 12 * scale),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF1B5B3E), Color(0xFF347756)],
                  )
                : null,
            color: active ? null : Colors.transparent,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _menuGreen.withValues(alpha: 0.16),
                      blurRadius: 18 * scale,
                      offset: Offset(0, 8 * scale),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: active ? Colors.white : _menuMuted,
                size: 20.5 * scale,
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : _menuText,
                    fontSize: 13.6 * scale,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    height: 1.1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _navigateTo(
  BuildContext context,
  String route, {
  bool push = false,
}) async {
  final router = GoRouter.of(context);
  final currentPath = GoRouterState.of(context).uri.path;
  final shouldNavigate = currentPath != route;
  final scaffold = Scaffold.maybeOf(context);
  final navigationDelay = _drawerNavigationDelayFor(context);

  if (scaffold?.isDrawerOpen ?? false) {
    scaffold!.closeDrawer();
    if (shouldNavigate && navigationDelay > Duration.zero) {
      await Future<void>.delayed(navigationDelay);
    }
  } else {
    Navigator.of(context).pop();
    if (shouldNavigate && navigationDelay > Duration.zero) {
      await Future<void>.delayed(navigationDelay);
    }
  }

  if (!shouldNavigate) return;
  if (push || route != AppRoutes.dashboard) {
    router.push(route);
  } else {
    router.go(route);
  }
}

Duration _drawerNavigationDelayFor(BuildContext context) {
  final platform = Theme.of(context).platform;
  return switch (platform) {
    TargetPlatform.iOS ||
    TargetPlatform.macOS => _cupertinoDrawerCloseNavigationDelay,
    _ => Duration.zero,
  };
}

class _MenuItemData {
  const _MenuItemData({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

const _menuItems = [
  _MenuItemData(
    label: 'Ana Sayfa',
    icon: Icons.home_rounded,
    route: AppRoutes.dashboard,
  ),
  _MenuItemData(
    label: 'Zikir Kütüphanesi',
    icon: Icons.menu_book_rounded,
    route: AppRoutes.dhikrLibrary,
  ),
  _MenuItemData(
    label: 'Esma-ül Hüsna',
    icon: Icons.auto_awesome_rounded,
    route: AppRoutes.esma,
  ),
  _MenuItemData(
    label: 'Namaz Tesbihatı',
    icon: Icons.mosque_rounded,
    route: AppRoutes.namazTesbihati,
  ),
  _MenuItemData(
    label: 'Virdler',
    icon: Icons.repeat_rounded,
    route: AppRoutes.vird,
  ),
  _MenuItemData(
    label: 'Hatırlatıcılar',
    icon: Icons.event_note_rounded,
    route: AppRoutes.reminders,
  ),
  _MenuItemData(
    label: 'İstatistikler',
    icon: Icons.insights_rounded,
    route: AppRoutes.statistics,
  ),
  _MenuItemData(
    label: 'Ayarlar',
    icon: Icons.tune_rounded,
    route: AppRoutes.settings,
  ),
];
