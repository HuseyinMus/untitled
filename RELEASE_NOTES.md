## Sürüm Notları

Bu dosya, uygulama sürümlerindeki önemli değişiklikleri, bilinen sorunları ve yükseltme notlarını içerir.

### 1.0.0+1
- İlk MVP sürümü
  - SRS motoru (SM-2 esintili) ve birim testleri
  - Flashcard modu: Again/Hard/Good/Easy değerlendirme, SRS güncelleme
  - Quiz modu: Çoktan seçmeli ve yazma
  - Dinleme modu (temel iskelet)
  - Repository soyutlaması: `InMemoryRepository` ve `FirebaseRepository`
  - Offline fallback: Firebase başarısızsa in-memory ile çalışma
  - İstatistikler: günlük özet ve liderlik tablosu (Firebase)
  - Analytics & Crashlytics entegrasyonu

Bilinen Sorunlar
- Firestore güvenlik kuralları ve App Check yapılandırmaları üretim seviyesinde tamamlanmalıdır.
- Offline-first kalıcı depolama (Hive) henüz eklenmemiştir.

Yükseltme Notları
- Firebase ile çalışan özellikler için `google-services.json` / `GoogleService-Info.plist` ve web `FirebaseOptions` değerlerinin doğru projeyi işaret ettiğinden emin olun.
- Paket kimliği/proje adı üretime geçmeden güncellenmelidir.


