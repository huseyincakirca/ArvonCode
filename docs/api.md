# API Endpoint Listesi (GERÇEK)

## AUTH (PUBLIC)
POST   /api/register
POST   /api/login

---

## AUTHENTICATED (auth:sanctum)

### Vehicle
POST   /api/vehicle/activate
GET    /api/vehicle/my
GET    /api/vehicles
GET    /api/vehicle/{vehicle_id}

### Parking
POST   /api/parking/set
GET    /api/parking/latest/{vehicle_id}
DELETE /api/parking/delete/{vehicle_id}

### Messages (Owner)
GET    /api/messages
GET    /api/messages/latest

### Locations (Owner)
GET    /api/locations

### Push
POST   /api/user/push-id

---

## PUBLIC (Guest) – /api/public

GET    /api/public/vehicle/{vehicle_uuid}
GET    /api/public/quick-messages
POST   /api/public/quick-message/send
POST   /api/public/message
POST   /api/public/location/save

---

## LEGACY (Dokümante edilmez)
GET    /api/v/{tag}
POST   /api/v/{tag}/message
