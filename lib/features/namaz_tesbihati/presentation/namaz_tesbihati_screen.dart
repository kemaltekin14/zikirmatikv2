import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/layout/proportional_layout.dart';
import '../../../shared/widgets/app_menu_drawer.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

const _pageBackground = Color(0xFFE9EEE4);
const _primaryGreen = Color(0xFF13472F);
const _mutedText = Color(0xFF69766E);
const _cardSurface = Color(0xFFFAFAF4);
const _paleSage = Color(0xFFE5ECE2);
const _softGold = Color(0xFFE9D798);
const _heroAsset = 'assets/images/namaztesbihatihero.webp';
const _heroSearchBackdropExtension = 20.0;
const _bottomNavBaseHeight = 76.0;
const _bottomNavBaseGap = 10.0;
const _bottomNavMaxSafeInset = 4.0;
const _scrollExtraBottomSpacing = 42.0;

double _bottomNavBottomOffset(double safeBottom, double scale) {
  final visualSafeInset = math.min(safeBottom, _bottomNavMaxSafeInset * scale);
  return _bottomNavBaseGap * scale + visualSafeInset;
}

const _prayerTimes = [
  _PrayerTimeData(label: 'Sabah', icon: Icons.wb_sunny_rounded),
  _PrayerTimeData(label: 'Öğle', icon: Icons.light_mode_outlined),
  _PrayerTimeData(label: 'İkindi', icon: Icons.wb_twilight_rounded),
  _PrayerTimeData(label: 'Akşam', icon: Icons.wb_twilight_outlined),
  _PrayerTimeData(label: 'Yatsı', icon: Icons.dark_mode_rounded),
];

const _tesbihatSteps = [
  _TesbihatStepData(title: 'Subhanallah', countLabel: '0/33'),
  _TesbihatStepData(title: 'Elhamdülillah', countLabel: '0/33'),
  _TesbihatStepData(title: 'Allahu Ekber', countLabel: '0/34'),
  _TesbihatStepData(title: 'Kelime-i\nTevhid', countLabel: '0/1'),
];

class NamazTesbihatiScreen extends StatefulWidget {
  const NamazTesbihatiScreen({super.key});

  @override
  State<NamazTesbihatiScreen> createState() => _NamazTesbihatiScreenState();
}

