import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _libraryHeroEdgeCream = Color(0xFFF6F3EE);
const _primaryGreen = Color(0xFF13472F);
const _buttonGreen = Color(0xFF327653);
const _cardBackground = Color(0xFFFAFAF4);
const _primaryText = Color(0xFF123B2B);
const _secondaryText = Color(0xFF69766E);
const _gold = Color(0xFFD4BA75);
const _dividerColor = Color(0xFFDDE4D9);

const _bottomNavBaseHeight = 76.0;
const _bottomNavBaseGap = 10.0;
const _bottomNavMaxSafeInset = 4.0;
const _scrollExtraBottomSpacing = 42.0;

const _statisticsHeroAsset = 'assets/images/istatistikler-hero.webp';
const _periods = ['Genel Bakış', 'Günlük', 'Haftalık', 'Aylık', 'Yıllık'];
const _statisticsPillLift = 56.0;

double _bottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(safeBottom, _bottomNavMaxSafeInset * scale);
  return _bottomNavBaseGap * scale + visualSafeInset;
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = _periods.first;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final scale = proportionalLayoutScaleFor(screenWidth);
    final contentWidth = math.min(screenWidth, appLayoutBaselineWidth * scale);
    final safeBottom = media.padding.bottom;
    final bottomNavHeight = _bottomNavBaseHeight * scale;
    final bottomNavOffset = _bottomNavBottomOffset(safeBottom, scale);
    final bottomReservedHeight = bottomNavHeight + bottomNavOffset;
    final scrollBottomPadding =
        bottomReservedHeight + _scrollExtraBottomSpacing * scale;
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
              Positioned.fill(
                child: CustomPaint(painter: _StatisticsWashPainter()),
              ),
              Positioned.fill(
                bottom: bottomReservedHeight,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: 0, bottom: scrollBottomPadding),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatisticsTopCluster(
                            scale: scale,
                            topInset: media.padding.top,
                            selectedPeriod: _selectedPeriod,
                            onSelected: (period) =>
                                setState(() => _selectedPeriod = period),
                          ),
                          SizedBox(height: 4 * scale),
                          _OverviewCard(scale: scale),
                          SizedBox(height: 10 * scale),
                          _DayPartDistributionCard(scale: scale),
                          SizedBox(height: 10 * scale),
                          _ResponsiveChartPair(scale: scale),
                          SizedBox(height: 10 * scale),
                          _MonthlyProgressCard(scale: scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              HomeBottomNav(
                scale: scale,
                contentWidth: contentWidth,
                activeDestination: HomeBottomNavDestination.statistics,
                quickStartKey: const Key('statistics.quickStart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsTopCluster extends StatelessWidget {
  const _StatisticsTopCluster({
    required this.scale,
    required this.topInset,
    required this.selectedPeriod,
    required this.onSelected,
  });

  final double scale;
  final double topInset;
  final String selectedPeriod;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: -42 * scale,
          child: const _StatisticsTopClusterBackground(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatisticsHero(scale: scale, topInset: topInset),
            SizedBox(height: 16 * scale),
            _PeriodFilter(
              scale: scale,
              selectedPeriod: selectedPeriod,
              onSelected: onSelected,
            ),
            SizedBox(height: 4 * scale),
          ],
        ),
      ],
    );
  }
}

class _StatisticsTopClusterBackground extends StatelessWidget {
  const _StatisticsTopClusterBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCF7), Color(0xFFFFFCF7), _pageBackground],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
    );
  }
}

class _StatisticsHeroAssetEdgeFill extends StatelessWidget {
  const _StatisticsHeroAssetEdgeFill();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _libraryHeroEdgeCream,
            Color(0xFFFCF5EC),
            Color(0xFFEEEDE4),
            Color(0xFFE7ECE3),
            Color(0x00E9EEE4),
          ],
          stops: [0.0, 0.36, 0.66, 0.86, 1.0],
        ),
      ),
    );
  }
}

