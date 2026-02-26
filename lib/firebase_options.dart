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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForWebPlatform123456789012345',
    appId: '1:123456789012:web:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'wattwise-demo',
    authDomain: 'wattwise-demo.firebaseapp.com',
    storageBucket: 'wattwise-demo.appspot.com',
    measurementId: 'G-MEASUREMENT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForAndroidPlatform123456789012',
    appId: '1:123456789012:android:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'wattwise-demo',
    storageBucket: 'wattwise-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForIOSPlatform1234567890123456',
    appId: '1:123456789012:ios:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'wattwise-demo',
    storageBucket: 'wattwise-demo.appspot.com',
    iosBundleId: 'com.example.wattWise',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForMacOSPlatform1234567890123456',
    appId: '1:123456789012:macos:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'wattwise-demo',
    storageBucket: 'wattwise-demo.appspot.com',
    iosBundleId: 'com.example.wattWise',
  );
}
