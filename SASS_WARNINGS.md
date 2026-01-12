# Giải thích về Sass Deprecation Warnings

## Vấn đề

Khi chạy `yarn run start:cvat-ui`, bạn thấy nhiều warnings:
- `Deprecation Warning [import]: Sass @import rules are deprecated`
- `Deprecation Warning [legacy-js-api]: The legacy JS API is deprecated`

## Đây KHÔNG phải là lỗi

✅ **UI vẫn hoạt động bình thường!** 

Các warnings này chỉ là cảnh báo về code cũ trong CVAT codebase. Chúng không ảnh hưởng đến chức năng.

## Giải thích

1. **Sass @import deprecated**: Sass khuyến nghị dùng `@use` thay vì `@import` (từ Dart Sass 2.0.0)
2. **Legacy JS API deprecated**: Sass đang chuyển sang API mới

Đây là warnings từ codebase CVAT gốc, không phải do code của chúng ta.

## Cách xử lý

### Option 1: Bỏ qua (Khuyến nghị)
Warnings này không ảnh hưởng đến chức năng. Bạn có thể bỏ qua chúng.

### Option 2: Suppress warnings trong webpack

Thêm vào `cvat-ui/webpack.config.js`:

```javascript
// Trong phần sass-loader config
{
    loader: 'sass-loader',
    options: {
        sassOptions: {
            quietDeps: true, // Suppress deprecation warnings
            silenceDeprecations: ['legacy-js-api', 'import'],
        },
    },
}
```

### Option 3: Update CVAT codebase (Không khuyến nghị)
Cần migrate toàn bộ codebase từ `@import` sang `@use` - công việc lớn và không cần thiết.

## Kiểm tra UI hoạt động

```bash
# UI đang chạy tại:
http://localhost:3000

# Kiểm tra:
curl http://localhost:3000
```

Nếu UI load được, mọi thứ đều ổn! ✅

## Kết luận

**Bạn có thể bỏ qua các warnings này.** Chúng chỉ là cảnh báo về code cũ, không phải lỗi. UI vẫn hoạt động hoàn toàn bình thường.

