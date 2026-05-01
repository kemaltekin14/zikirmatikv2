import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/database_provider.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../counter/application/counter_controller.dart';
import '../../dhikr_library/application/dhikr_providers.dart';
import '../../dhikr_library/data/builtin_dhikrs.dart';
import '../../dhikr_library/domain/dhikr_item.dart';
import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';

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

const _homeQuoteBaseHeight = 72.0;
const _homeQuoteBaseWidth = 224.0;
const _homeQuoteTextMaxScale = 1.14;
const _homeBottomNavBaseHeight = 76.0;
const _homeBottomNavBaseGap = 10.0;
const _homeBottomNavMaxSafeInset = 4.0;
const _homeScrollBottomSpacing = 12.0;
const _todayEsmaCardBackgroundAsset =
    'assets/images/today_esma_card_background.png';

double _homeBottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(
    safeBottom,
    _homeBottomNavMaxSafeInset * scale,
  );
  return _homeBottomNavBaseGap * scale + visualSafeInset;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                        'El-Vekîl',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 16.4 * scale,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        'Her şeyi vekil edinen,\ngüvenilir olan.',
                        textAlign: TextAlign.center,
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
              context.push(AppRoutes.esma);
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
          data: (entries) => entries.isEmpty ? _sampleHistoryEntries : entries,
          orElse: () => _sampleHistoryEntries,
        );
    final historyEntries = _historyEntriesWithActiveCounter(
      storedHistoryEntries,
      ref.watch(counterControllerProvider),
      hasRememberedDhikr: ref.watch(lastStartedDhikrIdProvider) != null,
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
              _HistorySeeAllButton(scale: scale, onTap: showAllHistory),
            ],
          ),
          SizedBox(height: 7 * scale),
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
          .watchCounterEvents()
          .map(_historyEntriesFromEvents);
    });

class _HistoryEntry {
  const _HistoryEntry({
    required this.dhikrId,
    required this.title,
    required this.count,
    required this.target,
    required this.completed,
    required this.updatedAt,
    this.active = false,
    this.paused = false,
  });

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

List<_HistoryEntry> _historyEntriesFromEvents(List<CounterEvent> events) {
  final orderedEvents = [...events]
    ..sort((a, b) {
      final dateComparison = b.createdAt.compareTo(a.createdAt);
      if (dateComparison != 0) return dateComparison;
      return b.countAfter.compareTo(a.countAfter);
    });
  final currentOpenEntries = <String, _HistoryEntry>{};
  final currentStateResolved = <String>{};
  final completedEntries = <_HistoryEntry>[];

  for (final event in orderedEvents) {
    final completed =
        event.target > 0 &&
        (event.eventType == 'completed' || event.countAfter >= event.target);

    if (completed) {
      completedEntries.add(
        _HistoryEntry(
          dhikrId: event.dhikrId,
          title: event.dhikrName,
          count: event.target,
          target: event.target,
          completed: true,
          updatedAt: event.createdAt,
        ),
      );
    }

    if (currentStateResolved.add(event.dhikrId)) {
      final isOpen = event.countAfter > 0 && !completed;
      if (isOpen) {
        currentOpenEntries[event.dhikrId] = _HistoryEntry(
          dhikrId: event.dhikrId,
          title: event.dhikrName,
          count: event.countAfter,
          target: event.target,
          completed: false,
          updatedAt: event.createdAt,
        );
      }
    }
  }

  final entries = <_HistoryEntry>[
    ...currentOpenEntries.values,
    ...completedEntries,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  return entries;
}

List<_HistoryEntry> _historyEntriesWithActiveCounter(
  List<_HistoryEntry> entries,
  CounterState counter, {
  required bool hasRememberedDhikr,
}) {
  if (counter.count <= 0 && !hasRememberedDhikr) return entries;

  final activeEntry = _HistoryEntry(
    dhikrId: counter.activeDhikr.id,
    title: counter.activeDhikr.name,
    count: counter.count,
    target: counter.target,
    completed: !counter.isInfinite && counter.count >= counter.target,
    updatedAt: DateTime.now(),
    active: true,
  );

  final mergedEntries = [
    activeEntry,
    for (final entry in entries)
      if (!(entry.dhikrId == activeEntry.dhikrId && !entry.completed)) entry,
  ];

  return [
    for (final entry in mergedEntries)
      if (entry.active || entry.completed)
        entry
      else
        _HistoryEntry(
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

List<_HistoryEntry> get _sampleHistoryEntries {
  return [
    _HistoryEntry(
      dhikrId: 'subhanallah',
      title: 'Subhanallah',
      count: 33,
      target: 100,
      completed: false,
      updatedAt: DateTime(2026),
    ),
    _HistoryEntry(
      dhikrId: 'elhamdulillah',
      title: 'Elhamdulillah',
      count: 33,
      target: 33,
      completed: true,
      updatedAt: DateTime(2026),
    ),
    _HistoryEntry(
      dhikrId: 'allahu-ekber',
      title: 'Allahu Ekber',
      count: 99,
      target: 99,
      completed: true,
      updatedAt: DateTime(2026),
    ),
  ];
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

class CategoryZikrSection extends StatelessWidget {
  const CategoryZikrSection({super.key, required this.scale});

  final double scale;

  static const _items = [
    _CategoryItem('Rızık &\nBereket', Icons.eco_rounded),
    _CategoryItem('Şifa &\nSağlık', Icons.health_and_safety_rounded),
    _CategoryItem('Huzur &\nİç Sükun', Icons.spa_rounded),
    _CategoryItem('Şükran &\nHamd', Icons.volunteer_activism_rounded),
    _CategoryItem('İlişkiler &\nSevgi', Icons.favorite_rounded),
    _CategoryItem('Tövbe &\nMağfiret', Icons.restart_alt_rounded),
    _CategoryItem('Hidayet &\nİlim', Icons.school_rounded),
    _CategoryItem('Koruma &\nMuhafaza', Icons.shield_rounded),
  ];

  @override
  Widget build(BuildContext context) {
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
          height: 106 * scale,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 18 * scale),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) =>
                _CategoryCard(scale: scale, item: _items[index]),
            separatorBuilder: (context, index) => SizedBox(width: 12 * scale),
            itemCount: _items.length,
          ),
        ),
      ],
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.scale, required this.item});

  final double scale;
  final _CategoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96 * scale,
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: _cardBackground.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: _softShadow,
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
    );
  }
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
    final lastStartedDhikrId = ref.watch(lastStartedDhikrIdProvider);
    final dhikrs = ref
        .watch(dhikrItemsProvider)
        .maybeWhen(data: (items) => items, orElse: () => builtinDhikrs);
    final quickStartDhikrId =
        lastStartedDhikrId ?? activeCounterState.activeDhikr.id;
    final quickStartDhikr =
        _dhikrById(dhikrs, quickStartDhikrId) ??
        (activeCounterState.activeDhikr.id == quickStartDhikrId
            ? activeCounterState.activeDhikr
            : null) ??
        _dhikrById(builtinDhikrs, 'subhanallah') ??
        builtinDhikrs.first;
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
      ref.read(counterControllerProvider.notifier).startDhikr(quickStartDhikr);
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
