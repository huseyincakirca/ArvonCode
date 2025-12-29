# ArvonCode — Monorepo

## 1. Proje Tanımı

ArvonCode; **NFC tabanlı dijital kimlik / araç / mesaj / konum yönetimi** odaklı, mobil uygulama + API mimarisiyle geliştirilen bir sistemdir.

Bu repository **tek gerçek kaynak (single source of truth)** olacak şekilde **monorepo** yapısında tasarlanmıştır.

---

## 2. Repository Yapısı

```
ArvonCode/
├── app/            # Flutter mobil uygulama
├── api/            # Laravel API
├── docs/           # Dokümantasyon, mimari notlar, promptlar
└── README.md       # Bu dosya
```

### Temel Kurallar

* `app` ve `api` **asla birbirine karışmaz**
* Flutter kodu **sadece** `/app`
* Laravel kodu **sadece** `/api`
* Ortak bilgi **/docs** altında tutulur

---

## 3. Teknoloji Stack

### Mobil (app)

* Flutter
* Android öncelikli (iOS opsiyonel)
* NFC
* Konum (Geolocator)
* HTTP API entegrasyonu

### Backend (api)

* Laravel
* REST API
* Sanctum (token bazlı auth)
* MySQL / MariaDB

---

## 4. Geliştirme Ortamı

### API Çalıştırma

```bash
cd api
composer install
php artisan key:generate
php artisan migrate
php artisan serve
```

Varsayılan adres:

```
http://127.0.0.1:8000
```

---

### App Çalıştırma

```bash
cd app
flutter clean
flutter pub get
flutter run
```

---

## 5. Ortamlar (Environment)

### Development

* Localhost
* Debug açık
* Hızlı iterasyon

### Staging (ileride)

* Canlıya yakın ortam
* Gerçek API URL
* Test NFC kartları

### Production (ileride)

* Canlı kullanıcılar
* Kilitli config
* Log ve izleme aktif

---

## 6. API – App İlişkisi

* App **hiçbir zaman** doğrudan veritabanına erişmez
* Tüm işlemler API üzerinden yapılır
* Token bazlı kimlik doğrulama kullanılır

---

## 7. NFC Akışı (Özet)

1. NFC kart okunur
2. Kart UID alınır
3. API’ye gönderilir
4. Duruma göre:

   * Yeni kart → kayıt
   * Mevcut kart → ilişkilendirme
   * Geçersiz → reddetme

> Detaylı NFC akışı `/docs/nfc.md` altında tutulacaktır.

---

## 8. Geliştirme Kuralları (KESİN)

* Kod yazmadan önce **hangi klasörde çalıştığını belirt**
* Aynı anda hem `app` hem `api` değiştirme
* Tahmin ederek kod yazma
* Her önemli adım dokümante edilir

---

## 9. Codex Kullanım Prensibi

Codex bu repository’nin **root context’ine sahiptir**.

Her görevde:

* Hangi klasör
* Hangi dosya
* Ne yapılacağı

**Net olarak belirtilir.**

---

## 10. Proje Durumu

* Mimari: ✅ Stabil
* Monorepo: ✅ Aktif
* Geliştirme: 🚧 Devam ediyor

---

## 11. Not

Bu dosya **canlıdır**.
Proje ilerledikçe güncellenecektir.

Dağınıklık = hata.
Disiplin = hız.
