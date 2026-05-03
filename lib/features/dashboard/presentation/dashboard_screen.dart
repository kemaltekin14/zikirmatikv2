import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router/app_router.dart';
import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/database_provider.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../counter/application/counter_controller.dart';
import '../../dhikr_library/application/dhikr_providers.dart';
import '../../dhikr_library/data/builtin_dhikrs.dart';
import '../../dhikr_library/domain/dhikr_item.dart';
import '../../dhikr_library/presentation/dhikr_detail_screen.dart';
import '../../esma/data/esma_data.dart';
import '../../esma/domain/esma_item.dart';
import '../../reminders/application/local_notification_service.dart';
import '../../reminders/application/reminder_providers.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';
import '../../../shared/widgets/app_time_picker.dart';
import '../../../shared/widgets/notification_permission_prompt.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _primaryGreen = Color(0xFF13472F);
const _buttonGreen = Color(0xFF327653);
const _mutedGreen = Color(0xFF7F9E88);
const _cardBackground = Color(0xFFFAFAF4);
const _dividerColor = Color(0xFFDDE4D9);
const _primaryText = Color(0xFF123B2B);
const _secondaryText = Color(0xFF69766E);
const _brandWordmarkGreen = Color(0xFF114B35);
const _brandWordmarkSuffixGreen = Color(0xFF828C6F);
const _goalGold = Color(0xFFD4BA75);
const _goalMint = Color(0xFFBEE1CB);

const _homeQuoteBaseHeight = 72.0;
const _homeQuoteBaseWidth = 224.0;
const _homeQuoteTextMaxScale = 1.14;
const _homeBottomNavBaseHeight = 76.0;
const _homeBottomNavBaseGap = 10.0;
const _homeBottomNavMaxSafeInset = 4.0;
const _homeScrollBottomSpacing = 12.0;
const _todayEsmaCardBackgroundAsset =
    'assets/images/today_esma_card_background.png';
const _statisticsDailyTargetKey = 'statistics.target.daily';
const _statisticsMonthlyTargetKey = 'statistics.target.monthly';
const _statisticsYearlyTargetKey = 'statistics.target.yearly';

double _homeBottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(
    safeBottom,
    _homeBottomNavMaxSafeInset * scale,
  );
  return _homeBottomNavBaseGap * scale + visualSafeInset;
}

EsmaItem _todayEsmaItem(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(2024);
  final dayIndex = today.difference(startDay).inDays;
  return esmaItems[dayIndex % esmaItems.length];
}

Duration _delayUntilNextLocalDay(DateTime now) {
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  return tomorrow.difference(now) + const Duration(seconds: 1);
}

final _todayEsmaProvider = StreamProvider.autoDispose<EsmaItem>((ref) {
  final controller = StreamController<EsmaItem>();
  Timer? timer;

  void publishToday() {
    final now = DateTime.now();
    controller.add(_todayEsmaItem(now));
    timer?.cancel();
    timer = Timer(_delayUntilNextLocalDay(now), publishToday);
  }

  publishToday();

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.showStartupNotificationPrompt = true});

  final bool showStartupNotificationPrompt;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.showStartupNotificationPrompt) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) {
        return;
      }
      await maybeShowStartupNotificationPermissionSheet(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final scale = proportionalLayoutScaleFor(screenWidth);
    final contentWidth = math.min(screenWidth, appLayoutBaselineWidth * scale);
    final contentLeft = (screenWidth - contentWidth) / 2;
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom;
    final menuTop = safeTop + 4 * scale;
    final menuLeft = contentLeft + 20 * scale;
    final menuSize = 35 * scale;
    final menuIconSize = 20 * scale;
    final quoteHeight = _homeQuoteBaseHeight * scale;
    final contentLift = 52 * scale;
    final contentTop =
        safeTop + 95 * scale + quoteHeight + 18 * scale - contentLift;
    final bottomNavHeight = _homeBottomNavBaseHeight * scale;
    final bottomNavOffset = _homeBottomNavBottomOffset(safeBottom, scale);
    final bottomNavReservedHeight = bottomNavHeight + bottomNavOffset;
    final scrollBottomPadding = _homeScrollBottomSpacing * scale;

    final textScale = media.textScaler.scale(1).clamp(1.0, 1.14).toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _pageBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          backgroundColor: _pageBackground,
          extendBody: true,
          drawer: const AppMenuDrawer(),
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: _pageBackground)),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: bottomNavReservedHeight,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: scrollBottomPadding),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      MosqueHeroLayer(
                        scale: scale,
                        contentWidth: contentWidth,
                        menuLeft: menuLeft,
                        menuSize: menuSize,
                        quoteHeight: quoteHeight,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: contentTop),
                        child: Center(
                          child: SizedBox(
                            width: contentWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18 * scale,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TodayZikrCard(scale: scale),
                                      ),
                                      SizedBox(width: 14 * scale),
                                      Expanded(
                                        child: StartZikrCard(scale: scale),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16 * scale),
                                ContinueZikrCard(scale: scale),
                                SizedBox(height: 14 * scale),
                                CategoryZikrSection(scale: scale),
                              ],
                            ),
                          ),
                        ),
                      ),
                      HeaderActions(
                        top: menuTop,
                        left: menuLeft,
                        size: menuSize,
                        iconSize: menuIconSize,
                        scale: scale,
                      ),
                    ],
                  ),
                ),
              ),
              HomeBottomNav(scale: scale, contentWidth: contentWidth),
            ],
          ),
        ),
      ),
    );
  }
}

class MosqueHeroLayer extends StatelessWidget {
  const MosqueHeroLayer({
    super.key,
    required this.scale,
    required this.contentWidth,
    required this.menuLeft,
    required this.menuSize,
    required this.quoteHeight,
  });

  final double scale;
  final double contentWidth;
  final double menuLeft;
  final double menuSize;
  final double quoteHeight;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final heroHeight = math.min(screenHeight * 0.44, 360 * scale);
    final safeTop = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: heroHeight,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroWidth = constraints.maxWidth;
            final heroContentWidth = math.min(heroWidth, contentWidth);
            final heroContentLeft = (heroWidth - heroContentWidth) / 2;
            final mosqueWidth = heroWidth * 1.12;
            final menuLeftInContent = menuLeft - heroContentLeft;
            final quoteLeft = menuLeftInContent;
            final availableQuoteWidth = math.max(
              0.0,
              heroContentWidth - quoteLeft - 18 * scale,
            );
            final quoteWidth = math.min(
              _homeQuoteBaseWidth * scale,
              availableQuoteWidth,
            );
            final quoteTop = safeTop + 4 * scale + menuSize + 12 * scale;

            return Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: OverflowBox(
                    alignment: Alignment.topRight,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: SizedBox(
                      width: mosqueWidth,
                      child: Image.asset(
                        'assets/images/home_mosque.webp',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: quoteTop,
                  left: heroContentLeft + quoteLeft,
                  width: quoteWidth,
                  height: quoteHeight,
                  child: CompactHeroQuoteCard(scale: scale),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class HeaderActions extends StatelessWidget {
  const HeaderActions({
    super.key,
    required this.top,
    required this.left,
    required this.size,
    required this.iconSize,
    required this.scale,
  });

  final double top;
  final double left;
  final double size;
  final double iconSize;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CircleActionButton(
            size: size,
            icon: Icons.menu_rounded,
            iconSize: iconSize,
            onPressed: () => openAppMenu(context),
          ),
          SizedBox(width: 14 * scale),
          DashboardBrandWordmark(scale: scale, height: size),
        ],
      ),
    );
  }
}

class DashboardBrandWordmark extends StatelessWidget {
  const DashboardBrandWordmark({
    super.key,
    required this.scale,
    required this.height,
  });

  final double scale;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160 * scale,
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: RichText(
          maxLines: 1,
          textAlign: TextAlign.left,
          textScaler: TextScaler.noScaling,
          text: TextSpan(
            style: TextStyle(
              color: _brandWordmarkGreen,
              fontFamily: 'EB Garamond',
              fontSize: 45 * scale,
              fontWeight: FontWeight.w500,
              height: 59 / 45,
            ),
            children: const [
              TextSpan(text: 'Zikirmatik'),
              TextSpan(
                text: '.pro',
                style: TextStyle(
                  color: _brandWordmarkSuffixGreen,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.onPressed,
  });

  final double size;
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _cardBackground.withValues(alpha: 0.96),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        enableFeedback: false,
        onPressed: onPressed,
        icon: Icon(icon, color: _primaryGreen, size: iconSize),
      ),
    );
  }
}

class CompactHeroQuoteCard extends StatelessWidget {
  const CompactHeroQuoteCard({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22 * scale);
    final textScale = scale
        .clamp(appLayoutMinScale, _homeQuoteTextMaxScale)
        .toDouble();
    final mainQuoteSize = 11.8 * textScale;
    final authorSize = 10.2 * textScale;
    final textMaxWidth = 190 * scale;

    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.fromLTRB(9 * scale, 8 * scale, 8 * scale, 8 * scale),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _cardBackground.withValues(alpha: 0.66),
            _cardBackground.withValues(alpha: 0.52),
            _cardBackground.withValues(alpha: 0.22),
            _cardBackground.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.46, 0.78, 1.0],
        ),
      ),
      child: SizedBox(
        width: textMaxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unutma, zikre devam etmek\nkalbe nur, hayata huzur katar.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _primaryText,
                fontSize: mainQuoteSize,
                fontWeight: FontWeight.w500,
                height: 1.26,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 3 * scale),
            Text(
              'İbn Kayyım',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _primaryText.withValues(alpha: 0.88),
                fontSize: authorSize,
                fontWeight: FontWeight.w500,
                height: 1.12,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayZikrCard extends ConsumerWidget {
  const TodayZikrCard({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEsma =
        ref.watch(_todayEsmaProvider).value ?? _todayEsmaItem(DateTime.now());

    return _TodayEsmaCardSurface(
      height: 238 * scale,
      radius: 20 * scale,
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        14 * scale,
        15 * scale,
        15 * scale,
      ),
      child: Column(
        children: [
          Text(
            'Günün Esması',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryText,
              fontSize: 14.8 * scale,
              fontWeight: FontWeight.w600,
              height: 1.05,
            ),
          ),
          SizedBox(height: 8 * scale),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 130 * scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EsmaSeal(size: 88 * scale, scale: scale),
                      SizedBox(height: 7 * scale),
                      Text(
                        todayEsma.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 16.4 * scale,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        todayEsma.meaning,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _primaryText,
                          fontSize: 11.2 * scale,
                          fontWeight: FontWeight.w500,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _TodayPremiumDivider(scale: scale),
          _TodayStartButton(
            key: const Key('home.todayEsma'),
            scale: scale,
            label: 'Esmayı İncele',
            icon: Icons.auto_awesome_rounded,
            onPressed: () {
              final feedback = ref.read(interactionFeedbackServiceProvider);
              context.push('${AppRoutes.esma}?number=${todayEsma.number}');
              feedback.selection();
            },
          ),
        ],
      ),
    );
  }
}

class _TodayEsmaCardSurface extends StatelessWidget {
  const _TodayEsmaCardSurface({
    required this.height,
    required this.radius,
    required this.padding,
    required this.child,
  });

  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          ..._softShadow,
          BoxShadow(
            color: const Color(0xFFC8A85C).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: const Color(0xFFFFFCF3),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.58),
              width: 0.6,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, -3 * (height / 238)),
                child: Transform.scale(
                  scaleX: 1.08,
                  scaleY: 1.05,
                  child: Image.asset(
                    _todayEsmaCardBackgroundAsset,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.30),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.36, 0.84],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      _primaryGreen.withValues(alpha: 0.030),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(1.6 * (height / 238)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      math.max(0, radius - 1.6 * (height / 238)),
                    ),
                    border: Border.all(
                      color: const Color(0xFFD4BA75).withValues(alpha: 0.24),
                      width: 0.7,
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class EsmaSeal extends StatelessWidget {
  const EsmaSeal({super.key, required this.size, required this.scale});

  final double size;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size * 0.92,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD9C48C).withValues(alpha: 0.08),
                    const Color(0xFFDDE9D8).withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _EsmaSealPainter(strokeWidth: 3 * scale),
          ),
          Text(
            'الوكيل',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 27 * scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EsmaSealPainter extends CustomPainter {
  const _EsmaSealPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.47;

    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.34),
          const Color(0xFFE6EDE3).withValues(alpha: 0.50),
          const Color(0xFFDCE8D8).withValues(alpha: 0.20),
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.86))
      ..style = PaintingStyle.fill;

    final path = Path();
    const points = 24;
    for (var i = 0; i < points; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / points);
      final pointRadius = radius * (i.isEven ? 0.92 : 0.80);
      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final outlinePaint = Paint()
      ..color = const Color(0xFFC4D4C0).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final outlineHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, strokeWidth * 0.28)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius * 0.76, fillPaint);
    canvas.drawPath(path, outlinePaint);
    canvas.drawPath(path, outlineHighlightPaint);
  }

  @override
  bool shouldRepaint(covariant _EsmaSealPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth;
  }
}

