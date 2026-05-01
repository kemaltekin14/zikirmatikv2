import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

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

class PremiumTesbihBeadSnapshot {
  const PremiumTesbihBeadSnapshot({
    required this.index,
    required this.progress,
    required this.position,
    required this.tangentVector,
    required this.receiveGapIndex,
    required this.receiveGapProgress,
  });

  final int index;
  final double progress;
  final Offset position;
  final Offset tangentVector;
  final int? receiveGapIndex;
  final double? receiveGapProgress;
}

PremiumTesbihBeadSnapshot? nearestPremiumTesbihBeadSnapshot({
  required Size size,
  required Offset position,
  required double beadShift,
  double revealProgress = 1,
}) {
  return _PremiumTesbihPullPainter(
    scale: 1,
    beadShift: beadShift,
    lowerBeadShift: beadShift,
    pullFraction: 0,
    enabled: true,
    pass: PremiumTesbihPullLayerPass.overRingStrand,
    revealProgress: revealProgress,
    activeBeadIndex: null,
    activeBeadProgress: null,
    suppressedBeadIndex: null,
  ).nearestVisibleBeadSnapshot(position, size);
}

class PremiumTesbihPullLayer extends StatelessWidget {
  const PremiumTesbihPullLayer({
    super.key,
    required this.scale,
    required this.beadShift,
    this.lowerBeadShift,
    required this.pullFraction,
    required this.enabled,
    required this.pass,
    this.revealProgress = 1,
    this.activeBeadIndex,
    this.activeBeadProgress,
    this.suppressedBeadIndex,
  });

  final double scale;
  final double beadShift;
  final double? lowerBeadShift;
  final double pullFraction;
  final bool enabled;
  final PremiumTesbihPullLayerPass pass;
  final double revealProgress;
  final int? activeBeadIndex;
  final double? activeBeadProgress;
  final int? suppressedBeadIndex;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PremiumTesbihPullPainter(
        scale: scale,
        beadShift: beadShift,
        lowerBeadShift: lowerBeadShift ?? beadShift,
        pullFraction: pullFraction,
        enabled: enabled,
        pass: pass,
        revealProgress: revealProgress,
        activeBeadIndex: activeBeadIndex,
        activeBeadProgress: activeBeadProgress,
        suppressedBeadIndex: suppressedBeadIndex,
      ),
    );
  }
}

class _PremiumTesbihPullPainter extends CustomPainter {
  const _PremiumTesbihPullPainter({
    required this.scale,
    required this.beadShift,
    required this.lowerBeadShift,
    required this.pullFraction,
    required this.enabled,
    required this.pass,
    required this.revealProgress,
    required this.activeBeadIndex,
    required this.activeBeadProgress,
    required this.suppressedBeadIndex,
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
  static const _startUnderRange = _PathProgressRange(0.0, 0.12);
  static const _finalUnderRange = _PathProgressRange(0.86, 1.0);
  static const _hiddenGapRange = _PathProgressRange(0.36, 0.515);
  static const _upperFrontPullRange = _PathProgressRange(0.245, 0.36);
  static const _receiveGapRange = _PathProgressRange(0.515, 0.64);
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
  final double lowerBeadShift;
  final double pullFraction;
  final bool enabled;
  final PremiumTesbihPullLayerPass pass;
  final double revealProgress;
  final int? activeBeadIndex;
  final double? activeBeadProgress;
  final int? suppressedBeadIndex;

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
      if (index == activeBeadIndex || index == suppressedBeadIndex) {
        continue;
      }

      final bead = _beadSampleForIndex(metric, index, spacing, reveal);
      if (bead == null) continue;

      if (!_shouldPaintBeadForPass(bead.progress)) {
        continue;
      }

      if (_hiddenGapRange.contains(bead.progress)) {
        continue;
      }

      final pullGlow = activeBeadIndex == null && index == 0
          ? (0.18 + pullFraction * 0.52).clamp(0.0, 0.70)
          : 0.0;

      _drawEmeraldBead(
        canvas,
        bead.tangent.position,
        beadSize,
        opacity,
        glow: pullGlow,
        appearProgress: bead.reveal,
        visibilityProgress: bead.visibility,
        tangentVector: bead.tangent.vector,
      );
    }

    if (pass == PremiumTesbihPullLayerPass.overRingStrand &&
        activeBeadIndex != null &&
        activeBeadProgress != null) {
      final activePulledOpacity = 1.0 - _smoothStep(0.78, 0.94, pullFraction);
      if (pullFraction >= 0.94 || activePulledOpacity <= 0) {
        return;
      }

      final activeBead = _beadSampleForProgress(
        metric,
        activeBeadProgress!,
        reveal,
      );
      if (activeBead != null) {
        _drawEmeraldBead(
          canvas,
          activeBead.tangent.position,
          beadSize,
          opacity * activePulledOpacity,
          glow: (0.18 + pullFraction * 0.52).clamp(0.0, 0.70),
          appearProgress: activeBead.reveal,
          visibilityProgress: activeBead.visibility,
          tangentVector: activeBead.tangent.vector,
        );
      }
    }
  }

