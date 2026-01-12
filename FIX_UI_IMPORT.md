# Fix: UI không chuyển bước sau khi import ảnh

## Vấn đề

Sau khi upload ảnh và tạo task, UI hiển thị "CVAT queued the task to import" nhưng không tự động chuyển sang bước tiếp theo.

## Nguyên nhân

1. **Worker import chưa chạy**: Jobs đang trong queue nhưng chưa được xử lý
2. **UI không tự động redirect**: CVAT UI không tự động redirect sau khi import xong, cần thao tác thủ công

## Giải pháp

### 1. Khởi động Worker Import (Đã fix)

```bash
cd /Users/macbookprom1/Documents/thesis/cvat
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d cvat_worker_import cvat_worker_chunks
```

### 2. Kiểm tra Task Status

```bash
# Xem tasks
docker compose exec cvat_server python manage.py shell -c "
from cvat.apps.engine.models import Task
tasks = Task.objects.all().order_by('-id')[:5]
for t in tasks:
    print(f'Task {t.id}: {t.name} - Status: {t.status} - Size: {t.data.size if t.data else 0}')
"

# Xem jobs trong queue
docker compose exec cvat_server python manage.py shell -c "
from django_rq import get_queue
queue = get_queue('import')
jobs = queue.get_jobs()
print(f'Jobs in queue: {len(jobs)}')
for j in jobs[:3]:
    print(f'  Job: {j.id} - Status: {j.get_status()}')
"
```

### 3. Cách sử dụng UI

**Sau khi upload ảnh:**

1. **Option 1: Đợi import xong rồi click "Continue"**
   - Đợi message chuyển từ "CVAT queued the task to import" sang "Task creation finished"
   - Click nút "Continue" để chuyển sang task page

2. **Option 2: Đóng window và vào task sau**
   - Như message đã nói: "You may close the window"
   - Vào Tasks page và tìm task vừa tạo
   - Task sẽ tự động import trong background

3. **Option 3: Refresh page**
   - Nếu task đã import xong, refresh page sẽ tự động redirect

### 4. Kiểm tra Import Status

Trong browser console, bạn sẽ thấy:
- `GET_REQUEST_STATUS_SUCCESS` - Import đang được xử lý
- Khi import xong, status sẽ là `FINISHED`

### 5. Nếu Import bị stuck

```bash
# Xem logs worker
docker compose logs cvat_worker_import --tail 50

# Restart worker
docker compose restart cvat_worker_import

# Xem task details
docker compose exec cvat_server python manage.py shell -c "
from cvat.apps.engine.models import Task
task = Task.objects.get(id=2)  # Thay 2 bằng task ID của bạn
print(f'Task: {task.name}')
print(f'Status: {task.status}')
print(f'Data size: {task.data.size if task.data else 0}')
print(f'Images: {task.data.images.count() if task.data else 0}')
"
```

## Lưu ý

- **Import là async process**: CVAT queue task import vào background
- **UI không tự động redirect**: Đây là design của CVAT - user cần click Continue hoặc vào task page thủ công
- **Worker cần chạy**: Đảm bảo `cvat_worker_import` và `cvat_worker_chunks` đang chạy

## Update Script Start

Script `start_cvat_local.sh` đã được cập nhật để tự động khởi động workers.

