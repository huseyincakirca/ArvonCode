# ArvonCode — Phoenix Master Doc (ARVONCODE-PHOENIX)
# ArvonCode – Project Control File (MASTER)

⚠️ ÖNEMLİ NOT:
Bu dosya teknik dokümantasyon DEĞİLDİR.

Teknik gerçekler:
→ docs/ klasörü altındadır.

Bu dosyanın amacı:
- Yapılan işleri kayıt altına almak
- Checkpoint takibi yapmak
- Karar ve risk notlarını tutmak
- Sıradaki adımı netleştirmek

Teknik detay tekrarları bilinçli olarak tutulabilir ancak
aktif referans DEĞİLDİR.

---

> Bu dosya **proje yönetimi için tek kaynak gerçeğidir (single source of truth)**.
> Teknik gerçekler (endpoint sözleşmeleri, DB şemaları, request/response detayları)
> **docs/** klasörü altındadır.
>
> Bu dosya; kararlar, checkpoint’ler, ilerleme durumu ve risk takibi için referanstır.

> Yeni sekmeye geçerken bu dosyayı paylaş: Ben de **%100 buradan** devam ederim, karışıklık olmaz.
---

## 🔵 AKTİF CHECKPOINT DURUMU

 Aktif checkpoint: Checkpoint #41 — DEVAM EDİYOR — Push Gönderim Optimizasyonu & Queue (Backend)

### CHECKPOINT #39 — Push Stabilizasyonu & UX İyileştirme
- Durum: TAMAMLANDI
- Tamamlanan:
  - Push token refresh (onTokenRefresh) yönetimi
  - Logout sonrası push token revoke
  - Token sync retry guard (lifecycle bazlı)
  - Foreground push davranışı kontrol altına alındı (auto-navigation kapalı)
  - Push navigation dedup persisted hale getirildi
  - Push kaynaklı navigation crash riskleri giderildi
- Test:
  - Android gerçek cihazda:
    - token refresh
    - logout → login
    - foreground / background / killed push
    senaryoları manuel test edildi

### CHECKPOINT #40 — Push UX & Notification Tasarımı
- Durum: TAMAMLANDI
- Kararlar:
  - Push type sözleşmesi sabitlendi (message | location)
  - Foreground push’ta auto-navigation kapatıldı
  - Foreground push için in-app banner UX uygulandı
  - Background/killed durumda sistem notification kullanıldı
  - Push navigation dedup davranışı korundu
  - Android için tek notification channel tanımlandı
  - Badge / unread counter bilinçli olarak devre dışı bırakıldı
- Test:
  - Android gerçek cihazda:
    - foreground banner
    - background notification
    - killed state notification
    - notification tap → doğru araç ekranı
    manuel test edildi
- Bilinçli UX / Teknik Borçlar:
  - Foreground push banner uzun body durumlarında overflow riski taşır (prod polish’te ele alınacak)
  - Push navigation dedup şu an sadece vehicle_uuid bazlıdır (type bazlı ayrım yok)
  - flutter_local_notifications şu an yalnızca Android channel init için kullanılmaktadır
  - Push UX senaryoları Android gerçek cihazda manuel test edilecek; otomatik test yok

### CHECKPOINT #41 — Push Gönderim Optimizasyonu & Queue
- Durum: DEVAM EDİYOR
- Tamamlanan:
  - Push gönderimi queue tabanlı hale getirildi.
  - Retry & backoff mekanizması eklendi.
  - Backend flood koruması uygulandı.
  - PushService legacy FCM’den ayrıştırıldı.
### CHECKPOINT #42 — FCM HTTP v1 Geçiş Hazırlığı
- Service Account tabanlı HTTP v1 transport eklendi.
- Legacy ve HTTP v1 transport’lar paralel çalışabilir hale getirildi.
- Transport seçimi config (.env) üzerinden yapılabilir hale getirildi.
- JWT üretimi ve access token cache altyapısı eklendi.
- Legacy fallback bilinçli olarak korundu.
### Bilinçli Teknik Borçlar / Riskler (Checkpoint #42)
- PushNotificationService, payload içinde `created_at` zaman bilgisini taşımaya devam etmektedir; queue retry ve gecikmelerde zaman semantiği sapabilir.
- FCM HTTP v1 transport’ta tüm 4xx hatalar tek sınıf olarak ele alınmaktadır; farklı 4xx türleri (400 / 401 / 403 / 404) ayrıştırılmamaktadır.
- FCM HTTP v1 access token cache anahtarı yalnızca service account path’e bağlıdır; çoklu project / multi-account senaryoları için yetersizdir.
- HTTP v1 ve legacy push gönderimleri için metrik/istatistik (başarı, hata, retry sayısı) toplanmamaktadır.
- PUSH_TRANSPORT config değeri hatalı girilirse sistem sessizce legacy transport’a düşmektedir; yanlış konfigürasyon açık hata üretmez.
### CHECKPOINT #43 — Push Batch / Multicast & Token Invalidation
- Kapsam:
  - HTTP v1 push için token bazlı sonuç takibi + 500’lük chunk ile tekil HTTP v1 messages:send çağrıları (batch endpoint yok)
  - Invalid token’ların otomatik pasiflenmesi (soft disable + soft delete)
  - Retry-worthy token’lar için subset retry dispatch (batch tamamı retry edilmez)
- Kararlar:
  - PushTransportInterface’e sendMulticast eklendi; PushNotificationService tüm token listesi için multicast kullanıyor.
  - FCM HTTP v1 transport’ta 500’lük chunk’lar ile tekil messages:send çağrıları ve token bazlı success/invalid/retryable ayrımı yapılıyor.
  - Legacy transport tekil gönderimle korunuyor; multicast çağrıları tekil send üzerinden normalize ediliyor.
  - Retryable token’lar için yeni job dispatch edilir; invalid token’lar is_active=false + soft delete ile pasiflenir.
  - Her batch’te success/invalid/retry_count loglanır; sessiz invalidation yok.
- Bilinçli Teknik Borçlar / Kısıtlar:
  - Legacy transport’ta invalid token ayrımı sınırlı; client error’lar invalid olarak işaretlenir.
  - Access token üretimi hâlâ service account path + project_id cache anahtarına bağlı; multi-tenant için genişletme gerekir.
  - Multicast metrikleri log tabanlı; kalıcı metrik/alerting yok.
  - Subset retry yeni job oluşturur; toplam deneme sayısı transport seviyesinde izlenmez.
### Bilinçli Teknik Borçlar / Riskler
- HTTP v1 geçişi tamamlandı ancak legacy henüz kaldırılmadı.
- Service account IAM / quota hataları prod’da sessiz push kaybı riski taşır.
- JWT token cache süresi yanlış yönetilirse push gecikmeleri yaşanabilir.
- HTTP v1 multicast / batch gönderim bu checkpoint kapsamı dışındadır.
### Bilinçli Teknik Borçlar / Riskler (Checkpoint #41)
- Push job constructor içinde `createdAt` gibi zaman verisi taşınmaktadır; job execution gecikmelerinde zaman semantiği sapabilir.
- Flood koruması için kullanılan cache lock key, `vehicle_id` bulunamadığında `vehicle_uuid` fallback’i kullanmaktadır; tek tip anahtar semantiği yoktur.
- Push token varlığı Listener seviyesinde, token listesi ise Job içinde tekrar sorgulanmaktadır; veri erişimi duplike durumdadır.
- Queue worker lifecycle (supervisor / process yönetimi) bu checkpoint kapsamında tanımlanmamıştır.
- Checkpoint #41 commit’i, bu checkpoint’e ait olmayan önceden var olan workspace değişikliklerini de içermektedir; commit izolasyonu bozulmuştur.


## 🗂 ARŞİV – TARİHSEL TEKNİK NOTLAR

Aşağıdaki içerik, projenin önceki aşamalarında referans alınmış,
ancak güncel teknik gerçekliği docs/ klasörüne taşınmıştır.
⚠️ UYARI:
Bu bölüm aktif geliştirme için referans alınmaz.
Güncel teknik sözleşme her zaman docs/ klasöründedir.


Bu bölüm:
- Silinmez
- Değiştirilmez
- Geriye dönük referans amaçlıdır

### Public Security & Observability
- public_request_logs tablosu ile public istekler (başarılı/başarısız) merkezi loglanır.
- Public endpoint’ler context-aware rate limit (PUBLIC_RATE_LIMIT) altında çalışır.
- Abuse analizi için lokal/staging’de okuma komutları tercih edilir; prod’da kapalıdır.
- PublicRequestLogger log yazarken hata alırsa, request akışını bozmamak için exception yutar (bilinçli tercih: observability kaybı servis sürekliliğine tercih edilir).

## 0) Kimlik

- **Proje Adı:** ArvonCode
- **Kod Adı / Hafıza Anahtarı:** ARVONCODE-PHOENIX
- **Proje Türü:** NFC + QR kodlu akıllı araç kartı sistemi (Laravel API + Flutter mobil)
- **Ana Problem:** Aracı bulan kişi/ziyaretçi, araç sahibine **anonim, hızlı, güvenli** şekilde ulaşabilsin.
- **Hedef Çıktı:**
  1) Ziyaretçi QR/NFC okutur → araç ekranı açılır
  2) “Hızlı mesaj” seçer veya mesaj yazar
  3) (Opsiyonel) konum kaydeder
  4) Araç sahibi mobil/panel üzerinden görür

---

## 1) Vizyon & Ürün Tanımı

### 1.1 Vizyon
Araç sahibine, aracın yanında kimseyle numara paylaşmadan iletişim kurulabilen; **tek dokunuşla** “mesaj bırakma / konum kaydetme / acil durum hızlı mesaj” sunan sistem.

### 1.2 Ürün Bileşenleri
- **Araç Kartı:** NFC tag + QR kod (vehicle_id ile)
- **Ziyaretçi Akışı (Guest):** QR/NFC → araç profili → hızlı mesaj / özel mesaj → gönder
- **Araç Sahibi Akışı (Owner):** login → araçlar → QR/NFC üret → gelen mesajlar → konum kayıtları

### 1.3 Kritik Tasarım İlkeleri
- **Anonimlik:** Ziyaretçi araç sahibinin telefonunu görmez.
- **Hız:** 2 tıkta mesaj.
- **Stabilite:** Endpoint isimleri asla rastgele değişmez.
- **Standard JSON:** Tüm response formatı aynı olacak.

---

## 2) Teknoloji Yığını

### 2.1 Backend
- **Laravel 10**
- **Auth:** Laravel Sanctum (token)
- **DB:** MySQL/MariaDB
- **UUID:** `vehicle_id` (string, unique)

### 2.2 Mobil
- **Flutter (stable)**
- **QR okuma:** kamera
- **NFC okuma:** NDEF URI/record

---

## 3) Sistem Mimarisi (Özet)

```
[QR/NFC Kart]
     |
     v
[Flutter App / (opsiyonel web landing)]
     |
     v
[Laravel API]
     |
     v
[MySQL]
```
- ### Kart (vehicle_id) Kimliği Hakkında

Bu sistemde `vehicle_id`, backend tarafından rastgele oluşturulan bir değer değildir.

- `vehicle_id`, **önceden üretilmiş ve fiziksel karta (QR/NFC) yazılmış benzersiz kart kimliğidir**.
- Kartlar bu `vehicle_id` ile basılır, stoklanır ve satılır.
- Kullanıcı, kartı satın aldıktan sonra uygulama üzerinden kartı okutarak (`vehicle_id` göndererek) kartı kendi hesabına **aktive eder**.
- Activate işlemi, kartın (`vehicle_id`) ilgili kullanıcıya (`user_id`) bağlanmasıdır.
- Araç bilgileri (plate, brand, model, color) kart aktivasyonundan sonra veya ayrı bir adımda girilebilir.

Not:
- Bir kullanıcı birden fazla karta sahip olabilir (araç, motor, ev vb.).
- Public endpoint’lerde kullanılan `vehicle_uuid` ifadesi, teknik olarak `vehicle_id` ile aynı değeri temsil eder.

### Kart Aktivasyonu ve Araç Ekleme

Kullanıcı, kartı aktif etmeden önce araç bilgilerini sisteme ekleyebilir. Ancak kartın **aktif edilmesi**, yani **vehicle_id'nin kullanıcıya bağlanması** gereklidir. Kullanıcı kartı okutup sisteme `vehicle_id` gönderdiğinde, sistem kartı aktif eder ve kullanıcıya **araç bilgisi ekleme** imkânı sunar.

### Public Endpoint ve Kart Kimliği

QR ve NFC içeriği, araç kimliğini (`vehicle_id`) taşır. Bu `vehicle_id`, backend tarafından **fiziksel kart üretildiğinde** belirlenmiş ve kartın üzerinde yer alır. Public endpoint’ler bu `vehicle_id` değerini kullanarak araç bilgilerini ve mesajları sağlar.

Public endpoint’lerde kullanılan `vehicle_uuid` ile `vehicle_id` teknik olarak **aynı değeri** temsil eder. Bu iki isim farklı olsa da, **hepsi aynı kimliği taşır**.


---

## 4) Veri Modeli & Veritabanı Şeması

### 4.1 users
- `id` (PK)
- `name`
- `email` (unique)
- `password`
- timestamps

### 4.2 vehicles
| alan | tip | not |
|---|---|---|
| id | bigint unsigned | PK, auto |
| user_id | bigint unsigned | FK -> users.id |
| vehicle_id | varchar(255) | **unique** (UUID) |
| plate | varchar(255) | nullable |
| brand | varchar(255) | nullable |
| model | varchar(255) | nullable |
| color | varchar(255) | nullable |
| created_at | timestamp | |
| updated_at | timestamp | |

İlişki: `users (1) -> (N) vehicles`

### 4.3 messages
Amaç: Ziyaretçiden araç sahibine mesaj kaydı.

| alan | tip | not |
|---|---|---|
| id | bigint unsigned | PK |
| vehicle_id | bigint unsigned | FK -> vehicles.id (**dikkat: numeric ID**) |
| message | text | required |
| phone | varchar(255) | nullable |
| sender_ip | varchar(255) | nullable |
| created_at | timestamp | |
| updated_at | timestamp | |

> **Çok kritik nokta:** `messages.vehicle_id` burada **vehicles tablosundaki numeric id**.
> Ziyaretçi request’te `vehicle_uuid` (vehicles.vehicle_id) gönderirse, backend önce `vehicles.id`’yi bulup messages’a onu yazmalı.

### 4.4 quick_messages (önerilen)
- `id` (PK)
- `text` (string/text)
- `is_active` (bool, default true)
- timestamps

### 4.5 locations (önerilen)
- `id` (PK)
- `vehicle_id` (FK -> vehicles.id)
- `lat` (decimal)
- `lng` (decimal)
- `accuracy` (decimal, nullable)
- `source` (string: "guest_qr" / "guest_nfc", nullable)
- timestamps

---

## 5) API Tasarımı (Arşiv Referansı)

### 5.1 Response Standardı
Tüm endpoint’ler aynı format döner:

```json
{
  "ok": true,
  "message": "Human readable info",
  "data": {}
}
```

Hata:

```json
{
  "ok": false,
  "message": "Error message",
  "errors": {
    "field": ["reason"]
  }
}
```

### 5.2 Base URL
- `https://<domain>/api` (prod)
- `http://localhost:<port>/api` (dev)

---

## 6) Endpoint Listesi (Arşivlenmiş Sözleşme)

> Güncel ve bağlayıcı endpoint sözleşmeleri için `docs/` klasörüne bakılmalıdır. Bu bölüm yalnızca tarihsel referans niteliğindedir.

## 7) Laravel Dosya Yapısı (Referans)

```
routes/
  api.php

app/Http/Controllers/
  AuthController.php
  VehicleController.php
  PublicVehicleController.php
  MessageController.php
  QuickMessageController.php
  LocationController.php

app/Models/
  User.php
  Vehicle.php
  Message.php
  QuickMessage.php
  Location.php

database/migrations/
  xxxx_create_users_table.php
  xxxx_create_vehicles_table.php
  xxxx_create_messages_table.php
  xxxx_create_quick_messages_table.php
  xxxx_create_locations_table.php

database/seeders/
  QuickMessageSeeder.php
```

---

## 8) Flutter Dosya Yapısı (Referans)

```
lib/
  main.dart
  config/
    api_config.dart
  models/
    vehicle.dart
    quick_message.dart
    message.dart
    location.dart
  services/
    api_client.dart
    auth_service.dart
    vehicle_service.dart
    public_service.dart
  pages/
    auth/
      login_page.dart
      register_page.dart
    owner/
      vehicles_page.dart
      messages_page.dart
      locations_page.dart
    guest/
      scan_page.dart
      vehicle_profile_page.dart
      send_message_page.dart
  widgets/
    primary_button.dart
```

---

## 9) QR & NFC İçerik Formatı

### 9.1 QR İçeriği
Önerilen QR payload:
- `arvoncode://v/<vehicle_uuid>` (deep link)
veya
- `https://<domain>/v/<vehicle_uuid>`

### 9.2 NFC İçeriği
NDEF URI record:
- `arvoncode://v/<vehicle_uuid>`

---
---


## 10) Checkpoint Sistemi (Zorunlu)

Şablon:
```
### CHECKPOINT #N — (Tarih)
- Tamamlanan: ...
- Etkilenen dosyalar: ...
- Eklenen endpoint: ...
- Test sonucu: ...
```
---
### CHECKPOINT #1 — 2025-12-12
- Tamamlanan:
  - quick_messages tablosu oluşturuldu
  - QuickMessageSeeder yazıldı ve çalıştırıldı
- Etkilenen dosyalar:
  - database/migrations/2025_12_12_135247_create_quick_messages_table.php
  - database/seeders/QuickMessageSeeder.php
- Eklenen DB yapıları:
  - quick_messages (id, text, is_active, timestamps)
- Test sonucu:
  - quick_messages tablosunda 5 adet aktif hızlı mesaj doğrulandı

### CHECKPOINT #2 — 2025-12-12
- Tamamlanan:
  - GET /api/public/quick-messages endpoint’i çalışır hale getirildi
  - POST /api/public/quick-message/send endpoint’i çalışır hale getirildi
  - Ziyaretçiden gelen quick message, messages tablosuna kaydedildi
- Etkilenen dosyalar:
  - routes/api.php
  - app/Http/Controllers/QuickMessageController.php
  - database/migrations/2025_12_12_135247_create_quick_messages_table.php
  - database/seeders/QuickMessageSeeder.php
- Teknik notlar:
  - Laravel built-in server (php artisan serve) üzerinden test edildi
  - API istekleri 127.0.0.1:8000 portu üzerinden çalıştırıldı
  - vehicle_uuid → vehicles.vehicle_id eşleşmesi yapıldı
  - messages.vehicle_id alanına numeric vehicles.id yazıldı
- Test sonucu:
  - GET /api/public/quick-messages → 200 OK, aktif quick messages listelendi
  - POST /api/public/quick-message/send → 200 OK, message başarıyla kaydedildi

### CHECKPOINT #3 — 2025-12-13
- Tamamlanan:
  - GET /api/public/vehicle/{vehicle_uuid} endpoint’i eklendi
  - Araç profili + aktif quick_messages public olarak sunuldu
- Etkilenen dosyalar:
  - routes/api.php
  - app/Http/Controllers/Api/PublicController.php
  - app/Models/QuickMessage.php
- Teknik notlar:
  - Public endpoint’te user/owner bilgisi gizlendi
  - Response standardı `{ ok, message, data }` formatına alındı
- Test sonucu:
  - Geçerli vehicle_uuid → 200 OK
  - Geçersiz vehicle_uuid → 404 Vehicle not foun

### CHECKPOINT #4 — 2025-12-15
- Tamamlanan:
  - Vehicle activate (kart aktivasyonu) endpoint’i çalışır hale getirildi
  - Kart-önce (vehicle_id karttan gelir) mimarisi netleştirildi
  - ArvonCode.md mimari açıklamaları güncellendi
- Etkilenen dosyalar:
  - app/Http/Controllers/Api/VehicleController.php
  - routes/api.php
  - ArvonCode.md
- Test sonucu:
  - POST /api/vehicle/activate → 200 OK
  - Kart (vehicle_id) kullanıcıya başarıyla bağlandı
  - MySQL vehicles tablosuna kayıt doğrulandı

### CHECKPOINT #5 — 2025-12-16
- Tamamlanan:
  - Guest tarafından konum kaydetme (Location Save) akışı tamamlandı
  - POST /api/public/location/save endpoint’i aktif edildi
  - vehicle_uuid → vehicles.id (numeric) mapping doğrulandı
  - Konum kayıtları locations tablosuna başarıyla yazılıyor
  - Owner için konum listeleme endpoint’i eklendi

- Etkilenen dosyalar:
  - database/migrations/2025_12_16_xxxxxx_create_locations_table.php
  - app/Models/Location.php
  - app/Http/Controllers/LocationController.php
  - routes/api.php

- Eklenen endpoint’ler:
  - POST /api/public/location/save
  - GET /api/locations

- Teknik notlar:
  - Public endpoint auth gerektirmiyor
  - vehicle_uuid public katmanda kullanıldı
  - Internal kayıt numeric vehicles.id üzerinden yapıldı
  - Response standardı (ok / message / data) korundu

- Test sonucu:
  - POST /api/public/location/save → 200 OK
  - Konum DB’ye yazıldı
  - GET /api/locations → sadece owner’a ait araçların konumları listelendi


### CHECKPOINT #6 — 2025-12-16

- Tamamlanan:
  - 6.1 Flutter API Config kuruldu
  - ApiConfig ile dev/prod ayrımı yapıldı
  - baseUrl içinde /api sabitlendi
  - Gerçek cihaz testi için LAN IP kullanıldı (php artisan serve --host=0.0.0.0 --port=8000)
  - 6.2 Flutter Quick Message Send çalışır hale getirildi
  - Flutter’daki hardcode endpoint temizlendi (yanlış /v/{uuid}/message kaldırıldı)
  - Doğru endpoint’e geçildi: POST /api/public/quick-message/send
  - Doğru payload’a geçildi: vehicle_uuid + quick_message_id
  - JSON response için Accept: application/json eklendi
  - DB’de quick_messages boşluğu tespit edildi ve seeder ile veri doğrulandı/aktif edildi
  - Flutter’dan test: { ok:true, message:"Message sent", data:{ vehicle_uuid:"TEST123456", quick_message_id:1 } }
  - Etkilenen dosyalar (Flutter):

  - lib/config/api_config.dart (yeni)
  - lib/services/quick_message_service.dart (yeni)
  - lib/services/message_service.dart (refactor / eski hardcode kaldırıldı veya quick-flow’dan ayrıldı)

  - lib/screens/nfc_menu.dart (buton action güncellendi, req/custom flow temizlendi)
  - Etkilenen dosyalar (Backend):
  - database/seeders/QuickMessageSeeder.php (kullanıldığı doğrulandı / çalıştırıldı)
  - app/Models/QuickMessage.php (fillable doğrulandı)

- Test sonucu:
  - Telefon (aynı Wi-Fi) üzerinden Laravel’e erişim doğrulandı
  - Flutter’dan quick message gönderimi başarılı (200 + ok:true)
  - 404/422 hataları (endpoint/payload/id eksikliği) giderildi
Not: Bu checkpoint’te “custom message” endpoint’i (POST /api/public/message) henüz Flutter’da finalize edilmedi; quick message akışı netleştirildi.

### CHECKPOINT #7 — 2025-12-17

- Tamamlanan:
  - Flutter tarafında Guest konum kaydetme (Location Save) akışı tamamlandı
  - Android gerçek cihazdan GPS konumu alındı
  - Flutter → Laravel API entegrasyonu birebir doğrulandı
  - POST /api/public/location/save endpoint’i Flutter’dan başarıyla çağrıldı
  - Konum kayıtları MySQL `locations` tablosuna yazıldı
  - source alanı guest_qr olarak kaydedildi
  - vehicle_uuid → vehicles.id (numeric) mapping backend tarafında sorunsuz çalıştı

- Etkilenen dosyalar (Flutter):
  - lib/config/api_config.dart
  - lib/services/location_service.dart
  - lib/services/device_location_service.dart
  - lib/screens/location_test_screen.dart (geçici test ekranı)

- Etkilenen dosyalar (Backend):
  - app/Http/Controllers/LocationController.php
  - app/Models/Location.php
  - routes/api.php
  - database/migrations/*_create_locations_table.php

- Eklenen / kullanılan endpoint’ler:
  - POST /api/public/location/save
  - GET /api/locations (owner)

- Teknik notlar:
  - Flutter gerçek cihazda (LAN IP) test edildi
  - Android konum izinleri (FINE / COARSE) runtime’da alındı
  - geolocator paketi kullanıldı
  - Android Gradle + Flutter uyumsuzluğu için `android/build.gradle` içinde
    `ext.flutter.compileSdkVersion` workaround uygulandı
  - Terminal log’larındaki warning/debug mesajlarının runtime hata olmadığı doğrulandı

- Test sonucu:
  - Flutter ekranında `{ ok:true, message:"Location saved" }` alındı
  - MySQL doğrulaması yapıldı:
    `SELECT * FROM locations ORDER BY id DESC LIMIT 1;`
  - Gerçek koordinatlar (lat/lng) DB’de doğrulandı

### CHECKPOINT #8 — 2025-12-17

- Tamamlanan:
  - Flutter’da Public Vehicle Profile ekranı (Guest) tamamlandı
  - GET /api/public/vehicle/{vehicle_uuid} endpoint’i Flutter’dan gerçek cihazda çağrıldı ve doğrulandı
  - Araç bilgileri (plate, brand, model, color) UI’da gösterildi
  - Quick messages UI’da buton olarak listelendi
  - Butonlara basınca doğru quick_message_id loglandı (debug doğrulama)

- Etkilenen dosyalar (Flutter):
  - lib/services/public_service.dart (yeni)
  - lib/screens/vehicle_profile_screen.dart (yeni)
  - lib/main.dart (geçici test routing: VehicleProfileScreen(vehicleUuid: 'TEST123456'))

- Kullanılan endpoint:
  - GET /api/public/vehicle/{vehicle_uuid}

- Teknik notlar:
  - Accept: application/json header zorunluluğu uygulandı
  - jsonDecode sonrası Map cast düzgünleştirildi (tip güvenliği)
  - Bu checkpoint sadece “profile + quick messages list” doğrulamasıdır

- Test sonucu:
  - Gerçek cihazda Vehicle Profile ekranı açıldı
  - Plaka ve araç bilgileri doğru göründü
  - 5 adet hızlı mesaj butonu doğru render edildi
  - Tıklama ile “Quick message id: 1..5” logları alındı

  ### CHECKPOINT #9 — 2025-12-17

- Tamamlanan:
  - Flutter’da Public Vehicle Profile ekranındaki quick message butonları gerçek gönderim aksiyonuna bağlandı
  - POST /api/public/quick-message/send endpoint’i Flutter’dan gerçek cihazda kullanıldı
  - vehicle_uuid + quick_message_id payload standardı birebir uygulandı
  - Aynı hızlı mesaj için spam / tekrar gönderim problemi tespit edildi ve çözüldü
  - Flutter tarafında **ID bazlı cooldown (throttle)** mekanizması eklendi
  - Concurrent request + hızlı tekrar tıklama senaryoları kontrol altına alındı

- Etkilenen dosyalar (Flutter):
  - lib/services/quick_message_service.dart
  - lib/screens/vehicle_profile_screen.dart

- Teknik notlar:
  - Tek bir global `_sending` flag’inin FutureBuilder + rebuild sebebiyle yetersiz olduğu görüldü
  - Çözüm olarak:
    - `_sendingMessageIds: Set<int>` (concurrent lock)
    - `_lastSentAt: Map<int, DateTime>` + cooldown (2 saniye)
    - Minimum spinner süresi (400ms) eklendi
  - Böylece:
    - Aynı quick_message_id aynı anda 2 kere gönderilemiyor
    - Kısa sürede spam tıklama engelleniyor
    - UX stabil hale getirildi

- Kullanılan endpoint:
  - POST /api/public/quick-message/send

- Test sonucu:
  - Gerçek Android cihazda test edildi
  - Terminal log’larında beklenen davranış doğrulandı:
    - Aynı mesaja seri tıklamada **2 saniyede 1** istek
  - Backend response:
    `{ ok:true, message:"Message sent", data:{ vehicle_uuid, quick_message_id } }`
  - DB tarafında mesaj kayıtları beklendiği gibi oluştu

### CHECKPOINT #10 — 2025-12-20
- Tamamlanan:
  - Location Save (Konum Bildir) özelliği ana `VehicleProfileScreen` ekranına entegre edildi.
  - Bağımsız test ekranı (`location_test_screen.dart`) devre dışı bırakıldı/temizlendi.
  - UI tasarımı olarak "Aracın Yanında mısınız?" kart yapısı (3. seçenek) uygulandı.
  - Konum alma ve API'ye gönderme süreçleri tek buton altına toplandı.
- Etkilenen dosyalar (Flutter):
  - lib/screens/vehicle_profile_screen.dart
- Test sonucu:
  - Gerçek cihazda "Konumumu Bildir" butonuna basıldığında GPS verisi alınıyor ve `POST /api/public/location/save` başarılı şekilde tetikleniyor.
  - SnackBar ile kullanıcıya geri bildirim veriliyor.

  ### CHECKPOINT #11 — 2025-12-21

- Tamamlanan:
  - Flutter Guest Flow stabilizasyonu tamamlandı
  - Location Save akışı async-safe hale getirildi
  - `mounted` kontrolleri ile BuildContext async uyarıları giderildi
  - Location gönderimi için cooldown (10 sn) mekanizması eklendi
  - Location UI ve iş mantığı ayrıştırıldı:
    - `_onSendLocationPressed` → kontrol & throttle
    - `_sendCurrentLocation` → GPS + API işlemi
  - Guest Location Save akışı spam ve double-tap senaryolarına karşı korumalı hale getirildi
  - Location hata senaryoları (izin yok / konum kapalı / genel hata) kullanıcıya ayrıştırılarak bildirildi

- Etkilenen dosyalar (Flutter):
  - lib/screens/vehicle_profile_screen.dart

- Teknik notlar:
  - `use_build_context_synchronously` uyarıları tamamen giderildi
  - Location state yönetimi tek değişken (`_isLocationSending`) üzerinden sadeleştirildi
  - Cooldown logic UI’dan izole edildi
  - Test ekranı (`location_test_screen.dart`) tamamen kaldırıldı
  - Guest Flow artık tek ekranda:
    - Araç bilgileri
    - Quick Messages
    - Location Save
    şeklinde çalışıyor

- Test sonucu:
  - Gerçek Android cihazda test edildi
  - Konum gönderimi başarıyla backend’e iletildi
  - Cooldown süresi içinde tekrar gönderim engellendi
  - Async dispose senaryolarında crash gözlemlenmedi
  - Guest Flow stabil kabul edildi

### CHECKPOINT #12 — 2025-12-21

- Tamamlanan:
  - Flutter’da Scan / QR akışı (Guest) MVP seviyesinde tamamlandı:
    - Kamera açılıyor
    - QR okutuluyor
    - QR içeriğinden vehicle_uuid parse ediliyor
    - Vehicle Profile ekranına otomatik yönlendirme yapılıyor
  - QR okuma altyapısı için `mobile_scanner` eklendi ve proje SDK uyumsuzluğu çözülerek stabil sürüme indirildi
  - QR okuma “multi-trigger” (aynı QR’yi saniyede çok kez okuma → 3-4 sayfa açma) problemi çözüldü (tek seferlik handle/lock)
  - Scan ekranından Vehicle Profile’a geçişte kamera arkada açık kalma problemi çözüldü:
    - `Navigator.pushReplacement` ile ScanScreen stack’ten çıkarıldı → kamera kapanıyor
  - Geçersiz / kayıtlı olmayan QR okutulunca kullanıcıya ham JSON/Exception gösterme problemi çözüldü:
    - VehicleProfileScreen hata UI’ı kullanıcı-dostu mesaja çevrildi
  - QR okutma testleri:
    - Kayıtlı vehicle_uuid → Vehicle Profile doğru açılıyor ve veriler geliyor
    - Kayıtsız vehicle_uuid → kullanıcı-dostu “kayıtlı değil” ekranı gösteriliyor (JSON yok)

- Etkilenen dosyalar (Flutter):
  - lib/main.dart (test kilidi kaldırıldı, HomeScreen’e yönlendirme)
  - lib/screens/home_screen.dart (ana ekran + “QR / NFC Tara” butonu)
  - lib/screens/scan_screen.dart (QR tarama ekranı + single-scan lock + pushReplacement navigation)
  - lib/utils/vehicle_uuid_parser.dart (QR/NFC raw string → vehicle_uuid extraction)
  - lib/screens/vehicle_profile_screen.dart (hata ekranı UX düzeltmesi; ham exception/JSON kaldırıldı)
  - pubspec.yaml (mobile_scanner sürümü stabil uyumlu sürüme sabitlendi)

- Eklenen paket / teknik notlar:
  - `mobile_scanner` paketinde Android SDK / AGP uyumsuzluğu yaşandı
  - Çözüm: paketin stabil uyumlu sürümü kullanıldı (compileSdk/AGP yükseltmeye zorlanmadı)
  - QR okuma debounce/lock:
    - aynı QR kadrajda kalınca çoklu detect oluyordu → tek seferlik handle + replacement navigation ile çözüldü

- Silinen / devre dışı bırakılanlar:
  - main.dart içindeki hardcoded test routing kaldırıldı:
    - `home: VehicleProfileScreen(vehicleUuid: 'TEST...')` kaldırıldı
  - Scan ekranında “SnackBar ile sadece QR Okundu göster” test yaklaşımı production akışa çevrildi (artık parse + redirect var)

- Test sonucu:
  - Gerçek Android cihazda test edildi
  - Kamera açılıyor, QR okunuyor, tek sefer yönlendirme oluyor
  - Kayıtlı QR → Vehicle Profile ekranı doğru geliyor
  - Kayıtsız QR → kullanıcı-dostu hata ekranı geliyor (ham JSON/Exception yok)
  - Scan → Vehicle Profile geçişinde kamera arkada açık kalmıyor (ikon/pushReplacement etkisi doğrulandı)

### CHECKPOINT #13 — 2025-12-22

- Tamamlanan:
  - Public (Guest) endpoint’ler için server-side rate limit mekanizması eklendi (`throttle:public`)
  - IP bazlı request sınırlaması tanımlandı (RateLimiter: public)
  - Public endpoint’ler için request logging altyapısı kuruldu
  - Public istekler DB seviyesinde loglanmaya başlandı
  - Validation hataları için Laravel default response’ları devre dışı bırakıldı
  - Public endpoint’lerde FormRequest tabanlı validation yapısına geçildi
  - Validation hataları `{ ok, message, error_code, errors }` standart formatına alındı
  - Rate limit (429) hataları global olarak yakalanıp standart JSON response’a çevrildi
  - Public Quick Message Send akışı FormRequest + `$validated` kullanacak şekilde refactor edildi
  - Public Location Save akışı FormRequest + `$validated` kullanacak şekilde refactor edildi
  - `vehicle_uuid` (public) → `vehicles.id` (numeric) mapping güvenli hale getirildi
  - Controller seviyesinde doğrudan `$request->field` kullanımı kaldırıldı (public endpoint’ler)

- Etkilenen dosyalar:
  - routes/api.php
  - app/Providers/RouteServiceProvider.php
  - app/Http/Kernel.php
  - app/Http/Middleware/PublicRequestLogger.php
  - app/Models/PublicRequestLog.php
  - database/migrations/2025_12_22_xxxxxx_create_public_request_logs_table.php
  - app/Http/Requests/PublicQuickMessageSendRequest.php
  - app/Http/Requests/PublicLocationSaveRequest.php
  - app/Exceptions/Handler.php
  - app/Http/Controllers/QuickMessageController.php
  - app/Http/Controllers/LocationController.php

- Eklenen DB yapıları:
  - public_request_logs
    - endpoint
    - method
    - ip
    - user_agent
    - vehicle_uuid
    - vehicle_id
    - ok
    - status_code
    - error_code
    - error_message
    - created_at
    - updated_at

- Teknik notlar:
  - Public endpoint’ler artık abuse / spam senaryolarına karşı korumalıdır
  - Validation hataları Flutter tarafında ham Laravel JSON olarak görünmez
  - 404 / 422 / 429 hata senaryoları standart response formatında dönmektedir
  - Public request’ler geriye dönük analiz edilebilir hale getirilmiştir
  - Guest Flow backend tarafı prod seviyesine yaklaştırılmıştır

- Test sonucu:
  - GET /api/public/quick-messages → 200 OK
  - POST /api/public/quick-message/send
    - eksik payload → 422 VALIDATION_ERROR
    - geçerli payload → 200 OK
  - POST /api/public/location/save
    - eksik lat/lng → 422 VALIDATION_ERROR
    - geçerli payload → 200 OK
  - Rate limit aşıldığında → 429 RATE_LIMIT
  - Public isteklerin tamamı public_request_logs tablosuna yazıldı

### CHECKPOINT #14 — 2025-12-23

- Tamamlanan:
  - Flutter Guest Custom Message akışı tamamlandı
  - Vehicle Profile ekranına “Mesaj Yaz” butonu eklendi
  - Ziyaretçi kendi mesajını ve telefon bilgisini girip gönderebiliyor
  - POST /api/public/message endpoint’i Flutter’dan başarıyla kullanıldı
  - Boş mesaj gönderimi UI seviyesinde engellendi
  - Başarılı gönderimde kullanıcıya geri bildirim verildi

- Etkilenen dosyalar (Flutter):
  - lib/screens/send_custom_message_screen.dart (yeni)
  - lib/screens/vehicle_profile_screen.dart
  - lib/services/message_service.dart

- Etkilenen dosyalar (Backend):
  - app/Http/Controllers/Api/PublicController.php
  - routes/api.php

- Kullanılan endpoint:
  - POST /api/public/message

- Test sonucu:
  - Gerçek Android cihazda test edildi
  - Mesaj ve telefon bilgisi messages tablosuna doğru şekilde yazıldı
  - sender_ip, vehicle_id ve message alanları doğrulandı

  #### CHECKPOINT #15 — 2025-12-26 (NFC Platform Setup)

- Tamamlanan: nfc_manager eklendi;
  - Android NFC izinleri/intent-filter;
  - NDEF tech listesi;
  - iOS NFC kullanım mesajı
  - Entitlements (NDEF okuma) bağlandı.

- Etkilenen dosyalar:
  - pubspec.yaml,
  - AndroidManifest.xml,
  - nfc_tech_list.xml,
  - Info.plist,
  - Runner.entitlements,
  - project.pbxproj.

- Test: Çalıştırılmadı;
  - sadece config eklendi.

  ### CHECKPOINT #16 — 2025-12-26 (Flutter NFC Okuma & UI Ayrımı)

- Tamamlanan:
  - Flutter’da NFC okuma akışı `nfc_manager` ile aktif hale getirildi.
  - NFC NDEF URI → `vehicle_uuid` parse → `VehicleProfileScreen` yönlendirme zinciri tamamlandı.
  - QR ve NFC tarama akışları **UI ve logic olarak ayrıldı**:
    - QR modunda kamera aktif.
    - NFC modunda kamera kapalı, sadece NFC oturumu açık.
  - `VehicleUuidParser` genişletildi:
    - `arvoncode://v/<uuid>`
    - plain `<uuid>`
    - IP tabanlı public endpoint URI’ları
      (`http://192.168.1.115:8000/api/public/vehicle/<uuid>`)
  - Android build hatası (`NdefTypeNameFormat`) giderildi.

- Etkilenen dosyalar (Flutter):
  - `lib/screens/scan_screen.dart`
  - `lib/screens/home_screen.dart`
  - `lib/utils/vehicle_uuid_parser.dart`

- Teknik notlar:
  - NFC oturumu yalnızca NFC modu aktifken başlatılıyor.
  - QR tarama akışı NFC lifecycle’ından tamamen izole edildi.
  - Lokal LAN IP ile yazılmış NDEF URI’lar test amaçlı desteklenmektedir.
  - Parser, URI formatına bağımlı olmadan **sadece vehicle_uuid** çıkarmaya odaklanır.

- Test sonucu:
  - Gerçek Android cihazda `flutter run` ile test edildi.
  - NDEF URI içeren NFC tag’lar okutuldu:
    - `arvoncode://v/TEST123456`
    - `http://192.168.1.115:8000/api/public/vehicle/TEST123456`
  - Her iki senaryoda da:
    - `vehicle_uuid` doğru parse edildi
    - `VehicleProfileScreen` otomatik açıldı
  - QR tarama akışı ayrı buton üzerinden sorunsuz çalışıyor.



  #### CHECKPOINT #17 — 2025-12-25
- Frontend:
  - `lib/models/message.dart` oluşturuldu.
  - `Message` ve `MessageVehicle` sınıfları tanımlandı.
  - Backend'den gelen JSON yapısı (nested objects, datetime parsing) ile Dart nesneleri eşleştirildi.

### CHECKPOINT #18 — 2025-12-27

- Tamamlanan:
  - Flutter Owner Message Inbox için servis katmanı eklendi
  - GET /api/messages endpoint’i Flutter’dan çağrılabilir hale getirildi
  - Backend response → List<Message> mapping doğrulandı

- Etkilenen dosyalar (Flutter):
  - lib/services/message_service.dart

- Kullanılan endpoint:
  - GET /api/messages (auth required)

- Test sonucu:
  - Token ile istek atıldı
  - Owner’a ait mesajlar başarıyla alındı
  - JSON → Dart model dönüşümü hatasız

### CHECKPOINT #18 — 2025-12-27

- Tamamlanan:
  - Flutter Owner Messages Inbox UI (MVP) tamamlandı
  - GET /api/messages endpoint’i UI üzerinden listelenebilir hale getirildi
  - Loading / Error / Empty / List state’leri ayrıştırıldı

- Etkilenen dosyalar (Flutter):
  - lib/screens/owner/messages_page.dart

- Teknik notlar:
  - Token constructor üzerinden alınıyor (hardcode yok)
  - Message modeli backend JSON’una uyumlu şekilde parse ediliyor
  - initState + mounted kontrolü ile async lifecycle güvenli

- Test sonucu:
  - Gerçek cihazda mesajlar başarıyla listelendi
  - Boş liste ve hata senaryoları UI’da doğru gösterildi

- Owner Messages özelliği yalnızca servis ve model seviyesinde değil, UI ve navigation dahil olacak şekilde tamamlandı.
  - OwnerDashboard üzerinden MessagesPage’e güvenli token aktarımı sağlandı.

### CHECKPOINT #19 — 2025-12-27

- Tamamlanan:
  - Owner Messages UI (Inbox) uygulama içine tam entegre edildi.
  - OwnerDashboard üzerinden “Mesajlarım” butonu ile MessagesPage’e geçiş sağlandı.
  - Navigation sırasında owner JWT token güvenli şekilde parametre olarak aktarılıyor.
  - Token eksik veya boş ise kullanıcı SnackBar ile uyarılıyor.

- Etkilenen dosyalar (Flutter):
  - lib/screens/owner/messages_page.dart
  - lib/screens/owner/owner_dashboard.dart

- Teknik notlar:
  - OwnerDashboard artık opsiyonel `ownerToken` parametresi alıyor.
  - MessagesPage token’a bağımlı çalışıyor, hardcode token yok.
  - Navigation akışı: Login → OwnerDashboard → MessagesPage.

- Teknik borçlar / bilinçli eksikler:
  - OwnerDashboard üzerindeki “Son Mesaj” paneli statik (hardcode) verilerle gösteriliyor.
    - İleride GET /api/messages üzerinden gerçek son mesaj verisi bağlanacak.
  - Token yönetimi UI katmanında yapılıyor.
    - İleride merkezi auth state (provider/bloc vb.) ile yönetilmeli.

- Test sonucu:
  - Gerçek cihazda dashboard üzerinden MessagesPage’e geçiş başarılı.
  - Token mevcutken mesaj listesi doğru şekilde yükleniyor.
  - Token yokken kullanıcı uyarılıyor, uygulama crash olmuyor.

### CHECKPOINT #20 — 2025-12-27

- Tamamlanan:
  - Flutter Owner Locations UI tamamlandı.
  - GET /api/locations endpoint’i Flutter UI’ya bağlandı.
  - Backend response sözleşmesi Flutter ile uyumlu hale getirildi (`data` doğrudan liste).
  - Loading / Empty / Error / List state’leri ayrıştırıldı.
  - OwnerDashboard üzerinden “Konumlarım” ekranına güvenli navigation eklendi.
  - Gerçek cihazda owner’a ait konum kayıtları başarıyla listelendi.

- Etkilenen dosyalar (Flutter):
  - lib/screens/owner/locations_page.dart
  - lib/services/location_service.dart
  - lib/screens/owner/owner_dashboard.dart
  - lib/main.dart (geçici test routing)

- Etkilenen dosyalar (Backend):
  - app/Http/Controllers/LocationController.php

- Kullanılan endpoint:
  - GET /api/locations (auth required)

- Test sonucu:
  - Gerçek Android cihazda test edildi.
  - Owner’a ait konum kayıtları tarih sırasıyla listelendi.
  - Boş veri, hata ve loading senaryoları UI’da doğru şekilde gösterildi.
  - Backend–Flutter veri sözleşmesi doğrulandı.

- Git durumu:
  - `git status` → temiz
  - `git add -A` → çalıştırıldı
  - `git commit -m "feat(owner): locations UI and backend response alignment"` → tamamlandı
  - `git push` → tamamlandı

### CHECKPOINT #21 — 2025-12-28

- Tamamlanan:
  - Owner Dashboard “Son Konum” paneli canlı backend verisi ile çalışır hale getirildi
  - GET /api/locations endpoint’i Owner Dashboard özet ekranında kullanıldı
  - En güncel konum kaydı (son location) dashboard üzerinde gösterildi
  - Loading / Empty / Data state’leri ayrıştırıldı
  - Hardcode (statik) konum verileri tamamen kaldırıldı

- Etkilenen dosyalar (Flutter):
  - lib/screens/owner/owner_dashboard.dart

- Kullanılan endpoint:
  - GET /api/locations (auth required)

- Test sonucu:
  - Gerçek Android cihazda test edildi
  - Owner Dashboard açılışında:
    - Konum mevcutsa → son konum bilgisi gösteriliyor
    - Konum yoksa → “Henüz konum kaydı yok” mesajı gösteriliyor
    - Yükleme sırasında UI stabil, crash yok

- Notlar:
  - Konum verileri backend’den canlı olarak alınmaktadır
  - Timestamp (created_at) şu an ham backend formatında gösterilmektedir

### CHECKPOINT #22 — 2025-12-28

- Tamamlanan:
  - Owner Dashboard “Son Mesaj” paneli canlı backend verisi ile çalışır hale getirildi
  - GET /api/messages endpoint’i Owner Dashboard özet ekranında kullanıldı
  - En güncel mesaj (son message) dashboard üzerinde gösterildi
  - Loading / Empty / Data state’leri ayrıştırıldı
  - Hardcode (statik) mesaj verileri tamamen kaldırıldı

- Etkilenen dosyalar (Flutter):
  - lib/screens/owner/owner_dashboard.dart

- Kullanılan endpoint:
  - GET /api/messages (auth required)

- Test sonucu:
  - Gerçek Android cihazda test edildi
  - Mesaj mevcutsa → son mesaj doğru şekilde gösteriliyor
  - Mesaj yoksa → “Henüz mesaj yok” state’i gösteriliyor
  - Dashboard açılışında crash veya UI kilitlenmesi gözlemlenmedi

- Notlar:
  - created_at alanı şu an ham backend formatında gösterilmektedir
  - UI etiketleri backend field isimlerine birebir bağlıdır (ileride iyileştirilecek)

### (M3) Owner Son Mesaj (Dashboard)
- **GET** `/api/messages/latest` (auth required)

Açıklama:
Owner Dashboard özet paneli için kullanılır.
Owner’a ait araçlara gelen **en güncel tek mesajı** döner.

Davranış:
- Mesajlar `created_at DESC, id DESC` sıralamasıyla değerlendirilir.
- Kayıt varsa:
  - `data` alanında **tek Message objesi** döner.
- Kayıt yoksa:
  - `data: null` döner.
- Endpoint yalnızca **özet kullanım** içindir, inbox yerine geçmez.

Teknik Not:
- `/api/messages` endpoint’i yalnızca **Owner Messages Inbox (liste)** için kullanılmalıdır.
- Dashboard bu endpoint’i kullanmaz.


### CHECKPOINT #23 — 2025-12-28 (Owner Dashboard Latest Message Endpoint + Bütünleşik Test)

- Tamamlanan:
  - Backend’de Owner Dashboard için özet endpoint eklendi:
    - GET /api/messages/latest (auth required)
  - `/api/messages/latest` endpoint’i:
    - Owner’a ait araç mesajları içinde en güncel **tek** mesajı döner
    - Sıralama garantisi: `created_at DESC, id DESC`
    - Mesaj yoksa `data: null` döner
  - Flutter OwnerDashboard “Son Mesaj” paneli `/api/messages/latest` endpoint’ine geçirildi
  - Inbox (liste) endpoint’i `/api/messages` korunarak ayrıştırıldı
  - Flutter’da MessageService içine `fetchLatestMessage()` eklendi (liste endpoint’i etkilenmedi)

- Etkilenen dosyalar (Backend):
  - routes/api.php
  - app/Http/Controllers/MessageController.php

- Etkilenen dosyalar (Flutter):
  - lib/screens/owner_dashboard.dart
  - lib/services/message_service.dart

- Eklenen / kullanılan endpoint’ler:
  - GET /api/messages/latest (auth required)

- Test sonucu (Bütünleşik Smoke + Backend):
  - Flutter Owner Dashboard:
    - “Son Mesaj” paneli doğru şekilde veri gösteriyor
    - “Son Konum” paneli doğru şekilde veri gösteriyor
  - Flutter Owner Inbox:
    - “Mesajlarım” listesi geliyor
    - Sıralama en yeni → en eski (desc) doğrulandı
  - Postman:
    - GET /api/messages/latest → 200 OK
    - ok:true, message:"Latest message retrieved", data: Message objesi doğrulandı


### CHECKPOINT  #24 — Flutter Tarih Formatı Standardizasyonu
  - Kod seviyesi tamamlandı
  - Mimari borç temizlendi
  - Git kapanışı bekleniyor (commit & push doğrulaması olmadan checkpoint kapatılama


### CHECKPOINT #24 — Flutter Tarih Formatı Standardizasyonu
- Durum: TAMAMLANDI
- Açıklama:
  - Flutter UI genelinde tarih/saat gösterimi merkezi DateFormatter üzerinden yönetilecek şekilde standardize edildi.
  - Model ve UI katmanlarında DateTime parse işlemleri kaldırıldı.
  - Backend tarih sözleşmesine (ISO string) dokunulmadı.
- Git:
  - Commit ve push tamamlandı.

### CHECKPOINT #25 — Push Notification Altyapısı (Owner: Token Kaydı)
- Amaç:
  - Owner kullanıcılar için push token’larının backend’e kaydedilmesi
- Kapsam:
  - user_push_tokens tablosu
  - User ↔ PushToken ilişkisi
  - POST /api/user/push-id endpoint’i
- Not:
  - Bu checkpoint yalnızca token kayıt altyapısını kapsar. Controller/Request/Migration düzeyinde ek refactor bu checkpoint’e DAHİL DEĞİLDİR.
  - Push gönderimi bu checkpoint’te YOK

### CHECKPOINT #25 — Push Notification Altyapısı (Owner: Token Kaydı)
- Durum: TAMAMLANDI
- Tamamlananlar:
  - user_push_tokens tablosu oluşturuldu
  - User ↔ PushToken ilişkisi eklendi
  - POST /api/user/push-id endpoint’i eklendi
  - FormRequest tabanlı validation uygulandı
  - Namespace ve route disiplini sağlandı
- Not:
  - Bu checkpoint yalnızca token kayıt altyapısını kapsar. Controller/Request/Migration düzeyinde ek refactor bu checkpoint’e DAHİL DEĞİLDİR.
  - Push gönderimi bu aşamada YOK

### CHECKPOINT #26 — Legacy Endpoint Temizliği (/api/v/* kaldırıldı)
- Durum: TAMAMLANDI
- Tamamlanan:
  - routes içinde /api/v/* legacy endpoint’leri kaldırıldı
  - Legacy endpoint’lere bağlı controller/method referansları temizlendi
  - Repo genelinde /api/v ve /v referans taraması yapıldı, kalanlar silindi
- Test sonucu:
  - php artisan route:list üzerinde /api/v/* bulunamadı
  - (Varsa) php artisan test başarıyla çalıştı

### CHECKPOINT #27 — ArvonCode Tutarlılık ve Gerçeklik Temizliği
- Durum: TAMAMLANDI
- Amaç:
  - Proje kontrol dosyasının (ArvonCode.md) tek kaynak gerçeği olmasını sağlamak
- Yapılanlar:
  - Aktif checkpoint tanımı düzeltildi
  - Çift yazılmış checkpoint (#24) tekilleştirildi
  - Checkpoint #25 kapsamı netleştirildi (sessiz genişleme engellendi)
  - Arşiv bölümündeki güncel olmayan endpoint tanımları yanlış yönlendirmeye karşı işaretlendi
- Etki:
  - Proje yönetimi ile teknik gerçekler arasındaki kopukluk giderildi
  - Bir sonraki checkpoint için net ve güvenilir zemin oluşturuldu

### CHECKPOINT #28 — Staging Ortam Kurulumu
- Durum: TAMAMLANDI
- Amaç:
  - Production’dan izole bir staging ortamı oluşturmak
  - API ve Flutter için ayrı base URL tanımlamak
- Kapsam:
  - Backend (.env) staging ayrımı
  - Flutter tarafında staging baseUrl hazırlığı
- Not:
  - Bu checkpoint yalnızca ortam hazırlığını kapsar
  - Firebase / Push gönderimi bu checkpoint’te YOK
- Yapılanlar:
  - Backend için `.env.staging` dosyası oluşturuldu
  - Staging ve prod environment ayrımı netleştirildi
  - Flutter ApiConfig yapısına staging environment eklendi
  - dev / staging / prod ayrımı enum tabanlı hale getirildi
  - Staging environment güvenlik temizliği yapıldı
  - Hardcode test token’ları projeden kaldırıldı
- Test:
  - APP_ENV=staging ile Laravel config cache başarıyla oluşturuldu
  - Flutter uygulaması staging baseUrl ile API çağrısı yapabiliyor (local run denemesi erişim izni hatası nedeniyle teyit edilemedi)

### CHECKPOINT #29 — Flutter Auth Token Yönetimi Altyapısı
- Durum: TAMAMLANDI
- Yapılanlar:
  - Flutter tarafında secure token storage altyapısı kuruldu
  - App başlangıcında token var/yok kontrolü eklendi
  - Minimal login ekranı eklendi
  - Login sonrası token secure storage’a kaydediliyor
  - App başlangıcında Login / Home ayrımı aktif hale geldi
  - Login response parse işlemi API standart formatına uygun hale getirildi
  - Login ekranındaki debug token temizleme davranışı kaldırıldı
- Not:
  - Bu adımda refresh token ve logout henüz yok

### CHECKPOINT #30 — Logout & Token Invalidasyonu
- Durum: TAMAMLANDI
- Amaç:
  - Güvenli logout akışı ile token’ı backend ve frontend tarafında temizlemek
- Kapsam:
  - Auth logout endpoint’ini kullanarak token’ın geçersiz kılınması
  - Uygulama içinde logout akışı (Login’e yönlendirme)
- Not:
  - refresh token bu checkpoint’te yok
- Yapılanlar:
  - Backend logout endpoint’i eklendi (POST /api/logout)
  - Sanctum currentAccessToken revoke ediliyor
  - Backend logout smoke test başarılı
  - Login ve register auth response’ları standart {ok,message,data} formatına alındı
  - Auth endpoint’leri arasında response tutarsızlığı giderildi

### CHECKPOINT #31 — Auth Dayanıklılık & Test Hazırlığı
- Durum: TAMAMLANDI
- Yapılanlar:
  - Backend genelinde namespace / use / model typing hijyeni yapıldı
  - Static analyzer (Intelephense) false-positive hataları temizlendi
  - Runtime davranışı değiştirilmedi
  - Test öncesi kod hijyeni tamamlandı
  - VehicleController tüm endpoint’leri response standardına alındı
  - savePushId legacy response temizlendi
  - Auth’lu endpoint’lerde response tutarsızlığı kalmadı
  - Intelephense vendor kaynaklı false-positive hatalar IDE seviyesinde temizlendi
  - Application koduna dokunulmadı
  - Static analysis yalnızca proje kodunu kapsayacak şekilde sınırlandı
  - Laravel Auth facade içindeki providerIsLoaded Intelephense false-positive’i IDE seviyesinde bilinçli olarak susturuldu (vendor/framework koduna müdahale edilmedi)
- Not:
  - response standardizasyonu tamamlandı, test aşamasına hazır

### CHECKPOINT #32 — Backend Auth Otomatik Test Paketi
- Durum: TAMAMLANDI
- Amaç:
  - Auth sözleşmesini (register/login/logout) otomatik test ile kilitlemek
- Kapsam:
  - Feature test: register, login, login negatif, logout, token invalidasyonu
- Çıkış kriteri:
  - Tüm testler yeşil (php artisan test / proje test komutu)
  - docs/api.md auth endpoint listesi logout ile tutarlı

### CHECKPOINT #33 — Auth Edge Case & Security Netleştirme
- Durum: TAMAMLANDI
- Amaç:
  - Auth akışını edge-case ve saldırı senaryolarına karşı sağlamlaştırmak
- Kapsam:
  - Register email normalize + password confirmation
  - Login rate limit (bruteforce koruması)
  - Logout idempotency (çift logout güvenliği)
- Çıkış kriteri:
  - Tüm auth feature testleri yeşil
  - Rate limit ve validation davranışı testle doğrulanmış

### CHECKPOINT #34 — Prod Auth Temizlik & Sertleştirme
- Durum: TAMAMLANDI
- Amaç:
  - Auth mimarisini prod seviyesine taşımak
- Kapsam:
  - Logout route mimari temizliği
  - Context-aware rate limit
  - Test DB izolasyonu (SQLite in-memory)
  - Auth boundary netleştirme
- Çıkış kriteri:
  - Auth testleri SQLite ile yeşil
  - Logout sadece authenticated çalışıyor
  - Rate limit error_code context’e göre dönüyor

### CHECKPOINT #35 — Public Güvenlik & Observability
- Durum: TAMAMLANDI
- Amaç:
  - Public (auth’suz) endpoint’leri abuse/spam’e karşı prod seviyesinde sağlamlaştırmak
- Kapsam:
  - Public endpoint rate limit ve guard netleştirmeleri
  - public_request_logs gerçek kullanımı (başarılı + hatalı istekler)
  - Rate limit error_code context-aware (PUBLIC_RATE_LIMIT vs AUTH_RATE_LIMIT)
  - Lokal/staging için read-only gözlem aracı
- Kapsam dışı:
  - Yeni endpoint ekleme, push notification, Flutter değişiklikleri
- Çıkış kriteri:
  - Public endpoint’ler context-aware rate limit ile duruyor
  - public_request_logs başarı+validation+rate-limit+exception kayıtlarını içeriyor
  - Auth testleri yeşil, endpoint sözleşmeleri korunuyor
  - SQLite test izolasyonu doğrulandı
  - Rate limit error_code tek merkezden yönetiliyor
- Test sonucu:
  - `php artisan test (SQLite in-memory)` → PASS
- Etkilenen dosyalar:
  - api/app/Http/Middleware/PublicRequestLogger.php
  - api/app/Providers/RouteServiceProvider.php
  - api/routes/api.php
  - api/app/Console/Commands/ShowPublicRequestLogs.php

### CHECKPOINT #36 — Staging Environment Validation & Safety Net
- Durum: TAMAMLANDI
- Amaç:
  - Staging ortamının prod’a zarar vermeyecek şekilde izole olduğunu doğrulamak
- Kapsam:
  - APP_ENV / DEBUG doğrulaması
  - Staging DB izolasyon kilidi
  - Auth + Public smoke test
  - Observability doğrulaması
- Kapsam dışı:
  - Push notification
  - CI / Docker
- Test sonucu:
  - `php artisan test (staging env)` → PASS
- Staging doğrulama:
  - Staging MySQL bağlantısı doğrulandı
  - Migration + seeder staging DB üzerinde başarıyla çalıştı
  - public_request_logs staging ortamda canlı veri alıyor

### CHECKPOINT #37 — Owner Push Notification (MVP)
- Durum: TAMAMLANDI
- Tamamlanan:
  - Guest message & location sonrası owner’a push gönderimi
  - Event → Listener → PushService mimarisi
  - Push token kayıt altyapısı (#25) aktif kullanıldı
  - Push payload standardize edildi (vehicle_uuid)
- Bilinçli teknik borçlar:
  - FCM legacy HTTP API kullanılıyor
  - Push işlemleri queue üzerinden async çalışıyor
  - Flutter push handling bu checkpoint’te yok
- Test:
  - php artisan test → PASS

### CHECKPOINT #38 — Flutter Push Notification Handling (MVP)
- Durum: TAMAMLANDI
- Tamamlanan:
  - Firebase Flutter entegrasyonu (Android + iOS)
  - Push token alma ve backend’e gönderme
  - Foreground / background / killed state ayrımı
  - Push payload ile doğru ekrana yönlendirme (vehicle_uuid)
- Kapsam dışı:
  - Bildirim tasarımı
  - Topic / segment
  - Analytics
- Test:
  - Android gerçek cihazda foreground / background / killed test edildi

### [2025-12-28] Owner Dashboard için Latest Message endpoint’i ve bütünleşik test
- Ne değişti:
    Owner Dashboard “Son Mesaj” paneli mesaj liste endpoint’inden ayrıldı ve /api/messages/latest ile tek kayıt bazlı özet akışına geçirildi.
- Neden:
    Dashboard özet kullanımının inbox liste endpoint’ine bağımlı olması gereksiz payload ve ileride pagination/sözleşme çakışması riski oluşturuyordu.
- Etkilenen endpoint/dosya:
    GET /api/messages/latest
    Backend: routes/api.php, MessageController.php
    Flutter: owner_dashboard.dart, message_service.dart
- Test:
    Flutter dashboard + inbox smoke test yapıldı; Postman ile /api/messages/latest 200 OK doğrulandı.


#### ⚠️ Teknik Borçlar / İyileştirme Notları (Owner Messages UI)

- Owner Messages UI şu an MVP seviyesindedir.
- Mesajlar şu an sıralama/filtreleme yapmadan listelenmektedir.
  - İleride:
    - Tarihe göre sıralama
    - Araç bazlı gruplama
    uygulanabilir.

- OwnerDashboard üzerindeki “Son Mesaj” paneli şu an statik (hardcode) verilerle gösterilmektedir.
  - İleride:
    - GET /api/messages üzerinden son mesaj alınmalı
    - Gerçek mesaj içeriği ve tarihi gösterilmelidir.

- `createdAt` alanı artık ham `toString()` ile gösterilmemektedir.
    - Tarih/saat bilgisi lokal zamana çevrilerek `GG.AA.YYYY SS:DD` formatında UI’da gösterilmektedir.
- Hata state’i artık sadece generic string değildir.
    - Network / timeout hataları ayrı mesajla gösterilmektedir.
    - 401 (unauthorized / token) hataları ayrı mesajla gösterilmektedir.
    - Diğer tüm durumlar için generic hata mesajı kullanılmaktadır.
- Owner Messages Inbox ekranına retry (“Tekrar Dene”) aksiyonu eklenmiştir.
    - Retry butonu hata state’inde görünür.
    - Retry, mevcut GET `/api/messages` çağrısını yeniden tetikler.



## 11) Yapılanlar / Kalanlar (Durum Tablosu)

### 11.1 Yapılanlar (Bilinen)
- [x] `vehicles` tablosu mevcut (DESCRIBE çıktısı görüldü)
- [x] `messages` migration hazır (paylaşıldı)
- [x] Genel akış net: QR/NFC → vehicle_uuid → profil/mesaj/konum
- [x] quick_messages tablosu ve varsayılan hızlı mesajlar (seeder ile) eklendi
- [x] Public quick_messages listeleme endpoint’i (GET /api/public/quick-messages)
- [x] Public quick_message gönderme endpoint’i (POST /api/public/quick-message/send)
- [x] Quick message → messages tablosuna kayıt akışı tamamlandı
- [x] Public vehicle profile endpoint’i (GET /api/public/vehicle/{vehicle_uuid}) tamamlandı
- [x] Public response standardı sabitlendi (ok/message/data)
- [x] QuickMessage → public profile entegrasyonu yapıldı
- [x] Vehicle (kart) aktivasyon akışı tamamlandı
- [x]  POST /api/vehicle/activate
- [x]  Kart (vehicle_id) kullanıcıya bağlanıyor
- [x]  Owner’a ait kartları listeleme endpoint’i eklendi
- [x]  GET /api/vehicles
- [x]  API isteklerinde JSON/HTML dönüş problemi çözüldü
- [x]  Accept: application/json zorunluluğu netleştirildi
- [x] locations tablosu oluşturuldu
- [x] Location modeli eklendi
- [x] Public konum kaydetme endpoint’i (POST /api/public/location/save)
- [x] vehicle_uuid → vehicles.id mapping doğrulandı
- [x] Guest QR/NFC üzerinden konum kaydı alınıyor
- [x] Owner için konum listeleme endpoint’i (GET /api/locations)
- [x] Location kayıtları sadece owner’a ait araçlara filtreleniyor
- [x] Flutter ApiConfig eklendi (dev/prod + /api prefix sabit)
- [x] Laravel’i LAN’dan erişilebilir çalıştırma doğrulandı (--host=0.0.0.0)
- [x] Flutter → POST /api/public/quick-message/send başarıyla çalıştı
- [x] Quick message payload standardı Flutter’da uygulandı (vehicle_uuid, quick_message_id)
- [x] JSON header standardı Flutter’da uygulandı (Accept: application/json)
- [x] Flutter – Guest konum alma (GPS) başarıyla çalışıyor
- [x] Flutter – POST /api/public/location/save entegrasyonu tamamlandı
- [x] Android runtime konum izinleri (FINE / COARSE) doğrulandı
- [x] Flutter → Backend → DB konum kayıt akışı uçtan uca test edildi
- [x] locations tablosuna gerçek cihazdan veri yazıldığı doğrulandı
- [x] Flutter – Public Vehicle Profile (GET /api/public/vehicle/{uuid}) entegrasyonu tamamlandı
- [x] Flutter – Vehicle Profile ekranında araç bilgileri + quick messages UI hazır
- [x] Flutter – public_service.dart ile public profile fetch standardı eklendi
- [x] Flutter – Location Save’i Vehicle Profile ekranına taşı (Kart tasarımı ile)
- [x] Flutter – location_test_screen.dart temizlendi / devre dışı bırakıldı
- [x] Konum gönderme işlemi için setState tabanlı loading (spinner) yönetimi eklendi
- [x] NFC platform izinleri/entitlements tamamlandı (Android + iOS).
- [x] nfc_manager bağımlılığı projeye eklendi ve paketler çekildi.
- [x] Owner Messages Inbox UI kalite iyileştirmeleri tamamlandı:
  - [x] Tarih/saat formatlama uygulandı (`createdAt`).
  - [x] Retry (“Tekrar Dene”) mekanizması eklendi.
  - [x] Hata mesajları minimum seviyede ayrıştırıldı (network / auth / generic).
- [x] Owner Messages Inbox UI, MVP seviyesinden **MVP+** seviyesine yükseltildi.
- [x] UI tarafında backend endpoint veya veri sözleşmesi değişikliği yapılmadı.
- [x] Flutter UI’da tarih formatı merkezi `DateFormatter` üzerinden yönetiliyor
- [x] Backend tarih sözleşmesine dokunulmadı (ISO string korunuyor)
- [x] Owner Dashboard:
  - Son Mesaj
  - Son Konum
  panellerinde tarih gösterimi standartlaştırıldı
- [x] Owner Inbox (MessagesPage) tarih gösterimi standartlaştırıldı
- [x] Owner Locations listesi tarih gösterimi standartlaştırıldı
- [x] Message modelinde tarih alanları sadeleştirildi:
  - [x] `DateTime` tabanlı alanlar tamamen kaldırıldı
  - [x] Sadece backend’den gelen `created_at` raw string tutuluyor
- [x] Tarih parse/format işlemleri UI ve model katmanından izole edildi


> Not: Endpoint’lerin “kesin çalışır” listesini repo/dosya içeriğiyle doğrulayıp buraya kilitleyeceğiz.

### 11.2 Kalanlar (Sırayla)

- [x] Owner Message Inbox (Flutter Service)
- [x] Owner Message Inbox (Flutter UI)
- [x] Owner Locations Screen (Flutter)
- [x] Owner Dashboard “Son Konum” panelinin canlı backend verisiyle beslenmesi



---

## 12) Test Planı (Minimum)

### 12.1 Backend Smoke Test
- Register → Login → token al
- POST /vehicles → uuid dönüyor mu?
- GET /public/vehicle/{uuid} → araç + quick messages geliyor mu?
- POST /public/message → messages tablosuna yazıyor mu?
- POST /public/location/save → locations tablosuna yazıyor mu?
- GET /messages (owner) → sadece owner araçlarına ait mi?
- GET /locations (owner) → sadece owner araçlarına ait mi?

### 12.2 Flutter Smoke Test
- QR okutup deeplink alıyor mu?
- vehicle profile çekiyor mu? ✅ (gerçek cihazda doğrulandı)
- quick message gönderiyor mu? ✅ (telefon test edildi, ok:true)
- özel mesaj gönderiyor mu?
- konum kaydediyor mu?
- quick message spam / tekrar tıklama senaryosu → cooldown ile kontrol altında


---

## 13) Değişiklik Günlüğü (Çok Önemli)

Şablon:
```
### [2025-12-16] Flutter API config ve QuickMessage entegrasyonu
- Ne değişti:
    Flutter’da merkezi baseUrl config eklendi
    Quick message endpoint/payload düzeltildi
- Neden:
    Hardcode endpoint ve yanlış route nedeniyle 404/HTML hataları vardı
    quick_messages DB boşluğu nedeniyle 404 “Invalid quick_message_id” alınıyordu
- Etkilenen endpoint/dosya:
    POST /api/public/quick-message/send
    Flutter: api_config.dart, quick_message_service.dart, nfc_menu.dart
- Flutter etkisi:
    Guest hızlı mesaj akışı stabil hale geldi


### [2025-12-17] Flutter Guest Location Save entegrasyonu

- Ne değişti:
    Flutter’da GPS üzerinden konum alınıp backend’e gönderilen akış tamamlandı
    POST /api/public/location/save endpoint’i Flutter’dan gerçek cihazla test edildi

- Neden:
    Ziyaretçinin araç sahibine konum bırakabilmesi MVP’nin kritik parçalarından biri

- Etkilenen endpoint/dosya:
    POST /api/public/location/save
    Flutter: location_service.dart, device_location_service.dart

- Flutter etkisi:
    Guest QR/NFC akışında konum kaydetme altyapısı hazır hale geldi


### [2025-12-17] Flutter Guest Vehicle Profile (Public) entegrasyonu

- Ne değişti:
    Flutter’da public araç profili ekranı oluşturuldu
    GET /api/public/vehicle/{vehicle_uuid} endpoint’i Flutter servisinden çağrıldı ve UI’da gösterildi
    Quick messages buton olarak listelendi, tıklama id log ile doğrulandı

- Neden:
    MVP’de ana akış: QR/NFC → profil → hızlı mesaj / konum temel taş

- Etkilenen endpoint/dosya:
    GET /api/public/vehicle/{vehicle_uuid}
    Flutter: public_service.dart, vehicle_profile_screen.dart, main.dart (geçici test)

- Flutter etkisi:
    Guest profile akışı çalışır hale geldi
    Bir sonraki adım: Quick message gönderme aksiyonu


### [2025-12-20] Location Save UI Entegrasyonu
- Ne değişti:
    Konum kaydetme özelliği test ekranından çıkarılıp ana araç profil ekranına (Guest Flow) taşındı.
- Neden:
    Kullanıcının ayrı bir ekrana gitmeden, aynı sayfada hem mesaj atabilmesi hem de konum bırakabilmesi sağlandı.
- Etkilenen endpoint/dosya:
    Flutter: vehicle_profile_screen.dart
- Flutter etkisi:
    Guest flow (Ziyaretçi akışı) büyük oranda tamamlandı. UI artık daha profesyonel ve toplu duruyor.


### [2025-12-26] NFC Platform Hazırlığı

- Ne değişti:
    Flutter projeye nfc_manager dahil edildi; Android’de NFC permission/feature + NDEF intent-filter ve tech list eklendi; iOS’ta NFC reader usage description ve NDEF entitlements tanımlandı.
- Neden:
    NFC kart okuma akışı başlatılmadan önce platform izinleri/entitlements zorunlu.
- Flutter etkisi:
    NFC okuma kodu yazmaya hazır altyapı; sonraki adım nfc_manager ile NDEF URI → vehicle_uuid parse akışı.


### [2025-12-26] Flutter NFC Okuma Akışı & QR/NFC UI Ayrımı

- Ne değişti:
    ScanScreen QR ve NFC modlarına ayrıldı.
    NFC modunda kamera devre dışı bırakıldı, yalnızca NFC okuma aktif.
    `VehicleUuidParser`, IP tabanlı public endpoint URI’larını destekleyecek şekilde genişletildi.

- Neden:
    QR ve NFC akışları birbirine giriyordu.
    Lokal backend IP’si ile yazılmış NFC tag’ların parse edilememesi test sürecini kilitliyordu.

- Etkilenen dosyalar:
    Flutter:
      - scan_screen.dart
      - home_screen.dart
      - vehicle_uuid_parser.dart

- Flutter etkisi:
    NFC tag okutulduğunda doğrudan araç profiline yönlendirme yapılır.
    QR ve NFC kullanıcı akışları sade, öngörülebilir ve çakışmasız hale geldi.



### [2025-12-30] Flutter Tarih Formatı Standardizasyonu (UI Katmanı)

- Ne değişti:
    Flutter tarafında tüm tarih/saat gösterimleri merkezi `DateFormatter` utility’sine taşındı.
    UI ve model katmanlarında DateTime parse işlemleri tamamen kaldırıldı.
    Backend’den gelen ISO tarih string’leri ham olarak taşınıyor.

- Neden:
    UI tarafında tutarsız tarih formatları ve gizli teknik borç oluşuyordu.
    Push notification ve ilerideki locale/timezone ihtiyaçları için sağlam bir zemin gerekiyordu.

- Etkilenen dosyalar:
    Flutter:
      - lib/utils/date_formatter.dart
      - lib/models/message.dart
      - lib/screens/owner/owner_dashboard.dart
      - lib/screens/owner/messages_page.dart
      - lib/screens/owner/locations_page.dart

- Flutter etkisi:
    Tarih formatı artık uygulama genelinde tutarlı ve tek merkezden yönetiliyor.
    UI katmanı backend tarih sözleşmesine birebir uyumlu hale geldi.

- Durum:
    Kod tamamlandı.
    Git kapanış adımları (commit & push) henüz doğrulanmadı.


```

---

## 14) Çalışma Protokolü (Seninle Nasıl Çalışacağız)

1) **Her yeni oturumda** bu dosyayı gönderiyorsun.
2) Ben sadece bu dosyaya dayanarak “şu an durum” çıkarıyorum.
3) Yeni endpoint/dosya adı önermeden önce bu dosyadaki standartlara bakarım.
4) Bir adımı bitirdiğinde:
   - Sen **Checkpoint** eklersin
   - “Değişiklik Günlüğü”ne yazarsın
5) Yeni sekmeye geçince:
   - Dosyayı yapıştırırsın
   - “ARVONCODE-PHOENIX devam” dersin
   - Ben kaldığımız checkpoint’ten yürürüm

---

## 15) Şu An Başlamak İçin 1 Numara Adım (Öneri)

**QuickMessage sistemi** en önce.
Hedef:
- `quick_messages` migration
- `QuickMessageSeeder`
- `GET /public/quick-messages`
- `POST /public/quick-message/send` (messages tablosuna da yaz)

---

# EK: Kırmızı Çizgiler

- Endpoint isimleri keyfine göre değişmez.
- `vehicle_uuid` (public) ile `vehicles.id` (internal) karıştırılırsa proje sürekli kırılır.
- Flutter “hangi endpoint’i çağırıyor?” sorusu bu dosyada her zaman net olmalı.


## 🔧 Version Control (Git & GitHub)

### Repository
- **Platform:** GitHub
- **Repository URL:**
  https://github.com/huseyincakirca/arvoncode-car-nfc-api
- **Branch:** `main`
- **Local Path:** `/opt/lampp/htdocs/car-nfc-api`

### Git Initialization
Proje yerel ortamda Git ile aşağıdaki adımlar izlenerek versiyon kontrolüne alınmıştır:

```bash
git init
git branch -M main
git add .
git commit -m "Initial commit: ArvonCode Car NFC API backend"


## 🗺️ Roadmap

### MVP (Phase 1)
- [x] Vehicle + UUID sistemi
- [x] Quick Messages
- [x] Public Vehicle Profile
- [x] Location save (guest)

### Beta (Phase 2)
- [ ] Push notification (Firebase)
- [ ] Rate limit / abuse protection
- [ ] Admin panel basic

### Prod (Phase 3)
- [ ] Multi-language
- [ ] Subscription / pricing
- [ ] Logging & monitoring



## Environment & System Setup (2025-01 Reset)

### Operating System
- OS: Ubuntu 24.04 LTS (Clean Install)
- Kernel: 6.14.x
- Installation type: Manual partitioning
- /home directory: Recreated (restored from backup)
- /opt directory: Restored from opt-backup.tar.gz

### System Reset Notes
- Previous system had snap & package corruption
- Full clean installation was performed
- All development tools reinstalled manually
- Legacy paths and broken snap configurations removed

### Core Development Tools

#### Flutter
- Flutter SDK: 3.24.4 (stable)
- Install method: Local SDK restored from backup
- Path: ~/flutter
- PATH configured in ~/.bashrc
- flutter doctor: ✅ all checks passed

#### Android
- Android Studio: 2025.2.2
- Installed to: /opt/android-studio
- Android SDK path: /home/cakirca/Android/Sdk
- cmdline-tools installed
- Licenses accepted
- Physical device tested successfully

#### Backend
- Laravel API repository: arvoncode-car-nfc-api
- Location: /home/cakirca/arvoncode-car-nfc-api
- API previously located under /opt/lampp/htdocs (legacy)
- New structure prefers HOME-based projects

#### Git
- Git installed via apt
- Global user configured:
  - Name: Hüseyin Çakırca
  - Email: huseyincakirca@hotmail.com.tr
- GitHub authentication via Personal Access Token
- Credential helper: store
- Token stored locally

#### Frontend
- Flutter App repository: arvoncode_app
- Git repository initialized after restore
- Branch: main
- GitHub remote configured and verified
- Application successfully built and deployed to device

### Notes
- System verified by running:
  - flutter run (Android device)
  - git push / pull
  - android build & install
- This environment is considered STABLE BASELINE


---

## 🖥️ Sistem Yeniden Kurulum Kaydı (15.12.2025)

### İşletim Sistemi
- Ubuntu 24.04 LTS (temiz kurulum)

### Geliştirme Ortamı
- Flutter SDK: 3.24.4 (manual kurulum, `$HOME/flutter`)
- Android Studio: 2025.2.2 (`/opt/android-studio`)
- Android SDK: `/home/cakirca/Android/Sdk`
- Git: 2.43.0
- VS Code: 1.107.0

### Flutter Doctor Durumu
- Android: ✅
- Web (Chrome): ✅
- Linux Desktop: ✅
- Device: Fiziksel Android cihaz

### Git
- HTTPS + token kullanımı
- credential.helper = store

### Notlar
- Eski sistemde `/opt/lampp/htdocs` altında bulunan Laravel API,
  yeni sistemde kullanıcı dizinine alınmıştır.
- NTFS diskler manuel mount ile kurtarılmıştır.
- Tüm kritik projeler yedekten geri yüklenmiştir.

---
