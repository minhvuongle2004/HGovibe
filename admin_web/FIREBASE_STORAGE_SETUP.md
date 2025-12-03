# 🔥 Hướng dẫn Setup Firebase Storage

## 📋 Yêu cầu

Firebase Storage cần được **enable** và **cấu hình** trong Firebase Console trước khi có thể upload images.

---

## 🚀 Các bước Setup

### **Bước 1: Enable Firebase Storage**

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn: **smart-travel-app**
3. Vào **Storage** ở menu bên trái
4. Click **"Get started"** hoặc **"Create bucket"**
5. Chọn **"Start in test mode"** (hoặc **"Start in production mode"** nếu muốn cấu hình rules ngay)
6. Chọn location cho Storage bucket (ví dụ: `asia-southeast1` - Singapore)
7. Click **"Done"**

### **Bước 2: Cấu hình Security Rules**

Sau khi enable Storage, cần cấu hình Security Rules để cho phép upload/download:

1. Vào **Storage** → **Rules** tab
2. Cập nhật rules như sau:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Cho phép admin upload/delete images trong destinations folder
    match /destinations/{allPaths=**} {
      // Chỉ cho phép authenticated users (admin)
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.resource.size < 5 * 1024 * 1024 // Max 5MB
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Cho phép public read cho images (để hiển thị trên app)
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **"Publish"** để lưu rules

### **Bước 3: Kiểm tra Storage Bucket**

1. Vào **Storage** → **Files** tab
2. Bạn sẽ thấy bucket đã được tạo
3. Cấu trúc sẽ là:
   ```
   destinations/
     └── {destinationId}/
         └── {image_name}.jpg
   ```

---

## ⚠️ Lưu ý

### **Test Mode vs Production Mode**

- **Test Mode**: Cho phép read/write trong 30 ngày (chỉ dùng cho development)
- **Production Mode**: Cần cấu hình rules ngay (khuyến nghị cho production)

### **Security Rules**

Rules trên cho phép:
- ✅ Authenticated users (admin) có thể upload/delete
- ✅ Public có thể read images (để hiển thị trên app)
- ✅ Giới hạn file size: 5MB
- ✅ Chỉ cho phép image files

### **Storage Location**

Chọn location gần với users của bạn:
- `asia-southeast1` (Singapore) - Tốt cho Việt Nam
- `asia-east1` (Taiwan)
- `us-central1` (Iowa) - Default

---

## 🧪 Test Storage

Sau khi setup xong, bạn có thể test bằng cách:

1. Mở Admin Web Interface
2. Vào **Destinations** → **Thêm mới**
3. Click **"Chọn hình ảnh"**
4. Chọn một vài images
5. Xem upload progress
6. Kiểm tra Firebase Console → Storage → Files để thấy images đã upload

---

## ❌ Nếu gặp lỗi

### **Lỗi: "Permission denied"**
- Kiểm tra Security Rules đã publish chưa
- Kiểm tra user đã login chưa
- Kiểm tra rules có cho phép write không

### **Lỗi: "Bucket not found"**
- Kiểm tra Storage đã enable chưa
- Kiểm tra `firebase_options.dart` có đúng storageBucket không

### **Lỗi: "File too large"**
- Giảm size của image (max 5MB theo rules)
- Hoặc tăng limit trong rules

---

## 📝 Next Steps

Sau khi setup xong:
1. ✅ Test upload images trong Destination Form
2. ✅ Kiểm tra images hiển thị đúng không
3. ✅ Test delete images
4. ✅ Test set thumbnail

---

## 🔗 Tài liệu tham khảo

- [Firebase Storage Documentation](https://firebase.google.com/docs/storage)
- [Firebase Storage Security Rules](https://firebase.google.com/docs/storage/security)
- [Flutter Firebase Storage](https://firebase.flutter.dev/docs/storage/overview)