class _TodayPremiumDivider extends StatelessWidget {
  const _TodayPremiumDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    const sand = Color(0xFFD3BA7D);

    return SizedBox(
      height: 7 * scale,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24 * scale),
        child: Row(
          children: [
            Expanded(
              child: _TodayDividerLine(
                begin: Colors.transparent,
                end: sand.withValues(alpha: 0.30),
              ),
            ),
            SizedBox(width: 4 * scale),
            Container(
              width: 2.8 * scale,
              height: 2.8 * scale,
              decoration: BoxDecoration(
                color: sand.withValues(alpha: 0.40),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4 * scale),
            Expanded(
              child: _TodayDividerLine(
                begin: sand.withValues(alpha: 0.30),
                end: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayDividerLine extends StatelessWidget {
  const _TodayDividerLine({required this.begin, required this.end});

  final Color begin;
  final Color end;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.7,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [begin, end])),
    );
  }
}

class _TodayStartButton extends StatelessWidget {
  const _TodayStartButton({
    super.key,
    required this.scale,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final double scale;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(30 * scale);

    return _PressedScale(
      child: Container(
        width: double.infinity,
        height: 42 * scale,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.075),
              blurRadius: 12 * scale,
              offset: Offset(0, 5 * scale),
            ),
            BoxShadow(
              color: const Color(0xFFD3BA7D).withValues(alpha: 0.06),
              blurRadius: 6 * scale,
              offset: Offset(0, 1 * scale),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEAF1E5), Color(0xFFE5EFE1), Color(0xFFEAF1E5)],
            ),
            border: Border.all(
              color: const Color(0xFFD3BA7D).withValues(alpha: 0.34),
              width: 0.8 * scale,
            ),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: borderRadius,
                splashColor: _primaryGreen.withValues(alpha: 0.08),
                highlightColor: _primaryGreen.withValues(alpha: 0.06),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.white.withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                color: _primaryGreen,
                                size: 18 * scale,
                              ),
                              SizedBox(width: 6 * scale),
                              Text(
                                label,
                                style: TextStyle(
                                  color: _primaryGreen,
                                  fontSize: 13.5 * scale,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StartZikrCard extends ConsumerWidget {
  const StartZikrCard({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SoftCard(
      height: 238 * scale,
      radius: 20 * scale,
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        14 * scale,
        15 * scale,
        15 * scale,
      ),
      child: Column(
        children: [
          Text(
            'Zikir Kütüphanesi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryText,
              fontSize: 14.8 * scale,
              fontWeight: FontWeight.w500,
              height: 1.05,
            ),
          ),
          SizedBox(height: 10 * scale),
          BookIllustration(size: 80 * scale),
          SizedBox(height: 7 * scale),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Kütüphaneden seç,\nhedefini belirle ve\nyeni zikrine başla.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 11.1 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.34,
                  ),
                ),
              ),
            ),
          ),
          _PillButton(
            key: const Key('home.chooseDhikr'),
            scale: scale,
            label: 'Zikir Seç',
            icon: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 12 * scale,
            ),
            trailingIcon: Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 18 * scale,
            ),
            onPressed: () {
              final feedback = ref.read(interactionFeedbackServiceProvider);
              context.push(AppRoutes.dhikrLibrary);
              feedback.primaryAction();
            },
          ),
        ],
      ),
    );
  }
}

