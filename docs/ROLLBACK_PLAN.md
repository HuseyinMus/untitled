## Geri Dönüş (Rollback) Planı

Bu belge, hatalı bir yayından sonra uygulamayı güvenli şekilde önceki sürüme döndürme adımlarını açıklar.

### Önkoşullar
- Her sürüm için imzalı/versiyonlanmış APK/AAB (Android) ve IPA/TestFlight build (iOS) arşivlenir.
- `RELEASE_NOTES.md` güncel tutulur ve dağıtılan sürüm notları etiketlenir.
- CI/CD üzerinde en azından test/build artefact saklama etkin olmalıdır.

### Rollback Tetikleyicileri (Örnek)
- Kritik crash oranı artışı (örn. %2+ ANR/Crash)
- Oturum açma/ödeme gibi kritik akışlarda başarısızlık artışı
- Performans regresyonu (Soğuk başlatma, kare düşüşleri)

### Rollback Adımları
1. İzleme ve karar
   - Crashlytics, Analytics ve mağaza incelemeleriyle problemi teyit et.
   - Etkilenen platform/sürümü belirle (örn. Android 1.0.1).
2. Yayını duraklat/geri çek
   - Google Play: Release > Artifact > Manage rollout > Pause/Stop.
   - App Store: Sürümü satıştan kaldır veya önceki sürümü yeniden onaya hazırla.
3. Önceki stabil sürüme dön
   - Play Console: Son stabil AAB’yi yüzde 100’e genişlet.
   - App Store: Önceki onaylı sürümü tekrar gönder veya phased release’i geri al.
4. Hotfix hazırlığı (opsiyonel)
   - Sorunu izole et, küçük bir PR ile düzelt; CI: test+build.
   - Yeni sürümü kademeli yayına al (5% → 25% → 50% → 100%).
5. İletişim ve dokümantasyon
   - `RELEASE_NOTES.md` içine olay ve çözümü ekle.
   - İç paydaşlara (ürün, destek) durum raporu geç.

### Risk Azaltma
- Kademeli dağıtım kullan (staged rollout).
- Feature flag/remote config ile riskli özellikleri kapat.
- A/B test ve canary kullanıcı grupları.

### Kontrol Listesi
- [ ] Rollout durduruldu
- [ ] Etkilenen sürüm belirlendi
- [ ] Önceki stabil sürüm %100 yayında
- [ ] Notlar güncellendi (`RELEASE_NOTES.md`)
- [ ] Root-cause analizi başlatıldı


