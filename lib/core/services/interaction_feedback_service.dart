import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/settings_controller.dart';

class InteractionFeedbackService {
  const InteractionFeedbackService(this._readSettings);

  static const _nativeFeedbackChannel = MethodChannel(
    'pro.zikirmatik.app/feedback',
  );

  final SettingsState Function() _readSettings;

  void selection() {
    _run(haptic: HapticFeedback.selectionClick);
  }

  void primaryAction() {
    _run(
      haptic: () => _nativeVibrate(
        durationMs: 28,
        amplitude: 135,
        fallback: HapticFeedback.mediumImpact,
      ),
    );
  }

  void success() {
    _run(
      haptic: () => _nativeVibrate(
        durationMs: 46,
        amplitude: 175,
        fallback: HapticFeedback.heavyImpact,
      ),
      sound: _nativeSuccessSound,
    );
  }

  void _run({Future<void> Function()? haptic, Future<void> Function()? sound}) {
    final settings = _readSettings();
    if (settings.vibrationEnabled && haptic != null) {
      unawaited(_guard(haptic));
    }
    if (settings.soundEnabled && sound != null) {
      unawaited(_guard(sound));
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Platform feedback can be unavailable in tests, desktop, or emulators.
    }
  }

  Future<void> _nativeVibrate({
    required int durationMs,
    required int amplitude,
    required Future<void> Function() fallback,
  }) async {
    try {
      await _nativeFeedbackChannel.invokeMethod<void>('vibrate', {
        'durationMs': durationMs,
        'amplitude': amplitude,
      });
    } on MissingPluginException {
      await fallback();
    } on PlatformException {
      await fallback();
    }
  }

  Future<void> _nativeSuccessSound() {
    return _nativeFeedbackChannel.invokeMethod<void>('playSuccessSound');
  }
}

final interactionFeedbackServiceProvider = Provider<InteractionFeedbackService>(
  (ref) =>
      InteractionFeedbackService(() => ref.read(settingsControllerProvider)),
);
