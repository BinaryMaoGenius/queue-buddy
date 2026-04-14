import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB2wajtQhspTRMbwByRF3gZOurd3nf-8rg',
    appId: '1:637182578674:web:e000000000000000000000',
    messagingSenderId: '637182578674',
    projectId: 'projet-banque-1f8da',
    authDomain: 'projet-banque-1f8da.firebaseapp.com',
    storageBucket: 'projet-banque-1f8da.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2wajtQhspTRMbwByRF3gZOurd3nf-8rg',
    appId: '1:637182578674:android:e000000000000000000000', // Note: Android appId or apiKey from google-services.json
    messagingSenderId: '637182578674',
    projectId: 'projet-banque-1f8da',
    storageBucket: 'projet-banque-1f8da.firebasestorage.app',
  );
}
