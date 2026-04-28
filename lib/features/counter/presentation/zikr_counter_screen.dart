import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/counter_controller.dart';
import '../../../shared/layout/proportional_layout.dart';

const _backgroundAsset = 'assets/images/zikr_counter_bg.webp';
const _counterRingAsset = 'assets/images/zikr_counter_ring.png';
const _tesbihAsset = 'assets/images/zikr_tesbih.png';

const _pageBackground = Color(0xFFE9EEE4);
const _primaryGreen = Color(0xFF123B2B);
const _deepGreen = Color(0xFF082D20);
const _gold = Color(0xFFD2B56D);
const _sonarGold = Color(0xFFC4A25A);
const _sonarSage = Color(0xFF8C9A78);
const _titleGold = Color(0xFFB88B37);
const _mutedGold = Color(0xFF9D7D36);
const _arabicTitleColor = Color(0xFFC89B3C);
const _latinTitleColor = Color(0xFF0F4A36);
const _latinTitleGlowColor = Color(0xFFE8C764);
const _cream = Color(0xFFFBF7ED);
const _counterInterior = Color(0xFFECE5D4);
const _counterTargetPillSurface = Color(0xFFE7DFC8);
const _referencePanelSurface = Color(0xFFF0EADD);
const _referenceControlSurface = Color(0xFFF0EBDE);
const _referenceModeTop = Color(0xFF184637);
const _referenceModeMiddle = Color(0xFF123B2B);
const _referenceModeBottom = Color(0xFF0F362C);

const _contentHorizontalPadding = 24.0;
const _topContentInset = 8.0;
const _topNavHeight = 46.0;
const _titleTopGap = 5.0;
const _titleSectionHeight = 122.0;
const _targetTopGap = 3.0;
const _targetPillHeight = 31.0;
const _counterTopGap = 2.0;
const _progressTopGap = 14.0;
const _progressCardHeight = 86.0;
const _progressHorizontalInset = 30.0;
const _bottomControlGap = 10.0;
const _bottomControlHeight = 84.0;
const _bottomInset = 6.0;
const _navButtonSize = 42.0;
const _counterMinSize = 292.0;
const _counterMaxSize = 382.0;
const _counterGroupScale = 1.10;
const _counterVisualLift = 12.0;
const _titleVisualLift = 18.0;
const _targetPillRowLift = 14.0;
const _infiniteTarget = 0;
const _maxLayoutHeight = 778.0;
const _contentMaxWidth = 430.0;
const _minScreenScale = 0.92;
const _maxScreenScale = 1.10;
const _minCompactScale = 0.88;
const _progressAnimationDuration = Duration(milliseconds: 560);
const _progressAnimationCurve = Curves.fastOutSlowIn;

class ZikrCounterScreen extends ConsumerStatefulWidget {
  const ZikrCounterScreen({super.key});

  @override
  ConsumerState<ZikrCounterScreen> createState() => _ZikrCounterScreenState();
}

