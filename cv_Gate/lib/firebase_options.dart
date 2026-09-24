// File generated for CVGate multi-platform Firebase configuration (macOS, iOS, Android, Web)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA-k33GDpBjoijh36uM8E5NpfQkqiAGbJk',
    appId: '1:127135368449:web:8e6c793eae6b7cfc30c700',
    messagingSenderId: '127135368449',
    projectId: 'cvgate-f44df',
    authDomain: 'cvgate-f44df.firebaseapp.com',
    storageBucket: 'cvgate-f44df.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-k33GDpBjoijh36uM8E5NpfQkqiAGbJk',
    appId: '1:127135368449:android:8e6c793eae6b7cfc30c700',
    messagingSenderId: '127135368449',
    projectId: 'cvgate-f44df',
    storageBucket: 'cvgate-f44df.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-k33GDpBjoijh36uM8E5NpfQkqiAGbJk',
    appId: '1:127135368449:ios:8e6c793eae6b7cfc30c700',
    messagingSenderId: '127135368449',
    projectId: 'cvgate-f44df',
    storageBucket: 'cvgate-f44df.firebasestorage.app',
    iosBundleId: 'com.example.cvGate',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA-k33GDpBjoijh36uM8E5NpfQkqiAGbJk',
    appId: '1:127135368449:ios:8e6c793eae6b7cfc30c700',
    messagingSenderId: '127135368449',
    projectId: 'cvgate-f44df',
    storageBucket: 'cvgate-f44df.firebasestorage.app',
    iosBundleId: 'com.example.cvGate',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA-k33GDpBjoijh36uM8E5NpfQkqiAGbJk',
    appId: '1:127135368449:web:8e6c793eae6b7cfc30c700',
    messagingSenderId: '127135368449',
    projectId: 'cvgate-f44df',
    authDomain: 'cvgate-f44df.firebaseapp.com',
    storageBucket: 'cvgate-f44df.firebasestorage.app',
  );
}
