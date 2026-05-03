import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/settings_controller.dart';

class InteractionFeedbackService {
  InteractionFeedbackService(this._readSettings);

  static const _nativeFeedbackChannel = MethodChannel(
    'pro.kt.zikirmatikv2/feedback',
  );
  static const _tesbihTickCooldown = Duration(milliseconds: 25);

  final SettingsState Function() _readSettings;
  DateTime? _lastTesbihTickAt;

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

  void counterTick() {
    _run(
      haptic: () => _nativeVibrate(
        durationMs: 36,
        amplitude: 205,
        fallback: HapticFeedback.mediumImpact,
      ),
      sound: _nativeCounterTickSound,
    );
  }

  void tesbihTick() {
    final now = DateTime.now();
    final lastTick = _lastTesbihTickAt;
    if (lastTick != null && now.difference(lastTick) < _tesbihTickCooldown) {
      return;
    }

    _lastTesbihTickAt = now;
    _run(
      haptic: () => _nativeVibrate(
        durationMs: 34,
        amplitude: 230,
        fallback: HapticFeedback.mediumImpact,
      ),
    );
  }

  void beadCollision() {
    _run(sound: _nativeBeadCollisionSound);
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

  Future<void> _nativeCounterTickSound() {
    return _nativeFeedbackChannel.invokeMethod<void>('playCounterTickSound');
  }

  Future<void> _nativeBeadCollisionSound() {
    return _nativeFeedbackChannel.invokeMethod<void>('playBeadCollisionSound');
  }
}

final interactionFeedbackServiceProvider = Provider<InteractionFeedbackService>(
  (ref) =>
      InteractionFeedbackService(() => ref.read(settingsControllerProvider)),
);
