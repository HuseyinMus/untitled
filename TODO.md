## TODO (MVP Yol Haritası)

### 0) Acil – Çalışmayı Etkileyen (Güvenlik/İzinler)
- [ ] Firestore kurallarını (DEV) yayınla; yalnızca kendi kullanıcı verisine erişime izin ver.
- [ ] App Check (DEV): Enforcement geçici kapalı veya Debug token ekli olacak.
- [ ] Authentication: Email/Password (ve opsiyonel Anonymous) etkin.
- [ ] Firebase proje eşleşmesi: Android `google-services.json`, iOS `GoogleService-Info.plist`, Web `FirebaseOptions` aynı projeyi işaret ediyor.
- [ ] `catalog_words` için admin yazma izni: admin e-postalarını kurallara ekle (`AdminConfig.adminEmails` ile uyumlu).

### 1) Altyapı ve Mimari
- [ ] Proje adı ve paket kimlikleri güncellensin (`pubspec.yaml`, Android/iOS bundle id, `applicationId`).
- [x] Klasör yapısı: `core/`, `data/`, `features/`.
- [x] Modeller: `Word`, `UserWordState`, `ReviewGrade`.
- [x] SRS motoru (SM-2 esintili): `core/srs/srs.dart`.
- [x] Geçici (in-memory) repository: örnek kelimeler + SRS güncelleme.
- [ ] State management standardizasyonu (örn. Provider/Riverpod) ve DI katmanı.
- [ ] Ortam/Flavors: dev/stage/prod yapılandırmaları, `--dart-define` ile anahtarlar.
- [ ] Hata yönetimi: global error handler, kullanıcıya gösterim stratejisi (Snackbar/Dialogs).
- [ ] Uygulama loglama & crash raporlama stratejisi.

### 2) Veri ve Senkronizasyon
- [ ] Repository genişletmeleri: Firebase tabanlı kalıcı repository’ler (kelimeler, kullanıcı listeleri, istatistikler) – okuma/yazma akışları.
- [ ] Offline-first: Hive entegrasyonu ve senkronizasyon stratejisi (onay sonrası paket kurulumu).
- [ ] Çakışma çözümü ve basit versiyonlama (client timestamp vs server timestamp).
- [ ] Model doğrulama ve serileştirme (gerekirse `json_serializable`/`freezed`) – onay sonrası kurulum.

### 3) Özellikler (Product)
- [x] Ana sayfa: günlük hedef, due sayısı, Flashcard başlat.
- [x] Flashcard ekranı: ön/arka yüz, Again/Hard/Good/Easy puanlama.
- [x] Quiz modu (çoktan seçmeli / yazma) – temel iskelet.
- [x] Admin Paneli: katalog CRUD (kelime ekle/sil/görüntüle).
- [x] Admin Paneli: JSON içe/dışa aktarma (toplu yükleme/indirme).
- [ ] Quiz: soru türleri genişletme (eşleştirme, boşluk doldurma), süre/puanlama, adaptif zorluk.
- [ ] Dinleme modu – TTS ve örnek sesler (yerel/uzak), önbellekleme.
- [ ] Görsel eşleştirme modu.
- [ ] Gamification: XP, seviye, rozet, günlük görevler, seri (streak) iyileştirmeleri.
- [ ] Kullanıcı kelime listeleri: paylaşma/dışa aktarma, sıralama/filtreleme, batch işlemler.
- [ ] Liderlik tablosu: ülke filtresi, arkadaşlar sekmesi.

### 4) Bildirimler ve Etkileşim
- [ ] FCM entegrasyonu: kullanıcıya özel bildiriler (hedef hatırlatma, streak).
- [ ] Yerel bildirim planlama (günlük hatırlatma) – onay sonrası kurulum.
- [ ] Uygulama içi bildirim/duyuru alanı.

### 5) Gelir (Opsiyonel)
- [ ] AdMob entegrasyonu (banner/interstitial/rewarded) – onay sonrası kurulum ve yerleşim.
- [ ] Reklam gösterim kuralları (frekans sınırı, öğrenme akışını bölmemek).

