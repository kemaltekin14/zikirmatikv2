// File generated from Firebase config files.
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia => throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for this platform.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD015t0Pwao5jAT_iC8ny3m9TpD8gX0lrY',
    appId: '1:731860561020:android:6da37d16d0952d04442df9',
    messagingSenderId: '731860561020',
    projectId: 'zikirmatik-pro-5ddb0',
    storageBucket: 'zikirmatik-pro-5ddb0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAgGP3hNq2EYXv-nnyvhWORxVFsQG7OOQE',
    appId: '1:731860561020:ios:ffeccdc828212147442df9',
    messagingSenderId: '731860561020',
    projectId: 'zikirmatik-pro-5ddb0',
    storageBucket: 'zikirmatik-pro-5ddb0.firebasestorage.app',
    iosBundleId: 'pro.kt.zikirmatikv2',
  );
}
