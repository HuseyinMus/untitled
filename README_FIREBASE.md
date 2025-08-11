## Firebase Kurulum Rehberi (Flutter)

Bu projede Firebase: Auth, Firestore, Storage, Analytics, Crashlytics, Messaging (bildirim) için yapılandırılacaktır. Aşağıdaki adımlar kurulum içindir. Kurulum yapmadan önce onayınız gereklidir.

### 1) Firebase Console
1. `https://console.firebase.google.com` → Proje oluştur
2. Android ve iOS (opsiyonel web/macOS/windows) uygulamalarını ekle
3. Android için `applicationId` (varsayılan: `com.example.untitled`) girilecek. Gerçek paket adınızı iletin.
4. `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını indirin.

### 2) Projeye ekleme
- Android: `android/app/google-services.json`
- iOS: Xcode ile Runner içine `GoogleService-Info.plist` ekle (Target → Runner → Build Phases kontrol)

### 3) Flutter paketleri (onay sonrası yüklenecek)
```
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutter pub add firebase_analytics firebase_crashlytics firebase_messaging
```

Android Gradle eklentileri:
- `android/build.gradle` → `classpath 'com.google.gms:google-services:...'
- `android/app/build.gradle` → `apply plugin: 'com.google.gms.google-services'`

### 4) Başlatma kodu (örnek)
```
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // FlutterFire CLI ile üretilir

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

FlutterFire CLI ile `firebase_options.dart` üretimi yapılabilir (onay sonrası komut verilecektir).

### 5) Güvenlik kuralları (taslak)
Firestore: kullanıcı kendi verisini okur/yazar; `catalog_words` read-only.

### 6) Test
`flutter run`, sonra login/okuma/yazma akışını kontrol.


