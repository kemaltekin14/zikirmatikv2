import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

const _tesbihCord = Color(0xFF8F6F35);
const _tesbihEmerald = Color(0xFF7F8B6F);
const _tesbihEmeraldDeep = Color(0xFF4E5A43);
const _tesbihEmeraldLight = Color(0xFFDDE6D0);
const _tesbihEmeraldMist = Color(0xFFB7C2A7);
const _tesbihShadow = Color(0xFF273022);

const List<Offset> tesbihPathPoints = [
  Offset(0.58, 0.12),
  Offset(0.68, 0.10),
  Offset(0.76, 0.16),
  Offset(0.74, 0.27),
  Offset(0.69, 0.39),
  Offset(0.64, 0.52),
  Offset(0.58, 0.66),
  Offset(0.52, 0.79),
  Offset(0.50, 0.90),
  Offset(0.58, 0.94),
  Offset(0.67, 0.87),
];

enum PremiumTesbihPullLayerPass { underRingSegments, overRingStrand }

class PremiumTesbihPullLayer extends StatelessWidget {
  const PremiumTesbihPullLayer({
    super.key,
    required this.scale,
    required this.beadShift,
    required this.pullFraction,
    required this.enabled,
    required this.pass,
    this.revealProgress = 1,
  });

  final double scale;
  final double beadShift;
  final double pullFraction;
  final bool enabled;
  final PremiumTesbihPullLayerPass pass;
  final double revealProgress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PremiumTesbihPullPainter(
        scale: scale,
        beadShift: beadShift,
        pullFraction: pullFraction,
        enabled: enabled,
        pass: pass,
        revealProgress: revealProgress,
      ),
    );
  }
}

class _PremiumTesbihPullPainter extends CustomPainter {
  const _PremiumTesbihPullPainter({
    required this.scale,
    required this.beadShift,
    required this.pullFraction,
    required this.enabled,
    required this.pass,
    required this.revealProgress,
  });

