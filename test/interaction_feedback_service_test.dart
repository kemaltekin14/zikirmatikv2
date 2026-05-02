import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zikirmatik_v2/core/services/interaction_feedback_service.dart';
import 'package:zikirmatik_v2/features/settings/application/settings_controller.dart';

const _feedbackChannel = MethodChannel('pro.kt.zikirmatikv2/feedback');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_feedbackChannel, null);
  });

  test(
    'primary feedback is silent when vibration and sound are disabled',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            return null;
          });

      final service = InteractionFeedbackService(
        () => const SettingsState(vibrationEnabled: false, soundEnabled: false),
      );

      service.primaryAction();
      await Future<void>.delayed(Duration.zero);

      expect(calls, isEmpty);
    },
  );

  test('bead collision plays native sound when sound is enabled', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_feedbackChannel, (call) async {
          calls.add(call);
          return null;
        });

    final service = InteractionFeedbackService(
      () => const SettingsState(vibrationEnabled: false, soundEnabled: true),
    );

    service.beadCollision();
    await Future<void>.delayed(Duration.zero);

    expect(calls.single.method, 'playBeadCollisionSound');
  });

  test(
    'tesbih tick uses softer native vibration and throttles repeats',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_feedbackChannel, (call) async {
            calls.add(call);
            return null;
          });

      final service = InteractionFeedbackService(
        () => const SettingsState(vibrationEnabled: true, soundEnabled: false),
      );

      service.tesbihTick();
      service.tesbihTick();
      await Future<void>.delayed(Duration.zero);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'vibrate');
      expect(calls.single.arguments, {'durationMs': 34, 'amplitude': 230});
    },
  );
}