class CircularZikrProgress extends StatelessWidget {
  const CircularZikrProgress({
    super.key,
    required this.progress,
    required this.size,
    required this.strokeWidth,
    this.center,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _CircularZikrProgressPainter(
              progress: progress,
              strokeWidth: strokeWidth,
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _CircularZikrProgressPainter extends CustomPainter {
  const _CircularZikrProgressPainter({
    required this.progress,
    required this.strokeWidth,
  });

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = const Color(0xFFE3E9DF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = _buttonGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularZikrProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class BookIllustration extends StatelessWidget {
  const BookIllustration({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFE4EADF),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: size),
          ),
          Transform.translate(
            offset: Offset(0, size * 0.07),
            child: OverflowBox(
              alignment: Alignment.center,
              minWidth: 0,
              maxWidth: double.infinity,
              minHeight: 0,
              maxHeight: double.infinity,
              child: SizedBox(
                width: size * 1.45,
                child: Image.asset(
                  'assets/images/home_book.png',
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StartZikrIllustration extends StatelessWidget {
  const StartZikrIllustration({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE4EADF),
          shape: BoxShape.circle,
        ),
        child: CustomPaint(painter: _StartZikrIllustrationPainter()),
      ),
    );
  }
}

class _StartZikrIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final coverPaint = Paint()..color = _buttonGreen;
    final pagePaint = Paint()..color = const Color(0xFFFFF8DD);
    final pageShadow = Paint()..color = const Color(0xFFE5DCBB);
    final beadPaint = Paint()
      ..color = _primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;

    final leftCover = Path()
      ..moveTo(w * 0.26, h * 0.54)
      ..lineTo(w * 0.31, h * 0.30)
      ..quadraticBezierTo(w * 0.43, h * 0.34, w * 0.50, h * 0.44)
      ..lineTo(w * 0.50, h * 0.69)
      ..quadraticBezierTo(w * 0.39, h * 0.58, w * 0.26, h * 0.54);

    final rightCover = Path()
      ..moveTo(w * 0.50, h * 0.44)
      ..quadraticBezierTo(w * 0.62, h * 0.34, w * 0.74, h * 0.30)
      ..lineTo(w * 0.80, h * 0.55)
      ..quadraticBezierTo(w * 0.62, h * 0.58, w * 0.50, h * 0.69)
      ..close();

    final leftPage = Path()
      ..moveTo(w * 0.32, h * 0.31)
      ..quadraticBezierTo(w * 0.43, h * 0.34, w * 0.50, h * 0.44)
      ..lineTo(w * 0.50, h * 0.63)
      ..quadraticBezierTo(w * 0.41, h * 0.54, w * 0.33, h * 0.51)
      ..close();

    final rightPage = Path()
      ..moveTo(w * 0.50, h * 0.44)
      ..quadraticBezierTo(w * 0.61, h * 0.34, w * 0.72, h * 0.31)
      ..lineTo(w * 0.75, h * 0.52)
      ..quadraticBezierTo(w * 0.62, h * 0.55, w * 0.50, h * 0.63)
      ..close();

    canvas.drawPath(leftCover, coverPaint);
    canvas.drawPath(rightCover, coverPaint);
    canvas.drawPath(leftPage, pagePaint);
    canvas.drawPath(rightPage, pagePaint);
    canvas.drawLine(
      Offset(w * 0.50, h * 0.43),
      Offset(w * 0.50, h * 0.65),
      pageShadow,
    );

    final beadsPath = Path()
      ..moveTo(w * 0.68, h * 0.61)
      ..cubicTo(w * 0.91, h * 0.56, w * 0.90, h * 0.83, w * 0.69, h * 0.79);
    canvas.drawPath(beadsPath, beadPaint);

    final beadFill = Paint()..color = _primaryGreen;
    for (final point in [
      Offset(w * 0.70, h * 0.62),
      Offset(w * 0.78, h * 0.62),
      Offset(w * 0.84, h * 0.68),
      Offset(w * 0.84, h * 0.76),
      Offset(w * 0.77, h * 0.80),
      Offset(w * 0.69, h * 0.78),
    ]) {
      canvas.drawCircle(point, w * 0.026, beadFill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PressedScale extends StatefulWidget {
  const _PressedScale({required this.child});

  final Widget child;

  @override
  State<_PressedScale> createState() => _PressedScaleState();
}

class _PressedScaleState extends State<_PressedScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    super.key,
    required this.scale,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
  });

  final double scale;
  final String label;
  final VoidCallback onPressed;
  final Widget? icon;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return _PressedScale(
      child: SizedBox(
        width: double.infinity,
        height: 42 * scale,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _buttonGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30 * scale),
            ),
            textStyle: TextStyle(
              fontSize: 13.9 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: icon == null && trailingIcon == null
                ? Text(label)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        SizedBox(
                          width: 20 * scale,
                          height: 20 * scale,
                          child: icon!,
                        ),
                        SizedBox(width: 8 * scale),
                      ],
                      Text(label),
                      if (trailingIcon != null) ...[
                        SizedBox(width: 9 * scale),
                        SizedBox(
                          width: 18 * scale,
                          height: 18 * scale,
                          child: trailingIcon!,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class BeadsIcon extends StatelessWidget {
  const BeadsIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BeadsIconPainter(color),
    );
  }
}

class _BeadsIconPainter extends CustomPainter {
  const _BeadsIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    final beadPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width * 0.26, size.height * 0.88)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.30,
        size.width * 0.82,
        size.height * 0.36,
        size.width * 0.70,
        size.height * 0.66,
      );
    canvas.drawPath(path, paint);
    for (final point in [
      Offset(size.width * 0.42, size.height * 0.34),
      Offset(size.width * 0.54, size.height * 0.30),
      Offset(size.width * 0.66, size.height * 0.34),
      Offset(size.width * 0.75, size.height * 0.44),
      Offset(size.width * 0.76, size.height * 0.57),
    ]) {
      canvas.drawCircle(point, size.width * 0.045, beadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BeadsIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class ContinueZikrCard extends ConsumerWidget {
  const ContinueZikrCard({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storedHistoryEntries = ref
        .watch(_dashboardHistoryProvider)
        .maybeWhen(
          data: (entries) => entries,
          orElse: () => const <_HistoryEntry>[],
        );
    final historyEntries = _historyEntriesWithActiveCounter(
      storedHistoryEntries,
      ref.watch(counterControllerProvider),
    );
    final visibleEntries = historyEntries.take(3).toList();
    final feedback = ref.read(interactionFeedbackServiceProvider);

    void openHistoryEntry(_HistoryEntry entry) {
      final dhikrs = ref
          .read(dhikrItemsProvider)
          .maybeWhen(data: (items) => items, orElse: () => builtinDhikrs);
      final dhikr =
          _dhikrById(dhikrs, entry.dhikrId) ??
          DhikrItem(
            id: entry.dhikrId,
            name: entry.title,
            category: 'Geçmiş',
            defaultTarget: entry.target <= 0 ? 33 : entry.target,
          );

      ref
          .read(counterControllerProvider.notifier)
          .startDhikr(
            dhikr,
            target: entry.target,
            initialCount: entry.completed ? 0 : entry.count,
            sessionId: entry.completed ? null : entry.sessionId,
          );
      context.push(AppRoutes.counter);
      feedback.primaryAction();
    }

    void showAllHistory() {
      feedback.selection();
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.18),
        builder: (sheetContext) {
          return _HistorySheet(
            scale: scale,
            entries: historyEntries,
            onEntryTap: (entry) {
              Navigator.of(sheetContext).pop();
              openHistoryEntry(entry);
            },
          );
        },
      );
    }

    return _SectionCard(
      scale: scale,
      height: 170 * scale,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: _secondaryText,
                size: 24 * scale,
              ),
              SizedBox(width: 11 * scale),
              Expanded(
                child: Text(
                  'Geçmiş',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 16.6 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (historyEntries.isNotEmpty)
                _HistorySeeAllButton(scale: scale, onTap: showAllHistory),
            ],
          ),
          SizedBox(height: 7 * scale),
          if (visibleEntries.isEmpty)
            _HistoryEmptyState(scale: scale)
          else
            for (var index = 0; index < visibleEntries.length; index++)
              _HistoryRow(
                scale: scale,
                entry: visibleEntries[index],
                showDivider: index != visibleEntries.length - 1,
                onTap: () => openHistoryEntry(visibleEntries[index]),
              ),
        ],
      ),
    );
  }
}

final _dashboardHistoryProvider =
    StreamProvider.autoDispose<List<_HistoryEntry>>((ref) {
      return ref
          .watch(appDatabaseProvider)
          .watchCounterSessions()
          .map(_historyEntriesFromSessions);
    });

class _HistoryEntry {
  const _HistoryEntry({
    required this.sessionId,
    required this.dhikrId,
    required this.title,
    required this.count,
    required this.target,
    required this.completed,
    required this.updatedAt,
    this.active = false,
    this.paused = false,
  });

  final String sessionId;
  final String dhikrId;
  final String title;
  final int count;
  final int target;
  final bool completed;
  final DateTime updatedAt;
  final bool active;
  final bool paused;

  double get progress {
    if (target <= 0) return 0;
    return (count / target).clamp(0, 1).toDouble();
  }

  String get countLabel => target <= 0 ? '$count' : '$count / $target';
  String get statusLabel => completed ? 'Tamamlandı' : 'Devam ediyor';
}

List<_HistoryEntry> _historyEntriesFromSessions(List<CounterSession> sessions) {
  final entries = [
    for (final session in sessions)
      if (session.count > 0)
        _HistoryEntry(
          sessionId: session.id,
          dhikrId: session.dhikrId,
          title: session.dhikrName,
          count: session.target > 0 && session.count >= session.target
              ? session.target
              : session.count,
          target: session.target,
          completed:
              session.status == 'completed' ||
              (session.target > 0 && session.count >= session.target),
          updatedAt: session.completedAt ?? session.updatedAt,
        ),
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  return entries;
}

List<_HistoryEntry> _historyEntriesWithActiveCounter(
  List<_HistoryEntry> entries,
  CounterState counter,
) {
  if (counter.count <= 0) return entries;

  final activeEntry = _HistoryEntry(
    sessionId: counter.sessionId,
    dhikrId: counter.activeDhikr.id,
    title: counter.activeDhikr.name,
    count: counter.count,
    target: counter.target,
    completed: !counter.isInfinite && counter.count >= counter.target,
    updatedAt: DateTime.now(),
    active: true,
  );
  final activeAlreadyStoredAsCompleted =
      activeEntry.completed &&
      entries.any(
        (entry) =>
            entry.completed &&
            entry.sessionId == activeEntry.sessionId &&
            entry.dhikrId == activeEntry.dhikrId &&
            entry.count == activeEntry.count &&
            entry.target == activeEntry.target,
      );

  final mergedEntries = [
    if (!activeAlreadyStoredAsCompleted) activeEntry,
    for (final entry in entries)
      if (!(!activeAlreadyStoredAsCompleted &&
          entry.sessionId == activeEntry.sessionId &&
          !entry.completed))
        entry,
  ];

  return [
    for (final entry in mergedEntries)
      if (entry.active || entry.completed)
        entry
      else
        _HistoryEntry(
          sessionId: entry.sessionId,
          dhikrId: entry.dhikrId,
          title: entry.title,
          count: entry.count,
          target: entry.target,
          completed: entry.completed,
          updatedAt: entry.updatedAt,
          paused: true,
        ),
  ];
}

_HistoryEntry? _ongoingEntryFromCounter(CounterState counter) {
  if (counter.count <= 0) return null;
  if (!counter.isInfinite && counter.count >= counter.target) return null;

  return _HistoryEntry(
    sessionId: counter.sessionId,
    dhikrId: counter.activeDhikr.id,
    title: counter.activeDhikr.name,
    count: counter.count,
    target: counter.target,
    completed: false,
    updatedAt: DateTime.now(),
    active: true,
  );
}

_HistoryEntry? _latestOngoingHistoryEntry(List<_HistoryEntry> entries) {
  final ongoingEntries = entries.where(_isOngoingHistoryEntry).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return ongoingEntries.isEmpty ? null : ongoingEntries.first;
}

bool _isOngoingHistoryEntry(_HistoryEntry entry) {
  if (entry.completed || entry.count <= 0) return false;
  return entry.target <= 0 || entry.count < entry.target;
}

DhikrItem _defaultQuickStartDhikr(List<DhikrItem> dhikrs) {
  return _dhikrById(dhikrs, 'estagfirullah') ??
      _dhikrById(builtinDhikrs, 'estagfirullah') ??
      builtinDhikrs.first;
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _primaryGreen.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(18 * scale),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.64),
            width: 0.7 * scale,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 11 * scale,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _buttonGreen.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 36 * scale,
                  child: Icon(
                    Icons.spa_rounded,
                    color: _primaryGreen,
                    size: 18 * scale,
                  ),
                ),
              ),
              SizedBox(width: 11 * scale),
              Expanded(
                child: Text(
                  'Henüz gerçek zikir kaydı yok.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 11.2 * scale,
                    fontWeight: FontWeight.w700,
                    height: 1.18,
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

class _HistorySeeAllButton extends StatelessWidget {
  const _HistorySeeAllButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
              width: 0.6 * scale,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 5 * scale,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tümü',
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 11.3 * scale,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                SizedBox(width: 2 * scale),
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: _primaryGreen,
                  size: 16 * scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  const _HistorySheet({
    required this.scale,
    required this.entries,
    required this.onEntryTap,
  });

  final double scale;
  final List<_HistoryEntry> entries;
  final ValueChanged<_HistoryEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetMaxHeight = media.size.height * 0.62;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          0,
          16 * scale,
          14 * scale + media.padding.bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sheetMaxHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _cardBackground.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(26 * scale),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.76),
                  width: 0.7 * scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 34 * scale,
                    offset: Offset(0, 16 * scale),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16 * scale,
                  10 * scale,
                  14 * scale,
                  12 * scale,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38 * scale,
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: _dividerColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: _secondaryText,
                          size: 22 * scale,
                        ),
                        SizedBox(width: 9 * scale),
                        Expanded(
                          child: Text(
                            'Geçmiş',
                            style: TextStyle(
                              color: _primaryText,
                              fontSize: 17 * scale,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                        _HistorySheetCloseButton(scale: scale),
                      ],
                    ),
                    SizedBox(height: 8 * scale),
                    Flexible(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          return _HistoryRow(
                            scale: scale,
                            entry: entries[index],
                            showDivider: index != entries.length - 1,
                            onTap: () => onEntryTap(entries[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistorySheetCloseButton extends StatelessWidget {
  const _HistorySheetCloseButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 30 * scale,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: 'Kapat',
        icon: Icon(
          Icons.close_rounded,
          color: _secondaryText,
          size: 20 * scale,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.scale,
    required this.entry,
    required this.onTap,
    this.showDivider = true,
  });

  final double scale;
  final _HistoryEntry entry;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final accent = entry.completed
        ? const Color(0xFFB99A55)
        : entry.paused
        ? _secondaryText
        : _buttonGreen;
    final statusLabel = _historyStatusLabel(entry);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14 * scale),
        onTap: onTap,
        child: SizedBox(
          height: 34 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: showDivider
                  ? Border(
                      bottom: BorderSide(
                        color: _dividerColor.withValues(alpha: 0.84),
                        width: 0.8 * scale,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                _HistoryStatusMark(
                  scale: scale,
                  completed: entry.completed,
                  paused: entry.paused,
                  accent: accent,
                ),
                SizedBox(width: 9 * scale),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _primaryText,
                                fontSize: 13.1 * scale,
                                fontWeight: FontWeight.w600,
                                height: 1.05,
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            entry.countLabel,
                            style: TextStyle(
                              color: _primaryText.withValues(alpha: 0.88),
                              fontSize: 12.0 * scale,
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.5 * scale),
                      Row(
                        children: [
                          Expanded(
                            child: _HistoryProgressStrip(
                              scale: scale,
                              progress: entry.progress,
                              accent: accent,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10.1 * scale,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 5 * scale),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _secondaryText.withValues(alpha: 0.64),
                  size: 18 * scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryStatusMark extends StatelessWidget {
  const _HistoryStatusMark({
    required this.scale,
    required this.completed,
    required this.paused,
    required this.accent,
  });

  final double scale;
  final bool completed;
  final bool paused;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: completed ? 0.15 : 0.10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.76),
          width: 0.7 * scale,
        ),
      ),
      child: SizedBox.square(
        dimension: 24 * scale,
        child: Icon(
          completed
              ? Icons.check_rounded
              : paused
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          color: accent,
          size: 15 * scale,
        ),
      ),
    );
  }
}

String _historyStatusLabel(_HistoryEntry entry) {
  if (entry.completed) return entry.statusLabel;
  if (entry.active && entry.count <= 0) return 'Başlamadı';
  if (entry.paused) return 'Ara verildi';
  return entry.statusLabel;
}

class _HistoryProgressStrip extends StatelessWidget {
  const _HistoryProgressStrip({
    required this.scale,
    required this.progress,
    required this.accent,
  });

  final double scale;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 3.4 * scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: const Color(0xFFE3E9DF)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.72), accent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryZikrSection extends ConsumerWidget {
  const CategoryZikrSection({super.key, required this.scale});

  final double scale;

  static const _items = [
    _CategoryItem(
      label: 'Rızık &\nBereket',
      title: 'Rızık & Bereket',
      icon: Icons.eco_rounded,
      description: 'Temiz rızık, kapıların açılması ve genişlik niyeti.',
      esmaNumbers: [16, 17, 18, 21, 39, 42, 45, 88, 89],
      dhikrIds: [
        'allahumme-ilmen-rizqan-amalan',
        'rabbena-atina',
        'la-havle',
        'la-ilahe-illallah-vahdehu',
      ],
    ),
    _CategoryItem(
      label: 'Şifa &\nSağlık',
      title: 'Şifa & Sağlık',
      icon: Icons.health_and_safety_rounded,
      description: 'Afiyet, iyileşme ve kalbin güçlenmesi niyeti.',
      esmaNumbers: [1, 2, 5, 30, 39, 55, 62, 63, 92],
      dhikrIds: [
        'allahumme-rabben-nas-ishfi',
        'eselullahal-azim-yashfik',
        'ya-hayyu-ya-kayyum',
      ],
    ),
    _CategoryItem(
      label: 'Huzur &\nİç Sükun',
      title: 'Huzur & İç Sükun',
      icon: Icons.spa_rounded,
      description: 'Kalbin yatışması, tevekkül ve iç ferahlık niyeti.',
      esmaNumbers: [4, 5, 32, 52, 55, 62, 63, 68, 93, 96, 99],
      dhikrIds: [
        'la-havle',
        'hasbiyallah',
        'ya-hayyu-ya-kayyum',
        'subhanallahil-azim',
      ],
    ),
    _CategoryItem(
      label: 'Şükran &\nHamd',
      title: 'Şükran & Hamd',
      icon: Icons.volunteer_activism_rounded,
      description: 'Nimeti hatırlama, hamd ve tesbih niyeti.',
      esmaNumbers: [35, 42, 56, 79, 83, 85],
      dhikrIds: [
        'elhamdulillah',
        'subhanallahi-ve-bihamdihi',
        'subhanallahi-bihamdihi-adede-halkihi',
        'subhanallahil-azim',
        'la-ilahe-illallah-vahdehu',
      ],
    ),
    _CategoryItem(
      label: 'İlişkiler &\nSevgi',
      title: 'İlişkiler & Sevgi',
      icon: Icons.favorite_rounded,
      description: 'Merhamet, muhabbet, aile huzuru ve gönül birliği niyeti.',
      esmaNumbers: [1, 2, 30, 32, 47, 55, 79, 83, 87],
      dhikrIds: [
        'rabbena-hablana-min-azwajina',
        'allahumme-salli',
        'rabbigfir-li-ve-tub-aleyye',
      ],
    ),
    _CategoryItem(
      label: 'Tövbe &\nMağfiret',
      title: 'Tövbe & Mağfiret',
      icon: Icons.restart_alt_rounded,
      description: 'Arınma, bağışlanma ve yeniden yöneliş niyeti.',
      esmaNumbers: [1, 2, 14, 34, 44, 80, 82],
      dhikrIds: [
        'estagfirullah',
        'estagfirullah-el-azim',
        'seyyidul-istigfar',
        'rabbigfir-li-ve-tub-aleyye',
        'allahumme-inneke-afuvvun',
        'rabbena-zalemna',
        'yunus-duasi',
      ],
    ),
    _CategoryItem(
      label: 'Hidayet &\nİlim',
      title: 'Hidayet & İlim',
      icon: Icons.school_rounded,
      description: 'Faydalı ilim, doğru yol ve hikmetli karar niyeti.',
      esmaNumbers: [19, 26, 27, 28, 29, 31, 40, 46, 50, 51, 57, 94, 98],
      dhikrIds: [
        'rabbi-zidni-ilma',
        'allahumme-ilmen-rizqan-amalan',
        'ihdinas-siratal-mustakim',
        'rabbi-shrah-li-sadri',
      ],
    ),
    _CategoryItem(
      label: 'Koruma &\nMuhafaza',
      title: 'Koruma & Muhafaza',
      icon: Icons.shield_rounded,
      description: 'Sığınma, emniyet ve muhafaza niyeti.',
      esmaNumbers: [6, 7, 38, 43, 52, 53, 54, 55, 90],
      dhikrIds: [
        'hasbunallah',
        'hasbiyallah',
        'bismillah-alladhi-la-yadurru',
        'audhu-bikalimatillah',
        'muawwidhat-after-prayer',
        'la-havle',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 22 * scale),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Bugün ne dilersin?',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _SeeAll(scale: scale),
            ],
          ),
        ),
        SizedBox(height: 16 * scale),
        SizedBox(
          height: 116 * scale,
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: EdgeInsets.fromLTRB(
              18 * scale,
              2 * scale,
              18 * scale,
              14 * scale,
            ),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _CategoryCard(
                scale: scale,
                item: item,
                onTap: () => _showCategorySheet(context, ref, item),
              );
            },
            separatorBuilder: (context, index) => SizedBox(width: 12 * scale),
            itemCount: _items.length,
          ),
        ),
        SizedBox(height: 14 * scale),
        _DashboardGoalProgressCard(scale: scale),
      ],
    );
  }

  void _showCategorySheet(
    BuildContext context,
    WidgetRef ref,
    _CategoryItem item,
  ) {
    ref.read(interactionFeedbackServiceProvider).selection();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.20),
      builder: (sheetContext) {
        return _CategoryDhikrSheet(
          scale: scale,
          item: item,
          onOpenDhikr: (dhikr) {
            Navigator.of(sheetContext).pop();
            Future<void>.delayed(const Duration(milliseconds: 140), () {
              if (!context.mounted) return;
              unawaited(_showHomeDhikrDetail(context, ref, dhikr));
            });
          },
        );
      },
    );
  }
}

final _dashboardGoalBucketsProvider =
    StreamProvider.autoDispose<List<CounterStatBucket>>((ref) {
      return ref.watch(appDatabaseProvider).watchCounterStatBuckets();
    });

final _dashboardGoalTargetsProvider =
    FutureProvider.autoDispose<_DashboardGoalTargets>((ref) async {
      final prefs = await SharedPreferences.getInstance();
      return _DashboardGoalTargets(
        daily: _readDashboardTargetPreference(prefs, _statisticsDailyTargetKey),
        monthly: _readDashboardTargetPreference(
          prefs,
          _statisticsMonthlyTargetKey,
        ),
        yearly: _readDashboardTargetPreference(
          prefs,
          _statisticsYearlyTargetKey,
        ),
      );
    });

class _DashboardGoalProgressCard extends ConsumerWidget {
  const _DashboardGoalProgressCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buckets = ref
        .watch(_dashboardGoalBucketsProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <CounterStatBucket>[],
        );
    final targetsAsync = ref.watch(_dashboardGoalTargetsProvider);
    final targets = targetsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const _DashboardGoalTargets(),
    );
    final targetsLoaded = targetsAsync.maybeWhen(
      data: (_) => true,
      orElse: () => false,
    );
    final snapshot = _DashboardGoalSnapshot.fromBuckets(
      buckets,
      targets,
      DateTime.now(),
    );
    final focusProgress = snapshot.daily.hasTarget
        ? snapshot.daily
        : snapshot.monthly;
    final feedback = ref.read(interactionFeedbackServiceProvider);
    const actionLabel = 'Ayarla';

