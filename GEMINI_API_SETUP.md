# Hướng dẫn Setup Gemini API

## Vấn đề: API trả về lỗi 404 "model not found"

Nếu bạn gặp lỗi này, có thể do các nguyên nhân sau:

## 1. Enable Generative Language API

**Bước 1:** Vào Google Cloud Console
- Truy cập: https://console.cloud.google.com/
- Chọn project của bạn (hoặc tạo project mới)

**Bước 2:** Enable API
- Vào **APIs & Services** > **Library**
- Tìm kiếm: **"Generative Language API"**
- Click **Enable**

## 2. Kiểm tra API Key Restrictions

**Bước 1:** Vào Google AI Studio
- Truy cập: https://aistudio.google.com/api-keys
- Chọn API key của bạn

**Bước 2:** Kiểm tra restrictions
- Nếu có **Application restrictions**: Đảm bảo cho phép từ app của bạn
- Nếu có **API restrictions**: Đảm bảo **Generative Language API** được cho phép
- Hoặc tạm thời bỏ restrictions để test

## 3. Setup Billing (nếu cần)

Một số models yêu cầu billing:
- Vào Google Cloud Console > **Billing**
- Link credit card (có thể dùng free tier)
- Free tier thường đủ cho development

## 4. Models Available (Updated 2024)

Google đã đổi tên models. Code sẽ tự động thử:
- `gemini-1.5-flash-001` (thay thế cho `gemini-1.5-flash`)
- `gemini-1.5-pro-001` (thay thế cho `gemini-1.5-pro`)

**Lưu ý:** Các models cũ đã bị xóa:
- ❌ `gemini-pro` - Đã bị xóa
- ❌ `gemini-1.0-pro` - Đã bị xóa
- ❌ `gemini-1.5-flash-latest` - Đã bỏ
- ❌ `gemini-1.5-pro-latest` - Đã bỏ

## 5. Test API Key

Bạn có thể test API key bằng cách:
1. Vào Google AI Studio: https://aistudio.google.com/
2. Tạo một prompt test
3. Nếu hoạt động ở đây nhưng không hoạt động trong app → có thể do restrictions

## 6. Alternative: Sử dụng Fallback

Nếu không thể fix API, app sẽ tự động dùng **fallback estimation** (công thức chuẩn) vẫn hoạt động tốt và tạo kế hoạch đi chơi theo ngày.

## Troubleshooting

### Lỗi 404 "model not found"
- ✅ Enable Generative Language API
- ✅ Check API key restrictions
- ✅ Thử API key khác

### Lỗi 403 "Permission denied"
- ✅ Check API key có quyền truy cập Generative Language API
- ✅ Check billing đã setup chưa

### Lỗi 429 "Quota exceeded"
- ✅ Check quota limits trong Google Cloud Console
- ✅ Setup billing để tăng quota

## Liên kết hữu ích

- Google AI Studio: https://aistudio.google.com/
- API Documentation: https://ai.google.dev/gemini-api/docs
- Google Cloud Console: https://console.cloud.google.com/