class _StatisticsHeroLeftBlendPatch extends StatelessWidget {
  const _StatisticsHeroLeftBlendPatch();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.64, 1.0],
        ).createShader(bounds);
      },
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6F2ED),
              Color(0xFFFCF6ED),
              Color(0xFFEEEDE5),
              Color(0xFFE8EDE4),
              Color(0x00E9EEE4),
            ],
            stops: [0.0, 0.34, 0.58, 0.80, 1.0],
          ),
        ),
      ),
    );
  }
}

class _StatisticsHeroRightWash extends StatelessWidget {
  const _StatisticsHeroRightWash();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _pageBackground.withValues(alpha: 0.30),
            _libraryHeroEdgeCream.withValues(alpha: 0.18),
            _libraryHeroEdgeCream.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 0.74, 1.0],
        ),
      ),
    );
  }
}

class _StatisticsHero extends StatelessWidget {
  const _StatisticsHero({required this.scale, required this.topInset});

  final double scale;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    const heroAssetBaseWidth = appLayoutBaselineWidth;
    const heroAssetVisualScale = 0.90;
    final heroLayoutHeight = topInset + 150 * scale;
    final heroFlowHeight = heroLayoutHeight - _statisticsPillLift * scale;
    final heroImageLeftEdge =
        appLayoutBaselineWidth * (1 - heroAssetVisualScale) * scale;

    return SizedBox(
      height: heroFlowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: heroImageLeftEdge + 4 * scale,
            height: heroLayoutHeight + 46 * scale,
            child: const _StatisticsHeroAssetEdgeFill(),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Transform.scale(
                alignment: Alignment.topRight,
                scale: scale * heroAssetVisualScale,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0.0, 0.72, 1.0],
                    ).createShader(bounds);
                  },
                  child: Image.asset(
                    _statisticsHeroAsset,
                    width: heroAssetBaseWidth,
                    fit: BoxFit.contain,
                    alignment: Alignment.topRight,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: 140 * scale,
            height: heroLayoutHeight + 58 * scale,
            child: const IgnorePointer(child: _StatisticsHeroLeftBlendPatch()),
          ),
          Positioned(
            left: 112 * scale,
            right: 0,
            top: topInset + 32 * scale,
            height: 86 * scale,
            child: const IgnorePointer(child: _StatisticsHeroRightWash()),
          ),
          Positioned(
            left: 20 * scale,
            top: topInset + 4 * scale,
            child: _HeroMenuButton(scale: scale),
          ),
          Positioned(
            left: 64 * scale,
            top: topInset + 11 * scale,
            right: 70 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'İstatistikler',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 20.5 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Padding(
                  padding: EdgeInsets.only(right: 46 * scale),
                  child: Text(
                    'Zikir yolculuğunu takip et, istikrarını güçlendir.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryText.withValues(alpha: 0.88),
                      fontSize: 11.6 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.38,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMenuButton extends StatelessWidget {
  const _HeroMenuButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = 35 * scale;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
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
          tooltip: 'Menü',
          onPressed: () => openAppMenu(context),
          icon: Icon(
            Icons.menu_rounded,
            color: _primaryGreen,
            size: 20 * scale,
          ),
        ),
      ),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({
    required this.scale,
    required this.selectedPeriod,
    required this.onSelected,
  });

  final double scale;
  final String selectedPeriod;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48 * scale,
      child: ListView.separated(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18 * scale),
        itemBuilder: (context, index) {
          final period = _periods[index];
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 38 * scale,
              child: _PeriodPill(
                scale: scale,
                label: period,
                selected: period == selectedPeriod,
                onTap: () => onSelected(period),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => SizedBox(width: 8 * scale),
        itemCount: _periods.length,
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.scale,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : _primaryText;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(20 * scale),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 9 * scale,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _buttonGreen
                : _cardBackground.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(20 * scale),
            border: Border.all(
              color: selected
                  ? _gold.withValues(alpha: 0.70)
                  : Colors.white.withValues(alpha: 0.66),
              width: 0.7 * scale,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _buttonGreen.withValues(alpha: 0.16),
                      blurRadius: 16 * scale,
                      offset: Offset(0, 7 * scale),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.3 * scale,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    const metrics = [
      _MetricData(
        icon: Icons.spa_rounded,
        value: '15.432',
        label: 'Toplam Zikir',
        color: _buttonGreen,
      ),
      _MetricData(
        icon: Icons.calendar_today_rounded,
        value: '365',
        label: 'Aktif Gün',
        color: _primaryGreen,
      ),
      _MetricData(
        icon: Icons.schedule_rounded,
        value: '42 sa',
        label: 'Toplam Süre',
        color: _gold,
      ),
      _MetricData(
        icon: Icons.local_fire_department_rounded,
        value: '286',
        label: 'Bugünkü Zikir',
        color: _buttonGreen,
      ),
    ];

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        14 * scale,
        14 * scale,
        14 * scale,
        12 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OverviewHeader(scale: scale),
          SizedBox(height: 14 * scale),
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(
                  child: _OverviewMetricTile(scale: scale, metric: metrics[i]),
                ),
                if (i != metrics.length - 1)
                  _SubtleVerticalDivider(scale: scale),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Genel Bakış',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryText,
            fontSize: 15 * scale,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        SizedBox(height: 5 * scale),
        Text(
          'Tüm zamanlar özeti',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _secondaryText,
            fontSize: 11.1 * scale,
            fontWeight: FontWeight.w600,
            height: 1.08,
          ),
        ),
      ],
    );
  }
}

