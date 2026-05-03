import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

const _pushChannel = AndroidNotificationChannel(
  'push_messages',
  'Genel bildirimler',
  description: 'Firebase ile gelen genel bildirimler',
  importance: Importance.high,
);

final _localNotifications = FlutterLocalNotificationsPlugin();
bool _localNotificationsInitialized = false;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void registerFirebasePushBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<void> initializeFirebasePushNotifications() async {
  try {
    await _configureFirebasePushNotifications();
  } on Object catch (error, stackTrace) {
    developer.log(
      'Firebase push kurulumu tamamlanamadi.',
      name: 'FirebasePush',
      error: error,
      stackTrace: stackTrace,
    );
    debugPrint('Firebase push kurulumu tamamlanamadi: $error');
  }
}

Future<void> _configureFirebasePushNotifications() async {
  await _initializeLocalNotifications();

  final messaging = FirebaseMessaging.instance;
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.onMessage.listen(_showForegroundNotification);

  final notificationsAllowed = await areFirebasePushNotificationsAllowed();
  await messaging.setAutoInitEnabled(notificationsAllowed);
  if (notificationsAllowed) {
    await _ensureFirebaseMessagingToken();
  }
}

Future<bool> areFirebasePushNotificationsAllowed() async {
  await _initializeLocalNotifications();

  if (defaultTargetPlatform == TargetPlatform.android) {
    return await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled() ??
        true;
  }

  final settings = await FirebaseMessaging.instance.getNotificationSettings();
  return switch (settings.authorizationStatus) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
    AuthorizationStatus.denied || AuthorizationStatus.notDetermined => false,
  };
}

Future<bool> requestFirebasePushNotificationPermission() async {
  await _initializeLocalNotifications();

  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  final granted = switch (settings.authorizationStatus) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
    AuthorizationStatus.denied || AuthorizationStatus.notDetermined => false,
  };

  if (!granted) {
    return false;
  }

  await messaging.setAutoInitEnabled(true);
  await _ensureFirebaseMessagingToken();
  return true;
}

Future<void> _ensureFirebaseMessagingToken() async {
  try {
    await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      debugPrint('FCM token hazir.');
    }
  } on Object catch (error, stackTrace) {
    developer.log(
      'FCM token alinamadi.',
      name: 'FirebasePush',
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      debugPrint('FCM token alinamadi: $error');
    }
  }
}

Future<void> _initializeLocalNotifications() async {
  if (_localNotificationsInitialized) return;

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _localNotifications.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
  );

  await _localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_pushChannel);

  _localNotificationsInitialized = true;
}

Future<void> _showForegroundNotification(RemoteMessage message) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  final notification = message.notification;
  final title = notification?.title ?? message.data['title']?.toString();
  final body = notification?.body ?? message.data['body']?.toString();
  if (title == null && body == null) return;

  await _localNotifications.show(
    id: _notificationIdFor(message),
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _pushChannelId,
        _pushChannelName,
        channelDescription: _pushChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: message.data['route']?.toString(),
  );
}

int _notificationIdFor(RemoteMessage message) {
  final source = message.messageId ?? DateTime.now().microsecondsSinceEpoch;
  return source.hashCode & 0x7fffffff;
}

const _pushChannelId = 'push_messages';
const _pushChannelName = 'Genel bildirimler';
const _pushChannelDescription = 'Firebase ile gelen genel bildirimler';
