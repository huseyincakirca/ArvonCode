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

---

## Authenticated Requests
Tüm korumalı endpoint'lerde:

Authorization: Bearer {token}
