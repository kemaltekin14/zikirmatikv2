import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class IosEdgeBackGesture extends StatefulWidget {
  const IosEdgeBackGesture({
    super.key,
    required this.child,
    this.enableOnAllPlatforms = false,
    this.edgeWidth = 32,
    this.popThreshold = 52,
  });

  final Widget child;
  final bool enableOnAllPlatforms;
  final double edgeWidth;
  final double popThreshold;

  @override
  State<IosEdgeBackGesture> createState() => _IosEdgeBackGestureState();
}

class _IosEdgeBackGestureState extends State<IosEdgeBackGesture> {
  double _horizontalDrag = 0;
  double _verticalDrag = 0;
  bool _popRequested = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enableOnAllPlatforms &&
        Theme.of(context).platform != TargetPlatform.iOS) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: widget.edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _resetDrag(),
            onHorizontalDragUpdate: (details) {
              _horizontalDrag += details.delta.dx;
              _verticalDrag += details.delta.dy.abs();
            },
            onHorizontalDragEnd: (_) {
              final isIntentionalBackSwipe =
                  _horizontalDrag >= widget.popThreshold &&
                  _horizontalDrag > math.max(_verticalDrag * 1.5, 12);

              if (isIntentionalBackSwipe && !_popRequested) {
                _popRequested = true;
                unawaited(Navigator.maybePop(context));
              }

              _resetDrag();
            },
            onHorizontalDragCancel: _resetDrag,
          ),
        ),
      ],
    );
  }

  void _resetDrag() {
    _horizontalDrag = 0;
    _verticalDrag = 0;
    _popRequested = false;
  }
}