    void openStatistics() {
      feedback.selection();
      context.push(AppRoutes.statistics).whenComplete(() {
        if (context.mounted) {
          ref.invalidate(_dashboardGoalTargetsProvider);
        }
      });
    }

    Future<void> openTargetEditor() async {
      if (!targetsLoaded) return;
      feedback.selection();
      final previousDailyTarget = targets.daily;
      final updatedTargets = await showModalBottomSheet<_DashboardGoalTargets>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return _DashboardGoalTargetSheet(scale: scale, targets: targets);
        },
      );
      if (updatedTargets == null) return;

      final prefs = await SharedPreferences.getInstance();
      await _writeDashboardTargetPreference(
        prefs,
        _statisticsDailyTargetKey,
        updatedTargets.daily,
      );
      await _writeDashboardTargetPreference(
        prefs,
        _statisticsMonthlyTargetKey,
        updatedTargets.monthly,
      );
      await _writeDashboardTargetPreference(
        prefs,
        _statisticsYearlyTargetKey,
        updatedTargets.yearly,
      );

      if (context.mounted) {
        ref.invalidate(_dashboardGoalTargetsProvider);
      }

      final dailyTarget = updatedTargets.daily;
      if (dailyTarget == null ||
          dailyTarget == previousDailyTarget ||
          !context.mounted) {
        return;
      }

      await _offerDashboardDailyTargetReminder(
        context: context,
        ref: ref,
        dailyTarget: dailyTarget,
      );
    }

    void handleCardTap() {
      if (targetsLoaded && targets.hasAny) {
        openStatistics();
      } else {
        openTargetEditor();
      }
    }

    void handleActionTap() {
      openTargetEditor();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18 * scale),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26 * scale),
          onTap: targetsLoaded ? handleCardTap : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26 * scale),
              color: _cardBackground.withValues(alpha: 0.98),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.76),
                width: 0.8 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.13),
                  blurRadius: 30 * scale,
                  offset: Offset(0, 15 * scale),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.72),
                  blurRadius: 7 * scale,
                  offset: Offset(0, -1 * scale),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26 * scale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26 * scale),
                        bottom: Radius.circular(18 * scale),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF123F2D), Color(0xFF1F6C4B)],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        15 * scale,
                        14 * scale,
                        15 * scale,
                        14 * scale,
                      ),
                      child: Row(
                        children: [
                          _DashboardGoalMedallion(
                            scale: scale,
                            progress: focusProgress.progress,
                            active: focusProgress.hasTarget,
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Hedef Akışı',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.8 * scale,
                                    fontWeight: FontWeight.w900,
                                    height: 1.02,
                                  ),
                                ),
                                SizedBox(height: 5 * scale),
                                Text(
                                  _dashboardGoalStatusText(
                                    snapshot,
                                    targetsLoaded,
                                    targets,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.74),
                                    fontSize: 10.8 * scale,
                                    fontWeight: FontWeight.w700,
                                    height: 1.12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          _DashboardGoalActionPill(
                            scale: scale,
                            label: targetsLoaded ? actionLabel : '...',
                            onTap: targetsLoaded ? handleActionTap : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      15 * scale,
                      14 * scale,
                      15 * scale,
                      15 * scale,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _DashboardGoalLane(
                              scale: scale,
                              icon: Icons.today_rounded,
                              label: 'Bugün',
                              progress: snapshot.daily,
                              color: _buttonGreen,
                              emptyStatus: targetsLoaded
                                  ? 'Günlük hedef yok'
                                  : 'Yükleniyor',
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12 * scale,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: _dividerColor.withValues(
                                      alpha: 0.95,
                                    ),
                                    width: 0.8 * scale,
                                  ),
                                ),
                              ),
                              child: const SizedBox(width: 0),
                            ),
                          ),
                          Expanded(
                            child: _DashboardGoalLane(
                              scale: scale,
                              icon: Icons.calendar_month_rounded,
                              label: 'Bu ay',
                              progress: snapshot.monthly,
                              color: _goalGold,
                              badge: snapshot.monthlyAutomatic
                                  ? 'otomatik'
                                  : null,
                              emptyStatus: targetsLoaded
                                  ? 'Aylık hedef yok'
                                  : 'Yükleniyor',
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
        ),
      ),
    );
  }
}

