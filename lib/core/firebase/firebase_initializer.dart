import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Web için verilen Firebase konfigürasyonu
const FirebaseOptions _webOptions = FirebaseOptions(
  apiKey: 'AIzaSyCL5T98R95vBYB25FpP7_OUeO_X9p6yopM',
  authDomain: 'meme-d63ef.firebaseapp.com',
  projectId: 'meme-d63ef',
  storageBucket: 'meme-d63ef.firebasestorage.app',
  messagingSenderId: '934538270692',
  appId: '1:934538270692:web:ccc7caf2ce78f7d49859f1',
  measurementId: 'G-EKT3QKFMBP',
);

Future<bool> initializeFirebaseSafely() async {
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: _webOptions);
    } else {
      // Android/iOS/Desktop için platform dosyaları eklendiyse çalışır
      await Firebase.initializeApp();
    }
    return true;
  } catch (_) {
    // Kurulum eksikse sessizce in-memory fallback'e döneceğiz
    return false;
  }
}