  static const _beadSlotCount = 22;
  static const _beadSpacing = 1 / _beadSlotCount;
  static const _beadWidthFactor = 0.0816;
  static const _beadHeightFactor = 0.0816;
  static const _beadMinWidth = 25.92;
  static const _beadMaxWidth = 36.0;
  static const _beadMinHeight = 25.92;
  static const _beadMaxHeight = 36.0;
  static const _showDebugPath = false;
  static const _livePullBeadShiftSlots = 0.22;
  static const _startUnderRange = _PathProgressRange(0.0, 0.12);
  static const _finalUnderRange = _PathProgressRange(0.86, 1.0);
  static const _hiddenGapRange = _PathProgressRange(0.36, 0.515);
  static const _tailControlPoint = Offset(0.69, 0.845);
  static const _tailEndPoint = Offset(0.705, 0.805);
  static const _beadSettleSpring = SpringDescription(
    mass: 1,
    stiffness: 360,
    damping: 13,
  );
  static const _cordSettleSpring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 18,
  );

  final double scale;
  final double beadShift;
  final double pullFraction;
  final bool enabled;
  final PremiumTesbihPullLayerPass pass;
  final double revealProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final path = _buildPath(size);
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final reveal = revealProgress.clamp(0.0, 1.0).toDouble();
    if (reveal <= 0.001) return;
    final cordReveal = _cordRevealFor(reveal);
    final cordSettle = _cordSettleFor(reveal);
    final opacity = enabled ? 1.0 : 0.24;

    final spacing = metric.length * _beadSpacing;
    final beadSize = _beadSize(size);
    final activePullIndex = pullFraction > 0.001
        ? _closestBeadIndexToProgress(_hiddenGapRange.start)
        : null;
    final activePullStartProgress = activePullIndex == null
        ? null
        : _stableBeadProgress(activePullIndex);
    final activePullProgress = activePullStartProgress == null
        ? null
        : _activePullProgress(activePullStartProgress);

    if (pass == PremiumTesbihPullLayerPass.underRingSegments) {
      final startCord = _extractRevealedPath(
        metric,
        _startUnderRange.start,
        _startUnderRange.end,
        cordReveal,
      );
      final tailCord = _extractRevealedPath(
        metric,
        _finalUnderRange.start,
        _finalUnderRange.end,
        cordReveal,
      );

      if (startCord != null) {
        _drawCord(canvas, startCord, opacity, settleProgress: cordSettle);
      }
      if (tailCord != null) {
        _drawCord(canvas, tailCord, opacity, settleProgress: cordSettle);
      }
      if (_showDebugPath) {
        if (startCord != null) _drawDebugPath(canvas, startCord);
        if (tailCord != null) _drawDebugPath(canvas, tailCord);
      }
    } else {
      final overRingPath = _extractRevealedPath(
        metric,
        _startUnderRange.end,
        _finalUnderRange.start,
        cordReveal,
      );
      if (overRingPath != null) {
        _drawCord(canvas, overRingPath, opacity, settleProgress: cordSettle);
      }
      if (_showDebugPath) {
        _drawDebugPath(canvas, path);
      }
    }

    for (var index = 0; index < _beadSlotCount; index++) {
      if (index == activePullIndex) {
        continue;
      }

      final distance = _wrapDistance(
        (index * spacing) + beadShift * spacing,
        metric.length,
      );
      final progress = distance / metric.length;
      final isUnderRingBead =
          _startUnderRange.contains(progress) ||
          _finalUnderRange.contains(progress);
      final shouldPaintForPass =
          pass == PremiumTesbihPullLayerPass.underRingSegments
          ? isUnderRingBead
          : !isUnderRingBead;

      if (!shouldPaintForPass) {
        continue;
      }

      if (_hiddenGapRange.contains(progress)) {
        continue;
      }

      final beadPhase = _beadPhaseFor(progress, reveal);
      if (beadPhase <= 0) {
        continue;
      }
      final beadReveal = _beadRevealFor(beadPhase);

      final beadDistance =
          metric.length * _slidingBeadProgress(progress, beadPhase, beadReveal);
      final tangent = metric.getTangentForOffset(beadDistance);
      if (tangent == null) continue;

      final pullGlow = index == 0
          ? (0.18 + pullFraction * 0.52).clamp(0.0, 0.70)
          : 0.0;

      _drawEmeraldBead(
        canvas,
        tangent.position,
        beadSize,
        opacity,
        glow: pullGlow,
        appearProgress: beadReveal,
        visibilityProgress: _beadVisibilityFor(beadPhase),
        tangentVector: tangent.vector,
      );
    }

    if (pass == PremiumTesbihPullLayerPass.overRingStrand &&
        activePullProgress != null) {
      final activeBeadPhase = _beadPhaseFor(activePullProgress, reveal);
      final activeBeadReveal = _beadRevealFor(activeBeadPhase);
      final activeBeadDistance =
          metric.length *
          _slidingBeadProgress(
            activePullProgress,
            activeBeadPhase,
            activeBeadReveal,
          );
      final activeTangent = metric.getTangentForOffset(activeBeadDistance);
      if (activeTangent != null) {
        _drawEmeraldBead(
          canvas,
          activeTangent.position,
          beadSize,
          opacity,
          glow: (0.24 + pullFraction * 0.34).clamp(0.0, 0.58).toDouble(),
          appearProgress: activeBeadReveal,
          visibilityProgress: _beadVisibilityFor(activeBeadPhase),
          tangentVector: activeTangent.vector,
        );
      }
    }
  }

  Path? _extractRevealedPath(
    PathMetric metric,
    double startProgress,
    double endProgress,
    double reveal,
  ) {
    final revealedEnd = math.min(endProgress, reveal);
    if (revealedEnd <= startProgress) return null;
    return metric.extractPath(
      metric.length * startProgress,
      metric.length * revealedEnd,
    );
  }

  Path _buildPath(Size size) {
    final points = tesbihPathPoints
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    if (points.length < 2) return Path();

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length - 1; index++) {
      final p0 = points[math.max(0, index - 1)];
      final p1 = points[index];
      final p2 = points[index + 1];
      final p3 = points[math.min(points.length - 1, index + 2)];

      final control1 = p1 + (p2 - p0) / 6;
      final control2 = p2 - (p3 - p1) / 6;
      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        p2.dx,
        p2.dy,
      );
    }

    _appendFinalTailExtension(path, size);
    return path;
  }

  void _appendFinalTailExtension(Path path, Size size) {
    final control = Offset(
      _tailControlPoint.dx * size.width,
      _tailControlPoint.dy * size.height,
    );
    final end = Offset(
      _tailEndPoint.dx * size.width,
      _tailEndPoint.dy * size.height,
    );

    path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }

  Size _beadSize(Size size) {
    return Size(
      (size.shortestSide * _beadWidthFactor)
          .clamp(_beadMinWidth, _beadMaxWidth)
          .toDouble(),
      (size.shortestSide * _beadHeightFactor)
          .clamp(_beadMinHeight, _beadMaxHeight)
          .toDouble(),
    );
  }

  double _activePullProgress(double startProgress) {
    final easedPull = Curves.easeInOutCubic.transform(
      pullFraction.clamp(0.0, 1.0).toDouble(),
    );
    final travel = _forwardProgressDelta(startProgress, _hiddenGapRange.end);
    return _wrapProgress(startProgress + travel * easedPull);
  }

  int _closestBeadIndexToProgress(double targetProgress) {
    var closestIndex = 0;
    var closestScore = double.infinity;
    for (var index = 0; index < _beadSlotCount; index++) {
      final progress = _stableBeadProgress(index);
      final score = _progressDelta(progress, targetProgress);
      if (score < closestScore) {
        closestScore = score;
        closestIndex = index;
      }
    }

    return closestIndex;
  }

  double _stableBeadProgress(int index) {
    final stableBeadShift = beadShift - pullFraction * _livePullBeadShiftSlots;
    return _wrapProgress((index + stableBeadShift) * _beadSpacing);
  }

  void _drawCord(
    Canvas canvas,
    Path path,
    double opacity, {
    required double settleProgress,
  }) {
    final settle = settleProgress.clamp(0.0, 1.12).toDouble();
    final tension = (1 - (settle - 1).abs()).clamp(0.0, 1.0).toDouble();
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (5.5 + tension * 0.3) * scale
      ..color = _tesbihShadow.withValues(alpha: 0.18 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.2 * scale);
    canvas.drawPath(path.shift(Offset(1.8 * scale, 2.5 * scale)), shadowPaint);

    final cordPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (2.65 + tension * 0.45) * scale
      ..color = _tesbihCord.withValues(alpha: 0.78 * opacity);
    canvas.drawPath(path, cordPaint);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.2 * scale
      ..color = const Color(0xFFD8BB72).withValues(alpha: 0.58 * opacity);
    canvas.drawPath(
      path.shift(Offset(-0.55 * scale, -0.55 * scale)),
      highlightPaint,
    );
  }

  void _drawDebugPath(Canvas canvas, Path path) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2
      ..color = Colors.red.withValues(alpha: 0.72);
    canvas.drawPath(path, paint);
  }

  void _drawEmeraldBead(
    Canvas canvas,
    Offset center,
    Size beadSize,
    double opacity, {
    required double glow,
    required double appearProgress,
    required double visibilityProgress,
    required Offset tangentVector,
  }) {
    final springAppear = appearProgress.clamp(0.0, 1.16).toDouble();
    final visibleAppear = visibilityProgress.clamp(0.0, 1.0).toDouble();
    final beadOpacity = opacity * visibleAppear;
    if (beadOpacity <= 0.001) return;

    final impact = _impactFor(springAppear);
    final scaleFactor = (0.58 + springAppear * 0.42 + impact * 0.012)
        .clamp(0.58, 1.035)
        .toDouble();
    final scaledBeadSize = Size(
      beadSize.width * scaleFactor * (1 + impact * 0.028),
      beadSize.height * scaleFactor * (1 - impact * 0.018),
    );
    final radius = math.min(scaledBeadSize.width, scaledBeadSize.height) / 2;
    final beadRect = Rect.fromCenter(
      center: center,
      width: scaledBeadSize.width,
      height: scaledBeadSize.height,
    );

    if (glow > 0) {
      final glowPaint = Paint()
        ..color = _tesbihEmeraldLight.withValues(alpha: glow * beadOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.62);
      canvas.drawOval(beadRect.inflate(radius * 0.38), glowPaint);
    }

    final shadowPaint = Paint()
      ..color = _tesbihShadow.withValues(alpha: 0.25 * beadOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.32);
    canvas.drawOval(
      beadRect.shift(Offset(radius * 0.18, radius * 0.28)),
      shadowPaint,
    );

    final beadPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.42, -0.52),
        radius: 0.92,
        colors: [
          Colors.white.withValues(alpha: 0.86 * beadOpacity),
          _tesbihEmeraldLight.withValues(alpha: 0.96 * beadOpacity),
          _tesbihEmerald.withValues(alpha: beadOpacity),
          _tesbihEmeraldDeep.withValues(alpha: beadOpacity),
        ],
        stops: const [0.0, 0.18, 0.58, 1.0],
      ).createShader(beadRect);
    canvas.drawOval(beadRect, beadPaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale
      ..color = _tesbihEmeraldDeep.withValues(alpha: 0.62 * beadOpacity);
    canvas.drawOval(beadRect.deflate(0.12 * scale), rimPaint);

    final crescentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.05 * scale
      ..color = _tesbihEmeraldMist.withValues(alpha: 0.42 * beadOpacity);
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: scaledBeadSize.width * 0.72,
        height: scaledBeadSize.height * 0.72,
      ),
      -math.pi * 0.06,
      math.pi * 0.58,
      false,
      crescentPaint,
    );

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.68 * beadOpacity);
    canvas.drawCircle(
      center.translate(
        -scaledBeadSize.width * 0.165,
        -scaledBeadSize.height * 0.21,
      ),
      radius * 0.20,
      highlightPaint,
    );
  }

  double _beadPhaseFor(double progress, double reveal) {
    final start = 0.08 + progress * 0.12;
    return ((reveal - start) / 0.62).clamp(0.0, 1.0).toDouble();
  }

  double _beadRevealFor(double phase) {
    return _springProgress(
      _beadSettleSpring,
      phase,
      secondsScale: 0.36,
    ).clamp(0.0, 1.24).toDouble();
  }

  double _beadVisibilityFor(double phase) {
    final slide = _beadSlideFor(phase);
    return Curves.easeOutCubic.transform(
      ((slide - 0.12) / 0.22).clamp(0.0, 1.0).toDouble(),
    );
  }

  double _slidingBeadProgress(
    double targetProgress,
    double phase,
    double appearProgress,
  ) {
    final slide = _beadSlideFor(phase);
    final springOvershoot = (appearProgress - 1).clamp(0.0, 0.24).toDouble();
    final slideBack = (1 - slide) * 0.145;
    final impactForward = springOvershoot * 0.026;
    return (targetProgress - slideBack + impactForward)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _beadSlideFor(double phase) {
    return Curves.easeOutCubic.transform(phase.clamp(0.0, 1.0).toDouble());
  }

  double _impactFor(double appearProgress) {
    final impactWindow = ((appearProgress - 1.0) / 0.18)
        .clamp(0.0, 1.0)
        .toDouble();
    return (math.sin(impactWindow * math.pi) * 0.55).clamp(0.0, 1.0).toDouble();
  }

  double _cordRevealFor(double reveal) {
    final normalizedTime = reveal / 0.54;
    if (normalizedTime <= 0) return 0;
    return _springProgress(
      _cordSettleSpring,
      normalizedTime,
      secondsScale: 0.48,
    ).clamp(0.0, 1.0).toDouble();
  }

  double _cordSettleFor(double reveal) {
    final normalizedTime = reveal / 0.60;
    if (normalizedTime <= 0) return 0;
    return _springProgress(
      _cordSettleSpring,
      normalizedTime,
      secondsScale: 0.50,
    ).clamp(0.0, 1.18).toDouble();
  }

  double _springProgress(
    SpringDescription spring,
    double normalizedTime, {
    required double secondsScale,
  }) {
    final simulation = SpringSimulation(spring, 0, 1, 0);
    return simulation.x(normalizedTime * secondsScale);
  }

  double _wrapDistance(double distance, double length) {
    final wrapped = distance % length;
    return (wrapped < 0 ? wrapped + length : wrapped)
        .clamp(0.0, length - 0.01)
        .toDouble();
  }

  double _wrapProgress(double progress) {
    final wrapped = progress % 1.0;
    return wrapped < 0 ? wrapped + 1.0 : wrapped;
  }

  double _progressDelta(double a, double b) {
    final raw = (a - b).abs();
    return math.min(raw, 1.0 - raw);
  }

  double _forwardProgressDelta(double start, double end) {
    final delta = end - start;
    return delta < 0 ? delta + 1.0 : delta;
  }

  @override
  bool shouldRepaint(covariant _PremiumTesbihPullPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.beadShift != beadShift ||
        oldDelegate.pullFraction != pullFraction ||
        oldDelegate.enabled != enabled ||
        oldDelegate.pass != pass ||
        oldDelegate.revealProgress != revealProgress;
  }
}

class _PathProgressRange {
  const _PathProgressRange(this.start, this.end);

  final double start;
  final double end;

  bool contains(double progress) {
    if (start <= end) {
      return progress >= start && progress <= end;
    }
    return progress >= start || progress <= end;
  }
}
