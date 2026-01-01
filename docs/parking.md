# Parking — Ürün Senaryosu ve API Sözleşmesi (GERÇEK)

## Parking Ürün Senaryosu (Owner-only)
- Araç sahibi, park yerini uygulama üzerinden kaydeder ve sadece kendisi görüntüler/siler.
- Kayıtlı park bilgisi **yalnızca araç sahibi token’ı** ile erişilebilir; ziyaretçi/public akışı yoktur.

## Giriş Akışı (NFC / QR → vehicle_uuid)
- Owner, karttaki `vehicle_id` (uuid/string) bilgisini bilir; park çağrıları bu değerle yapılır.
- Backend bu değeri `vehicles.vehicle_id` ile eşleştirip ilgili `vehicles.id` üzerinde işlem yapar.

## Sahiplik Kontrolü
- Her endpoint, `vehicles.user_id == auth()->id()` kontrolü yapar; değilse 403 döner.
- Her araç için **tek aktif park kaydı** tutulur; yeni kayıt eskiyi günceller.

## Konum Kaydetme Onayı
- Park kaydı; lat/lng + vehicle_id ile **owner token** üzerinden kaydedilir.
- Geçersiz/hatalı istekler 422 (validation) veya 403 (sahiplik) döner.

## “Parkta Arabamı Bul” Akışı
- Owner, “latest parking” sorgusuyla son park konumunu çeker; kayıt yoksa `parking: null`.
- İsterse park kaydını silebilir; tüm park kayıtları ilgili araç için temizlenir.

## Kimlik Doğrulama
- Tüm parking endpoint’leri `auth:sanctum` koruması altındadır.
- İsteklerde `Authorization: Bearer <token>` ve `Accept: application/json` kullanılmalıdır.

## Endpointler

### 1) Park Kaydet
- **POST** `/api/parking/set`
- **Body** (JSON):
  - `vehicle_id` (string, required): Araç kartındaki `vehicle_id` (uuid/string). Backend’de `vehicles.vehicle_id` ile eşleşir.
  - `lat` (number, required)
  - `lng` (number, required)
- **Response (200)**:
```json
{
  "ok": true,
  "message": "Parking saved",
  "data": {
    "parking": {
      "id": 1,
      "vehicle_id": 10,
      "lat": "41.1234567",
      "lng": "29.1234567",
      "parked_at": "2026-01-02T10:00:00.000000Z",
      "created_at": "2026-01-02T10:00:00.000000Z",
      "updated_at": "2026-01-02T10:00:00.000000Z"
    }
  }
}
```
- **Hata Senaryoları**:
  - 401: Token yok/Geçersiz (Laravel Sanctum default response).
  - 403: Araç kullanıcıya ait değil → `{ "ok": false, "message": "Unauthorized vehicle", "data": {} }`
  - 422: Validation hatası (Laravel validation formatı).

### 2) Son Parkı Getir
- **GET** `/api/parking/latest/{vehicle_id}`
- **Path Param**:
  - `vehicle_id` (string): Araç kartındaki `vehicle_id` (uuid/string).
- **Response (200)**:
```json
{
  "ok": true,
  "message": "Latest parking fetched",
  "data": {
    "parking": {
      "id": 1,
      "vehicle_id": 10,
      "lat": "41.1234567",
      "lng": "29.1234567",
      "parked_at": "2026-01-02T10:00:00.000000Z",
      "created_at": "2026-01-02T10:00:00.000000Z",
      "updated_at": "2026-01-02T10:00:00.000000Z"
    }
  }
}
```
- `parking` alanı, kayıt yoksa `null` olabilir.
- **Hata Senaryoları**:
  - 401: Token yok/Geçersiz.
  - 403: Araç kullanıcıya ait değil → `{ "ok": false, "message": "Unauthorized vehicle", "data": {} }`

### 3) Park Kayıtlarını Sil
- **DELETE** `/api/parking/delete/{vehicle_id}`
- **Path Param**:
  - `vehicle_id` (string): Araç kartındaki `vehicle_id` (uuid/string).
- **Response (200)**:
```json
{
  "ok": true,
  "message": "Parking deleted",
  "data": {}
}
```
- **Hata Senaryoları**:
  - 401: Token yok/Geçersiz.
  - 403: Araç kullanıcıya ait değil → `{ "ok": false, "message": "Unauthorized vehicle", "data": {} }`

## Veri Modeli
- DB tablosu: `parkings`
- Alanlar: `id`, `vehicle_id` (foreign key → `vehicles.id`), `lat` (decimal 10,7), `lng` (decimal 10,7), `parked_at` (timestamp), `created_at`, `updated_at`.
