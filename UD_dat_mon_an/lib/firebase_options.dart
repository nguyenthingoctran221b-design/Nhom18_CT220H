import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Dự án hiện tại chỉ cấu hình chạy trên nền tảng Android.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCU8vZo0340Rx6I52rkJbu1ACIQNabDYkA',
    appId: '1:557802161294:android:17581e7054af862ad4f5df',
    messagingSenderId: '557802161294',
    projectId: 'csdl-d9373', // Điền đúng Project ID từ web của bạn
    storageBucket: 'csdl-d9373.firebasestorage.app',
  );
}