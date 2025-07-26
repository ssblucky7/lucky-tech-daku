import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'AIzaSyCC9QbhAD8epAectQ8XIuoAhcwnPF3IHqc',
    appId: '1:${dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867'}:web:finalapp',
    messagingSenderId: dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'school-app-dfaea',
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'school-app-dfaea.firebaseapp.com',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'school-app-dfaea.appspot.com',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'AIzaSyCC9QbhAD8epAectQ8XIuoAhcwnPF3IHqc',
    appId: '1:${dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867'}:android:finalapp',
    messagingSenderId: dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'school-app-dfaea',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'school-app-dfaea.appspot.com',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'AIzaSyCC9QbhAD8epAectQ8XIuoAhcwnPF3IHqc',
    appId: '1:${dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867'}:ios:finalapp',
    messagingSenderId: dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'school-app-dfaea',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'school-app-dfaea.appspot.com',
    iosBundleId: 'com.example.finalapp',
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'AIzaSyCC9QbhAD8epAectQ8XIuoAhcwnPF3IHqc',
    appId: '1:${dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867'}:macos:finalapp',
    messagingSenderId: dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'school-app-dfaea',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'school-app-dfaea.appspot.com',
    iosBundleId: 'com.example.finalapp',
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'AIzaSyCC9QbhAD8epAectQ8XIuoAhcwnPF3IHqc',
    appId: '1:${dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867'}:web:finalapp',
    messagingSenderId: dotenv.env['FIREBASE_PROJECT_NUMBER'] ?? '1012131031867',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'school-app-dfaea',
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'school-app-dfaea.firebaseapp.com',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'school-app-dfaea.appspot.com',
  );
}