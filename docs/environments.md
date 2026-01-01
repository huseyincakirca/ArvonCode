# Ortamlar (Environments)

## Local
- localhost
- debug açık
- test verisi
- Queue Worker:
  - `cd api && php artisan queue:work --queue=default --tries=5 --backoff=10 --timeout=60`

## Staging
- Gerçek API
- Test kullanıcıları
- NFC test kartları
- Queue Worker:
  - Supervisor config: `api/deploy/supervisor/arvoncode-queue-worker.conf`
  - Uygulama: `supervisorctl reread && supervisorctl update && supervisorctl start arvoncode-queue-worker:*`

## Production
- Gerçek kullanıcı
- Rate-limit aktif
- Log zorunlu
- Queue Worker:
  - Supervisor/systemd kurulumu deploy adımıdır; config: `api/deploy/supervisor/arvoncode-queue-worker.conf`
  - Uygulama: `supervisorctl reread && supervisorctl update && supervisorctl restart arvoncode-queue-worker:*`
