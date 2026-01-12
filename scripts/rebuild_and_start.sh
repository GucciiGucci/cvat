#!/bin/bash

# Script để rebuild CVAT server với code mới

set -e

echo "🔨 Rebuilding CVAT server với code mới..."

cd "$(dirname "$0")/.."

# Sử dụng docker compose (mới) hoặc docker-compose (cũ)
COMPOSE_CMD="docker compose"
if ! $COMPOSE_CMD version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
fi

echo "📦 Đang rebuild cvat_server image..."
$COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml build cvat_server

echo "🔄 Đang restart cvat_server..."
$COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml up -d cvat_server

echo "⏳ Đợi server sẵn sàng..."
sleep 10

echo "✅ Đã rebuild và restart thành công!"
echo ""
echo "📝 Bây giờ có thể chạy migrations chung (nếu cần):"
echo "   docker compose exec cvat_server python manage.py migrate"