  PremiumTesbihBeadSnapshot? nearestVisibleBeadSnapshot(
    Offset position,
    Size size,
  ) {
    if (size.isEmpty) return null;

    final path = _buildPath(size);
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return null;

    final metric = metrics.first;
    final spacing = metric.length * _beadSpacing;
    final reveal = revealProgress.clamp(0.0, 1.0).toDouble();
    _TesbihBeadSample? turnBead;
    _TesbihBeadSample? fallbackTurnBead;
    var turnBeadIndex = -1;
    var fallbackTurnBeadIndex = -1;
    var turnDistanceToGate = double.infinity;
    var fallbackDistanceToGate = double.infinity;
    var turnTouchDistance = double.infinity;
    var receiveGapIndex = -1;
    double? receiveGapProgress;
    var receiveGapDistance = double.infinity;
    final maxHitDistance = (size.shortestSide * 0.56)
        .clamp(148.0, 220.0)
        .toDouble();

    for (var index = 0; index < _beadSlotCount; index++) {
      final bead = _beadSampleForIndex(metric, index, spacing, reveal);
      if (bead == null || _hiddenGapRange.contains(bead.progress)) {
        continue;
      }

      if (_upperFrontPullRange.contains(bead.progress)) {
        final gateDistance = (_hiddenGapRange.start - bead.progress).abs();
        if (gateDistance < turnDistanceToGate) {
          turnDistanceToGate = gateDistance;
          turnBeadIndex = index;
          turnBead = bead;
          turnTouchDistance = (bead.tangent.position - position).distance;
        }
      }

      if (bead.progress >= _startUnderRange.end &&
          bead.progress < _hiddenGapRange.start) {
        final gateDistance = (_hiddenGapRange.start - bead.progress).abs();
        if (gateDistance < fallbackDistanceToGate) {
          fallbackDistanceToGate = gateDistance;
          fallbackTurnBeadIndex = index;
          fallbackTurnBead = bead;
        }
      }

      if (_receiveGapRange.contains(bead.progress)) {
        final receiveDistance = (bead.progress - _hiddenGapRange.end).abs();
        if (receiveDistance < receiveGapDistance) {
          receiveGapDistance = receiveDistance;
          receiveGapIndex = index;
          receiveGapProgress = bead.progress;
        }
      }
    }

    if (turnBead == null) {
      turnBead = fallbackTurnBead;
      turnBeadIndex = fallbackTurnBeadIndex;
      if (turnBead != null) {
        turnTouchDistance = (turnBead.tangent.position - position).distance;
      }
    }

    if (turnBead == null) {
      return null;
    }

    final normalizedX = position.dx / size.width;
    final normalizedY = position.dy / size.height;
    final inPullCorridor =
        normalizedX >= 0.28 &&
        normalizedX <= 1.24 &&
        normalizedY >= 0.0 &&
        normalizedY <= 1.14;
    if (turnTouchDistance > maxHitDistance && !inPullCorridor) {
      return null;
    }

    return PremiumTesbihBeadSnapshot(
      index: turnBeadIndex,
      progress: turnBead.progress,
      position: turnBead.tangent.position,
      tangentVector: turnBead.tangent.vector,
      receiveGapIndex: receiveGapIndex >= 0 ? receiveGapIndex : null,
      receiveGapProgress: receiveGapProgress,
    );
  }

