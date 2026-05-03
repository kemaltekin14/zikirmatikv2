import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

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
    debugPrint(
      'analytics[$channel] $name ${_firebaseAnalyticsParameters(parameters) ?? const {}}',
    );
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    debugPrint('screen[$channel] $screenName');
  }
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this.channel, {FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final StoreChannel channel;
  final FirebaseAnalytics _analytics;
  var _collectionEnabled = false;

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    try {
      await _ensureCollectionEnabled();
      final sanitizedParameters = _firebaseAnalyticsParameters(parameters);
      await _analytics.logEvent(name: name, parameters: sanitizedParameters);
      if (kDebugMode) {
        debugPrint(
          'firebase-analytics[$channel] $name ${sanitizedParameters ?? const {}}',
        );
      }
    } catch (error) {
      debugPrint('firebase-analytics[$channel] skipped $name: $error');
    }
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    try {
      await _ensureCollectionEnabled();
      await _analytics.logScreenView(screenName: screenName);
      if (kDebugMode) {
        debugPrint('firebase-screen[$channel] $screenName');
      }
    } catch (error) {
      debugPrint('firebase-screen[$channel] skipped $screenName: $error');
    }
  }

  Future<void> _ensureCollectionEnabled() async {
    if (_collectionEnabled) return;
    await _analytics.setAnalyticsCollectionEnabled(true);
    _collectionEnabled = true;
  }
}

Map<String, Object>? _firebaseAnalyticsParameters(
  Map<String, Object?> parameters,
) {
  final sanitized = <String, Object>{};
  for (final entry in parameters.entries) {
    if (_blockedAnalyticsParameterKeys.contains(entry.key)) continue;

    final value = entry.value;
    if (value == null) continue;

    if (value is String) {
      if (!_allowedStringAnalyticsParameterKeys.contains(entry.key)) continue;
      sanitized[entry.key] = value.length > 40 ? value.substring(0, 40) : value;
    } else if (value is int) {
      sanitized[entry.key] = value;
    } else if (value is double && value.isFinite) {
      sanitized[entry.key] = value;
    } else if (value is bool) {
      sanitized[entry.key] = value ? 1 : 0;
    }
  }

  return sanitized.isEmpty ? null : sanitized;
}

// Keep Firebase events useful without sending religious text, custom content,
// identifiers, exact reminder times, or prayer/counter quantities.
const _blockedAnalyticsParameterKeys = {
  'category',
  'count',
  'dhikr_category',
  'dhikr_id',
  'dhikr_name',
  'esma_name',
  'esma_number',
  'hour',
  'minute',
  'previous_target_count',
  'target',
  'target_count',
  'target_dhikr_id',
  'title',
  'body',
  'query',
  'search_query',
};

const _allowedStringAnalyticsParameterKeys = {
  'source',
  'reminder_type',
  'repeat_type',
};

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
  if (env.usesHuaweiServices) {
    return NoopAnalyticsService(env.storeChannel);
  }

  return FirebaseAnalyticsService(env.storeChannel);
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
