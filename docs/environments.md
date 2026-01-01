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

## Queue Operations / Failed Jobs
- `php artisan queue:failed` — başarısız job kayıtlarını listeler (failed_jobs).
- `php artisan queue:retry all` — tüm failed job kayıtlarını yeniden kuyruğa alır.
- `php artisan queue:retry {id}` — belirli failed job kaydını yeniden kuyruğa alır.
- `php artisan queue:flush` — failed job kayıtlarını temizler.
- `php artisan queue:work --once` — kuyruğu bir kez çalıştırır (health check amaçlı).
- Bu komutlar monitoring değildir, manuel operasyon içindir.