Future<void> _offerDashboardDailyTargetReminder({
  required BuildContext context,
  required WidgetRef ref,
  required int dailyTarget,
}) async {
  final reminderTime = await showDialog<TimeOfDay>(
    context: context,
    builder: (dialogContext) {
      var selectedTime = const TimeOfDay(
        hour: ReminderRepository.dailyTargetReminderHour,
        minute: ReminderRepository.dailyTargetReminderMinute,
      );

      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final timeLabel = _formatDashboardReminderDialogTime(selectedTime);

          return AlertDialog(
            backgroundColor: _cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: const Icon(
              Icons.notifications_active_rounded,
              color: _buttonGreen,
            ),
            title: const Text('Hedefini her gün yanında tutalım mı?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Günlük ${_formatDashboardNumber(dailyTarget)} zikir hedefin güzel bir adım. '
                  'Sana uygun bir saatte küçük bir hatırlatma ekleyelim; '
                  'günün yoğunluğunda unutmaz, ilerlemeni düzenli takip edersin.',
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showAppTimePicker(
                      context: dialogContext,
                      initialTime: selectedTime,
                      helpText: 'Günlük hedef hatırlatma saati',
                    );
                    if (picked == null || !dialogContext.mounted) {
                      return;
                    }

                    setDialogState(() => selectedTime = picked);
                  },
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hatırlatma saati'),
                      Text(
                        timeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryText,
                    side: BorderSide(
                      color: _buttonGreen.withValues(alpha: 0.22),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Şimdi değil'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(selectedTime),
                icon: const Icon(Icons.add_alert_rounded, size: 18),
                label: Text("$timeLabel'te ekle"),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    },
  );

  if (reminderTime == null || !context.mounted) {
    return;
  }

  final notifications = ref.read(localNotificationServiceProvider);
  final notificationsAllowed = await ensureNotificationPermissionForReminder(
    context: context,
    areNotificationsAllowed: notifications.areNotificationsAllowed,
    requestPermission: notifications.requestNotificationPermission,
  );
  if (!notificationsAllowed || !context.mounted) {
    return;
  }

  try {
    await ref
        .read(reminderRepositoryProvider)
        .upsertDailyTargetReminder(
          target: dailyTarget,
          hour: reminderTime.hour,
          minute: reminderTime.minute,
        );
    if (!context.mounted) {
      return;
    }

    final timeLabel = _formatDashboardReminderDialogTime(reminderTime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Günlük hedef hatırlatıcısı her gün $timeLabel'te aktif.",
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hatırlatıcı eklenemedi. Lütfen tekrar dene.'),
      ),
    );
  }
}

String _formatDashboardReminderDialogTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _DashboardGoalLane extends StatelessWidget {
  const _DashboardGoalLane({
    required this.scale,
    required this.icon,
    required this.label,
    required this.progress,
    required this.color,
    required this.emptyStatus,
    this.badge,
  });

  final double scale;
  final IconData icon;
  final String label;
  final _DashboardGoalProgress progress;
  final Color color;
  final String emptyStatus;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final status = progress.hasTarget
        ? progress.completed
              ? 'Tamamlandı'
              : '${_formatDashboardNumber(progress.remaining)} kaldı'
        : emptyStatus;
    final badge = this.badge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 17.5 * scale),
            SizedBox(width: 6 * scale),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 12.2 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * scale),
        Text(
          progress.countLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryText,
            fontSize: 16.2 * scale,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        SizedBox(height: 10 * scale),
        _DashboardGoalBar(
          scale: scale,
          progress: progress.progress,
          color: color,
          active: progress.hasTarget,
        ),
        SizedBox(height: 8 * scale),
        Row(
          children: [
            Expanded(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: progress.completed
                      ? color
                      : _secondaryText.withValues(alpha: 0.82),
                  fontSize: 11.0 * scale,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 6 * scale),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5 * scale,
                    vertical: 2 * scale,
                  ),
                  child: Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 9.2 * scale,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DashboardGoalBar extends StatelessWidget {
  const _DashboardGoalBar({
    required this.scale,
    required this.progress,
    required this.color,
    required this.active,
  });

  final double scale;
  final double progress;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6.2 * scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: _dividerColor.withValues(alpha: 0.78)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: active ? progress : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.70), color],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardGoalMedallion extends StatelessWidget {
  const _DashboardGoalMedallion({
    required this.scale,
    required this.progress,
    required this.active,
  });

  final double scale;
  final double progress;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final size = 50 * scale;
    final percent = (progress * 100).round();

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DashboardGoalRingPainter(
              progress: progress,
              active: active,
              scale: scale,
            ),
          ),
          if (active)
            Text(
              '%$percent',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.2 * scale,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            )
          else
            Icon(
              Icons.flag_rounded,
              color: Colors.white.withValues(alpha: 0.82),
              size: 19 * scale,
            ),
        ],
      ),
    );
  }
}

