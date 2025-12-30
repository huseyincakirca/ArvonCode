# Mimari Yapı

## 1. Bileşenler

### Mobile App (Flutter)
- Kullanıcı kayıt / giriş
- Araç ekleme (NFC aktivasyon)
- Gelen mesajları görüntüleme
- Konum ve park geçmişi

### Backend API (Laravel)
- Auth (Sanctum)
- Araç yönetimi
- Mesajlaşma
- Konum kayıtları
- Public (guest) endpoint'ler

### Public (Guest) Katmanı
- NFC / QR okutulduğunda çalışır
- Login gerektirmez
- Rate-limit ve log zorunludur

---

## 2. Veri Akışı

### Authenticated Akış
App → API → Database

### Guest Akış
NFC / QR → Public API → Database → Owner bildirim

---

## 3. Güvenlik
- Auth işlemleri: Sanctum token
- Public endpoint'ler:
  - throttle
  - IP log
  - validation zorunlu