class _OverviewMetricTile extends StatelessWidget {
  const _OverviewMetricTile({required this.scale, required this.metric});

  final double scale;
  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: metric.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 29 * scale,
            child: Icon(metric.icon, color: metric.color, size: 15 * scale),
          ),
        ),
        SizedBox(height: 9 * scale),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryText,
            fontSize: 14.7 * scale,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        SizedBox(height: 5 * scale),
        Text(
          metric.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryText,
            fontSize: 8.5 * scale,
            fontWeight: FontWeight.w700,
            height: 1.08,
          ),
        ),
      ],
    );
  }
}

class _DayPartDistributionCard extends StatelessWidget {
  const _DayPartDistributionCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    const rows = [
      _DayPartData(
        icon: Icons.wb_sunny_rounded,
        label: 'Sabah',
        percent: 0,
        color: Color(0xFFE9A84B),
      ),
      _DayPartData(
        icon: Icons.light_mode_rounded,
        label: 'Öğle',
        percent: 18,
        color: Color(0xFFD8BA65),
      ),
      _DayPartData(
        icon: Icons.wb_twilight_rounded,
        label: 'İkindi',
        percent: 11,
        color: Color(0xFFC9A554),
      ),
      _DayPartData(
        icon: Icons.apartment_rounded,
        label: 'Akşam',
        percent: 19,
        color: _buttonGreen,
      ),
      _DayPartData(
        icon: Icons.nightlight_round,
        label: 'Yatsı',
        percent: 52,
        color: _gold,
        highlighted: true,
      ),
    ];

    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        14 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gün İçi Zikir Dağılımı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 17 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      'Zikirlerini hangi vakit diliminde çekiyorsun?',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 12.2 * scale,
                        fontWeight: FontWeight.w600,
                        height: 1.18,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10 * scale),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.60),
                    width: 0.7 * scale,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9 * scale,
                    vertical: 5.5 * scale,
                  ),
                  child: Text(
                    'Tüm zamanlar',
                    style: TextStyle(
                      color: _primaryText.withValues(alpha: 0.78),
                      fontSize: 10.2 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(18 * scale),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.58),
                width: 0.7 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12 * scale,
                12 * scale,
                12 * scale,
                11 * scale,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    _DayPartRow(scale: scale, data: rows[i]),
                    if (i != rows.length - 1) SizedBox(height: 9 * scale),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 10 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14 * scale),
              border: Border.all(
                color: _gold.withValues(alpha: 0.22),
                width: 0.7 * scale,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 11 * scale,
                vertical: 9 * scale,
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: _gold, size: 14 * scale),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: _primaryText,
                          fontFamily: 'Inter',
                          fontSize: 10.7 * scale,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        children: const [
                          TextSpan(text: 'Zikirlerinin %52’sini '),
                          TextSpan(
                            text: 'Yatsı vaktinde',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' çekiyorsun.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPartRow extends StatelessWidget {
  const _DayPartRow({required this.scale, required this.data});

  final double scale;
  final _DayPartData data;

  @override
  Widget build(BuildContext context) {
    final labelColor = data.highlighted ? _primaryText : _primaryText;
    final valueColor = data.highlighted ? _primaryText : _secondaryText;

    return Row(
      children: [
        SizedBox.square(
          dimension: 22 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: data.color.withValues(
                alpha: data.highlighted ? 0.18 : 0.13,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 13 * scale),
          ),
        ),
        SizedBox(width: 9 * scale),
        SizedBox(
          width: 47 * scale,
          child: Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: 11.3 * scale,
              fontWeight: data.highlighted ? FontWeight.w800 : FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: 9 * scale),
        Expanded(
          child: SizedBox(
            height: 7 * scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: _primaryGreen.withValues(alpha: 0.075)),
                  FractionallySizedBox(
                    widthFactor: data.percent / 100,
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            data.color.withValues(alpha: 0.48),
                            data.color,
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
        SizedBox(width: 10 * scale),
        SizedBox(
          width: 32 * scale,
          child: Text(
            '%${data.percent}',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 10.8 * scale,
              fontWeight: data.highlighted ? FontWeight.w900 : FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveChartPair extends StatelessWidget {
  const _ResponsiveChartPair({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final pairCardHeight = 262 * scale;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              height: pairCardHeight,
              child: _DistributionCard(
                scale: scale,
                includeMargin: false,
                compact: true,
              ),
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: SizedBox(
              height: pairCardHeight,
              child: _RecordCard(scale: scale),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.scale,
    this.includeMargin = true,
    this.compact = false,
  });

  final double scale;
  final bool includeMargin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const items = [
      _DistributionItem('Sübhanallah', '6.120', '%39', Color(0xFF1D6B49), 39),
      _DistributionItem('Elhamdülillah', '4.230', '%27', Color(0xFF5D9B78), 27),
      _DistributionItem('Allahu Ekber', '3.150', '%20', Color(0xFFA8CDB7), 20),
      _DistributionItem('Estağfirullah', '1.932', '%14', Color(0xFF8DBA9E), 14),
    ];

    return _StatsCard(
      scale: scale,
      margin: includeMargin
          ? EdgeInsets.symmetric(horizontal: 18 * scale)
          : EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(
        (compact ? 11 : 15) * scale,
        (compact ? 12 : 15) * scale,
        (compact ? 11 : 15) * scale,
        (compact ? 11 : 15) * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          compact
              ? _CompactCardHeader(
                  scale: scale,
                  title: 'Zikir Dağılımı',
                  description: 'En çok okuduğun zikirler',
                )
              : _CardHeader(
                  scale: scale,
                  title: 'Zikir Dağılımı',
                  description: 'En çok okuduğun zikirler',
                ),
          SizedBox(height: (compact ? 10 : 16) * scale),
          Center(
            child: SizedBox.square(
              dimension: (compact ? 104 : 142) * scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square((compact ? 104 : 142) * scale),
                    painter: _DonutChartPainter(
                      segments: items
                          .map(
                            (item) => _DonutSegment(
                              value: item.percent.toDouble(),
                              color: item.color,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Toplam',
                        style: TextStyle(
                          color: _secondaryText,
                          fontSize: (compact ? 9.5 : 11.4) * scale,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: (compact ? 4 : 5) * scale),
                      Text(
                        '15.432',
                        style: TextStyle(
                          color: _primaryText,
                          fontSize: (compact ? 14.5 : 18) * scale,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: (compact ? 11 : 16) * scale),
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: (compact ? 7 : 8) * scale),
              child: _DistributionRow(
                scale: scale,
                item: item,
                compact: compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.scale,
    required this.item,
    this.compact = false,
  });

  final double scale;
  final _DistributionItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
          child: SizedBox.square(dimension: (compact ? 6.5 : 8) * scale),
        ),
        SizedBox(width: (compact ? 6 : 10) * scale),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _primaryText,
              fontSize: (compact ? 9.3 : 11.8) * scale,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        Text(
          item.value,
          style: TextStyle(
            color: _primaryText,
            fontSize: (compact ? 9.1 : 11.4) * scale,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        SizedBox(width: (compact ? 6 : 14) * scale),
        SizedBox(
          width: (compact ? 25 : 32) * scale,
          child: Text(
            item.percentLabel,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _secondaryText,
              fontSize: (compact ? 9 : 11.2) * scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(
        11 * scale,
        12 * scale,
        11 * scale,
        12 * scale,
      ),
      child: SizedBox(
        height: 225 * scale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: _gold,
                  size: 14 * scale,
                ),
                SizedBox(width: 4 * scale),
                Text(
                  'Rekorun',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 12.3 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 11 * scale),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.70),
                    width: 0.8 * scale,
                  ),
                ),
                child: SizedBox.square(
                  dimension: 64 * scale,
                  child: Center(
                    child: Text(
                      '88',
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 34 * scale,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              'zikir',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 10.2 * scale,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            SizedBox(height: 12 * scale),
            Text(
              '18 Nisan Cumartesi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryText,
                fontSize: 10.7 * scale,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            SizedBox(height: 12 * scale),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14 * scale),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.22),
                  width: 0.7 * scale,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 8 * scale,
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 8.6 * scale,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    children: const [
                      TextSpan(text: 'Günlük ortalamanın '),
                      TextSpan(
                        text: '4.6x katı',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(text: '\nEn çok '),
                      TextSpan(
                        text: 'Sübhanallah (84)',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _buttonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 9 * scale,
                  vertical: 7 * scale,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: _buttonGreen,
                      size: 13 * scale,
                    ),
                    SizedBox(width: 4 * scale),
                    Flexible(
                      child: Text(
                        'En iyi günün',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _primaryText,
                          fontSize: 9.8 * scale,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyProgressCard extends StatelessWidget {
  const _MonthlyProgressCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      scale: scale,
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        15 * scale,
        15 * scale,
        15 * scale,
        16 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            scale: scale,
            title: 'Aylık İlerleme',
            description: 'Son 6 ayda okuduğun zikir sayıları',
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            height: 162 * scale,
            child: CustomPaint(
              painter: _LineChartPainter(
                months: const ['Ara', 'Oca', 'Şub', 'Mar', 'Nis', 'May'],
                values: const [5200, 8500, 12000, 15500, 14200, 11800],
                scale: scale,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCardHeader extends StatelessWidget {
  const _CompactCardHeader({
    required this.scale,
    required this.title,
    required this.description,
  });

  final double scale;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryText,
            fontSize: 13.5 * scale,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _secondaryText,
            fontSize: 9.4 * scale,
            fontWeight: FontWeight.w600,
            height: 1.16,
          ),
        ),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.scale,
    required this.title,
    required this.description,
  });

  final double scale;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _primaryText,
            fontSize: 17 * scale,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        SizedBox(height: 5 * scale),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _secondaryText,
            fontSize: 12.2 * scale,
            fontWeight: FontWeight.w600,
            height: 1.18,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.scale,
    required this.margin,
    required this.padding,
    required this.child,
  });

  final double scale;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(24 * scale);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: _softShadow(scale),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _cardBackground.withValues(alpha: 0.92),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.68),
              width: 0.8 * scale,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _SubtleVerticalDivider extends StatelessWidget {
  const _SubtleVerticalDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8 * scale,
      height: 62 * scale,
      margin: EdgeInsets.symmetric(horizontal: 6 * scale),
      color: _dividerColor.withValues(alpha: 0.72),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.segments});

  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.18;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    var start = -math.pi / 2;
    final gap = 0.025;

    final backgroundPaint = Paint()
      ..color = _dividerColor.withValues(alpha: 0.44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    for (final segment in segments) {
      final sweep = math.pi * 2 * (segment.value / total);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start + gap, sweep - gap * 2, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.months,
    required this.values,
    required this.scale,
  });

  final List<String> months;
  final List<int> values;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    final leftPadding = 36 * scale;
    final bottomPadding = 26 * scale;
    final topPadding = 8 * scale;
    final rightPadding = 4 * scale;
    final chartRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );

    final gridPaint = Paint()
      ..color = _dividerColor.withValues(alpha: 0.62)
      ..strokeWidth = 0.7 * scale;
    final axisLabels = [
      ('20K', 20000.0),
      ('15K', 15000.0),
      ('10K', 10000.0),
      ('5K', 5000.0),
      ('0', 0.0),
    ];

    for (final (label, value) in axisLabels) {
      final y = _valueToY(value, chartRect);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: _secondaryText.withValues(alpha: 0.86),
          fontSize: 10 * scale,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout(maxWidth: leftPadding - 7 * scale);
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x =
          chartRect.left +
          (chartRect.width * i / math.max(1, values.length - 1));
      points.add(Offset(x, _valueToY(values[i].toDouble(), chartRect)));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _buttonGreen.withValues(alpha: 0.18),
          _buttonGreen.withValues(alpha: 0.02),
        ],
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = _buttonGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final pointFill = Paint()..color = _buttonGreen;
    final pointStroke = Paint()
      ..color = _cardBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale;
    for (final point in points) {
      canvas.drawCircle(point, 4 * scale, pointFill);
      canvas.drawCircle(point, 4 * scale, pointStroke);
    }

    for (var i = 0; i < months.length; i++) {
      textPainter.text = TextSpan(
        text: months[i],
        style: TextStyle(
          color: _secondaryText,
          fontSize: 10.4 * scale,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      final x =
          chartRect.left +
          (chartRect.width * i / math.max(1, months.length - 1)) -
          textPainter.width / 2;
      textPainter.paint(canvas, Offset(x, chartRect.bottom + 10 * scale));
    }
  }

  double _valueToY(double value, Rect rect) {
    final normalized = (value / 20000).clamp(0.0, 1.0);
    return rect.bottom - rect.height * normalized;
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.months != months ||
        oldDelegate.values != values ||
        oldDelegate.scale != scale;
  }
}

class _StatisticsWashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lowerPaint = Paint()
      ..color = _gold.withValues(alpha: 0.030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;
    final lowerPath = Path()
      ..moveTo(size.width * 1.12, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.58,
        size.width * -0.12,
        size.height * 0.86,
      );
    canvas.drawPath(lowerPath, lowerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

List<BoxShadow> _softShadow(double scale) {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.045),
      blurRadius: 18 * scale,
      offset: Offset(0, 8 * scale),
    ),
  ];
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
}

class _DistributionItem {
  const _DistributionItem(
    this.label,
    this.value,
    this.percentLabel,
    this.color,
    this.percent,
  );

  final String label;
  final String value;
  final String percentLabel;
  final Color color;
  final int percent;
}

class _DayPartData {
  const _DayPartData({
    required this.icon,
    required this.label,
    required this.percent,
    required this.color,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final int percent;
  final Color color;
  final bool highlighted;
}

class _DonutSegment {
  const _DonutSegment({required this.value, required this.color});

  final double value;
  final Color color;
}