class _DashboardGoalActionPill extends StatelessWidget {
  const _DashboardGoalActionPill({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _cardBackground.withValues(alpha: 0.96),
          border: Border.all(
            color: _goalGold.withValues(alpha: 0.42),
            width: 0.7 * scale,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 6 * scale,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                color: _primaryGreen,
                size: 13.5 * scale,
              ),
              SizedBox(width: 4 * scale),
              Text(
                label,
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 10.4 * scale,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardGoalTargetSheet extends StatefulWidget {
  const _DashboardGoalTargetSheet({required this.scale, required this.targets});

  final double scale;
  final _DashboardGoalTargets targets;

  @override
  State<_DashboardGoalTargetSheet> createState() =>
      _DashboardGoalTargetSheetState();
}

class _DashboardGoalTargetSheetState extends State<_DashboardGoalTargetSheet> {
  late final TextEditingController _dailyController;
  late final TextEditingController _monthlyController;
  late final TextEditingController _yearlyController;

  @override
  void initState() {
    super.initState();
    _dailyController = TextEditingController(
      text: _dashboardTargetInputText(widget.targets.daily),
    );
    _monthlyController = TextEditingController(
      text: _dashboardTargetInputText(widget.targets.monthly),
    );
    _yearlyController = TextEditingController(
      text: _dashboardTargetInputText(widget.targets.yearly),
    );
    _dailyController.addListener(_refreshAutomaticTargets);
  }

  @override
  void dispose() {
    _dailyController.removeListener(_refreshAutomaticTargets);
    _dailyController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final now = DateTime.now();
    final dailyDraft = _parseDashboardTargetInput(_dailyController.text);
    final automaticMonthly = dailyDraft == null
        ? null
        : dailyDraft * DateUtils.getDaysInMonth(now.year, now.month);
    final automaticYearly = dailyDraft == null
        ? null
        : dailyDraft * _dashboardDaysInYear(now.year);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28 * scale)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24 * scale,
              offset: Offset(0, -8 * scale),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20 * scale,
                12 * scale,
                20 * scale,
                18 * scale,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42 * scale,
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: _dividerColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hedefleri düzenle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 19 * scale,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, size: 20 * scale),
                        color: _secondaryText,
                        style: IconButton.styleFrom(
                          fixedSize: Size.square(36 * scale),
                          minimumSize: Size.square(36 * scale),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  _DashboardGoalInputField(
                    scale: scale,
                    controller: _dailyController,
                    icon: Icons.today_rounded,
                    label: 'Günlük hedef',
                    hint: '2500',
                  ),
                  SizedBox(height: 10 * scale),
                  _DashboardAutomaticTargetPreview(
                    scale: scale,
                    monthlyValue: automaticMonthly,
                    yearlyValue: automaticYearly,
                  ),
                  SizedBox(height: 10 * scale),
                  _DashboardGoalInputField(
                    scale: scale,
                    controller: _monthlyController,
                    icon: Icons.calendar_month_rounded,
                    label: 'Aylık özel hedef',
                    hint: automaticMonthly == null
                        ? 'Günlükten otomatik'
                        : 'Otomatik: ${_formatDashboardNumber(automaticMonthly)}',
                  ),
                  SizedBox(height: 10 * scale),
                  _DashboardGoalInputField(
                    scale: scale,
                    controller: _yearlyController,
                    icon: Icons.flag_rounded,
                    label: 'Yıllık özel hedef',
                    hint: automaticYearly == null
                        ? 'Günlükten otomatik'
                        : 'Otomatik: ${_formatDashboardNumber(automaticYearly)}',
                  ),
                  SizedBox(height: 14 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearInputs,
                          icon: Icon(Icons.backspace_rounded, size: 15 * scale),
                          label: const Text('Temizle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _secondaryText,
                            side: BorderSide(
                              color: _dividerColor,
                              width: 1 * scale,
                            ),
                            minimumSize: Size.fromHeight(46 * scale),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: Icon(Icons.check_rounded, size: 16 * scale),
                          label: const Text('Kaydet'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            minimumSize: Size.fromHeight(46 * scale),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _refreshAutomaticTargets() {
    setState(() {});
  }

  void _clearInputs() {
    _dailyController.clear();
    _monthlyController.clear();
    _yearlyController.clear();
  }

  void _save() {
    Navigator.of(context).pop(
      _DashboardGoalTargets(
        daily: _parseDashboardTargetInput(_dailyController.text),
        monthly: _parseDashboardTargetInput(_monthlyController.text),
        yearly: _parseDashboardTargetInput(_yearlyController.text),
      ),
    );
  }
}

class _DashboardAutomaticTargetPreview extends StatelessWidget {
  const _DashboardAutomaticTargetPreview({
    required this.scale,
    required this.monthlyValue,
    required this.yearlyValue,
  });

  final double scale;
  final int? monthlyValue;
  final int? yearlyValue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: _primaryGreen.withValues(alpha: 0.12),
          width: 0.7 * scale,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          11 * scale,
          9 * scale,
          11 * scale,
          9 * scale,
        ),
        child: Row(
          children: [
            Expanded(
              child: _DashboardAutomaticTargetValue(
                scale: scale,
                label: 'Aylık otomatik',
                value: monthlyValue,
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: _DashboardAutomaticTargetValue(
                scale: scale,
                label: 'Yıllık otomatik',
                value: yearlyValue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAutomaticTargetValue extends StatelessWidget {
  const _DashboardAutomaticTargetValue({
    required this.scale,
    required this.label,
    required this.value,
  });

  final double scale;
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _secondaryText,
            fontSize: 8.6 * scale,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          _formatDashboardTargetValue(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryText,
            fontSize: 12.2 * scale,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _DashboardGoalInputField extends StatelessWidget {
  const _DashboardGoalInputField({
    required this.scale,
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
  });

  final double scale;
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [const _DashboardTargetNumberInputFormatter()],
      style: TextStyle(
        color: _primaryText,
        fontSize: 15 * scale,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _primaryGreen, size: 20 * scale),
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: _secondaryText.withValues(alpha: 0.52)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.62),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color: _dividerColor, width: 1 * scale),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color: _dividerColor, width: 1 * scale),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * scale),
          borderSide: BorderSide(color: _primaryGreen, width: 1.3 * scale),
        ),
      ),
    );
  }
}

class _DashboardTargetNumberInputFormatter extends TextInputFormatter {
  const _DashboardTargetNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _dashboardDigitsOnly(
      newValue.text,
    ).replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _formatDashboardDigitString(digits);
    final extentOffset = newValue.selection.extentOffset;
    final safeOffset = extentOffset < 0
        ? 0
        : math.min(extentOffset, newValue.text.length);
    final digitsBeforeCursor = _dashboardDigitsOnly(
      newValue.text.substring(0, safeOffset),
    ).length;
    final selectionOffset = _dashboardOffsetForDigitPosition(
      formatted,
      digitsBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
      composing: TextRange.empty,
    );
  }
}

class _DashboardGoalRingPainter extends CustomPainter {
  const _DashboardGoalRingPainter({
    required this.progress,
    required this.active,
    required this.scale,
  });

  final double progress;
  final bool active;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2 * scale;
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawCircle(center, radius, rimPaint);

    if (!active) return;

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [_goalMint, _goalGold, _goalMint],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DashboardGoalRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.scale != scale;
  }
}

class _DashboardGoalSnapshot {
  const _DashboardGoalSnapshot({
    required this.daily,
    required this.monthly,
    required this.monthlyAutomatic,
  });

  final _DashboardGoalProgress daily;
  final _DashboardGoalProgress monthly;
  final bool monthlyAutomatic;

  factory _DashboardGoalSnapshot.fromBuckets(
    List<CounterStatBucket> buckets,
    _DashboardGoalTargets targets,
    DateTime now,
  ) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);
    var dailyTotal = 0;
    var monthlyTotal = 0;

    for (final bucket in buckets) {
      final count = math.max(0, bucket.count);
      if (count == 0) continue;

      final bucketStart = bucket.bucketStart;
      if (bucketStart.isBefore(monthStart) || !bucketStart.isBefore(monthEnd)) {
        continue;
      }

      monthlyTotal += count;
      if (!bucketStart.isBefore(todayStart) &&
          bucketStart.isBefore(tomorrowStart)) {
        dailyTotal += count;
      }
    }

    return _DashboardGoalSnapshot(
      daily: _DashboardGoalProgress(total: dailyTotal, target: targets.daily),
      monthly: _DashboardGoalProgress(
        total: monthlyTotal,
        target: targets.monthlyTargetFor(monthStart),
      ),
      monthlyAutomatic: targets.monthlyIsAutomatic,
    );
  }
}

class _DashboardGoalProgress {
  const _DashboardGoalProgress({required this.total, required this.target});

  final int total;
  final int? target;

  bool get hasTarget => target != null;

  bool get completed {
    final target = this.target;
    return target != null && total >= target;
  }

  int get remaining {
    final target = this.target;
    if (target == null) return 0;
    return math.max(0, target - total);
  }

  double get progress {
    final target = this.target;
    if (target == null) return 0;
    return (total / math.max(1, target)).clamp(0.0, 1.0).toDouble();
  }

  String get countLabel {
    final target = this.target;
    if (target == null) return _formatDashboardNumber(total);
    return '${_formatDashboardNumber(total)} / ${_formatDashboardNumber(target)}';
  }
}

class _DashboardGoalTargets {
  const _DashboardGoalTargets({this.daily, this.monthly, this.yearly});

  final int? daily;
  final int? monthly;
  final int? yearly;

  bool get hasAny => daily != null || monthly != null || yearly != null;

  bool get monthlyIsAutomatic => monthly == null && daily != null;

  bool get yearlyIsAutomatic => yearly == null && daily != null;

  int? monthlyTargetFor(DateTime month) {
    final customTarget = monthly;
    if (customTarget != null) return customTarget;

    final dailyTarget = daily;
    if (dailyTarget == null) return null;

    return dailyTarget * DateUtils.getDaysInMonth(month.year, month.month);
  }

  int? yearlyTargetFor(int year) {
    final customTarget = yearly;
    if (customTarget != null) return customTarget;

    final dailyTarget = daily;
    if (dailyTarget == null) return null;

    return dailyTarget * _dashboardDaysInYear(year);
  }
}

String _dashboardGoalStatusText(
  _DashboardGoalSnapshot snapshot,
  bool targetsLoaded,
  _DashboardGoalTargets targets,
) {
  if (!targetsLoaded) return 'Hedefler hazırlanıyor';
  if (!targets.hasAny) return 'Günlük hedefini gir, ay kendini tamamlasın';
  if (snapshot.daily.completed && snapshot.monthly.completed) {
    return 'Bugün ve bu ay hedef tamam';
  }
  if (snapshot.daily.completed) return 'Bugün tamam; ay izleniyor';
  if (snapshot.daily.hasTarget) {
    return 'Bugün ${_formatDashboardNumber(snapshot.daily.remaining)} zikir kaldı';
  }
  if (snapshot.monthly.hasTarget) {
    return 'Bu ay ${_formatDashboardNumber(snapshot.monthly.remaining)} zikir kaldı';
  }

  return 'İlerleme burada birikecek';
}

int? _readDashboardTargetPreference(SharedPreferences prefs, String key) {
  final value = prefs.getInt(key);
  if (value == null || value <= 0) return null;
  return value;
}

Future<void> _writeDashboardTargetPreference(
  SharedPreferences prefs,
  String key,
  int? value,
) {
  if (value == null || value <= 0) {
    return prefs.remove(key);
  }

  return prefs.setInt(key, value);
}

int? _parseDashboardTargetInput(String raw) {
  final value = int.tryParse(_dashboardDigitsOnly(raw));
  if (value == null || value <= 0) return null;
  return value;
}

String _formatDashboardNumber(int value) {
  return _formatDashboardDigitString(value.toString());
}

String _formatDashboardTargetValue(int? value) {
  if (value == null) return 'Belirle';
  return _formatDashboardNumber(value);
}

String _dashboardTargetInputText(int? value) =>
    value == null ? '' : _formatDashboardNumber(value);

String _dashboardDigitsOnly(String value) =>
    value.replaceAll(RegExp(r'\D'), '');

String _formatDashboardDigitString(String digits) {
  final raw = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
}

int _dashboardOffsetForDigitPosition(String formatted, int digitPosition) {
  if (digitPosition <= 0) return 0;

  var seenDigits = 0;
  for (var i = 0; i < formatted.length; i++) {
    if (RegExp(r'\d').hasMatch(formatted[i])) {
      seenDigits++;
    }
    if (seenDigits >= digitPosition) {
      return i + 1;
    }
  }

  return formatted.length;
}

int _dashboardDaysInYear(int year) {
  return DateTime(year + 1).difference(DateTime(year)).inDays;
}

class _CategoryItem {
  const _CategoryItem({
    required this.label,
    required this.title,
    required this.icon,
    required this.description,
    required this.esmaNumbers,
    required this.dhikrIds,
  });

  final String label;
  final String title;
  final IconData icon;
  final String description;
  final List<int> esmaNumbers;
  final List<String> dhikrIds;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.scale,
    required this.item,
    required this.onTap,
  });

