import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'premium_tesbih_pull_layer.dart';
import '../application/counter_controller.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../dhikr_library/presentation/dhikr_library_screen.dart';
import '../../settings/application/settings_controller.dart';
import '../../../shared/layout/proportional_layout.dart';

const _backgroundAsset = 'assets/images/zikr_counter_bg.webp';
const _counterRingAsset = 'assets/images/zikr_counter_ring.png';
const _tesbihAsset = 'assets/images/zikr_tesbih.png';
const _completionCardAsset = 'assets/images/kartbitti.png';

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
  var _tesbihModeEnabled = false;
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
    ref.listen<int>(counterControllerProvider.select((state) => state.target), (
      previous,
      next,
    ) {
      if (!mounted || _selectedTarget == next) return;
      setState(() => _selectedTarget = next);
    });

    final counter = ref.watch(counterControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
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
                    final baseLayoutHeight = math.min(
                      constraints.maxHeight,
                      _maxLayoutHeight * scale,
                    );
                    final extraHeight = math.max(
                      0.0,
                      constraints.maxHeight - baseLayoutHeight,
                    );
                    final wideScreenFactor =
                        ((scale - 1.0) / (_maxScreenScale - 1.0))
                            .clamp(0.0, 1.0)
                            .toDouble();
                    final tallScreenFactor =
                        ((extraHeight - 32 * scale) / (72 * scale))
                            .clamp(0.0, 1.0)
                            .toDouble();
                    final spaciousLayoutFactor =
                        wideScreenFactor * tallScreenFactor;
                    final layoutHeight = math.min(
                      constraints.maxHeight,
                      baseLayoutHeight +
                          extraHeight * 0.78 * spaciousLayoutFactor,
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
                    final titleVisualLift =
                        (y(_titleVisualLift, min: 15, max: 22) -
                                24 * spaciousLayoutFactor)
                            .clamp(0.0, 22.0)
                            .toDouble();
                    final targetPillRowLift =
                        (y(_targetPillRowLift, min: 10, max: 16) -
                                18 * spaciousLayoutFactor)
                            .clamp(0.0, 16.0)
                            .toDouble();

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
                                  offset: Offset(0, -titleVisualLift),
                                  child: _TappableZikrTitle(
                                    onTap: _openDhikrLibrary,
                                    child: _ZikrTitleSection(
                                      scale: scale,
                                      name: counter.activeDhikr.name,
                                      arabicText:
                                          counter.activeDhikr.arabicText,
                                      meaning: counter.activeDhikr.meaning,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: y(_targetTopGap, min: 1, max: 4),
                              ),
                              Transform.translate(
                                offset: Offset(0, -targetPillRowLift),
                                child: _TargetCountPills(
                                  scale: scale,
                                  height: y(
                                    _targetPillHeight,
                                    min: 29,
                                    max: 33,
                                  ),
                                  selectedTarget: _selectedTarget,
                                  onTargetChanged: _selectTarget,
                                  onCustomTarget: _showCustomTargetPicker,
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
                                  tesbihModeEnabled: _tesbihModeEnabled,
                                  onIncrement: _incrementCounter,
                                  onBeadCollision: _playBeadCollisionSound,
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
                                        _tesbihModeEnabled
                                            ? 'T E S B İ H İ  A Ş A Ğ I  Ç E K'
                                            : 'D O K U N A R A K  S A Y',
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
                                vibrationEnabled: settings.vibrationEnabled,
                                soundEnabled: settings.soundEnabled,
                                onReset: _resetCounter,
                                onUndo: _decrementCounter,
                                onToggleTesbihMode: _toggleTesbihMode,
                                onToggleVibration: _toggleVibration,
                                onToggleSound: _toggleSound,
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
              if (counter.completed)
                _CompletionAssetOverlay(
                  scale: scale,
                  count: counter.count,
                  target: counter.target,
                  dhikrName: counter.activeDhikr.name,
                  onDismiss: ref
                      .read(counterControllerProvider.notifier)
                      .dismissCompletion,
                  onReset: _resetCounter,
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

  Future<void> _showCustomTargetPicker() async {
    final currentTarget = ref.read(counterControllerProvider).target;
    final value = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final sheetScale = _counterScaleFor(media.size.width);
        return _CustomTargetSheet(
          scale: sheetScale,
          initialValue:
              currentTarget > 0 && !{33, 99, 100}.contains(currentTarget)
              ? currentTarget
              : null,
        );
      },
    );
    if (!mounted || value == null) return;
    _selectTarget(value);
  }

  void _openDhikrLibrary() {
    ref.read(interactionFeedbackServiceProvider).selection();
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.push('/zikirler');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const DhikrLibraryScreen()),
    );
  }

  void _incrementCounter() {
    ref
        .read(counterControllerProvider.notifier)
        .increment(useTesbihFeedback: _tesbihModeEnabled);
  }

  void _playBeadCollisionSound() {
    ref.read(interactionFeedbackServiceProvider).beadCollision();
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
    ref.read(settingsControllerProvider.notifier).toggleVibration();
  }

  void _toggleSound() {
    ref.read(settingsControllerProvider.notifier).toggleSound();
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

class _TappableZikrTitle extends StatelessWidget {
  const _TappableZikrTitle({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Zikir sayfasını aç',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: _gold.withValues(alpha: 0.08),
          highlightColor: _gold.withValues(alpha: 0.04),
          child: child,
        ),
      ),
    );
  }
}

class _ZikrTitleSection extends StatelessWidget {
  const _ZikrTitleSection({
    required this.scale,
    required this.name,
    this.arabicText,
    this.meaning,
  });

  final double scale;
  final String name;
  final String? arabicText;
  final String? meaning;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final titleWidth = math.min(screenWidth - 48 * scale, 336 * scale);
    final displayArabic = arabicText?.trim();
    final displayMeaning = meaning?.trim();
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
              if (displayArabic != null && displayArabic.isNotEmpty)
                Text(
                  displayArabic,
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
                name,
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
                displayMeaning == null || displayMeaning.isEmpty
                    ? ''
                    : displayMeaning,
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
    final customTargetSelected =
        selectedTarget != _infiniteTarget &&
        !{33, 99, 100}.contains(selectedTarget);

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
                  selected: customTargetSelected,
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

class _CustomTargetSheet extends StatefulWidget {
  const _CustomTargetSheet({required this.scale, this.initialValue});

  final double scale;
  final int? initialValue;

  @override
  State<_CustomTargetSheet> createState() => _CustomTargetSheetState();
}

class _CustomTargetSheetState extends State<_CustomTargetSheet> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final media = MediaQuery.of(context);
    final canSubmit = _parsedValue != null;
    final sheetWidth = math.min(media.size.width - 32 * scale, 360 * scale);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 10 * scale),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: sheetWidth,
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                10 * scale,
                18 * scale,
                16 * scale,
              ),
              decoration: BoxDecoration(
                color: _referencePanelSurface.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(22 * scale),
                border: Border.all(
                  color: _mutedGold.withValues(alpha: 0.34),
                  width: scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 28 * scale,
                    offset: Offset(0, 14 * scale),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40 * scale,
                    height: 4 * scale,
                    decoration: BoxDecoration(
                      color: _mutedGold.withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(height: 13 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Özel hedef',
                          style: TextStyle(
                            color: _primaryGreen,
                            fontSize: (17 * scale).clamp(16, 19).toDouble(),
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kapat',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: _primaryGreen,
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * scale),
                  Container(
                    height: (52 * scale).clamp(48, 58).toDouble(),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _cream.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14 * scale),
                      border: Border.all(
                        color: _mutedGold.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      _value.isEmpty ? 'Hedef sayısı' : _value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _value.isEmpty
                            ? _primaryGreen.withValues(alpha: 0.44)
                            : _primaryGreen,
                        fontSize: _value.isEmpty
                            ? (14 * scale).clamp(13, 15.5).toDouble()
                            : (24 * scale).clamp(22, 28).toDouble(),
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8 * scale,
                    crossAxisSpacing: 8 * scale,
                    childAspectRatio: 2.12,
                    children: [
                      for (final digit in const [
                        '1',
                        '2',
                        '3',
                        '4',
                        '5',
                        '6',
                        '7',
                        '8',
                        '9',
                      ])
                        _NumpadButton(
                          scale: scale,
                          label: digit,
                          onPressed: () => _appendDigit(digit),
                        ),
                      _NumpadButton(
                        scale: scale,
                        icon: Icons.backspace_outlined,
                        onPressed: _value.isEmpty ? null : _backspace,
                      ),
                      _NumpadButton(
                        scale: scale,
                        label: '0',
                        onPressed: () => _appendDigit('0'),
                      ),
                      _NumpadButton(
                        scale: scale,
                        icon: Icons.check_rounded,
                        filled: true,
                        onPressed: canSubmit ? _submit : null,
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

  int? get _parsedValue {
    final value = int.tryParse(_value);
    if (value == null || value < 1) return null;
    return value;
  }

  void _appendDigit(String digit) {
    if (_value.length >= 5) return;
    setState(() {
      if (_value == '0') {
        _value = digit;
      } else {
        _value += digit;
      }
    });
  }

  void _backspace() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  void _submit() {
    final value = _parsedValue;
    if (value == null) return;
    Navigator.of(context).pop(value);
  }
}

class _NumpadButton extends StatelessWidget {
  const _NumpadButton({
    required this.scale,
    this.label,
    this.icon,
    this.filled = false,
    this.onPressed,
  });

  final double scale;
  final String? label;
  final IconData? icon;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = filled
        ? const Color(0xFFF2DE9B)
        : _primaryGreen.withValues(alpha: enabled ? 1 : 0.35);
    final surface = filled
        ? _primaryGreen.withValues(alpha: enabled ? 0.96 : 0.38)
        : _cream.withValues(alpha: enabled ? 0.96 : 0.56);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(13 * scale),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        splashColor: _gold.withValues(alpha: 0.14),
        highlightColor: _gold.withValues(alpha: 0.08),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13 * scale),
            border: Border.all(
              color: filled
                  ? _gold.withValues(alpha: 0.60)
                  : _mutedGold.withValues(alpha: enabled ? 0.32 : 0.16),
            ),
          ),
          child: Center(
            child: icon == null
                ? Text(
                    label ?? '',
                    style: TextStyle(
                      color: foreground,
                      fontSize: (19 * scale).clamp(18, 22).toDouble(),
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  )
                : Icon(
                    icon,
                    color: foreground,
                    size: (21 * scale).clamp(20, 24).toDouble(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CentralCounterArea extends StatelessWidget {
  const _CentralCounterArea({
    required this.scale,
    required this.count,
    required this.selectedTarget,
    required this.tesbihModeEnabled,
    required this.onIncrement,
    required this.onBeadCollision,
    required this.onSonarStart,
  });

  final double scale;
  final int count;
  final int selectedTarget;
  final bool tesbihModeEnabled;
  final VoidCallback onIncrement;
  final VoidCallback onBeadCollision;
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
        final tesbihHeight = counterSize * 1.40;
        final tesbihWidth = tesbihHeight * 2 / 3;
        final tesbihRight = -counterSize * 0.04;
        final tesbihTop = -counterSize * 0.055;
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
              tesbihModeEnabled: tesbihModeEnabled,
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
              onBeadCollision: onBeadCollision,
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
    required this.tesbihModeEnabled,
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
    required this.onBeadCollision,
    required this.onSonarStart,
  });

  final double scale;
  final int count;
  final String targetLabel;
  final bool tesbihModeEnabled;
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
  final VoidCallback onBeadCollision;
  final void Function(Offset center, double ringRadius) onSonarStart;

  @override
  State<_PressableCounterDial> createState() => _PressableCounterDialState();
}

class _PressableCounterDialState extends State<_PressableCounterDial>
    with TickerProviderStateMixin {
  static const _tesbihBeadSlotProgress = 1 / 22;
  static const _pullHiddenGapStart = 0.36;
  static const _pullHiddenGapEnd = 0.515;
  static const _livePullBeadShiftSlots = 0.17;

  static const _pressSpring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 28,
  );

  late final AnimationController _pressController;
  late final AnimationController _countPopController;
  late final AnimationController _beadSlideController;
  late final AnimationController _tesbihModeController;
  late final AnimationController _pullHintController;
  late final AnimationController _pullReturnController;
  final _counterDialKey = GlobalKey();
  var _beadShiftStart = 0.0;
  var _beadShiftEnd = 0.0;
  var _dragPullDistance = 0.0;
  var _pullReturnStartFraction = 0.0;
  var _isDraggingTesbih = false;
  var _pullCompletedForGesture = false;
  var _pullHintIntroReady = false;
  var _showPullHint = false;
  var _pullHintCompletedPulls = 0;
  var _beadSettleGeneration = 0;
  int? _activePulledBeadIndex;
  double? _activeBeadStartProgress;
  double? _activeBeadEndProgress;
  PremiumTesbihBeadSnapshot? _pendingTesbihActiveBead;
  int? _tesbihPointer;
  Offset? _lastTesbihPointerPosition;
  Timer? _pullHintIntroTimer;
  Timer? _pullHintTimer;
  double? _pendingBeadSettleStart;

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
    _beadShiftStart = widget.count.toDouble();
    _beadShiftEnd = widget.count.toDouble();
    _beadSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      value: 1,
    );
    _tesbihModeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2050),
      value: widget.tesbihModeEnabled ? 1 : 0,
    );
    _pullHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    _pullReturnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _PressableCounterDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      final settleGeneration = ++_beadSettleGeneration;
      _beadShiftStart = _pendingBeadSettleStart ?? oldWidget.count.toDouble();
      _pendingBeadSettleStart = null;
      _beadShiftEnd = widget.count.toDouble();
      _beadSlideController.forward(from: 0).whenComplete(() {
        if (!mounted || settleGeneration != _beadSettleGeneration) return;
        setState(() {
          _dragPullDistance = 0;
          _pullReturnStartFraction = 0;
          _isDraggingTesbih = false;
          _pullCompletedForGesture = false;
          _activePulledBeadIndex = null;
          _activeBeadStartProgress = null;
          _activeBeadEndProgress = null;
          _pendingTesbihActiveBead = null;
          _tesbihPointer = null;
          _lastTesbihPointerPosition = null;
        });
      });
      _countPopController.forward(from: 0);
    }
    if (oldWidget.tesbihModeEnabled != widget.tesbihModeEnabled) {
      _beadSettleGeneration++;
      _dragPullDistance = 0;
      _pullReturnStartFraction = 0;
      _isDraggingTesbih = false;
      _pullCompletedForGesture = false;
      _activePulledBeadIndex = null;
      _activeBeadStartProgress = null;
      _activeBeadEndProgress = null;
      _pendingTesbihActiveBead = null;
      _tesbihPointer = null;
      _lastTesbihPointerPosition = null;
      _pullReturnController.value = 1;
      if (widget.tesbihModeEnabled) {
        _resetPullHint();
        _tesbihModeController.forward();
        _pullHintIntroTimer = Timer(
          const Duration(milliseconds: 1180),
          _showPullHintAfterIntro,
        );
      } else {
        _hidePullHint();
        _tesbihModeController.animateBack(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _countPopController.dispose();
    _beadSlideController.dispose();
    _tesbihModeController.dispose();
    _pullReturnController.dispose();
    _pullHintIntroTimer?.cancel();
    _pullHintTimer?.cancel();
    _pullHintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: GestureDetector(
        key: const Key('counter.increment'),
        behavior: HitTestBehavior.translucent,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onPanCancel: _handlePanCancel,
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
                            child: AnimatedBuilder(
                              animation: _tesbihModeController,
                              builder: (context, child) {
                                return _StaticTesbihAssetReveal(
                                  fadeOutProgress: _tesbihModeController.value,
                                  tesbihModeEnabled: widget.tesbihModeEnabled,
                                  child: child!,
                                );
                              },
                              child: Image.asset(
                                _tesbihAsset,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        if (widget.tesbihModeEnabled)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _beadSlideController,
                                  _tesbihModeController,
                                  _pullReturnController,
                                ]),
                                builder: (context, _) {
                                  final revealProgress = _tesbihModeController
                                      .value
                                      .clamp(0.0, 1.0)
                                      .toDouble();
                                  return PremiumTesbihPullLayer(
                                    scale: widget.scale,
                                    beadShift: _visualBeadShift,
                                    lowerBeadShift: _lowerVisualBeadShift,
                                    pullFraction: _pullFraction,
                                    enabled: true,
                                    revealProgress: revealProgress,
                                    activeBeadIndex: _activePulledBeadIndex,
                                    activeBeadProgress:
                                        _activePulledBeadProgress,
                                    suppressedBeadIndex: null,
                                    pass: PremiumTesbihPullLayerPass
                                        .underRingSegments,
                                  );
                                },
                              ),
                            ),
                          ),
                        SizedBox.square(
                          dimension: widget.ringSize,
                          child: Image.asset(
                            _counterRingAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (widget.tesbihModeEnabled)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _beadSlideController,
                                  _tesbihModeController,
                                  _pullReturnController,
                                ]),
                                builder: (context, _) {
                                  final revealProgress = _tesbihModeController
                                      .value
                                      .clamp(0.0, 1.0)
                                      .toDouble();
                                  return PremiumTesbihPullLayer(
                                    scale: widget.scale,
                                    beadShift: _visualBeadShift,
                                    lowerBeadShift: _lowerVisualBeadShift,
                                    pullFraction: _pullFraction,
                                    enabled: true,
                                    revealProgress: revealProgress,
                                    activeBeadIndex: _activePulledBeadIndex,
                                    activeBeadProgress:
                                        _activePulledBeadProgress,
                                    suppressedBeadIndex: null,
                                    pass: PremiumTesbihPullLayerPass
                                        .overRingStrand,
                                  );
                                },
                              ),
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
                        if (widget.tesbihModeEnabled)
                          Positioned(
                            right: (-widget.counterSize * 0.018)
                                .clamp(-8.0, -5.0)
                                .toDouble(),
                            top: (widget.counterSize * 0.395)
                                .clamp(114.0, 151.0)
                                .toDouble(),
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                opacity:
                                    _pullHintIntroReady &&
                                        _showPullHint &&
                                        _pullHintCompletedPulls < 2
                                    ? 1
                                    : 0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                child: AnimatedSlide(
                                  offset:
                                      _pullHintIntroReady &&
                                          _showPullHint &&
                                          _pullHintCompletedPulls < 2
                                      ? Offset.zero
                                      : const Offset(0.08, 0.12),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedScale(
                                    scale:
                                        _pullHintIntroReady &&
                                            _showPullHint &&
                                            _pullHintCompletedPulls < 2
                                        ? 1
                                        : 0.92,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    child: _TesbihPullHintPill(
                                      scale: widget.scale,
                                      animation: _pullHintController,
                                    ),
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
      ),
    );
  }

  double get _pullThreshold => (25.5 * widget.scale).clamp(22, 31).toDouble();

  double get _gesturePullFraction =>
      (_dragPullDistance / _pullThreshold).clamp(0.0, 1.0).toDouble();

  double get _pullFraction {
    if (_isDraggingTesbih) {
      return _gesturePullFraction;
    }

    final returnProgress = Curves.easeOutCubic.transform(
      _pullReturnController.value.clamp(0.0, 1.0).toDouble(),
    );
    return (_pullReturnStartFraction * (1 - returnProgress))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double get _currentBeadShift {
    final slide = Curves.easeOutCubic.transform(
      _beadSlideController.value.clamp(0.0, 1.0).toDouble(),
    );
    return _beadShiftStart + (_beadShiftEnd - _beadShiftStart) * slide;
  }

  double get _visualBeadShift => _currentBeadShift;

  double get _lowerVisualBeadShift {
    if (_pullCompletedForGesture) {
      return _pendingBeadSettleStart ?? _currentBeadShift;
    }

    return _currentBeadShift + _pullFraction * _livePullBeadShiftSlots;
  }

  double? get _activePulledBeadProgress {
    if (_activePulledBeadIndex == null) return null;
    final start = _activeBeadStartProgress;
    final end = _activeBeadEndProgress;
    if (start == null || end == null) return null;

    final softenedPull = math.pow(_pullFraction, 1.55).toDouble();
    final easedPull = Curves.easeInOutCubic.transform(softenedPull);
    return start + (end - start) * easedPull;
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
    if (widget.tesbihModeEnabled) return;
    _pressController.stop();
    _startSonarFromDialCenter();
    _pressController.animateTo(
      1,
      duration: const Duration(milliseconds: 72),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.tesbihModeEnabled) return;
    _releasePress();
  }

  void _handleTapCancel() {
    if (widget.tesbihModeEnabled) return;
    _releasePress();
  }

  void _handleTap() {
    if (widget.tesbihModeEnabled) return;
    _playAcceptedTapPulse();
    widget.onIncrement();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.tesbihModeEnabled) return;
    _pendingTesbihActiveBead = _tesbihBeadSnapshotAt(event.localPosition);
    if (_pendingTesbihActiveBead == null &&
        !_isTesbihPullStart(event.localPosition)) {
      return;
    }

    _tesbihPointer = event.pointer;
    _lastTesbihPointerPosition = event.localPosition;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!widget.tesbihModeEnabled || event.pointer != _tesbihPointer) return;

    final lastPosition = _lastTesbihPointerPosition ?? event.localPosition;
    final delta = event.localPosition - lastPosition;
    _lastTesbihPointerPosition = event.localPosition;

    if (!_isDraggingTesbih) {
      final activeBead =
          _pendingTesbihActiveBead ??
          _tesbihBeadSnapshotAt(event.localPosition);
      if (activeBead == null || delta.dy <= 0) return;
      _beginTesbihPull(activeBead);
    }

    _applyTesbihPullDelta(delta);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _tesbihPointer) return;
    _tesbihPointer = null;
    _lastTesbihPointerPosition = null;
    if (_pullCompletedForGesture) {
      _releaseCompletedPullInput();
      return;
    }
    if (_isDraggingTesbih) {
      _endTesbihPull();
    } else {
      _pendingTesbihActiveBead = null;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _tesbihPointer) return;
    _tesbihPointer = null;
    _lastTesbihPointerPosition = null;
    if (_pullCompletedForGesture) {
      _releaseCompletedPullInput();
      return;
    }
    _cancelTesbihPull();
  }

  void _playAcceptedTapPulse() {
    _pressController.stop();
    final visiblePress = math
        .max(_pressController.value.clamp(0.0, 1.0).toDouble(), 0.72)
        .toDouble();
    _pressController
        .animateTo(
          visiblePress,
          duration: const Duration(milliseconds: 48),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted && !widget.tesbihModeEnabled) {
            _releasePress();
          }
        });
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.tesbihModeEnabled) return;
    if (_tesbihPointer != null) return;

    final activeBead =
        _pendingTesbihActiveBead ??
        _tesbihBeadSnapshotAt(details.localPosition);
    _isDraggingTesbih =
        activeBead != null || _isTesbihPullStart(details.localPosition);
    if (!_isDraggingTesbih) return;

    if (activeBead == null) {
      _isDraggingTesbih = false;
      return;
    }

    _beginTesbihPull(activeBead);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_tesbihPointer != null) return;
    if (!widget.tesbihModeEnabled || !_isDraggingTesbih) return;
    _applyTesbihPullDelta(details.delta);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_tesbihPointer != null) return;
    if (!widget.tesbihModeEnabled || !_isDraggingTesbih) return;
    _endTesbihPull();
  }

  void _handlePanCancel() {
    if (_tesbihPointer != null) return;
    _cancelTesbihPull();
  }

  void _beginTesbihPull(PremiumTesbihBeadSnapshot activeBead) {
    if (_isDraggingTesbih && _activePulledBeadIndex != null) return;

    _beadSettleGeneration++;
    _pullReturnController.stop();
    _startSonarFromDialCenter();
    setState(() {
      _dragPullDistance = 0;
      _pullReturnStartFraction = 0;
      _pullReturnController.value = 1;
      _isDraggingTesbih = true;
      _pullCompletedForGesture = false;
      _pendingTesbihActiveBead = null;
      _activePulledBeadIndex = activeBead.index;
      _activeBeadStartProgress = activeBead.progress;
      _activeBeadEndProgress =
          activeBead.receiveGapProgress ??
          _activeBeadEndProgressFor(activeBead.progress);
    });
  }

  void _applyTesbihPullDelta(Offset delta) {
    if (!widget.tesbihModeEnabled || !_isDraggingTesbih) return;
    if (_pullCompletedForGesture) {
      return;
    }

    final diagonalPull = delta.dy - delta.dx * 0.12;
    final effectivePull = math.max(0.0, diagonalPull);
    if (effectivePull == 0 && _dragPullDistance == 0) return;

    final currentFraction = _gesturePullFraction;
    final maxStep = (30.0 * widget.scale).clamp(24.0, 36.0).toDouble();
    final resistedPull =
        math.min(effectivePull, maxStep) *
        (1.40 + (1 - currentFraction) * 0.22);
    final nextDistance = (_dragPullDistance + resistedPull).clamp(
      0.0,
      _pullThreshold * 1.12,
    );
    if (!_pullCompletedForGesture && nextDistance >= _pullThreshold) {
      final settleStart = _beadShiftEnd + _livePullBeadShiftSlots;
      setState(() {
        _dragPullDistance = _pullThreshold;
        _pullCompletedForGesture = true;
      });
      _performTesbihPullIncrement(settleStart: settleStart);
      return;
    }

    setState(() => _dragPullDistance = nextDistance);
  }

  void _endTesbihPull() {
    if (!widget.tesbihModeEnabled || !_isDraggingTesbih) return;
    if (_pullCompletedForGesture) {
      return;
    }

    final shouldCompletePull =
        !_pullCompletedForGesture && _gesturePullFraction >= 0.52;
    final returnFraction = _gesturePullFraction;
    final settleStart = _beadShiftEnd + _livePullBeadShiftSlots;
    if (shouldCompletePull) {
      setState(() {
        _dragPullDistance = _pullThreshold;
        _pullCompletedForGesture = true;
      });
      _performTesbihPullIncrement(settleStart: settleStart);
      return;
    }

    setState(() {
      _dragPullDistance = 0;
      _isDraggingTesbih = false;
      _pullCompletedForGesture = false;
      _pendingTesbihActiveBead = null;
    });
    if (returnFraction > 0) {
      _animatePullReturnFrom(returnFraction);
    } else {
      _clearActivePulledBead();
    }
  }

  void _cancelTesbihPull() {
    if (_dragPullDistance == 0 && !_isDraggingTesbih) {
      _pendingTesbihActiveBead = null;
      return;
    }
    if (_pullCompletedForGesture) {
      return;
    }

    final returnFraction = _gesturePullFraction;
    setState(() {
      _dragPullDistance = 0;
      _isDraggingTesbih = false;
      _pullCompletedForGesture = false;
      _pendingTesbihActiveBead = null;
    });
    if (returnFraction > 0) {
      _animatePullReturnFrom(returnFraction);
    } else {
      _clearActivePulledBead();
    }
  }

  void _releaseCompletedPullInput() {
    if (!_pullCompletedForGesture) return;

    setState(() {
      _dragPullDistance = 0;
      _pullReturnStartFraction = 0;
      _isDraggingTesbih = false;
      _activePulledBeadIndex = null;
      _activeBeadStartProgress = null;
      _activeBeadEndProgress = null;
      _pendingTesbihActiveBead = null;
    });
  }

  void _performTesbihPullIncrement({required double settleStart}) {
    _pullReturnController.stop();
    _pullReturnStartFraction = 0;
    _pendingBeadSettleStart = settleStart;
    _registerPullHintProgress();
    _startSonarFromDialCenter();
    _pressController.stop();
    _pressController
        .animateTo(
          0.52,
          duration: const Duration(milliseconds: 64),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted) {
            _releasePress();
          }
        });
    widget.onBeadCollision();
    widget.onIncrement();
  }

  void _resetPullHint() {
    _pullHintIntroTimer?.cancel();
    _pullHintTimer?.cancel();
    setState(() {
      _pullHintIntroReady = false;
      _pullHintCompletedPulls = 0;
      _showPullHint = false;
    });
  }

  void _hidePullHint() {
    _pullHintIntroTimer?.cancel();
    _pullHintTimer?.cancel();
    _pullHintIntroReady = false;
    _pullHintCompletedPulls = 0;
    _showPullHint = false;
  }

  void _showPullHintAfterIntro() {
    if (!mounted || !widget.tesbihModeEnabled) return;
    setState(() {
      _pullHintIntroReady = true;
      _showPullHint = _pullHintCompletedPulls < 2;
    });
  }

  void _registerPullHintProgress() {
    _pullHintTimer?.cancel();
    final completedPulls = _pullHintCompletedPulls + 1;

    setState(() {
      _pullHintCompletedPulls = completedPulls;
      _showPullHint = completedPulls < 2;
    });

    _pullHintTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !widget.tesbihModeEnabled) return;
      setState(() {
        _pullHintCompletedPulls = 0;
        _showPullHint = _pullHintIntroReady;
      });
    });
  }

  void _animatePullReturnFrom(double fraction) {
    _pullReturnController.stop();
    setState(() {
      _pullReturnStartFraction = fraction.clamp(0.0, 1.0).toDouble();
      _pullReturnController.value = 0;
    });
    _pullReturnController.forward(from: 0).whenComplete(() {
      if (!mounted || _isDraggingTesbih) return;
      setState(() {
        _pullReturnStartFraction = 0;
        _activePulledBeadIndex = null;
        _activeBeadStartProgress = null;
        _activeBeadEndProgress = null;
        _pendingTesbihActiveBead = null;
      });
    });
  }

  void _clearActivePulledBead() {
    setState(() {
      _activePulledBeadIndex = null;
      _activeBeadStartProgress = null;
      _activeBeadEndProgress = null;
      _pendingTesbihActiveBead = null;
    });
  }

  PremiumTesbihBeadSnapshot? _tesbihBeadSnapshotAt(Offset localPosition) {
    if (!_isTesbihPullStart(localPosition)) return null;
    return nearestPremiumTesbihBeadSnapshot(
      size: Size.square(widget.counterSize),
      position: _dialPositionForLocal(localPosition),
      beadShift: _currentBeadShift,
      revealProgress: _tesbihModeController.value,
    );
  }

  double _activeBeadEndProgressFor(double startProgress) {
    if (startProgress < _pullHiddenGapStart) {
      return (_pullHiddenGapEnd + _tesbihBeadSlotProgress * 0.88)
          .clamp(0.54, 0.57)
          .toDouble();
    }

    return (startProgress + _tesbihBeadSlotProgress * 1.08)
        .clamp(0.56, 0.80)
        .toDouble();
  }

  Offset _dialPositionForLocal(Offset localPosition) {
    final dialLeft = (widget.areaWidth - widget.counterSize) / 2;
    final dialTop =
        (widget.areaHeight - widget.counterSize) / 2 - widget.counterVisualLift;
    return localPosition - Offset(dialLeft, dialTop);
  }

  bool _isTesbihPullStart(Offset localPosition) {
    final dialPosition = _dialPositionForLocal(localPosition);
    final x = dialPosition.dx / widget.counterSize;
    final y = dialPosition.dy / widget.counterSize;

    return x >= 0.28 && x <= 1.24 && y >= 0.0 && y <= 1.14;
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

class _TesbihPullHintPill extends StatelessWidget {
  const _TesbihPullHintPill({required this.scale, required this.animation});

  final double scale;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final height = (28 * scale).clamp(25.0, 31.0).toDouble();
    final iconSize = (16.5 * scale).clamp(14.0, 18.0).toDouble();
    final fontSize = (11.4 * scale).clamp(10.2, 12.4).toDouble();

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final pulse = Curves.easeInOutCubic.transform(animation.value);
        final chevronOffset = (pulse * 3.2 * scale).clamp(1.6, 3.8).toDouble();

        return Transform.translate(
          offset: Offset(0, pulse * 1.2),
          child: Container(
            height: height,
            padding: EdgeInsetsDirectional.only(
              start: 6 * scale,
              end: 10 * scale,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cream.withValues(alpha: 0.92),
                  _counterTargetPillSurface.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _gold.withValues(alpha: 0.62),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _deepGreen.withValues(alpha: 0.12),
                  blurRadius: 9 * scale,
                  offset: Offset(0, 4 * scale),
                ),
                BoxShadow(
                  color: _gold.withValues(alpha: 0.14 + pulse * 0.10),
                  blurRadius: 13 * scale,
                  spreadRadius: 0.3 * scale,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: iconSize + 1.5 * scale,
                  height: height,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, chevronOffset - 2.0 * scale),
                        child: Icon(
                          Icons.keyboard_double_arrow_down_rounded,
                          size: iconSize,
                          color: _mutedGold.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4 * scale),
                Text(
                  'Tesbihi çek',
                  style: TextStyle(
                    color: _primaryGreen.withValues(alpha: 0.92),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                    shadows: [
                      Shadow(
                        color: _cream.withValues(alpha: 0.65),
                        blurRadius: 3 * scale,
                        offset: Offset(0, 0.8 * scale),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StaticTesbihAssetReveal extends StatelessWidget {
  const _StaticTesbihAssetReveal({
    required this.fadeOutProgress,
    required this.tesbihModeEnabled,
    required this.child,
  });

  final double fadeOutProgress;
  final bool tesbihModeEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rawProgress = fadeOutProgress.clamp(0.0, 1.0).toDouble();
    final visibleFraction = tesbihModeEnabled
        ? (1 -
                  Curves.easeOutCubic.transform(
                    (rawProgress / 0.035).clamp(0.0, 1.0).toDouble(),
                  ))
              .clamp(0.0, 1.0)
              .toDouble()
        : (1 - Curves.easeOutCubic.transform(rawProgress))
              .clamp(0.0, 1.0)
              .toDouble();
    if (visibleFraction <= 0.001) return const SizedBox.shrink();

    return Opacity(
      opacity: (visibleFraction * 1.08).clamp(0.0, 1.0).toDouble(),
      child: child,
    );
  }
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

class _CompletionAssetOverlay extends StatelessWidget {
  const _CompletionAssetOverlay({
    required this.scale,
    required this.count,
    required this.target,
    required this.dhikrName,
    required this.onDismiss,
    required this.onReset,
  });

  final double scale;
  final int count;
  final int target;
  final String dhikrName;
  final VoidCallback onDismiss;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final systemTextScale = media.textScaler.scale(1);
    final tightCompletionLayout =
        systemTextScale > 1.01 || media.size.shortestSide < 380;
    final cardWidth = math.min(media.size.width * 0.80, 360 * scale);
    final cardHeight = cardWidth * 540 / 360;
    final titleSize = ((tightCompletionLayout ? 30.5 : 32) * scale)
        .clamp(
          tightCompletionLayout ? 27.5 : 29,
          tightCompletionLayout ? 32.5 : 35,
        )
        .toDouble();
    final subtitleSize = ((tightCompletionLayout ? 13.4 : 15.8) * scale)
        .clamp(
          tightCompletionLayout ? 12.4 : 14.5,
          tightCompletionLayout ? 14.8 : 17.8,
        )
        .toDouble();
    final bodySize = ((tightCompletionLayout ? 10.6 : 11.8) * scale)
        .clamp(
          tightCompletionLayout ? 9.8 : 11.0,
          tightCompletionLayout ? 11.8 : 13.2,
        )
        .toDouble();
    final contentTopFactor = tightCompletionLayout ? 0.190 : 0.214;
    final contentSideFactor = tightCompletionLayout ? 0.095 : 0.085;
    final titleGapFactor = tightCompletionLayout ? 0.020 : 0.030;
    final bodyGapFactor = tightCompletionLayout ? 0.016 : 0.026;
    final bodyLineHeight = tightCompletionLayout ? 1.20 : 1.38;
    final buttonSideFactor = tightCompletionLayout ? 0.22 : 0.26;
    final praiseButtonBottomFactor = tightCompletionLayout ? 0.198 : 0.205;
    final resetButtonBottomFactor = tightCompletionLayout ? 0.120 : 0.126;
    const completionBodySuffix =
        '\nzikrini tamamladın.\n'
        'Allah kabul etsin, kalbine huzur,\n'
        'gönlüne ferahlık versin.';

    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          final cardProgress = Curves.easeOutBack
              .transform(progress)
              .clamp(0.0, 1.08)
              .toDouble();
          final cardScale = 0.92 + cardProgress * 0.08;
          final cardLift = (1 - progress) * 24 * scale;

          return BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 7 * progress,
              sigmaY: 7 * progress,
            ),
            child: MediaQuery(
              data: media.copyWith(textScaler: TextScaler.noScaling),
              child: Material(
                color: Colors.black.withValues(alpha: 0.24 * progress),
                child: SafeArea(
                  child: Center(
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          -media.size.height * 0.055 + cardLift,
                        ),
                        child: Transform.scale(
                          scale: cardScale,
                          child: SizedBox(
                            width: cardWidth,
                            height: cardHeight,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    _completionCardAsset,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                Positioned(
                                  top: cardHeight * contentTopFactor,
                                  left: cardWidth * contentSideFactor,
                                  right: cardWidth * contentSideFactor,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PremiumShimmerText(
                                        'Maşâallah!',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _titleGold,
                                          fontFamily: 'EB Garamond',
                                          fontSize: titleSize,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                          shadows: [
                                            Shadow(
                                              color: _mutedGold.withValues(
                                                alpha: 0.22,
                                              ),
                                              blurRadius: 4.4 * scale,
                                              offset: Offset(0, 1.2 * scale),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: cardHeight * titleGapFactor,
                                      ),
                                      Text(
                                        'HEDEFİNE ULAŞTIN',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _primaryGreen,
                                          fontSize: subtitleSize,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0,
                                          height: 1,
                                        ),
                                      ),
                                      SizedBox(
                                        height: cardHeight * bodyGapFactor,
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(text: '$target defa '),
                                            TextSpan(
                                              text: '"$dhikrName"',
                                              style: TextStyle(
                                                color: _titleGold,
                                                fontWeight: FontWeight.w800,
                                                shadows: [
                                                  Shadow(
                                                    color: _mutedGold
                                                        .withValues(
                                                          alpha: 0.18,
                                                        ),
                                                    blurRadius: 3 * scale,
                                                    offset: Offset(
                                                      0,
                                                      0.8 * scale,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            TextSpan(
                                              text: completionBodySuffix,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _primaryGreen.withValues(
                                            alpha: 0.90,
                                          ),
                                          fontSize: bodySize,
                                          fontWeight: FontWeight.w500,
                                          height: bodyLineHeight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: cardWidth * buttonSideFactor,
                                  right: cardWidth * buttonSideFactor,
                                  bottom: cardHeight * praiseButtonBottomFactor,
                                  child: _CompletionPraiseButton(
                                    scale: scale,
                                    onPressed: onDismiss,
                                  ),
                                ),
                                Positioned(
                                  left: cardWidth * buttonSideFactor,
                                  right: cardWidth * buttonSideFactor,
                                  bottom: cardHeight * resetButtonBottomFactor,
                                  child: _CompletionResetButton(
                                    scale: scale,
                                    onPressed: onReset,
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
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompletionPraiseButton extends StatelessWidget {
  const _CompletionPraiseButton({required this.scale, required this.onPressed});

  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (43 * scale).clamp(41, 48).toDouble(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _deepGreen.withValues(alpha: 0.18),
              blurRadius: 12 * scale,
              offset: Offset(0, 5 * scale),
            ),
          ],
        ),
        child: Material(
          color: const Color(0xFF0D4A34),
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            splashColor: _gold.withValues(alpha: 0.16),
            highlightColor: _gold.withValues(alpha: 0.08),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.78),
                  width: 1.2 * scale,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Elhamdülillah',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFF2DE9B),
                          fontSize: (12.4 * scale).clamp(11.6, 13.2).toDouble(),
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Icon(
                      Icons.favorite_border_rounded,
                      color: const Color(0xFFF2DE9B),
                      size: (17 * scale).clamp(15.5, 18.5).toDouble(),
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

class _CompletionResetButton extends StatelessWidget {
  const _CompletionResetButton({required this.scale, required this.onPressed});

  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (34 * scale).clamp(32, 38).toDouble(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _mutedGold.withValues(alpha: 0.10),
              blurRadius: 8 * scale,
              offset: Offset(0, 3 * scale),
            ),
          ],
        ),
        child: Material(
          color: _cream.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            splashColor: _gold.withValues(alpha: 0.12),
            highlightColor: _gold.withValues(alpha: 0.07),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _mutedGold.withValues(alpha: 0.58),
                  width: 1.05 * scale,
                ),
              ),
              child: Center(
                child: Text(
                  'TEKRAR BAŞLA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: (11.8 * scale).clamp(11.2, 13.2).toDouble(),
                    fontWeight: FontWeight.w800,
                    height: 1,
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

// ignore: unused_element
class _CompletionOverlay extends StatelessWidget {
  const _CompletionOverlay({
    required this.scale,
    required this.count,
    required this.target,
    required this.onDismiss,
    required this.onReset,
  });

  final double scale;
  final int count;
  final int target;
  final VoidCallback onDismiss;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.18),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30 * scale),
              child: Container(
                width: math.min(328 * scale, 340),
                padding: EdgeInsets.fromLTRB(
                  22 * scale,
                  22 * scale,
                  22 * scale,
                  18 * scale,
                ),
                decoration: BoxDecoration(
                  color: _referencePanelSurface.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(22 * scale),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.48),
                    width: scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 30 * scale,
                      offset: Offset(0, 14 * scale),
                    ),
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.16),
                      blurRadius: 22 * scale,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54 * scale,
                      height: 54 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryGreen,
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.74),
                          width: 1.2 * scale,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: const Color(0xFFF2DE9B),
                        size: 31 * scale,
                      ),
                    ),
                    SizedBox(height: 14 * scale),
                    Text(
                      'Tebrikler',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _primaryGreen,
                        fontSize: (22 * scale).clamp(21, 25).toDouble(),
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      'Hedef tamamlandı',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _primaryGreen.withValues(alpha: 0.76),
                        fontSize: (13.4 * scale).clamp(12.5, 15).toDouble(),
                        fontWeight: FontWeight.w700,
                        height: 1.16,
                      ),
                    ),
                    SizedBox(height: 13 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 17 * scale,
                        vertical: 9 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: _cream.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _mutedGold.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        '$count / $target',
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: (15 * scale).clamp(14, 17).toDouble(),
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: 17 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: _CompletionActionButton(
                            scale: scale,
                            label: 'Kapat',
                            onPressed: onDismiss,
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: _CompletionActionButton(
                            scale: scale,
                            label: 'Sıfırla',
                            filled: true,
                            onPressed: onReset,
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
      ),
    );
  }
}

class _CompletionActionButton extends StatelessWidget {
  const _CompletionActionButton({
    required this.scale,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final double scale;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (40 * scale).clamp(38, 44).toDouble(),
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: const Color(0xFFF2DE9B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: (12.5 * scale).clamp(12, 14).toDouble(),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryGreen,
                side: BorderSide(color: _mutedGold.withValues(alpha: 0.42)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: (12.5 * scale).clamp(12, 14).toDouble(),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
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
              Expanded(
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
    required this.soundEnabled,
    required this.onReset,
    required this.onUndo,
    required this.onToggleTesbihMode,
    required this.onToggleVibration,
    required this.onToggleSound,
  });

  final double scale;
  final double height;
  final bool tesbihModeEnabled;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final VoidCallback onReset;
  final VoidCallback onUndo;
  final VoidCallback onToggleTesbihMode;
  final VoidCallback onToggleVibration;
  final VoidCallback onToggleSound;

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
                    showStatusDot: true,
                    onPressed: onToggleVibration,
                  ),
                  _ControlButton(
                    scale: scale,
                    icon: soundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: 'SES',
                    selected: soundEnabled,
                    showStatusDot: true,
                    onPressed: onToggleSound,
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
    this.showStatusDot = false,
  });

  final double scale;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final bool showStatusDot;

  @override
  Widget build(BuildContext context) {
    final itemWidth = (54 * scale).clamp(48, 60).toDouble();
    final buttonSize = (38 * scale).clamp(34, 42).toDouble();
    final iconSize = (20 * scale).clamp(18, 22).toDouble();
    final labelSize = (8.8 * scale).clamp(8, 9.6).toDouble();
    final inactiveToggle = showStatusDot && !selected;
    final activeToggle = showStatusDot && selected;
    final buttonSurface = selected
        ? activeToggle
              ? _cream.withValues(alpha: 0.90)
              : _primaryGreen.withValues(alpha: 0.96)
        : _cream.withValues(alpha: inactiveToggle ? 0.58 : 0.90);
    final iconColor = selected
        ? activeToggle
              ? _primaryGreen.withValues(alpha: 0.86)
              : const Color(0xFFF0D78B)
        : _primaryGreen.withValues(alpha: inactiveToggle ? 0.44 : 0.86);
    final borderColor = selected
        ? activeToggle
              ? _mutedGold.withValues(alpha: 0.20)
              : _gold.withValues(alpha: 0.72)
        : _mutedGold.withValues(alpha: inactiveToggle ? 0.14 : 0.20);
    final labelColor = selected
        ? _primaryGreen
        : _primaryGreen.withValues(alpha: inactiveToggle ? 0.50 : 0.76);
    final dotSize = (5.2 * scale).clamp(4.6, 5.8).toDouble();

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
                  color: _deepGreen.withValues(alpha: selected ? 0.18 : 0.08),
                  blurRadius: (selected ? 13 : 10) * scale,
                  offset: Offset(0, (selected ? 5 : 4) * scale),
                ),
                if (selected)
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.18),
                    blurRadius: 9 * scale,
                    offset: Offset.zero,
                  ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: selected ? 0.16 : 0.30),
                  blurRadius: 2 * scale,
                  offset: Offset(0, -0.5 * scale),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Material(
                    color: buttonSurface,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: borderColor,
                        width: (selected ? 1.05 : 0.8) * scale,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onPressed,
                      splashColor: _gold.withValues(alpha: 0.12),
                      highlightColor: _gold.withValues(alpha: 0.08),
                      child: Icon(icon, color: iconColor, size: iconSize),
                    ),
                  ),
                ),
                if (showStatusDot)
                  Positioned(
                    top: (4.8 * scale).clamp(4.2, 5.6).toDouble(),
                    right: (7.1 * scale).clamp(6.3, 7.8).toDouble(),
                    child: IgnorePointer(
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? const Color(0xFFF5D76E)
                              : _mutedGold.withValues(alpha: 0.24),
                          border: Border.all(
                            color: selected
                                ? _cream.withValues(alpha: 0.72)
                                : _cream.withValues(alpha: 0.28),
                            width: 0.65 * scale,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selected
                                  ? _gold.withValues(alpha: 0.64)
                                  : _deepGreen.withValues(alpha: 0.04),
                              blurRadius: (selected ? 5.5 : 1.8) * scale,
                              offset: Offset.zero,
                            ),
                            if (selected)
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.36),
                                blurRadius: 2.2 * scale,
                                offset: Offset(0, -0.3 * scale),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: (3 * scale).clamp(2, 4).toDouble()),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: labelColor,
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
    final statusDotSize = (9.2 * scale).clamp(8.2, 10.2).toDouble();

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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              shape: CircleBorder(
                side: BorderSide(
                  color: _gold.withValues(alpha: 0.62),
                  width: 1.2,
                ),
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
                        color: selected
                            ? _gold
                            : _cream.withValues(alpha: 0.86),
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
          ),
          Positioned(
            top: (8.0 * scale).clamp(7.0, 9.5).toDouble(),
            right: (12.0 * scale).clamp(10.5, 13.5).toDouble(),
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: statusDotSize,
                height: statusDotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xFFFFDC68)
                      : _gold.withValues(alpha: 0.30),
                  border: Border.all(
                    color: selected
                        ? _cream.withValues(alpha: 0.88)
                        : _cream.withValues(alpha: 0.26),
                    width: 0.75 * scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? _gold.withValues(alpha: 0.86)
                          : _deepGreen.withValues(alpha: 0.06),
                      blurRadius: (selected ? 9 : 2.2) * scale,
                      spreadRadius: selected ? 0.7 * scale : 0,
                    ),
                    if (selected)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.44),
                        blurRadius: 3 * scale,
                        offset: Offset(0, -0.4 * scale),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
