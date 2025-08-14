import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  // Debug/prod bayrağı: debug'da test üniteleri, prod'da gerçek üniteler
  static bool useTestAds = false;
  static bool _initialized = false;
  static Future<void> init() async {
    if (_initialized) return;
    // Sadece Android/iOS için başlat
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await MobileAds.instance.initialize();
      // Cihazı test olarak işaretle (loglarda önerilen örnek ID eklendi)
      // Kendi cihaz ID'n farklıysa loglarda görünen değerle aşağıdaki listeyi güncelleyebilirsin.
      const List<String> testIds = <String>[
        'E83A179CE35D98D702E6AE6DD65ADF21',
      ];
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testIds),
      );
      _initialized = true;
    } catch (_) {
      // Plugin yoksa sessizce geç
    }
  }

  // Test App IDs (Google):
  // Android: ca-app-pub-3940256099942544~3347511713
  // iOS:     ca-app-pub-3940256099942544~1458002511

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      if (useTestAds) {
        return 'ca-app-pub-3940256099942544/6300978111'; // Android Test Banner
      }
      return 'ca-app-pub-6780266285395945/6269199684'; // PROD
    } else if (Platform.isIOS) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/2934735716' // iOS Test Banner
          : 'ca-app-pub-3940256099942544/2934735716'; // örnek, gerçek iOS prod id yok
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      if (useTestAds) {
        return 'ca-app-pub-3940256099942544/1033173712'; // Android Test Interstitial
      }
      return 'ca-app-pub-6780266285395945/1912836489'; // PROD
    } else if (Platform.isIOS) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/4411468910' // iOS Test Interstitial
          : 'ca-app-pub-3940256099942544/4411468910'; // örnek, gerçek iOS prod id yok
    }
    return '';
  }
}