  final double scale;
  final _CategoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20 * scale);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          width: 96 * scale,
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 12 * scale,
          ),
          decoration: BoxDecoration(
            color: _cardBackground.withValues(alpha: 0.84),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.035),
                blurRadius: 14 * scale,
                spreadRadius: -4 * scale,
                offset: Offset(0, 5 * scale),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: _mutedGreen, size: 28 * scale),
              SizedBox(height: 7 * scale),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 12.4 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDhikrSheet extends ConsumerWidget {
  const _CategoryDhikrSheet({
    required this.scale,
    required this.item,
    required this.onOpenDhikr,
  });

  final double scale;
  final _CategoryItem item;
  final ValueChanged<DhikrItem> onOpenDhikr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final sheetScale = scale;
    final contentWidth = math.min(
      media.size.width,
      appLayoutBaselineWidth * sheetScale,
    );
    final bottomPadding = media.padding.bottom + 18 * sheetScale;
    final esmas = _categoryEsmas(item);
    final dhikrs = ref.watch(dhikrItemsProvider);
    final radius = BorderRadius.vertical(top: Radius.circular(28 * sheetScale));

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.28,
        maxChildSize: 0.88,
        expand: false,
        snap: true,
        shouldCloseOnMinExtent: true,
        builder: (context, scrollController) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _pageBackground,
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.70),
                  width: 0.8 * sheetScale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.18),
                    blurRadius: 28 * sheetScale,
                    offset: Offset(0, -10 * sheetScale),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: SizedBox(
                  width: contentWidth,
                  child: dhikrs.when(
                    data: (items) {
                      final dhikrItems = _categoryDhikrs(item, items);
                      return SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          18 * sheetScale,
                          10 * sheetScale,
                          18 * sheetScale,
                          bottomPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CategorySheetHeader(
                              scale: sheetScale,
                              item: item,
                              esmaCount: esmas.length,
                              dhikrCount: dhikrItems.length,
                            ),
                            SizedBox(height: 16 * sheetScale),
                            _CategorySheetSection(
                              scale: sheetScale,
                              title: 'Esma-ül Hüsna',
                              count: esmas.length,
                              children: [
                                for (final esma in esmas)
                                  _CategorySheetTile(
                                    scale: sheetScale,
                                    icon: Icons.auto_awesome_rounded,
                                    typeLabel: 'Esma',
                                    title: esma.dhikrName,
                                    arabicText: esma.dhikrArabicText,
                                    subtitle: '${esma.name} • ${esma.meaning}',
                                    target: esma.ebcedNumber,
                                    onTap: () => onOpenDhikr(esma.toDhikr()),
                                  ),
                              ],
                            ),
                            SizedBox(height: 12 * sheetScale),
                            _CategorySheetSection(
                              scale: sheetScale,
                              title: 'Zikir ve Dua',
                              count: dhikrItems.length,
                              children: [
                                for (final dhikr in dhikrItems)
                                  _CategorySheetTile(
                                    scale: sheetScale,
                                    icon: _categoryTileIcon(dhikr),
                                    typeLabel: _isCategoryDua(dhikr)
                                        ? 'Dua'
                                        : 'Zikir',
                                    title: dhikr.name,
                                    arabicText: dhikr.arabicText,
                                    subtitle: dhikr.meaning ?? dhikr.category,
                                    target: dhikr.defaultTarget,
                                    onTap: () => onOpenDhikr(dhikr),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        18 * sheetScale,
                        10 * sheetScale,
                        18 * sheetScale,
                        bottomPadding,
                      ),
                      child: _CategorySheetState(
                        scale: sheetScale,
                        icon: Icons.hourglass_top_rounded,
                        title: 'İçerik hazırlanıyor',
                        message: 'Esma ve zikirler birazdan açılacak.',
                      ),
                    ),
                    error: (error, stackTrace) => SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        18 * sheetScale,
                        10 * sheetScale,
                        18 * sheetScale,
                        bottomPadding,
                      ),
                      child: _CategorySheetState(
                        scale: sheetScale,
                        icon: Icons.error_outline_rounded,
                        title: 'İçerik açılamadı',
                        message: '$error',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategorySheetHeader extends StatelessWidget {
  const _CategorySheetHeader({
    required this.scale,
    required this.item,
    required this.esmaCount,
    required this.dhikrCount,
  });

  final double scale;
  final _CategoryItem item;
  final int esmaCount;
  final int dhikrCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 42 * scale,
            height: 4 * scale,
            decoration: BoxDecoration(
              color: _mutedGreen.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        SizedBox(height: 16 * scale),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _buttonGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 46 * scale,
                child: Icon(item.icon, color: _primaryGreen, size: 24 * scale),
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 21 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 12.2 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.28,
                    ),
                  ),
                  SizedBox(height: 9 * scale),
                  Wrap(
                    spacing: 7 * scale,
                    runSpacing: 7 * scale,
                    children: [
                      _CategoryCountChip(
                        scale: scale,
                        label: '$esmaCount esma',
                      ),
                      _CategoryCountChip(
                        scale: scale,
                        label: '$dhikrCount zikir',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryCountChip extends StatelessWidget {
  const _CategoryCountChip({required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _goalMint.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _buttonGreen.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 9 * scale,
          vertical: 5 * scale,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _primaryGreen,
            fontSize: 10.5 * scale,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _CategorySheetSection extends StatelessWidget {
  const _CategorySheetSection({
    required this.scale,
    required this.title,
    required this.count,
    required this.children,
  });

  final double scale;
  final String title;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 15.5 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$count kayıt',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 11 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * scale),
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) SizedBox(height: 8 * scale),
        ],
      ],
    );
  }
}

class _CategorySheetTile extends StatelessWidget {
  const _CategorySheetTile({
    required this.scale,
    required this.icon,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.target,
    required this.onTap,
    this.arabicText,
  });

  final double scale;
  final IconData icon;
  final String typeLabel;
  final String title;
  final String subtitle;
  final String? arabicText;
  final int target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18 * scale);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.fromLTRB(
            12 * scale,
            11 * scale,
            10 * scale,
            11 * scale,
          ),
          decoration: BoxDecoration(
            color: _cardBackground.withValues(alpha: 0.92),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _buttonGreen.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 36 * scale,
                  child: Icon(icon, color: _mutedGreen, size: 19 * scale),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: _goalGold,
                        fontSize: 9.4 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 13.3 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.14,
                      ),
                    ),
                    if (arabicText != null &&
                        arabicText!.trim().isNotEmpty) ...[
                      SizedBox(height: 6 * scale),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          arabicText!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: _primaryGreen,
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1.34,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 5 * scale),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * scale),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CategoryTargetBadge(scale: scale, target: target),
                  SizedBox(height: 8 * scale),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _mutedGreen,
                    size: 22 * scale,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTargetBadge extends StatelessWidget {
  const _CategoryTargetBadge({required this.scale, required this.target});

  final double scale;
  final int target;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _buttonGreen.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 7 * scale,
          vertical: 4 * scale,
        ),
        child: Text(
          '$target',
          style: TextStyle(
            color: _primaryGreen,
            fontSize: 10.2 * scale,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _CategorySheetState extends StatelessWidget {
  const _CategorySheetState({
    required this.scale,
    required this.icon,
    required this.title,
    required this.message,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 24 * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        28 * scale,
        32 * scale,
        28 * scale,
        bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _mutedGreen, size: 34 * scale),
          SizedBox(height: 12 * scale),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryText,
              fontSize: 16 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryText,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

List<EsmaItem> _categoryEsmas(_CategoryItem item) {
  return [
    for (final number in item.esmaNumbers)
      for (final esma in esmaItems)
        if (esma.number == number) esma,
  ];
}

List<DhikrItem> _categoryDhikrs(_CategoryItem item, List<DhikrItem> dhikrs) {
  return [
    for (final id in item.dhikrIds)
      for (final dhikr in dhikrs)
        if (dhikr.id == id) dhikr,
  ];
}

IconData _categoryTileIcon(DhikrItem item) {
  return switch (item.category) {
    'İstiğfar' => Icons.restart_alt_rounded,
    'Korunma' => Icons.shield_rounded,
    'Tesbih' => Icons.auto_awesome_rounded,
    'Tevhid' => Icons.brightness_high_rounded,
    _ => Icons.menu_book_rounded,
  };
}

bool _isCategoryDua(DhikrItem item) {
  return const {
    'allahumme-ilmen-rizqan-amalan',
    'allahumme-rabben-nas-ishfi',
    'eselullahal-azim-yashfik',
    'rabbena-hablana-min-azwajina',
    'ihdinas-siratal-mustakim',
    'rabbi-shrah-li-sadri',
    'rabbena-atina',
    'rabbi-zidni-ilma',
    'ya-hayyu-ya-kayyum',
  }.contains(item.id);
}

Future<void> _showHomeDhikrDetail(
  BuildContext context,
  WidgetRef ref,
  DhikrItem item,
) async {
  ref.read(interactionFeedbackServiceProvider).selection();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Zikir detayını kapat',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final media = MediaQuery.of(dialogContext);
      final detailScale = proportionalLayoutScaleFor(media.size.width);
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
                child: FadeTransition(
                  opacity: curved,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.24),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(curved),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: media.size.height * 0.92,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28 * detailScale),
                        ),
                        border: Border.all(
                          color: _goalGold.withValues(alpha: 0.55),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.55),
                            blurRadius: 1 * detailScale,
                            offset: Offset(0, -0.5 * detailScale),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(27 * detailScale),
                        ),
                        child: DhikrDetailScreen(
                          dhikrId: item.id,
                          sheetMode: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class HomeBottomNav extends ConsumerWidget {
  const HomeBottomNav({
    super.key,
    required this.scale,
    required this.contentWidth,
    this.activeDestination = HomeBottomNavDestination.home,
    this.quickStartKey = const Key('home.quickStart'),
  });

  final double scale;
  final double contentWidth;
  final HomeBottomNavDestination activeDestination;
  final Key quickStartKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final navShellWidth = math.min(
      MediaQuery.sizeOf(context).width,
      contentWidth,
    );
    final navRadius = BorderRadius.circular(32 * scale);
    final activeCounterState = ref.watch(counterControllerProvider);
    final storedHistoryEntries = ref
        .watch(_dashboardHistoryProvider)
        .maybeWhen(
          data: (entries) => entries,
          orElse: () => const <_HistoryEntry>[],
        );
    final dhikrs = ref
        .watch(dhikrItemsProvider)
        .maybeWhen(data: (items) => items, orElse: () => builtinDhikrs);
    final quickStartEntry =
        _ongoingEntryFromCounter(activeCounterState) ??
        _latestOngoingHistoryEntry(storedHistoryEntries);
    final quickStartDhikr = quickStartEntry == null
        ? _defaultQuickStartDhikr(dhikrs)
        : activeCounterState.activeDhikr.id == quickStartEntry.dhikrId
        ? activeCounterState.activeDhikr
        : _dhikrById(dhikrs, quickStartEntry.dhikrId) ??
              _dhikrById(builtinDhikrs, quickStartEntry.dhikrId) ??
              DhikrItem(
                id: quickStartEntry.dhikrId,
                name: quickStartEntry.title,
                category: 'History',
                defaultTarget: quickStartEntry.target <= 0
                    ? 33
                    : quickStartEntry.target,
              );
    final feedback = ref.read(interactionFeedbackServiceProvider);

    void openRouteWithSelectionFeedback(String route) {
      final currentPath = GoRouterState.of(context).uri.path;
      if (route == currentPath) {
        feedback.selection();
        return;
      }

      if (route == AppRoutes.dashboard) {
        context.go(route);
      } else {
        context.push(route);
      }
      feedback.selection();
    }

    void handleQuickStart() {
      ref
          .read(counterControllerProvider.notifier)
          .startDhikr(
            quickStartDhikr,
            target: quickStartEntry?.target,
            initialCount: quickStartEntry?.count ?? 0,
            sessionId: quickStartEntry?.sessionId,
          );
      context.push(AppRoutes.counter);
      feedback.primaryAction();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: _homeBottomNavBottomOffset(safeBottom, scale),
      height: _homeBottomNavBaseHeight * scale,
      child: Center(
        child: SizedBox(
          width: navShellWidth,
          height: _homeBottomNavBaseHeight * scale,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18 * scale),
            child: ClipRRect(
              borderRadius: navRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: navRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.76),
                        _cardBackground.withValues(alpha: 0.68),
                        const Color(0xFFEFF5EB).withValues(alpha: 0.58),
                      ],
                      stops: const [0.0, 0.54, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.70),
                      width: 0.8 * scale,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.06),
                        blurRadius: 28 * scale,
                        offset: Offset(0, 12 * scale),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.055),
                        blurRadius: 22 * scale,
                        offset: Offset(0, 8 * scale),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BottomNavItem(
                        scale: scale,
                        icon: Icons.home_rounded,
                        label: 'Ana Sayfa',
                        active:
                            activeDestination == HomeBottomNavDestination.home,
                        onTap: () =>
                            openRouteWithSelectionFeedback(AppRoutes.dashboard),
                      ),
                      _BottomNavItem(
                        scale: scale,
                        icon: Icons.menu_book_rounded,
                        label: 'Zikir Kütüphanesi',
                        active:
                            activeDestination ==
                            HomeBottomNavDestination.dhikrLibrary,
                        onTap: () => openRouteWithSelectionFeedback(
                          AppRoutes.dhikrLibrary,
                        ),
                      ),
                      _QuickStartNavButton(
                        scale: scale,
                        hasDhikr: true,
                        buttonKey: quickStartKey,
                        onPressed: handleQuickStart,
                      ),
                      _BottomNavItem(
                        scale: scale,
                        icon: Icons.auto_awesome_rounded,
                        label: 'Esma-ül Hüsna',
                        active:
                            activeDestination == HomeBottomNavDestination.esma,
                        onTap: () =>
                            openRouteWithSelectionFeedback(AppRoutes.esma),
                      ),
                      _BottomNavItem(
                        scale: scale,
                        icon: Icons.insights_rounded,
                        label: 'İstatistikler',
                        active:
                            activeDestination ==
                            HomeBottomNavDestination.statistics,
                        onTap: () => openRouteWithSelectionFeedback(
                          AppRoutes.statistics,
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

enum HomeBottomNavDestination { none, home, dhikrLibrary, esma, statistics }

DhikrItem? _dhikrById(List<DhikrItem> items, String? id) {
  if (id == null) return null;
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}

class _QuickStartNavButton extends StatefulWidget {
  const _QuickStartNavButton({
    required this.scale,
    required this.hasDhikr,
    required this.buttonKey,
    required this.onPressed,
  });

  final double scale;
  final bool hasDhikr;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  State<_QuickStartNavButton> createState() => _QuickStartNavButtonState();
}

class _QuickStartNavButtonState extends State<_QuickStartNavButton>
    with TickerProviderStateMixin {
  static bool _quickStartUsedInSession = false;

  late final AnimationController _ringController;
  late final AnimationController _introController;
  late final Animation<double> _breath;
  bool _hasUsedQuickStart = _quickStartUsedInSession;

  @override
  void initState() {
    super.initState();
    _ringController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 6800),
          )
          ..value =
              (DateTime.now().millisecondsSinceEpoch % 6800).toDouble() / 6800
          ..repeat();
    _breath =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _ringController, curve: Curves.easeInOutSine),
        );
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 11200),
    );
    if (_hasUsedQuickStart) {
      _introController.value = 0.6;
      _ringController.stop();
    } else {
      _introController.repeat();
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _handlePressed() {
    if (!_hasUsedQuickStart) {
      _quickStartUsedInSession = true;
      setState(() {
        _hasUsedQuickStart = true;
        _introController.value = 0.6;
        _introController.stop();
        _ringController.stop();
      });
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final label = widget.hasDhikr ? 'Hızlı Başlat' : 'Zikir Seç';

    return SizedBox(
      width: 68 * scale,
      child: Center(
        child: Semantics(
          button: true,
          label: label,
          child: Tooltip(
            message: label,
            child: AnimatedBuilder(
              animation: Listenable.merge([_ringController, _introController]),
              builder: (context, child) {
                final glow = _breath.value;
                final ringRotation = _hasUsedQuickStart
                    ? math.pi * 0.2
                    : _ringController.value * math.pi * 2;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _buttonGreen.withValues(
                          alpha: 0.19 + glow * 0.07,
                        ),
                        blurRadius: (18 + glow * 6) * scale,
                        offset: Offset(0, (7.5 + glow * 1.5) * scale),
                      ),
                      BoxShadow(
                        color: const Color(
                          0xFFD8C48A,
                        ).withValues(alpha: 0.14 + glow * 0.08),
                        blurRadius: (12 + glow * 7) * scale,
                        offset: Offset(0, (3.5 + glow) * scale),
                      ),
                    ],
                  ),
                  child: SizedBox.square(
                    dimension: 58 * scale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _QuickStartRingPainter(
                              rotation: ringRotation,
                              glow: _hasUsedQuickStart ? 0 : glow,
                            ),
                          ),
                        ),
                        SizedBox.square(
                          dimension: 49 * scale,
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              key: widget.buttonKey,
                              customBorder: const CircleBorder(),
                              onTap: _handlePressed,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF4DA071),
                                      const Color(0xFF3B8A61),
                                      _primaryGreen,
                                      const Color(0xFF0D3525),
                                    ],
                                    stops: const [0.0, 0.38, 0.72, 1.0],
                                  ),
                                ),
                                child: ClipOval(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned.fill(
                                        child: _QuickStartGlassDome(
                                          scale: scale,
                                        ),
                                      ),
                                      _QuickStartButtonFace(
                                        scale: scale,
                                        label: label,
                                        progress: _introController.value,
                                        lockedToIcon: _hasUsedQuickStart,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStartGlassDome extends StatelessWidget {
  const _QuickStartGlassDome({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -3 * scale,
          right: -3 * scale,
          top: -4 * scale,
          height: 27 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(34 * scale),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.34),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.00),
                ],
                stops: const [0.0, 0.58, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 10 * scale,
          top: 7 * scale,
          width: 19 * scale,
          height: 6 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.42),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 4 * scale,
          right: 4 * scale,
          bottom: 1 * scale,
          height: 22 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.13),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickStartButtonFace extends StatelessWidget {
  const _QuickStartButtonFace({
    required this.scale,
    required this.label,
    required this.progress,
    required this.lockedToIcon,
  });

  final double scale;
  final String label;
  final double progress;
  final bool lockedToIcon;

  @override
  Widget build(BuildContext context) {
    if (lockedToIcon) {
      return _QuickStartIcon(scale: scale, opacity: 1, yOffset: 0, scaleIn: 1);
    }

    final textExit = _curvedInterval(
      progress,
      start: 0.38,
      end: 0.54,
      curve: Curves.easeInOutCubic,
    );
    final textReturn = _curvedInterval(
      progress,
      start: 0.84,
      end: 1.0,
      curve: Curves.easeOutCubic,
    );
    final iconEnter = _curvedInterval(
      progress,
      start: 0.46,
      end: 0.62,
      curve: Curves.easeOutBack,
    );
    final iconExit = _curvedInterval(
      progress,
      start: 0.76,
      end: 0.9,
      curve: Curves.easeInOutCubic,
    );
    final shineForward = _curvedInterval(
      progress,
      start: 0.36,
      end: 0.58,
      curve: Curves.easeInOutCubic,
    );
    final shineBack = _curvedInterval(
      progress,
      start: 0.8,
      end: 0.98,
      curve: Curves.easeInOutCubic,
    );
    final textOpacity = (1 - textExit * 0.86 + textReturn).clamp(0.0, 1.0);
    final iconOpacity = (iconEnter - iconExit).clamp(0.0, 1.0);
    final textShift = textExit * (1 - textReturn);
    final iconScale = (0.86 + 0.14 * iconEnter) * (1 - 0.05 * iconExit);
    final shineProgress = shineForward < 1
        ? shineForward
        : (1 - shineBack).clamp(0.0, 1.0);
    final shineOpacity = ((shineForward - iconExit).clamp(0.0, 1.0) * 0.85)
        .clamp(0.0, 0.85);

    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Opacity(
            opacity: textOpacity,
            child: Transform.translate(
              offset: Offset(0, -3.5 * scale * textShift),
              child: Transform.scale(
                scale: 1 - 0.04 * textShift,
                child: SizedBox.square(
                  dimension: 38 * scale,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label.replaceFirst(' ', '\n'),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF4E7BE),
                        fontSize: 11.2 * scale,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                        letterSpacing: 0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 5 * scale,
                            offset: Offset(0, 1.2 * scale),
                          ),
                          Shadow(
                            color: const Color(
                              0xFFFFE4A1,
                            ).withValues(alpha: 0.22),
                            blurRadius: 8 * scale,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: _QuickStartShine(
            scale: scale,
            progress: shineProgress,
            opacity: shineOpacity,
          ),
        ),
        IgnorePointer(
          child: Opacity(
            opacity: iconOpacity,
            child: Transform.translate(
              offset: Offset(0.6 * scale, (2.8 - iconEnter * 2.1) * scale),
              child: Transform.scale(
                scale: iconScale,
                child: SvgPicture.asset(
                  'assets/images/hand_prayer_beads_icon.svg',
                  width: 41.5 * scale,
                  height: 35.5 * scale,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFF4E7BE),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _curvedInterval(
    double value, {
    required double start,
    required double end,
    required Curve curve,
  }) {
    final normalized = ((value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(normalized);
  }
}

class _QuickStartIcon extends StatelessWidget {
  const _QuickStartIcon({
    required this.scale,
    required this.opacity,
    required this.yOffset,
    required this.scaleIn,
  });

  final double scale;
  final double opacity;
  final double yOffset;
  final double scaleIn;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0.6 * scale, yOffset * scale),
        child: Transform.scale(
          scale: scaleIn,
          child: SvgPicture.asset(
            'assets/images/hand_prayer_beads_icon.svg',
            width: 41.5 * scale,
            height: 35.5 * scale,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Color(0xFFF4E7BE),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStartShine extends StatelessWidget {
  const _QuickStartShine({
    required this.scale,
    required this.progress,
    required this.opacity,
  });

  final double scale;
  final double progress;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ClipOval(
        child: SizedBox.square(
          dimension: 48 * scale,
          child: Transform.translate(
            offset: Offset((-42 + progress * 84) * scale, 0),
            child: Transform.rotate(
              angle: -0.72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      const Color(0xFFFFF3C8).withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: SizedBox(width: 14 * scale, height: 72 * scale),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStartRingPainter extends CustomPainter {
  const _QuickStartRingPainter({required this.rotation, required this.glow});

  final double rotation;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = size.shortestSide * 0.086;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: [
          const Color(0xFFD7BC72),
          const Color(0xFFFFF3C8),
          const Color(0xFF3B8A61),
          const Color(0xFFD7BC72),
        ],
        stops: const [0.0, 0.26, 0.64, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final glowPaint = Paint()
      ..color = const Color(0xFFE6D293).withValues(alpha: 0.10 + glow * 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.7
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + glow * 2);

    canvas.drawCircle(center, radius, glowPaint);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _QuickStartRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.glow != glow;
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.scale,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final double scale;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? _primaryGreen : const Color(0xFF7E8B82);

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8 * scale),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24 * scale),
          child: InkWell(
            borderRadius: BorderRadius.circular(24 * scale),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: active ? 48 * scale : 38 * scale,
                  height: 31 * scale,
                  decoration: BoxDecoration(
                    color: active
                        ? _primaryGreen.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18 * scale),
                    border: active
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.64),
                            width: 0.6 * scale,
                          )
                        : null,
                  ),
                  child: Icon(icon, color: color, size: 23 * scale),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active
                        ? _primaryGreen
                        : const Color(0xFF7E8B82).withValues(alpha: 0.92),
                    fontSize: 9.7 * scale,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    height: 1.04,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.height,
    required this.radius,
    required this.padding,
    required this.child,
  });

  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: _cardBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: _softShadow,
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.scale,
    required this.height,
    required this.child,
  });

  final double scale;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        14 * scale,
        13 * scale,
        12 * scale,
      ),
      decoration: BoxDecoration(
        color: _cardBackground.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22 * scale),
        boxShadow: _softShadow,
      ),
      child: child,
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tümü',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 14.5 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4 * scale),
        Icon(
          Icons.chevron_right_rounded,
          color: _secondaryText,
          size: 23 * scale,
        ),
      ],
    );
  }
}

List<BoxShadow> get _softShadow {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.045),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}
