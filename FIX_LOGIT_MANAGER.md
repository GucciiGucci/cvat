# Fix: No installed app with label 'logit_manager'

## Vấn đề

Khi chạy migration, gặp lỗi:
```
CommandError: No installed app with label 'logit_manager'.
```

## Nguyên nhân

Docker container `cvat_server` đang chạy với image cũ, chưa có code mới của app `logit_manager`.

## Giải pháp

### Cách 1: Rebuild và restart (Khuyến nghị)

```bash
cd /Users/macbookprom1/Documents/thesis/cvat

# Rebuild cvat_server image với code mới
docker compose -f docker-compose.yml -f docker-compose.dev.yml build cvat_server

# Restart container
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d cvat_server

# Đợi server sẵn sàng
sleep 10
```

### Cách 2: Sử dụng script helper

```bash
cd /Users/macbookprom1/Documents/thesis/cvat

# Rebuild và restart
./scripts/rebuild_and_start.sh
```

### Cách 3: Rebuild tất cả (nếu cần)

```bash
cd /Users/macbookprom1/Documents/thesis/cvat

# Rebuild tất cả services
docker compose -f docker-compose.yml -f docker-compose.dev.yml build

# Restart tất cả
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

## Kiểm tra

Sau khi rebuild, kiểm tra app đã được nhận diện:

```bash
docker compose exec cvat_server python manage.py shell -c "from django.apps import apps; print([app.label for app in apps.get_app_configs() if 'logit' in app.label])"
```

Kết quả mong đợi: `['logit_manager']`

Kiểm tra folder có tồn tại:

```bash
docker compose exec cvat_server ls -la /home/django/cvat/apps/logit_manager/
```

## Sau khi rebuild thành công

Sau khi rebuild thành công, bạn có thể chạy các migrations chung của CVAT (nếu cần):

```bash
docker compose exec cvat_server python manage.py migrate
```

## Lưu ý

- Rebuild có thể mất vài phút
- Đảm bảo Docker có đủ disk space
- Nếu gặp lỗi build, xem logs: `docker compose logs cvat_server`

