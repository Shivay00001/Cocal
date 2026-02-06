import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const String firebaseApiKey = 'AIzaSyBQsxXk98-T47biTA5zgGbI0yOQK6eq2Co';
  static const String firebaseAuthDomain = 'cocal-visionquantech.firebaseapp.com';
  static const String firebaseProjectId = 'cocal-visionquantech';
  static const String firebaseStorageBucket = 'cocal-visionquantech.firebasestorage.app';
  static const String firebaseMessagingSenderId = '768213217292';
  static const String firebaseAppId = '1:768213217292:web:c57a7a93bcd76a5017fe29';
  static const String firebaseMeasurementId = 'G-DF97Y14T7N';

  static FirebaseOptions get webOptions => const FirebaseOptions(
        apiKey: firebaseApiKey,
        authDomain: firebaseAuthDomain,
        projectId: firebaseProjectId,
        storageBucket: firebaseStorageBucket,
        messagingSenderId: firebaseMessagingSenderId,
        appId: firebaseAppId,
        measurementId: firebaseMeasurementId,
      );

  static FirebaseOptions get androidOptions => const FirebaseOptions(
        apiKey: firebaseApiKey,
        authDomain: firebaseAuthDomain,
        projectId: firebaseProjectId,
        storageBucket: firebaseStorageBucket,
        messagingSenderId: firebaseMessagingSenderId,
        appId: '1:768213217292:android:c57a7a93bcd76a5017fe29',
      );

  static FirebaseOptions get options {
    if (Platform.isAndroid) {
      return androidOptions;
    }
    return webOptions;
  }

  static Future<FirebaseApp> initialize() async {
    try {
      return await Firebase.initializeApp(options: options);
    } catch (e) {
      return await Firebase.initializeApp();
    }
  }
}