### 6) UX/UI
- [ ] Tema/Tipografi iyileştirmeleri, koyu/açık tema uyumu.
- [ ] Uygulama ikonu ve splash ekran güncellemesi.
- [ ] Responsive düzenler, tablet/masaüstü optimizasyonu.
- [ ] Yükleme iskeletleri (skeleton), boş durum ekranları (empty states).
- [ ] Erişilebilirlik: semantic label, kontrast, ekran okuyucu uyumu.
- [ ] Çok dillilik (TR/EN) ve metinlerin `l10n` yönetimi.

### 7) Analitik ve Ölçümleme
- [x] Analytics: temel ekran izleme (Navigator observer) ve olaylar (quiz/flashcard).
- [x] Crashlytics: global hata yakalama ve kaydetme.
- [ ] Analytics event haritası (ekran görüntüleme, quiz/flashcard etkileşimleri, retenisyon metrikleri).
- [ ] Crashlytics başlangıç doğrulaması ve simge/ProGuard mapping süreçleri.

### 8) Test ve Kalite
- [x] Widget testinin yeni akışa uyarlanması.
- [x] Unit test: `SrsEngine` temel senaryoları.
- [ ] Unit test: Repository’ler (in-memory ve Firebase mock).
- [ ] Widget test: kritik ekranlar (Home, Flashcard, Quiz, Profile).
- [ ] Entegrasyon testleri: Auth (login/register), veri akışları.
- [ ] Lint/format sıkılaştırma ve uyarıların kapatılması.

### 9) Dağıtım ve Operasyon
- [ ] CI/CD: format + analyze + test + build pipeline (GitHub Actions).
- [ ] Android imzalama, versiyonlama, Play Console hazırlıkları.
- [ ] iOS imzalama (signing), App Store Connect hazırlıkları.
- [x] Sürüm notları ve geri dönüş (rollback) planı.

### Kanban (Özet)
- Yapıldı (Done):
  - SRS motoru, in-memory repository, Flashcard, Quiz iskeleti
  - Offline MVP akışı (Firebase yoksa `ShellScreen` ile açılış)
  - İstatistik ekranı hataları düzeltildi (tip/dönüşüm güvenliği)
  - Admin Paneli (katalog CRUD) ve JSON içe/dışa aktarma
- Devam eden (In Progress):
  - Firestore kuralları ve App Check yapılandırması
  - Firebase proje dosyalarının eşleştirilmesi
- Bekleyen (Backlog):
  - State management/DI, Offline-first (Hive), model serileştirme
  - Quiz genişletmeleri, Dinleme iyileştirmeleri, Görsel eşleştirme, Gamification
  - Bildirimler (FCM/local), AdMob, Analytics/Crashlytics, CI/CD, PWA ayarları

### 10) Web ve PWA
- [ ] PWA manifest ve service worker doğrulaması.
- [ ] Web için Firebase App Check (reCAPTCHA) ayarı.
- [ ] Web performans optimizasyonları (lazy load, asset boyutları).

### 11) Masaüstü (Windows/macOS/Linux)
- [ ] Paketleme rehberi ve dağıtım notları (opsiyonel).
- [ ] Dosya sistemi izinleri ve path yönetimi (opsiyonel).

### 12) Dokümantasyon
- [ ] README güncellemesi: kurulum, Firebase yapılandırma, App Check, kurallar.
- [ ] Geliştirici rehberi: mimari, kod standartları, test çalıştırma, sürümler.
- [ ] Gizlilik politikası ve veri saklama prensipleri (bağlantılarla).

---

Notlar:
- Paket kurulumu gerektiren adımlarda onay beklenecek (Hive, json_serializable/freezed, bildirim/admob kütüphaneleri vb.).
- Şu an Flutter çekirdeği + temel Firebase entegrasyonu ile çalışan iskelet kurulu; üretim kullanımı için güvenlik, kurallar ve izleme (analytics/crash) mutlaka tamamlanmalıdır.


