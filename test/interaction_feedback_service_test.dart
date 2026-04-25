import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zikirmatik_v2/core/services/interaction_feedback_service.dart';
import 'package:zikirmatik_v2/features/settings/application/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
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
}