class _NamazTesbihatiScreenState extends State<NamazTesbihatiScreen> {
  int _selectedPrayerTimeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final scale = proportionalLayoutScaleFor(screenWidth);
    final contentWidth = math.min(screenWidth, appLayoutBaselineWidth * scale);
    final horizontalInset = (screenWidth - contentWidth) / 2;
    final safeBottom = media.padding.bottom;
    final bottomNavHeight = _bottomNavBaseHeight * scale;
    final bottomNavOffset = _bottomNavBottomOffset(safeBottom, scale);
    final bottomReservedHeight = bottomNavHeight + bottomNavOffset;
    final scrollBottomPadding =
        bottomReservedHeight + _scrollExtraBottomSpacing * scale;
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.12).toDouble();

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
                bottom: bottomReservedHeight,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: scrollBottomPadding),
                  children: [
                    _NamazTesbihatiHero(
                      scale: scale,
                      safeTop: media.padding.top,
                      contentWidth: contentWidth,
                      horizontalInset: horizontalInset,
                    ),
                    Transform.translate(
                      offset: Offset(0, -6 * scale),
                      child: _TesbihatOverview(
                        scale: scale,
                        horizontalInset: horizontalInset,
                        selectedPrayerTimeIndex: _selectedPrayerTimeIndex,
                        onPrayerTimeSelected: (index) {
                          setState(() => _selectedPrayerTimeIndex = index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              HomeBottomNav(
                scale: scale,
                contentWidth: contentWidth,
                activeDestination: HomeBottomNavDestination.none,
                quickStartKey: const Key('namazTesbihati.quickStart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerTimeData {
  const _PrayerTimeData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _TesbihatStepData {
  const _TesbihatStepData({required this.title, required this.countLabel});

  final String title;
  final String countLabel;
}

class _TesbihatOverview extends StatelessWidget {
  const _TesbihatOverview({
    required this.scale,
    required this.horizontalInset,
    required this.selectedPrayerTimeIndex,
    required this.onPrayerTimeSelected,
  });

  final double scale;
  final double horizontalInset;
  final int selectedPrayerTimeIndex;
  final ValueChanged<int> onPrayerTimeSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset + 19 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrayerTimeSelector(
            scale: scale,
            selectedIndex: selectedPrayerTimeIndex,
            onSelected: onPrayerTimeSelected,
          ),
          SizedBox(height: 12 * scale),
          _TesbihatProgressCard(scale: scale),
        ],
      ),
    );
  }
}

class _PrayerTimeSelector extends StatelessWidget {
  const _PrayerTimeSelector({
    required this.scale,
    required this.selectedIndex,
    required this.onSelected,
  });

  final double scale;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39 * scale,
      child: Row(
        children: [
          for (var index = 0; index < _prayerTimes.length; index++) ...[
            Expanded(
              child: _PrayerTimeChip(
                data: _prayerTimes[index],
                scale: scale,
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
            ),
            if (index != _prayerTimes.length - 1) SizedBox(width: 6 * scale),
          ],
        ],
      ),
    );
  }
}

class _PrayerTimeChip extends StatelessWidget {
  const _PrayerTimeChip({
    required this.data,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  final _PrayerTimeData data;
  final double scale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? _primaryGreen : _mutedText;
    final radius = BorderRadius.circular(17 * scale);

    return _PressedScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 39 * scale,
            padding: EdgeInsets.symmetric(horizontal: 5 * scale),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: selected
                  ? _cardSurface.withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.58),
              border: Border.all(
                color: selected
                    ? _primaryGreen.withValues(alpha: 0.62)
                    : Colors.white.withValues(alpha: 0.76),
                width: selected ? 1.15 * scale : 0.8 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? _primaryGreen.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.035),
                  blurRadius: selected ? 18 * scale : 12 * scale,
                  offset: Offset(0, selected ? 7 * scale : 5 * scale),
                ),
                if (selected)
                  BoxShadow(
                    color: _softGold.withValues(alpha: 0.18),
                    blurRadius: 12 * scale,
                    offset: Offset(0, 3 * scale),
                  ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.icon, color: foreground, size: 15 * scale),
                  SizedBox(width: 4.5 * scale),
                  Text(
                    data.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12.2 * scale,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      height: 1,
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

class _TesbihatProgressCard extends StatelessWidget {
  const _TesbihatProgressCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24 * scale),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            14 * scale,
            16 * scale,
            14 * scale,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24 * scale),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.84),
                _cardSurface.withValues(alpha: 0.72),
                _paleSage.withValues(alpha: 0.34),
              ],
              stops: const [0.0, 0.58, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.78),
              width: 0.8 * scale,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.08),
                blurRadius: 24 * scale,
                offset: Offset(0, 11 * scale),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.55),
                blurRadius: 12 * scale,
                offset: Offset(0, -3 * scale),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 37 * scale,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 16 * scale,
                      child: CustomPaint(
                        painter: _TesbihatConnectorPainter(
                          scale: scale,
                          activeIndex: 0,
                        ),
                        child: SizedBox(height: 3 * scale),
                      ),
                    ),
                    Row(
                      children: [
                        for (
                          var index = 0;
                          index < _tesbihatSteps.length;
                          index++
                        )
                          Expanded(
                            child: Center(
                              child: _TesbihatStepBadge(
                                number: index + 1,
                                active: index == 0,
                                scale: scale,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6 * scale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < _tesbihatSteps.length; index++)
                    Expanded(
                      child: _TesbihatStepLabel(
                        data: _tesbihatSteps[index],
                        active: index == 0,
                        scale: scale,
                      ),
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

class _TesbihatStepBadge extends StatelessWidget {
  const _TesbihatStepBadge({
    required this.number,
    required this.active,
    required this.scale,
  });

  final int number;
  final bool active;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = active ? 37 * scale : 34 * scale;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3F8A63), _primaryGreen],
              )
            : null,
        color: active ? null : _paleSage.withValues(alpha: 0.78),
        border: Border.all(
          color: active
              ? _softGold.withValues(alpha: 0.62)
              : Colors.white.withValues(alpha: 0.82),
          width: active ? 1.2 * scale : 0.9 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? _primaryGreen.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.035),
            blurRadius: active ? 14 * scale : 9 * scale,
            offset: Offset(0, active ? 6 * scale : 4 * scale),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: active ? const Color(0xFFF7EDC2) : _mutedText,
          fontSize: 13.2 * scale,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _TesbihatStepLabel extends StatelessWidget {
  const _TesbihatStepLabel({
    required this.data,
    required this.active,
    required this.scale,
  });

  final _TesbihatStepData data;
  final bool active;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final color = active ? _primaryGreen : _mutedText;
    final multiline = data.title.contains('\n');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3 * scale),
      child: Column(
        children: [
          SizedBox(
            height: 27 * scale,
            child: Center(
              child: multiline
                  ? Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: 10.8 * scale,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(height: 2 * scale),
          Text(
            data.countLabel,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color.withValues(alpha: active ? 0.92 : 0.78),
              fontSize: 11.7 * scale,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TesbihatConnectorPainter extends CustomPainter {
  const _TesbihatConnectorPainter({
    required this.scale,
    required this.activeIndex,
  });

  final double scale;
  final int activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final stepWidth = size.width / _tesbihatSteps.length;
    final y = size.height / 2;
    final inactivePaint = Paint()
      ..color = _paleSage.withValues(alpha: 0.80)
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = _primaryGreen.withValues(alpha: 0.78)
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < _tesbihatSteps.length - 1; index++) {
      final start = Offset((index + 0.5) * stepWidth + 24 * scale, y);
      final end = Offset((index + 1.5) * stepWidth - 24 * scale, y);
      canvas.drawLine(start, end, inactivePaint);

      if (index == activeIndex) {
        final activeEnd = Offset(start.dx + (end.dx - start.dx) * 0.48, y);
        canvas.drawLine(start, activeEnd, activePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TesbihatConnectorPainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.activeIndex != activeIndex;
  }
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
        scale: _pressed ? 0.985 : 1,
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

class _NamazTesbihatiHero extends StatelessWidget {
  const _NamazTesbihatiHero({
    required this.scale,
    required this.safeTop,
    required this.contentWidth,
    required this.horizontalInset,
  });

  final double scale;
  final double safeTop;
  final double contentWidth;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    const heroAssetVisualScale = 0.83;
    const heroAssetBaseWidth = appLayoutBaselineWidth;
    final heroHeight = (112 + _heroSearchBackdropExtension) * scale + safeTop;
    final heroAssetTop = contentWidth < appLayoutBaselineWidth
        ? -12 * scale
        : 0.0;
    final titleLeft = horizontalInset + 64 * scale;
    final titleTop = safeTop + 10 * scale;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFCF7),
                          Color(0xFFFFFCF7),
                          _pageBackground,
                        ],
                        stops: [0.0, 0.58, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: heroAssetTop,
                  right: 0,
                  child: IgnorePointer(
                    child: Transform.scale(
                      alignment: Alignment.topRight,
                      scale: scale * heroAssetVisualScale,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0xFFFFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.0, 0.28, 1.0],
                          ).createShader(bounds);
                        },
                        child: Image.asset(
                          _heroAsset,
                          width: heroAssetBaseWidth,
                          fit: BoxFit.contain,
                          alignment: Alignment.topRight,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFFFFFCF7).withValues(alpha: 0.48),
                          const Color(0xFFFFFCF7).withValues(alpha: 0.22),
                          const Color(0xFFFFFCF7).withValues(alpha: 0.00),
                        ],
                        stops: const [0.0, 0.38, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.00),
                          _pageBackground.withValues(alpha: 0.34),
                        ],
                        stops: const [0.0, 0.66, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: horizontalInset + 20 * scale,
            top: safeTop + 4 * scale,
            child: _HeroMenuButton(scale: scale),
          ),
          Positioned(
            left: titleLeft,
            right: horizontalInset + 18 * scale,
            top: titleTop,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Namaz Tesbihatı',
                    maxLines: 1,
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 21.5 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
                SizedBox(height: 8 * scale),
                SizedBox(
                  width: contentWidth * 0.62,
                  child: Text(
                    'Namaz sonrası tesbihatı huzurla,\nadım adım tamamla.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryGreen.withValues(alpha: 0.86),
                      fontSize: 12.2 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.34,
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
          color: _cardSurface.withValues(alpha: 0.96),
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
