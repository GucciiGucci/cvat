#!/bin/bash

# Script để chạy CVAT local cho development

set -e

echo "🚀 Bắt đầu chạy CVAT local..."

# Di chuyển đến thư mục CVAT
cd "$(dirname "$0")/.."

# Kiểm tra Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker chưa được cài đặt. Vui lòng cài Docker trước."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose chưa được cài đặt. Vui lòng cài Docker Compose trước."
    exit 1
fi

# Sử dụng docker compose (mới) hoặc docker-compose (cũ)
COMPOSE_CMD="docker compose"
if ! $COMPOSE_CMD version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
fi

echo "📦 Đang khởi động các services..."
$COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml up -d \
    cvat_db cvat_redis_inmem cvat_redis_ondisk cvat_clickhouse cvat_opa cvat_vector traefik \
    cvat_worker_import cvat_worker_chunks

echo "⏳ Đợi database sẵn sàng..."
sleep 5

# Kiểm tra xem cvat_server có cần rebuild không
echo "🔍 Kiểm tra cvat_server..."
if ! docker ps | grep -q cvat_server; then
    echo "📦 cvat_server chưa chạy. Đang rebuild và khởi động..."
    $COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml build cvat_server
    $COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml up -d cvat_server
    echo "⏳ Đợi cvat_server sẵn sàng..."
    sleep 10
else
    echo "⚠️  cvat_server đang chạy. Nếu gặp lỗi 'No installed app', cần rebuild:"
    echo "   ./scripts/rebuild_and_start.sh"
fi

echo "🔄 Đang chạy migrations..."
if docker compose exec -T cvat_server python manage.py migrate 2>/dev/null; then
    echo "✅ Migrations đã chạy thành công"
else
    echo "⚠️  Đang thử cách khác..."
    docker exec -i cvat_server python manage.py migrate
fi

# Kiểm tra và copy file urls.py nếu cần (để đảm bảo route mới được load)
echo "🔍 Kiểm tra và cập nhật route configuration..."
if [ -f "cvat/urls.py" ]; then
    echo "📋 Đang copy cvat/urls.py vào container..."
    if $COMPOSE_CMD cp cvat/urls.py cvat_server:/home/django/cvat/urls.py 2>/dev/null; then
        echo "✅ Đã cập nhật urls.py trong container"
        echo "🔄 Đang restart cvat_server để áp dụng thay đổi..."
        $COMPOSE_CMD restart cvat_server
        sleep 5
    else
        echo "⚠️  Không thể copy file. Có thể cần rebuild container."
    fi
fi

echo "✅ CVAT backend đã sẵn sàng!"
echo ""
echo "📝 Các bước tiếp theo:"
echo "1. Tạo superuser (nếu chưa có):"
echo "   docker compose exec cvat_server python manage.py createsuperuser"
echo ""
echo "2. Khởi động UI (trong terminal khác):"
echo "   yarn run start:cvat-ui"
echo ""
echo "3. Truy cập CVAT tại: http://localhost:8080"
echo ""
echo "⚠️  Lưu ý: Nếu code thay đổi, cần copy file vào container hoặc rebuild:"
echo "   docker compose cp cvat/urls.py cvat_server:/home/django/cvat/urls.py"
echo "   docker compose restart cvat_server"

