import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated from google-services.json for project: money-exchange-6c417
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
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWQnq82x1IPw0ov2NX17UXACrrOExvTFA',
    appId: '1:602323999202:android:517e42c83fbae1574ec1bb',
    messagingSenderId: '602323999202',
    projectId: 'money-exchange-6c417',
    storageBucket: 'money-exchange-6c417.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAWQnq82x1IPw0ov2NX17UXACrrOExvTFA',
    appId: '1:602323999202:android:517e42c83fbae1574ec1bb',
    messagingSenderId: '602323999202',
    projectId: 'money-exchange-6c417',
    authDomain: 'money-exchange-6c417.firebaseapp.com',
    storageBucket: 'money-exchange-6c417.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAWQnq82x1IPw0ov2NX17UXACrrOExvTFA',
    appId: '1:602323999202:android:517e42c83fbae1574ec1bb',
    messagingSenderId: '602323999202',
    projectId: 'money-exchange-6c417',
    storageBucket: 'money-exchange-6c417.firebasestorage.app',
  );
}
