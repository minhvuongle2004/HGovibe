# 🖼️ Hướng dẫn Setup ImgBB (Thay thế Firebase Storage)

## 📋 Tại sao chọn ImgBB?

- ✅ **Hoàn toàn miễn phí** - không cần thẻ tín dụng
- ✅ **Không cần upgrade Firebase plan**
- ✅ **Đơn giản** - chỉ cần API key
- ✅ **Không giới hạn** (theo lý thuyết)

---

## 🚀 Các bước Setup

### **Bước 1: Lấy API Key**

**Option A: Dùng Public Key (Nhanh nhất)**
- Không cần đăng ký
- Có thể bị rate limit nếu dùng nhiều
- Vào: https://api.imgbb.com/
- Copy public key

**Option B: Đăng ký tài khoản (Khuyến nghị)**
1. Vào https://imgbb.com/
2. Click **"Sign Up"** (miễn phí)
3. Đăng ký bằng email
4. Vào https://api.imgbb.com/
5. Click **"Get API Key"**
6. Copy API key

### **Bước 2: Cấu hình API Key**

Có 2 cách:

#### **Cách 1: Hardcode (Nhanh, cho development)**
Mở file `admin_web/lib/services/storage/imgbb_upload_service.dart`:
```dart
String _apiKey = 'YOUR_API_KEY_HERE'; // Thay bằng API key thật
```

#### **Cách 2: Environment Variable (Khuyến nghị cho production)**
1. Tạo file `.env` trong `admin_web/`:
```
IMGBB_API_KEY=your_api_key_here
```

2. Thêm package `flutter_dotenv`:
```yaml
dependencies:
  flutter_dotenv: ^5.0.2
```

3. Load trong `main.dart`:
```dart
await dotenv.load(fileName: ".env");
final apiKey = dotenv.env['IMGBB_API_KEY'] ?? '';
ImgBBUploadService.instance.setApiKey(apiKey);
```

---

## 🧪 Test Upload

1. Mở Admin Web Interface
2. Vào **Destinations** → **Thêm mới**
3. Click **"Chọn hình ảnh"**
4. Chọn images
5. Xem upload progress
6. Kiểm tra images hiển thị đúng không

---

## ⚠️ Lưu ý

### **Rate Limits**
- Public key: Có thể bị rate limit
- Registered key: Ít bị rate limit hơn

### **Delete Images**
- ImgBB **không hỗ trợ delete qua API công khai**
- Có thể delete thủ công tại https://imgbb.com/
- Hoặc bỏ qua nếu không quan trọng (images sẽ tự expire sau một thời gian)

### **Image Size**
- Max file size: **32MB** (đủ lớn cho hầu hết images)
- Nên compress images trước khi upload để tăng tốc độ

---

## 🔄 Switch từ Firebase Storage sang ImgBB

Đã update code để dùng `ImgBBUploadService` thay vì `ImageUploadService`.

Nếu muốn switch lại Firebase Storage sau này:
1. Enable Storage trong Firebase Console
2. Thay `ImgBBUploadService` → `ImageUploadService` trong `destination_form_screen.dart`

---

## 📝 Next Steps

1. ✅ Lấy API key từ https://api.imgbb.com/
2. ✅ Update `_apiKey` trong `imgbb_upload_service.dart`
3. ✅ Test upload images
4. ✅ Kiểm tra images hiển thị đúng

---

## 🔗 Tài liệu tham khảo

- [ImgBB API Documentation](https://api.imgbb.com/)
- [ImgBB Website](https://imgbb.com/)

