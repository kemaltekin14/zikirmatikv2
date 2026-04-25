import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment_provider.dart';
import '../config/store_channel.dart';

abstract interface class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object?> parameters});
  Future<void> setCurrentScreen(String screenName);
}

abstract interface class CrashService {
  Future<void> recordNonFatal(Object error, StackTrace stackTrace);
  Future<void> setUserId(String? userId);
}

abstract interface class PushService {
  Future<void> initialize();
  Future<String?> getToken();
}

abstract interface class RemoteConfigService {
  Future<String?> getString(String key);
  Future<bool?> getBool(String key);
}

class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService(this.channel);

  final StoreChannel channel;

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    debugPrint('analytics[$channel] $name $parameters');
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    debugPrint('screen[$channel] $screenName');
  }
}

class NoopCrashService implements CrashService {
  const NoopCrashService(this.channel);

  final StoreChannel channel;

  @override
  Future<void> recordNonFatal(Object error, StackTrace stackTrace) async {
    debugPrint('crash[$channel] $error');
  }

  @override
  Future<void> setUserId(String? userId) async {
    debugPrint('crash-user[$channel] $userId');
  }
}

class NoopPushService implements PushService {
  const NoopPushService(this.channel);

  final StoreChannel channel;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> initialize() async {
    debugPrint('push[$channel] initialized as no-op');
  }
}

class StaticRemoteConfigService implements RemoteConfigService {
  const StaticRemoteConfigService();

  @override
  Future<bool?> getBool(String key) async => null;

  @override
  Future<String?> getString(String key) async => null;
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  return NoopAnalyticsService(env.storeChannel);
});

final crashServiceProvider = Provider<CrashService>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  return NoopCrashService(env.storeChannel);
});

final pushServiceProvider = Provider<PushService>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  return NoopPushService(env.storeChannel);
});

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return const StaticRemoteConfigService();
});
