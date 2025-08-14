import 'package:flutter/material.dart';
import 'package:untitled/features/auth/auth_gate.dart';
import 'package:untitled/core/firebase/firebase_initializer.dart';
import 'package:untitled/theme/app_theme.dart';
import 'dart:ui' as ui;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:untitled/features/shell/shell_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled/ads/ads_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool firebaseReady = await initializeFirebaseSafely();
  // Debug'da test reklamları aç
  if (kDebugMode) {
    AdsService.useTestAds = true;
  }
  await AdsService.init();
  if (firebaseReady) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  runApp(MyApp(firebaseInitialized: firebaseReady));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.firebaseInitialized});

  final bool firebaseInitialized;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRS Vocabulary',
      theme: AppTheme.build(),
      darkTheme: AppTheme.buildDark(),
      themeMode: ThemeMode.system,
      navigatorObservers: firebaseInitialized
          ? <NavigatorObserver>[FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)]
          : const <NavigatorObserver>[],
      home: firebaseInitialized
          ? const AuthGate()
          : const ShellScreen(),
    );
  }
}
