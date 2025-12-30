# Kimlik Doğrulama (Auth)

## POST /api/register
Kullanıcı kaydı ve token üretimi.

Body:
{
  "name": "string",
  "email": "string",
  "password": "min 6"
}

---

## POST /api/login
Kullanıcı girişi ve token üretimi.

Body:
{
  "email": "string",
  "password": "string"
}

Response (Success):
```
{
  "ok": true,
  "message": "Login successful",
  "data": {
    "user": {...},
    "token": "..."
  }
}
```

Response (Error – 401):
```
{
  "ok": false,
  "message": "Invalid credentials",
  "data": {}
}
```

---

## POST /api/logout
Auth token revoke işlemi.

Auth:
- Authorization: Bearer {token} (Sanctum)

Response:
```
{
  "ok": true,
  "message": "Logged out",
  "data": {}
}
```

Not:
- Sadece currentAccessToken silinir
- Refresh token yoktur

---

## POST /api/register
Kullanıcı kaydı ve token üretimi.

Body:
{
  "name": "string",
  "email": "string",
  "password": "min 6"
}

Response (Success):
```
{
  "ok": true,
  "message": "Register successful",
  "data": {
    "user": {...},
    "token": "..."
  }
}
```

## Authenticated Requests
Tüm korumalı endpoint'lerde:

Authorization: Bearer {token}