class _ZikrCounterScreenState extends ConsumerState<ZikrCounterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sonarController;
  late int _selectedTarget;
  var _tesbihModeEnabled = true;
  var _vibrationEnabled = true;
  var _muted = false;
  Offset? _sonarCenter;
  var _sonarRingRadius = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedTarget = ref.read(counterControllerProvider).target;
    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
  }

  @override
  void dispose() {
    _sonarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counter = ref.watch(counterControllerProvider);
    final media = MediaQuery.of(context);
    final scale = _counterScaleFor(media.size.width);
    final contentWidth = math.min(media.size.width, _contentMaxWidth * scale);
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.12).toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _pageBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          backgroundColor: _pageBackground,
          body: Stack(
            children: [
              const Positioned.fill(child: _CounterBackgroundLayer()),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _sonarController,
                    builder: (context, _) {
                      final center = _sonarCenter;
                      if (center == null) return const SizedBox.shrink();

                      return CustomPaint(
                        painter: _CounterSonarPainter(
                          progress: _sonarController.value,
                          center: center,
                          ringRadius: _sonarRingRadius,
                          scale: scale,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final layoutHeight = math.min(
                      constraints.maxHeight,
                      _maxLayoutHeight * scale,
                    );
                    final compactScale =
                        (layoutHeight / (_maxLayoutHeight * scale))
                            .clamp(_minCompactScale, 1.0)
                            .toDouble();
                    double y(
                      double value, {
                      required double min,
                      required double max,
                    }) => (value * scale * compactScale)
                        .clamp(min, max)
                        .toDouble();
                    double x(
                      double value, {
                      required double min,
                      required double max,
                    }) => (value * scale).clamp(min, max).toDouble();

                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: contentWidth,
                        height: layoutHeight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: x(
                              _contentHorizontalPadding,
                              min: 18,
                              max: 27,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: y(_topContentInset, min: 8, max: 14),
                              ),
                              _TopNavigationArea(
                                scale: scale,
                                height: y(_topNavHeight, min: 42, max: 48),
                              ),
                              SizedBox(height: y(_titleTopGap, min: 3, max: 6)),
                              SizedBox(
                                height: y(
                                  _titleSectionHeight,
                                  min: 112,
                                  max: 130,
                                ),
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    -y(_titleVisualLift, min: 15, max: 22),
                                  ),
                                  child: _ZikrTitleSection(scale: scale),
                                ),
                              ),
                              SizedBox(
                                height: y(_targetTopGap, min: 1, max: 4),
                              ),
                              Transform.translate(
                                offset: Offset(
                                  0,
                                  -y(_targetPillRowLift, min: 10, max: 16),
                                ),
                                child: _TargetCountPills(
                                  scale: scale,
                                  height: y(
                                    _targetPillHeight,
                                    min: 29,
                                    max: 33,
                                  ),
                                  selectedTarget: _selectedTarget,
                                  onTargetChanged: _selectTarget,
                                  onCustomTarget: _showCustomTargetPlaceholder,
                                ),
                              ),
                              SizedBox(
                                height: y(_counterTopGap, min: 0, max: 3),
                              ),
                              Expanded(
                                child: _CentralCounterArea(
                                  scale: scale,
                                  count: counter.count,
                                  selectedTarget: _selectedTarget,
                                  onIncrement: _incrementCounter,
                                  onSonarStart: _startCounterSonar,
                                ),
                              ),
                              SizedBox(
                                height: y(_progressTopGap, min: 10, max: 15),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: x(
                                    _progressHorizontalInset,
                                    min: 26,
                                    max: 36,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        (-20 * scale)
                                            .clamp(-22, -18)
                                            .toDouble(),
                                      ),
                                      child: Text(
                                        'D O K U N A R A K  S A Y',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _titleGold,
                                          fontSize: (11.2 * scale)
                                              .clamp(10.4, 12.4)
                                              .toDouble(),
                                          fontWeight: FontWeight.w500,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: (7 * scale)
                                          .clamp(6, 8)
                                          .toDouble(),
                                    ),
                                    _ProgressCard(
                                      scale: scale,
                                      height: y(
                                        _progressCardHeight,
                                        min: 80,
                                        max: 90,
                                      ),
                                      count: counter.count,
                                      selectedTarget: _selectedTarget,
                                      progress: _progressFor(
                                        counter.count,
                                        _selectedTarget,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: y(_bottomControlGap, min: 7, max: 11),
                              ),
                              _BottomControlBar(
                                scale: scale,
                                height: y(
                                  _bottomControlHeight,
                                  min: 80,
                                  max: 88,
                                ),
                                tesbihModeEnabled: _tesbihModeEnabled,
                                vibrationEnabled: _vibrationEnabled,
                                muted: _muted,
                                onReset: _resetCounter,
                                onUndo: _decrementCounter,
                                onToggleTesbihMode: _toggleTesbihMode,
                                onToggleVibration: _toggleVibration,
                                onToggleMute: _toggleMute,
                              ),
                              SizedBox(height: y(_bottomInset, min: 4, max: 7)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTarget(int target) {
    setState(() => _selectedTarget = target);
    ref.read(counterControllerProvider.notifier).setTarget(target);
  }

  void _showCustomTargetPlaceholder() {}

  void _incrementCounter() {
    ref.read(counterControllerProvider.notifier).increment();
  }

  void _startCounterSonar(Offset center, double ringRadius) {
    setState(() {
      _sonarCenter = center;
      _sonarRingRadius = ringRadius;
    });
    _sonarController.forward(from: 0);
  }

  void _resetCounter() {
    ref.read(counterControllerProvider.notifier).reset();
  }

  void _decrementCounter() {
    ref.read(counterControllerProvider.notifier).decrement();
  }

  void _toggleTesbihMode() {
    setState(() => _tesbihModeEnabled = !_tesbihModeEnabled);
  }

  void _toggleVibration() {
    setState(() => _vibrationEnabled = !_vibrationEnabled);
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
  }

  double? _progressFor(int count, int target) {
    if (target == _infiniteTarget) return null;
    return (count / target).clamp(0, 1).toDouble();
  }

  double _counterScaleFor(double screenWidth) {
    return (screenWidth / appLayoutBaselineWidth)
        .clamp(_minScreenScale, _maxScreenScale)
        .toDouble();
  }
}

class _CounterBackgroundLayer extends StatelessWidget {
  const _CounterBackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _backgroundAsset,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  }
}

class _TopNavigationArea extends StatelessWidget {
  const _TopNavigationArea({required this.scale, required this.height});

  final double scale;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          _CounterNavButton(
            scale: scale,
            icon: Icons.chevron_left_rounded,
            tooltip: 'Geri',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          _CounterNavButton(
            scale: scale,
            icon: Icons.star_rounded,
            tooltip: 'Favori',
            color: const Color(0xFFE5B12E),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ZikrTitleSection extends StatelessWidget {
  const _ZikrTitleSection({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final titleWidth = math.min(screenWidth - 48 * scale, 336 * scale);
    final arabicFontSize = _responsiveFontSize(
      screenWidth,
      factor: 0.086,
      min: 31,
      max: 38,
    );
    final latinFontSize = _responsiveFontSize(
      screenWidth,
      factor: 0.074,
      min: 27,
      max: 33,
    );
    final meaningFontSize = _responsiveFontSize(
      screenWidth,
      factor: 0.03,
      min: 11.5,
      max: 13.2,
    );
    final gapScale = (screenWidth / appLayoutBaselineWidth)
        .clamp(0.9, 1.04)
        .toDouble();

    return Center(
      child: SizedBox(
        width: titleWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'سُبْحَانَ الله',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: _arabicTitleColor,
                  fontFamily: 'Amiri',
                  fontSize: arabicFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.04,
                  shadows: [
                    Shadow(
                      color: _mutedGold.withValues(alpha: 0.20),
                      blurRadius: 4 * scale,
                      offset: Offset(0, 1 * scale),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4 * gapScale),
              _PremiumShimmerText(
                'Sübhânallah',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _latinTitleColor,
                  fontFamily: 'EB Garamond',
                  fontSize: latinFontSize,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: _deepGreen.withValues(alpha: 0.14),
                      blurRadius: 4 * scale,
                      offset: Offset(0, 1.2 * scale),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5 * gapScale),
              _TitleDivider(scale: scale),
              SizedBox(height: 6 * gapScale),
              Text(
                'Allah her türlü eksiklikten uzaktır.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _primaryGreen.withValues(alpha: 0.88),
                  fontSize: meaningFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _responsiveFontSize(
    double screenWidth, {
    required double factor,
    required double min,
    required double max,
  }) {
    return (screenWidth * factor).clamp(min, max).toDouble();
  }
}

class _PremiumShimmerText extends StatefulWidget {
  const _PremiumShimmerText(
    this.text, {
    required this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  State<_PremiumShimmerText> createState() => _PremiumShimmerTextState();
}

class _PremiumShimmerTextState extends State<_PremiumShimmerText>
    with SingleTickerProviderStateMixin {
  static const _cycleDuration = Duration(milliseconds: 6400);
  static const _sweepWindow = 0.375;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycleDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final baseColor = widget.style.color ?? _latinTitleColor;
    final scale = (media.size.width / appLayoutBaselineWidth)
        .clamp(0.9, 1.08)
        .toDouble();

    if (media.disableAnimations) {
      return Text(
        widget.text,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
        style: widget.style,
      );
    }

    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final isSweeping = _controller.value <= _sweepWindow;
            final sweepRatio = (_controller.value / _sweepWindow)
                .clamp(0.0, 1.0)
                .toDouble();
            final shimmerProgress = sweepRatio;
            final glowStyle = widget.style.copyWith(
              color: baseColor,
              shadows: [
                ...?widget.style.shadows,
                if (isSweeping)
                  Shadow(
                    color: _latinTitleGlowColor.withValues(alpha: 0.11),
                    blurRadius: 6.2 * scale,
                    offset: Offset.zero,
                  ),
              ],
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  widget.text,
                  maxLines: widget.maxLines,
                  overflow: widget.overflow,
                  textAlign: widget.textAlign,
                  style: glowStyle,
                ),
                if (isSweeping)
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) {
                      final sweep = -1.06 + shimmerProgress * 2.12;
                      final softGold = Color.lerp(
                        baseColor,
                        _latinTitleGlowColor,
                        0.34,
                      )!;

                      return LinearGradient(
                        begin: Alignment(sweep - 1.08, -0.35),
                        end: Alignment(sweep + 1.08, 0.35),
                        colors: [
                          baseColor,
                          baseColor,
                          softGold,
                          _latinTitleGlowColor,
                          const Color(0xFFFFF0BC),
                          _latinTitleGlowColor,
                          softGold,
                          baseColor,
                          baseColor,
                        ],
                        stops: const [
                          0.00,
                          0.28,
                          0.40,
                          0.48,
                          0.52,
                          0.56,
                          0.64,
                          0.76,
                          1.00,
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      widget.text,
                      maxLines: widget.maxLines,
                      overflow: widget.overflow,
                      textAlign: widget.textAlign,
                      style: widget.style.copyWith(
                        color: Colors.white,
                        shadows: null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TitleDivider extends StatelessWidget {
  const _TitleDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 42 * scale,
          height: 1,
          color: _mutedGold.withValues(alpha: 0.74),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * scale),
          child: Icon(
            Icons.diamond_outlined,
            color: _mutedGold.withValues(alpha: 0.88),
            size: 14 * scale,
          ),
        ),
        Container(
          width: 42 * scale,
          height: 1,
          color: _mutedGold.withValues(alpha: 0.74),
        ),
      ],
    );
  }
}

class _TargetCountPills extends StatelessWidget {
  const _TargetCountPills({
    required this.scale,
    required this.height,
    required this.selectedTarget,
    required this.onTargetChanged,
    required this.onCustomTarget,
  });

  final double scale;
  final double height;
  final int selectedTarget;
  final ValueChanged<int> onTargetChanged;
  final VoidCallback onCustomTarget;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = math.min(5 * scale, constraints.maxWidth * 0.014);
        final rowWidth = math.min(
          constraints.maxWidth,
          (274 * scale).clamp(252, 296).toDouble(),
        );

        return Center(
          child: SizedBox(
            width: rowWidth,
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TargetPill(
                  scale: scale,
                  label: '33',
                  selected: selectedTarget == 33,
                  onPressed: () => onTargetChanged(33),
                ),
                SizedBox(width: gap),
                _TargetPill(
                  scale: scale,
                  label: '99',
                  selected: selectedTarget == 99,
                  onPressed: () => onTargetChanged(99),
                ),
                SizedBox(width: gap),
                _TargetPill(
                  scale: scale,
                  label: '100',
                  selected: selectedTarget == 100,
                  onPressed: () => onTargetChanged(100),
                ),
                SizedBox(width: gap),
                _TargetPill(
                  scale: scale,
                  icon: Icons.edit_rounded,
                  tooltip: 'Özel hedef',
                  onPressed: onCustomTarget,
                ),
                SizedBox(width: gap),
                _TargetPill(
                  scale: scale,
                  icon: Icons.all_inclusive_rounded,
                  tooltip: 'Sonsuz hedef',
                  selected: selectedTarget == _infiniteTarget,
                  onPressed: () => onTargetChanged(_infiniteTarget),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CentralCounterArea extends StatelessWidget {
  const _CentralCounterArea({
    required this.scale,
    required this.count,
    required this.selectedTarget,
    required this.onIncrement,
    required this.onSonarStart,
  });

  final double scale;
  final int count;
  final int selectedTarget;
  final VoidCallback onIncrement;
  final void Function(Offset center, double ringRadius) onSonarStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetLabel = selectedTarget == _infiniteTarget
            ? 'HEDEF ∞'
            : 'HEDEF $selectedTarget';
        final desiredRingSize =
            math.min(
              constraints.maxWidth * 0.98,
              constraints.maxHeight * 0.98,
            ) *
            _counterGroupScale;
        final ringMax = math.min(
          (_counterMaxSize * scale * _counterGroupScale)
              .clamp(363, 431)
              .toDouble(),
          math.min(constraints.maxWidth, constraints.maxHeight) * 1.12,
        );
        final ringMin = math.min(
          (_counterMinSize * scale * _counterGroupScale)
              .clamp(306, 350)
              .toDouble(),
          ringMax,
        );
        final ringSize = desiredRingSize.clamp(ringMin, ringMax).toDouble();
        final counterVisualLift = (_counterVisualLift * scale)
            .clamp(9, 14)
            .toDouble();
        final counterSize = ringSize;
        final tesbihHeight = (counterSize * 1.40).clamp(392, 520).toDouble();
        final tesbihWidth = tesbihHeight * 2 / 3;
        final tesbihRight = (-counterSize * 0.04).clamp(-18, -12).toDouble();
        final tesbihTop = (-counterSize * 0.055).clamp(-23, -14).toDouble();
        final interiorSize = (ringSize * 0.74).clamp(214, 286).toDouble();
        final counterNumberWidth = (ringSize * 0.48).clamp(154, 212).toDouble();
        final targetPillWidth = (ringSize * 0.27).clamp(92, 108).toDouble();
        final targetPillHeight = (31 * scale).clamp(29, 35).toDouble();
        final targetPillTop = counterSize * 0.69;

        return Center(
          child: Semantics(
            button: true,
            label: 'Sayacı artır',
            value: selectedTarget == _infiniteTarget
                ? '$count defa'
                : '$count / $selectedTarget',
            child: _PressableCounterDial(
              scale: scale,
              count: count,
              targetLabel: targetLabel,
              areaWidth: constraints.maxWidth,
              areaHeight: constraints.maxHeight,
              counterSize: counterSize,
              counterVisualLift: counterVisualLift,
              interiorSize: interiorSize,
              tesbihRight: tesbihRight,
              tesbihTop: tesbihTop,
              tesbihWidth: tesbihWidth,
              tesbihHeight: tesbihHeight,
              ringSize: ringSize,
              counterNumberWidth: counterNumberWidth,
              targetPillWidth: targetPillWidth,
              targetPillHeight: targetPillHeight,
              targetPillTop: targetPillTop,
              onIncrement: onIncrement,
              onSonarStart: onSonarStart,
            ),
          ),
        );
      },
    );
  }
}

class _PressableCounterDial extends StatefulWidget {
  const _PressableCounterDial({
    required this.scale,
    required this.count,
    required this.targetLabel,
    required this.areaWidth,
    required this.areaHeight,
    required this.counterSize,
    required this.counterVisualLift,
    required this.interiorSize,
    required this.tesbihRight,
    required this.tesbihTop,
    required this.tesbihWidth,
    required this.tesbihHeight,
    required this.ringSize,
    required this.counterNumberWidth,
    required this.targetPillWidth,
    required this.targetPillHeight,
    required this.targetPillTop,
    required this.onIncrement,
    required this.onSonarStart,
  });

  final double scale;
  final int count;
  final String targetLabel;
  final double areaWidth;
  final double areaHeight;
  final double counterSize;
  final double counterVisualLift;
  final double interiorSize;
  final double tesbihRight;
  final double tesbihTop;
  final double tesbihWidth;
  final double tesbihHeight;
  final double ringSize;
  final double counterNumberWidth;
  final double targetPillWidth;
  final double targetPillHeight;
  final double targetPillTop;
  final VoidCallback onIncrement;
  final void Function(Offset center, double ringRadius) onSonarStart;

  @override
  State<_PressableCounterDial> createState() => _PressableCounterDialState();
}

class _PressableCounterDialState extends State<_PressableCounterDial>
    with TickerProviderStateMixin {
  static const _pressSpring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 28,
  );

  late final AnimationController _pressController;
  late final AnimationController _countPopController;
  final _counterDialKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      lowerBound: -0.08,
      upperBound: 1,
    );
    _countPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _PressableCounterDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _countPopController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _countPopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('counter.increment'),
      behavior: HitTestBehavior.translucent,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _releasePress,
      onTap: _handleTap,
      child: SizedBox(
        width: widget.areaWidth,
        height: widget.areaHeight,
        child: Center(
          child: OverflowBox(
            maxWidth: widget.counterSize,
            maxHeight: widget.counterSize,
            child: Transform.translate(
              offset: Offset(0, -widget.counterVisualLift),
              child: RepaintBoundary(
                child: SizedBox.square(
                  key: _counterDialKey,
                  dimension: widget.counterSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pressController,
                        builder: (context, _) {
                          final pressState = _currentPressState;
                          final easedPress = pressState.easedPress;
                          final innerTravel = (4.2 * widget.scale)
                              .clamp(3.2, 5.1)
                              .toDouble();
                          final reboundLift = (1.0 * widget.scale)
                              .clamp(0.7, 1.3)
                              .toDouble();
                          final innerOffset =
                              easedPress * innerTravel -
                              pressState.rebound * reboundLift;
                          final innerScale =
                              1 -
                              easedPress * 0.010 +
                              pressState.rebound * 0.004;

                          return Transform.translate(
                            offset: Offset(0, innerOffset),
                            child: Transform.scale(
                              scale: innerScale,
                              child: Container(
                                width: widget.interiorSize,
                                height: widget.interiorSize,
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    _counterInterior,
                                    const Color(0xFFE0D0B2),
                                    easedPress * 0.88,
                                  )!,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: widget.tesbihRight,
                        top: widget.tesbihTop,
                        width: widget.tesbihWidth,
                        height: widget.tesbihHeight,
                        child: IgnorePointer(
                          child: Image.asset(_tesbihAsset, fit: BoxFit.contain),
                        ),
                      ),
                      SizedBox.square(
                        dimension: widget.ringSize,
                        child: Image.asset(
                          _counterRingAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pressController,
                        builder: (context, child) {
                          final pressState = _currentPressState;
                          final numberTravel = (2.7 * widget.scale)
                              .clamp(2.0, 3.4)
                              .toDouble();
                          final numberLift = (0.9 * widget.scale)
                              .clamp(0.6, 1.2)
                              .toDouble();
                          final numberOffset =
                              -widget.ringSize * 0.025 +
                              pressState.easedPress * numberTravel -
                              pressState.rebound * numberLift;
                          final numberScale =
                              1 -
                              pressState.easedPress * 0.012 +
                              pressState.rebound * 0.005;

                          return Transform.translate(
                            offset: Offset(0, numberOffset),
                            child: Transform.scale(
                              scale: numberScale,
                              child: child,
                            ),
                          );
                        },
                        child: SizedBox(
                          width: widget.counterNumberWidth,
                          height: (widget.ringSize * 0.23)
                              .clamp(66, 92)
                              .toDouble(),
                          child: AnimatedBuilder(
                            animation: _countPopController,
                            builder: (context, child) {
                              final progress = _countPopController.value
                                  .clamp(0.0, 1.0)
                                  .toDouble();
                              final pop = Curves.easeOutBack
                                  .transform(progress)
                                  .clamp(0.0, 1.12)
                                  .toDouble();
                              final settle = Curves.easeOutCubic.transform(
                                progress,
                              );
                              final scale = 0.92 + pop * 0.08;
                              final lift =
                                  (1 - settle) * widget.ringSize * 0.014;

                              return Transform.translate(
                                offset: Offset(0, lift),
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${widget.count}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _primaryGreen,
                                  fontSize: 90 * widget.scale,
                                  fontWeight: FontWeight.w900,
                                  height: 0.9,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pressController,
                        builder: (context, child) {
                          final pressState = _currentPressState;
                          final pillTravel = (2.2 * widget.scale)
                              .clamp(1.6, 2.8)
                              .toDouble();
                          final pillLift = (0.7 * widget.scale)
                              .clamp(0.5, 1.0)
                              .toDouble();

                          return Positioned(
                            top:
                                widget.targetPillTop +
                                pressState.easedPress * pillTravel -
                                pressState.rebound * pillLift,
                            left: 0,
                            right: 0,
                            child: child!,
                          );
                        },
                        child: Center(
                          child: Container(
                            width: widget.targetPillWidth,
                            height: widget.targetPillHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _counterTargetPillSurface.withValues(
                                alpha: 0.82,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _mutedGold.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Text(
                              widget.targetLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _primaryGreen.withValues(alpha: 0.86),
                                fontSize: 13 * widget.scale,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
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
      ),
    );
  }

  _CounterPressState get _currentPressState {
    final rawPress = _pressController.value;
    final press = rawPress.clamp(0.0, 1.0).toDouble();
    final rebound = ((-rawPress).clamp(0.0, 0.08) / 0.08).toDouble();
    return _CounterPressState(
      easedPress: Curves.easeOutCubic.transform(press),
      rebound: rebound,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.stop();
    _startSonarFromDialCenter();
    _pressController.animateTo(
      1,
      duration: const Duration(milliseconds: 72),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleTapUp(TapUpDetails details) {
    _releasePress();
  }

  void _handleTap() {
    widget.onIncrement();
  }

  void _releasePress() {
    _pressController.stop();
    _pressController.animateWith(
      SpringSimulation(_pressSpring, _pressController.value, 0, -4.4),
    );
  }

  void _startSonarFromDialCenter() {
    final renderBox =
        _counterDialKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    widget.onSonarStart(
      renderBox.localToGlobal(renderBox.size.center(Offset.zero)),
      widget.ringSize * 0.44,
    );
  }
}

class _CounterPressState {
  const _CounterPressState({required this.easedPress, required this.rebound});

  final double easedPress;
  final double rebound;
}

class _CounterSonarPainter extends CustomPainter {
  const _CounterSonarPainter({
    required this.progress,
    required this.center,
    required this.ringRadius,
    required this.scale,
  });

  final double progress;
  final Offset center;
  final double ringRadius;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    _drawRing(
      canvas: canvas,
      center: center,
      progress: progress,
      radiusStart: ringRadius + 1 * scale,
      radiusTravel: 22 * scale,
      alpha: 0.24,
      strokeWidth: 2.1 * scale,
      color: _sonarGold,
    );

    final delayedProgress = ((progress - 0.16) / 0.84).clamp(0.0, 1.0);
    if (delayedProgress > 0) {
      _drawRing(
        canvas: canvas,
        center: center,
        progress: delayedProgress,
        radiusStart: ringRadius + 4 * scale,
        radiusTravel: 18 * scale,
        alpha: 0.18,
        strokeWidth: 1.5 * scale,
        color: _sonarSage,
      );
    }

    final lateProgress = ((progress - 0.32) / 0.68).clamp(0.0, 1.0);
    if (lateProgress > 0) {
      _drawRing(
        canvas: canvas,
        center: center,
        progress: lateProgress,
        radiusStart: ringRadius + 7 * scale,
        radiusTravel: 14 * scale,
        alpha: 0.14,
        strokeWidth: 1.1 * scale,
        color: _sonarGold,
      );
    }
  }

  void _drawRing({
    required Canvas canvas,
    required Offset center,
    required double progress,
    required double radiusStart,
    required double radiusTravel,
    required double alpha,
    required double strokeWidth,
    required Color color,
  }) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final radiusProgress = Curves.easeOutCubic.transform(clampedProgress);
    final fade = math.pow(1 - clampedProgress, 0.72).toDouble();
    final radius = radiusStart + radiusTravel * radiusProgress;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (strokeWidth * (1 - radiusProgress * 0.34))
            .clamp(0.8, strokeWidth)
            .toDouble()
        ..color = color.withValues(alpha: alpha * fade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.55 * scale),
    );
  }

  @override
  bool shouldRepaint(covariant _CounterSonarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.center != center ||
        oldDelegate.ringRadius != ringRadius ||
        oldDelegate.scale != scale;
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.scale,
    required this.height,
    required this.count,
    required this.selectedTarget,
    required this.progress,
  });

  final double scale;
  final double height;
  final int count;
  final int selectedTarget;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final isInfinite = selectedTarget == _infiniteTarget;
    final remaining = isInfinite ? null : math.max(selectedTarget - count, 0);

    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(
        (20 * scale).clamp(17, 22).toDouble(),
        (10 * scale).clamp(8, 11).toDouble(),
        (20 * scale).clamp(17, 22).toDouble(),
        (8 * scale).clamp(6, 9).toDouble(),
      ),
      decoration: BoxDecoration(
        color: _referencePanelSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(
          color: _mutedGold.withValues(alpha: 0.34),
          width: 0.9 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: _deepGreen.withValues(alpha: 0.08),
            blurRadius: 22 * scale,
            offset: Offset(0, 9 * scale),
          ),
          BoxShadow(
            color: _gold.withValues(alpha: 0.07),
            blurRadius: 16 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'TOPLAM İLERLEMEN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 12.2 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Text(
                isInfinite ? '$count / ∞' : '$count / $selectedTarget',
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: (7 * scale).clamp(6, 8).toDouble()),
          _PremiumProgressBar(scale: scale, progress: progress),
          SizedBox(height: (7 * scale).clamp(5, 8).toDouble()),
          Text(
            isInfinite ? 'Sonsuz hedef' : '$remaining zikir kaldı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 12.5 * scale,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumProgressBar extends StatefulWidget {
  const _PremiumProgressBar({required this.scale, required this.progress});

  final double scale;
  final double? progress;

  @override
  State<_PremiumProgressBar> createState() => _PremiumProgressBarState();
}

class _PremiumProgressBarState extends State<_PremiumProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _sparkController;
  var _animationGeneration = 0;

  double get _targetProgress =>
      (widget.progress ?? 0).clamp(0.0, 1.0).toDouble();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
      value: _targetProgress,
    );
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
  }

  @override
  void didUpdateWidget(covariant _PremiumProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextProgress = _targetProgress;
    if ((_controller.value - nextProgress).abs() < 0.0001) {
      _controller.value = nextProgress;
      _sparkController.stop();
      _sparkController.value = 0;
      return;
    }
    final generation = ++_animationGeneration;
    _sparkController.repeat();
    _controller
        .animateTo(
          nextProgress,
          duration: _progressAnimationDuration,
          curve: _progressAnimationCurve,
        )
        .whenComplete(() {
          if (!mounted || generation != _animationGeneration) return;
          _sparkController
            ..stop()
            ..value = 0;
        });
  }

  @override
  void dispose() {
    _sparkController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackHeight = (10 * widget.scale).clamp(8.5, 11).toDouble();
    final glowSize = (24 * widget.scale).clamp(21, 27).toDouble();

    return SizedBox(
      height: trackHeight + 6 * widget.scale,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: Listenable.merge([_controller, _sparkController]),
            builder: (context, child) {
              return SizedBox.expand(
                child: CustomPaint(
                  painter: _MeteorProgressPainter(
                    progress: _controller.value,
                    shimmer: _sparkController.value,
                    active: _controller.isAnimating,
                    trackHeight: trackHeight,
                    glowSize: glowSize,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MeteorProgressPainter extends CustomPainter {
  const _MeteorProgressPainter({
    required this.progress,
    required this.shimmer,
    required this.active,
    required this.trackHeight,
    required this.glowSize,
  });

  final double progress;
  final double shimmer;
  final bool active;
  final double trackHeight;
  final double glowSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final value = progress.clamp(0.0, 1.0).toDouble();
    final centerY = size.height / 2;
    final trackRect = Rect.fromLTWH(
      0,
      centerY - trackHeight / 2,
      size.width,
      trackHeight,
    );
    final trackRRect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(999),
    );

    canvas.drawRRect(
      trackRRect,
      Paint()..color = const Color(0xFFD6D4C6).withValues(alpha: 0.86),
    );

    if (value <= 0.001) return;

    final fillWidth = (size.width * value).clamp(0.0, size.width).toDouble();
    final headX = fillWidth.clamp(0.0, size.width).toDouble();
    final fillRect = Rect.fromLTWH(0, trackRect.top, fillWidth, trackHeight);
    final fillRRect = RRect.fromRectAndRadius(
      fillRect,
      const Radius.circular(999),
    );
    final pulse = active
        ? (0.5 + 0.5 * math.sin(shimmer * math.pi * 2)).clamp(0.0, 1.0)
        : 0.0;
    const glowGold = Color(0xFFFFE01B);
    const softGlowGold = Color(0xFFFFC400);
    const deepGlowGold = Color(0xFFFF9800);
    final shine = active ? 0.92 + pulse * 0.08 : 0.58;

    canvas.drawRRect(
      fillRRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _primaryGreen,
            const Color(0xFF1C6B4B),
            _primaryGreen.withValues(alpha: 0.96),
          ],
          stops: const [0, 0.58, 1],
        ).createShader(trackRect),
    );

    final tailLength = math.min(
      size.width * 0.19,
      math.max(glowSize * 1.08, fillWidth),
    );
    final tailStart = (headX - tailLength).clamp(0.0, headX).toDouble();
    final safeTailEnd = headX.clamp(0.0, size.width).toDouble();
    final tailRect = Rect.fromLTRB(
      tailStart,
      trackRect.top - trackHeight * 0.38,
      safeTailEnd,
      trackRect.bottom + trackHeight * 0.38,
    );

    if (tailRect.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(tailRect, Radius.circular(glowSize)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              _gold.withValues(alpha: 0),
              deepGlowGold.withValues(alpha: 0.26 * shine),
              softGlowGold.withValues(alpha: 0.56 * shine),
              glowGold.withValues(alpha: 0.74 * shine),
            ],
            stops: const [0, 0.48, 0.82, 1],
          ).createShader(tailRect)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            active ? 1.25 + pulse * 0.55 : 0.9,
          )
          ..blendMode = BlendMode.srcOver,
      );

      canvas.save();
      canvas.clipRRect(trackRRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(tailRect, Radius.circular(glowSize)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              _gold.withValues(alpha: 0),
              deepGlowGold.withValues(alpha: 0.30 * shine),
              softGlowGold.withValues(alpha: 0.66 * shine),
              glowGold.withValues(alpha: 0.86 * shine),
            ],
            stops: const [0, 0.42, 0.78, 1],
          ).createShader(tailRect)
          ..blendMode = BlendMode.srcOver,
      );
      canvas.restore();
    }

    final capGlowRect = Rect.fromLTRB(
      (headX - glowSize * 0.42).clamp(0.0, size.width).toDouble(),
      trackRect.top - trackHeight * 0.18,
      (headX + trackHeight * 0.18).clamp(0.0, size.width).toDouble(),
      trackRect.bottom + trackHeight * 0.18,
    );
    if (capGlowRect.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(capGlowRect, Radius.circular(glowSize)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              _gold.withValues(alpha: 0),
              deepGlowGold.withValues(alpha: 0.38 * shine),
              glowGold.withValues(alpha: 0.88 * shine),
              _gold.withValues(alpha: 0),
            ],
            stops: const [0, 0.56, 0.82, 1],
          ).createShader(capGlowRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.9)
          ..blendMode = BlendMode.srcOver,
      );

      final headFlareRect = Rect.fromLTRB(
        (headX - trackHeight * 0.94).clamp(0.0, size.width).toDouble(),
        trackRect.top - trackHeight * 0.04,
        (headX + trackHeight * 0.28).clamp(0.0, size.width).toDouble(),
        trackRect.bottom + trackHeight * 0.04,
      );
      if (headFlareRect.width > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(headFlareRect, const Radius.circular(999)),
          Paint()
            ..shader = LinearGradient(
              colors: [
                _gold.withValues(alpha: 0),
                deepGlowGold.withValues(alpha: 0.42 * shine),
                glowGold.withValues(alpha: 1.0 * shine),
                softGlowGold.withValues(alpha: 0.74 * shine),
                _gold.withValues(alpha: 0),
              ],
              stops: const [0, 0.34, 0.68, 0.86, 1],
            ).createShader(headFlareRect)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.25),
        );
      }

      canvas.save();
      canvas.clipRRect(trackRRect);
      final headCoreRect = Rect.fromLTRB(
        (headX - trackHeight * 0.48).clamp(0.0, size.width).toDouble(),
        trackRect.top + trackHeight * 0.10,
        (headX + trackHeight * 0.16).clamp(0.0, size.width).toDouble(),
        trackRect.bottom - trackHeight * 0.10,
      );
      if (headCoreRect.width > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(headCoreRect, const Radius.circular(999)),
          Paint()
            ..shader = LinearGradient(
              colors: [
                deepGlowGold.withValues(alpha: 0),
                deepGlowGold.withValues(alpha: 0.58 * shine),
                glowGold.withValues(alpha: 0.96 * shine),
                softGlowGold.withValues(alpha: 0.72 * shine),
                _gold.withValues(alpha: 0),
              ],
              stops: const [0, 0.32, 0.62, 0.82, 1],
            ).createShader(headCoreRect),
        );
      }
      final edgeRect = Rect.fromLTRB(
        (headX - trackHeight * 0.42).clamp(0.0, size.width).toDouble(),
        trackRect.top,
        (headX + trackHeight * 0.14).clamp(0.0, size.width).toDouble(),
        trackRect.bottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(edgeRect, const Radius.circular(999)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              _gold.withValues(alpha: 0),
              glowGold.withValues(alpha: active ? 0.72 + pulse * 0.16 : 0.42),
              softGlowGold.withValues(alpha: 0.42 * shine),
              _gold.withValues(alpha: 0),
            ],
          ).createShader(edgeRect)
          ..blendMode = BlendMode.srcOver,
      );
      canvas.restore();
    }

    if (active && fillWidth > glowSize) {
      for (var index = 0; index < 5; index++) {
        final phase = (shimmer + index * 0.19) % 1;
        final sparkX = headX - tailLength * (0.10 + phase * 0.78);
        if (sparkX <= 0 || sparkX >= headX) continue;
        final fade = (1 - phase).clamp(0.0, 1.0).toDouble();
        final sparkY =
            centerY +
            math.sin((phase + index * 0.31) * math.pi * 2) * trackHeight * 0.34;
        final rayLength = glowSize * (0.38 + fade * 0.46);
        final sparkPaint = Paint()
          ..color = glowGold.withValues(alpha: (0.38 + fade * 0.42) * shine)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.0 + fade * 0.9
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1)
          ..blendMode = BlendMode.srcOver;
        canvas.drawLine(
          Offset(sparkX + rayLength * 0.22, sparkY),
          Offset(sparkX - rayLength, sparkY),
          sparkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MeteorProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.active != active ||
        oldDelegate.trackHeight != trackHeight ||
        oldDelegate.glowSize != glowSize;
  }
}

class _BottomControlBar extends StatelessWidget {
  const _BottomControlBar({
    required this.scale,
    required this.height,
    required this.tesbihModeEnabled,
    required this.vibrationEnabled,
    required this.muted,
    required this.onReset,
    required this.onUndo,
    required this.onToggleTesbihMode,
    required this.onToggleVibration,
    required this.onToggleMute,
  });

  final double scale;
  final double height;
  final bool tesbihModeEnabled;
  final bool vibrationEnabled;
  final bool muted;
  final VoidCallback onReset;
  final VoidCallback onUndo;
  final VoidCallback onToggleTesbihMode;
  final VoidCallback onToggleVibration;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: height - 10 * scale,
              padding: EdgeInsets.fromLTRB(
                (14 * scale).clamp(12, 16).toDouble(),
                (11 * scale).clamp(9, 12).toDouble(),
                (14 * scale).clamp(12, 16).toDouble(),
                (6 * scale).clamp(4, 7).toDouble(),
              ),
              decoration: BoxDecoration(
                color: _referenceControlSurface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22 * scale),
                border: Border.all(
                  color: _mutedGold.withValues(alpha: 0.34),
                  width: 0.9 * scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _deepGreen.withValues(alpha: 0.09),
                    blurRadius: 23 * scale,
                    offset: Offset(0, 9 * scale),
                  ),
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.08),
                    blurRadius: 14 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ControlButton(
                    scale: scale,
                    icon: Icons.refresh_rounded,
                    label: 'SIFIRLA',
                    onPressed: onReset,
                  ),
                  _ControlButton(
                    scale: scale,
                    icon: Icons.undo_rounded,
                    label: 'GERİ AL',
                    onPressed: onUndo,
                  ),
                  SizedBox(width: (66 * scale).clamp(60, 74).toDouble()),
                  _ControlButton(
                    scale: scale,
                    icon: Icons.vibration_rounded,
                    label: 'TİTREŞİM',
                    selected: vibrationEnabled,
                    onPressed: onToggleVibration,
                  ),
                  _ControlButton(
                    scale: scale,
                    icon: Icons.volume_off_rounded,
                    label: 'SESSİZ',
                    selected: muted,
                    onPressed: onToggleMute,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -6 * scale,
            child: _PrimaryModeButton(
              scale: scale,
              selected: tesbihModeEnabled,
              onPressed: onToggleTesbihMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterNavButton extends StatelessWidget {
  const _CounterNavButton({
    required this.scale,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = _primaryGreen,
  });

  final double scale;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _navButtonSize * scale,
      height: _navButtonSize * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _deepGreen.withValues(alpha: 0.12),
            blurRadius: 18 * scale,
            offset: Offset(0, 8 * scale),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.36),
            blurRadius: 2 * scale,
            offset: Offset(0, -0.5 * scale),
          ),
        ],
      ),
      child: Material(
        color: _cream.withValues(alpha: 0.82),
        shape: CircleBorder(
          side: BorderSide(
            color: _mutedGold.withValues(alpha: 0.36),
            width: 1.05 * scale,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 22 * scale,
          color: color,
          splashRadius: 21 * scale,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _TargetPill extends StatelessWidget {
  const _TargetPill({
    required this.scale,
    required this.onPressed,
    this.label,
    this.icon,
    this.tooltip,
    this.selected = false,
  });

  final double scale;
  final VoidCallback onPressed;
  final String? label;
  final IconData? icon;
  final String? tooltip;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final pillFontSize = (12 * scale).clamp(11, 13.2).toDouble();
    final pillIconSize = (18 * scale).clamp(16, 19.5).toDouble();

    final borderRadius = BorderRadius.circular(999);
    final foreground = selected ? const Color(0xFFF0D78B) : _primaryGreen;
    final surface = selected
        ? _primaryGreen.withValues(alpha: 0.94)
        : _referenceControlSurface.withValues(alpha: 0.94);
    final borderColor = selected
        ? _gold.withValues(alpha: 0.82)
        : _mutedGold.withValues(alpha: 0.38);
    final semanticLabel = tooltip ?? label ?? 'Hedef seçeneği';

    return Expanded(
      child: Tooltip(
        message: semanticLabel,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: _deepGreen.withValues(alpha: selected ? 0.14 : 0.08),
                blurRadius: (selected ? 12 : 9) * scale,
                offset: Offset(0, (selected ? 5 : 4) * scale),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.34),
                blurRadius: 2 * scale,
                offset: Offset(0, -0.6 * scale),
              ),
            ],
          ),
          child: Material(
            color: surface,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              borderRadius: borderRadius,
              splashColor: _gold.withValues(alpha: 0.14),
              highlightColor: _gold.withValues(alpha: 0.08),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(color: borderColor, width: 1.1 * scale),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: icon == null
                        ? Text(
                            label ?? '',
                            maxLines: 1,
                            style: TextStyle(
                              color: foreground,
                              fontSize: pillFontSize,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          )
                        : Icon(icon, color: foreground, size: pillIconSize),
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

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.scale,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final double scale;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final itemWidth = (54 * scale).clamp(48, 60).toDouble();
    final buttonSize = (38 * scale).clamp(34, 42).toDouble();
    final iconSize = (20 * scale).clamp(18, 22).toDouble();
    final labelSize = (8.8 * scale).clamp(8, 9.6).toDouble();

    return SizedBox(
      width: itemWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _deepGreen.withValues(alpha: 0.08),
                  blurRadius: 10 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            child: Material(
              color: _cream.withValues(alpha: selected ? 0.98 : 0.90),
              shape: CircleBorder(
                side: BorderSide(
                  color: (selected ? _gold : _mutedGold).withValues(
                    alpha: selected ? 0.40 : 0.20,
                  ),
                  width: 0.8 * scale,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                splashColor: _gold.withValues(alpha: 0.12),
                highlightColor: _gold.withValues(alpha: 0.08),
                child: Icon(icon, color: _primaryGreen, size: iconSize),
              ),
            ),
          ),
          SizedBox(height: (3 * scale).clamp(2, 4).toDouble()),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: _primaryGreen,
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryModeButton extends StatelessWidget {
  const _PrimaryModeButton({
    required this.scale,
    required this.selected,
    required this.onPressed,
  });

  final double scale;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dimension = (70 * scale).clamp(64, 78).toDouble();
    final iconSize = (22 * scale).clamp(20, 24).toDouble();
    final labelSize = (9.8 * scale).clamp(9, 10.8).toDouble();

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: selected ? 0.30 : 0.18),
            blurRadius: 18 * scale,
            offset: Offset(0, 7 * scale),
          ),
          BoxShadow(
            color: _gold.withValues(alpha: selected ? 0.20 : 0.10),
            blurRadius: 12 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(color: _gold.withValues(alpha: 0.62), width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          splashColor: _gold.withValues(alpha: 0.14),
          highlightColor: _gold.withValues(alpha: 0.08),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: selected
                    ? const [
                        _referenceModeTop,
                        _referenceModeMiddle,
                        _referenceModeBottom,
                      ]
                    : [
                        _referenceModeTop.withValues(alpha: 0.78),
                        _referenceModeMiddle.withValues(alpha: 0.82),
                        _referenceModeBottom.withValues(alpha: 0.88),
                      ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grain_rounded,
                  color: selected ? _gold : _cream.withValues(alpha: 0.86),
                  size: iconSize,
                ),
                SizedBox(height: 4 * scale),
                Text(
                  'TESBİH\nMODU',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _cream,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w800,
                    height: 0.98,
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
