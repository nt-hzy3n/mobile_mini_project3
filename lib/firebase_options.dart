import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated for VKU Expense QR project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_vku_expense_qr',
    appId: '1:102030405060:web:abcdef1234567890',
    messagingSenderId: '102030405060',
    projectId: 'vku-expense-qr',
    authDomain: 'vku-expense-qr.firebaseapp.com',
    storageBucket: 'vku-expense-qr.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_vku_expense_qr',
    appId: '1:102030405060:android:abcdef1234567890',
    messagingSenderId: '102030405060',
    projectId: 'vku-expense-qr',
    storageBucket: 'vku-expense-qr.appspot.com',
  );
}
