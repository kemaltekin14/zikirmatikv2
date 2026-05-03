import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_services.dart';

class AnalyticsScreenView extends ConsumerStatefulWidget {
  const AnalyticsScreenView({
    super.key,
    required this.screenName,
    required this.child,
  });

  final String screenName;
  final Widget child;

  @override
  ConsumerState<AnalyticsScreenView> createState() =>
      _AnalyticsScreenViewState();
}

class _AnalyticsScreenViewState extends ConsumerState<AnalyticsScreenView> {
  @override
  void initState() {
    super.initState();
    _logScreenView();
  }

  @override
  void didUpdateWidget(covariant AnalyticsScreenView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenName != widget.screenName) {
      _logScreenView();
    }
  }

  void _logScreenView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(analyticsServiceProvider).setCurrentScreen(widget.screenName),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
