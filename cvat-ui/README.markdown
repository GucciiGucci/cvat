# Hướng dẫn chạy CVAT UI Development Server với Hot Reload

Tài liệu này hướng dẫn cách chạy CVAT UI development server trên máy local với hot reload để phát triển và test code.

## 📋 Yêu cầu

- Node.js (version tương thích với project)
- Yarn package manager
- Docker và Docker Compose (để chạy backend services)
- Git

## 🚀 Các bước thiết lập

### Bước 1: Cài đặt Dependencies

Từ thư mục gốc của CVAT project, chạy lệnh sau để cài đặt tất cả dependencies:

```bash
# Enable corepack (nếu chưa enable)
corepack enable yarn

# Cài đặt dependencies cho tất cả workspaces
yarn --immutable
```

### Bước 2: Chạy Backend Services với Docker Compose

CVAT UI cần backend API để hoạt động. Chạy các backend services bằng Docker Compose:

```bash
# Chạy tất cả services trừ cvat_ui (vì chúng ta sẽ chạy UI local)
docker compose up -d --scale cvat_ui=0

# Hoặc nếu cvat_ui đã đang chạy, dừng nó:
docker compose stop cvat_ui
```

**Lưu ý:** Backend API sẽ chạy trên `http://localhost:8080` (qua traefik).

### Bước 3: Chạy UI Development Server

Từ thư mục gốc của CVAT project, chạy lệnh sau:

```bash
# Chạy UI dev server với hot reload
yarn run start:cvat-ui
```

Hoặc nếu bạn muốn chỉ định host và port khác:

```bash
CVAT_UI_HOST=localhost CVAT_UI_PORT=3000 yarn run start:cvat-ui
```

Development server sẽ:
- Chạy trên `http://localhost:3000` (mặc định)
- Tự động reload khi bạn sửa code trong `cvat-ui/src/`
- Proxy các API requests đến backend tại `http://localhost:8080`

### Bước 4: Truy cập ứng dụng

Mở browser và truy cập: **http://localhost:3000**

## 🔥 Hot Reload

Khi bạn sửa code trong thư mục `cvat-ui/src/`, webpack dev server sẽ tự động:
- Detect thay đổi
- Recompile code
- Reload browser (Hot Module Replacement)

**Ví dụ:** Sửa file `src/components/create-task-page/create-task-page.tsx`, browser sẽ tự động cập nhật mà không cần refresh thủ công.

## ⚙️ Cấu hình

### Thay đổi API URL

Nếu backend chạy trên port khác, bạn có thể override API_URL:

```bash
API_URL=http://localhost:8080 yarn run start:cvat-ui
```

### Thay đổi UI Port

Nếu port 3000 đã được sử dụng:

```bash
CVAT_UI_PORT=3001 yarn run start:cvat-ui
```

### Thay đổi UI Host

Nếu bạn muốn truy cập từ máy khác trong mạng:

```bash
CVAT_UI_HOST=0.0.0.0 CVAT_UI_PORT=3000 yarn run start:cvat-ui
```

## 🐛 Troubleshooting

### Lỗi 403 khi gọi API (CSRF Failed)

**Nguyên nhân:**
- API_URL không đúng hoặc backend chưa sẵn sàng
- **CSRF origin checking failed** - Backend không trust origin `http://localhost:3000`

**Giải pháp:**

1. **Nếu lỗi CSRF:** Backend đã được cấu hình để trust `http://localhost:3000` trong `cvat/settings/base.py`. Bạn cần restart backend container để áp dụng thay đổi:
   ```bash
   docker compose restart cvat_server
   ```

2. Kiểm tra backend có đang chạy:
   ```bash
   docker compose ps cvat_server
   ```

3. Kiểm tra API có hoạt động:
   ```bash
   curl http://localhost:8080/api/schema/
   ```

4. Đảm bảo API_URL trong script start là `http://localhost:8080`

**Lưu ý:** Nếu bạn vẫn gặp lỗi CSRF sau khi restart, có thể cần rebuild backend image:
   ```bash
   docker compose up -d --build cvat_server
   ```

### Hot reload không hoạt động

**Nguyên nhân:**
- Đang chạy container `cvat_ui` thay vì dev server local
- Webpack config chưa được cập nhật

**Giải pháp:**
1. Dừng container cvat_ui:
   ```bash
   docker compose stop cvat_ui
   ```

2. Đảm bảo bạn đang chạy dev server từ máy local, không phải trong container

3. Kiểm tra file `webpack.config.js` đã có cấu hình hot reload:
   - `hot: isDevelopment`
   - `liveReload: isDevelopment`
   - `watchFiles: isDevelopment ? ['src/**/*'] : false`

### Port đã được sử dụng

**Lỗi:** `Port 3000 is already in use`

**Giải pháp:**
```bash
# Sử dụng port khác
CVAT_UI_PORT=3001 yarn run start:cvat-ui
```

### Dependencies chưa được cài đặt

**Lỗi:** `Cannot find module` hoặc import errors

**Giải pháp:**
```bash
# Cài đặt lại dependencies
yarn --immutable
```

### Backend không kết nối được

**Lỗi:** Network errors hoặc connection refused

**Giải pháp:**
1. Kiểm tra Docker containers:
   ```bash
   docker compose ps
   ```

2. Kiểm tra logs của cvat_server:
   ```bash
   docker compose logs cvat_server
   ```

3. Đảm bảo traefik đang chạy và expose port 8080

## 📝 Scripts có sẵn

Từ thư mục gốc CVAT:

- `yarn run start:cvat-ui` - Chạy UI development server với hot reload
- `yarn run build:cvat-ui` - Build production bundle
- `yarn workspace cvat-ui run start` - Chạy từ workspace cvat-ui trực tiếp
- `yarn workspace cvat-ui run build` - Build từ workspace cvat-ui

## 🔗 Tài liệu tham khảo

- [CVAT Contributing Guide](https://docs.cvat.ai/docs/contributing/)
- [CVAT Development Environment](https://docs.cvat.ai/docs/contributing/development-environment/)
- [Webpack Dev Server Documentation](https://webpack.js.org/configuration/dev-server/)

## 💡 Tips

1. **Giữ terminal chạy dev server mở** trong khi phát triển để xem logs và errors

2. **Sử dụng browser DevTools** để debug:
   - Console để xem errors
   - Network tab để kiểm tra API calls
   - React DevTools để inspect components

3. **Type checking riêng:** Chạy type checking trong terminal riêng:
   ```bash
   yarn workspace cvat-ui run type-check:watch
   ```

4. **Linting:** Fix linting errors trước khi commit:
   ```bash
   yarn workspace cvat-ui run lint:fix
   ```

## ✅ Checklist trước khi bắt đầu

- [ ] Đã cài đặt dependencies (`yarn --immutable`)
- [ ] Backend services đang chạy (`docker compose ps`)
- [ ] Container `cvat_ui` đã được dừng
- [ ] Dev server đang chạy (`yarn run start:cvat-ui`)
- [ ] Browser mở tại `http://localhost:3000`
- [ ] Hot reload hoạt động (sửa code và xem browser tự động update)

---

**Chúc bạn code vui vẻ! 🎉**