  _TesbihBeadSample? _beadSampleForIndex(
    PathMetric metric,
    int index,
    double spacing,
    double reveal,
  ) {
    if (index < 0 || index >= _beadSlotCount) return null;

    final baseDistance = _wrapDistance(
      (index * spacing) + beadShift * spacing,
      metric.length,
    );
    final baseProgress = baseDistance / metric.length;
    final distance = _isLowerStrandProgress(baseProgress)
        ? _wrapDistance(
            (index * spacing) + lowerBeadShift * spacing,
            metric.length,
          )
        : baseDistance;
    final progress = distance / metric.length;

    final beadPhase = _beadPhaseFor(progress, reveal);
    if (beadPhase <= 0) return null;

    final beadReveal = _beadRevealFor(beadPhase);
    final beadDistance =
        metric.length * _slidingBeadProgress(progress, beadPhase, beadReveal);
    final tangent = metric.getTangentForOffset(beadDistance);
    if (tangent == null) return null;

    return _TesbihBeadSample(
      progress: progress,
      reveal: beadReveal,
      visibility: _beadVisibilityFor(beadPhase),
      tangent: tangent,
    );
  }

  _TesbihBeadSample? _beadSampleForProgress(
    PathMetric metric,
    double progress,
    double reveal,
  ) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final beadPhase = _beadPhaseFor(clampedProgress, reveal);
    if (beadPhase <= 0) return null;

    final beadReveal = _beadRevealFor(beadPhase);
    final beadDistance =
        metric.length *
        _slidingBeadProgress(clampedProgress, beadPhase, beadReveal);
    final tangent = metric.getTangentForOffset(beadDistance);
    if (tangent == null) return null;

    return _TesbihBeadSample(
      progress: clampedProgress,
      reveal: beadReveal,
      visibility: _beadVisibilityFor(beadPhase),
      tangent: tangent,
    );
  }

  bool _isLowerStrandProgress(double progress) {
    return progress >= _hiddenGapRange.end && progress <= _finalUnderRange.end;
  }

  double _smoothStep(double start, double end, double value) {
    final t = ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    return t * t * (3 - 2 * t);
  }

  bool _shouldPaintBeadForPass(double progress) {
    final isUnderRingBead =
        _startUnderRange.contains(progress) ||
        _finalUnderRange.contains(progress);
    return pass == PremiumTesbihPullLayerPass.underRingSegments
        ? isUnderRingBead
        : !isUnderRingBead;
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

  @override
  bool shouldRepaint(covariant _PremiumTesbihPullPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.beadShift != beadShift ||
        oldDelegate.lowerBeadShift != lowerBeadShift ||
        oldDelegate.pullFraction != pullFraction ||
        oldDelegate.enabled != enabled ||
        oldDelegate.pass != pass ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.activeBeadIndex != activeBeadIndex ||
        oldDelegate.activeBeadProgress != activeBeadProgress ||
        oldDelegate.suppressedBeadIndex != suppressedBeadIndex;
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

class _TesbihBeadSample {
  const _TesbihBeadSample({
    required this.progress,
    required this.reveal,
    required this.visibility,
    required this.tangent,
  });

  final double progress;
  final double reveal;
  final double visibility;
  final Tangent tangent;
}
