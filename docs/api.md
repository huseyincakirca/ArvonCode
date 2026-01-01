# API Endpoint Listesi (GERÇEK)

## AUTH (PUBLIC)
POST   /api/register
POST   /api/login

---

## AUTHENTICATED (auth:sanctum)

POST   /api/logout

### Vehicle
POST   /api/vehicle/activate
GET    /api/vehicle/my
GET    /api/vehicles
GET    /api/vehicle/{vehicle_id}

### Parking
POST   /api/parking/set
GET    /api/parking/latest/{vehicle_id}
DELETE /api/parking/delete/{vehicle_id}
- Detaylı sözleşme: `docs/parking.md`

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
