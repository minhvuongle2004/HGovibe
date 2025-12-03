# 🔐 HƯỚNG DẪN TẠO ADMIN USER

Có 2 cách để tạo admin user:

## 📋 CÁCH 1: Qua Firebase Console (Khuyến nghị)

### Bước 1: Tạo User trong Firebase Authentication

1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project `smart-travel-app-a2bfa`
3. Vào **Authentication** → **Users**
4. Click **Add user**
5. Nhập:
   - **Email**: `admin@smarttravel.app` (hoặc email bạn muốn)
   - **Password**: Mật khẩu mạnh (ít nhất 6 ký tự)
6. Click **Add user**

### Bước 2: Lấy User ID

1. Sau khi tạo user, click vào user đó
2. Copy **User UID** (ví dụ: `abc123def456...`)

### Bước 3: Thêm vào Firestore Collection `admins`

1. Vào **Firestore Database** trong Firebase Console
2. Click **Start collection** (nếu chưa có collection `admins`)
3. Collection ID: `admins`
4. Document ID: **Paste User UID** (từ bước 2)
5. Thêm các fields:

```json
{
  "userId": "abc123def456...",  // String - User UID từ bước 2
  "email": "admin@smarttravel.app",  // String - Email của admin
  "displayName": "Admin User",  // String - Tên hiển thị
  "role": "admin",  // String - Vai trò (luôn là "admin")
  "permissions": [  // Array of Strings - Danh sách quyền
    "manage_users",
    "manage_destinations",
    "manage_tours",
    "manage_bookings"
  ],
  "createdAt": "2024-01-01T00:00:00Z",  // Timestamp - Ngày tạo
  "updatedAt": "2024-01-01T00:00:00Z"   // Timestamp - Ngày cập nhật
}
```

**Kiểu dữ liệu trong Firestore:**
- `userId`: **String** (text)
- `email`: **String** (text)
- `displayName`: **String** (text)
- `role`: **String** (text) - Giá trị: "admin"
- `permissions`: **Array** (danh sách) chứa các **String**
- `createdAt`: **Timestamp** (ngày giờ) - Trong Firestore Console, chọn type "timestamp"
- `updatedAt`: **Timestamp** (ngày giờ) - Trong Firestore Console, chọn type "timestamp"

**Lưu ý khi thêm trong Firestore Console:**
- Với `permissions`: Click vào field, chọn type "array", sau đó thêm từng string vào
- Với `createdAt` và `updatedAt`: Chọn type "timestamp", sau đó chọn ngày giờ hiện tại
- Hoặc có thể để trống `createdAt` và `updatedAt`, sau đó dùng `FieldValue.serverTimestamp()` trong code

6. Click **Save**

### Bước 4: Test Login

1. Chạy admin web app: `flutter run -d chrome`
2. Đăng nhập với email và password đã tạo
3. Nếu thành công, bạn sẽ thấy Dashboard

---

## 📋 CÁCH 2: Qua Code (Development Only)

### Sử dụng Script Helper

1. Tạo file `create_admin.dart` trong `admin_web/lib/`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:admin_web/firebase_options.dart';
import 'package:admin_web/utils/create_admin_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await CreateAdminUser.createAdminUser(
    email: 'admin@smarttravel.app',
    password: 'your_secure_password',
    displayName: 'Admin User',
  );
}
```

2. Chạy script:

```bash
cd admin_web
dart run lib/create_admin.dart
```

**Lưu ý:** Cách này chỉ nên dùng trong development. Trong production, nên tạo admin user thủ công qua Firebase Console.

---

## ✅ KIỂM TRA ADMIN USER

Sau khi tạo admin user, kiểm tra:

1. **Firebase Authentication**: User có trong danh sách users
2. **Firestore**: Document trong collection `admins` với ID = User UID
3. **Login**: Có thể đăng nhập vào admin web app

---

## 🔒 SECURITY NOTES

1. **Mật khẩu mạnh**: Sử dụng mật khẩu ít nhất 12 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt
2. **Email verification**: Nên bật email verification cho admin accounts
3. **2FA**: Nên bật 2-factor authentication cho admin accounts (nếu có)
4. **Firestore Rules**: Đảm bảo Firestore security rules chỉ cho phép admin đọc collection `admins`

---

## 🆘 TROUBLESHOOTING

### Lỗi: "Bạn không có quyền truy cập admin panel"

**Nguyên nhân:** User chưa được thêm vào collection `admins`

**Giải pháp:**
1. Kiểm tra User UID trong Firebase Authentication
2. Kiểm tra có document trong Firestore collection `admins` với ID = User UID
3. Đảm bảo field `role` = "admin"

### Lỗi: "Email không hợp lệ" hoặc "Mật khẩu quá yếu"

**Giải pháp:**
- Email phải đúng format (có @)
- Password phải ít nhất 6 ký tự

### Lỗi: "User already exists"

**Giải pháp:**
- User đã tồn tại trong Firebase Authentication
- Chỉ cần thêm vào collection `admins` (Cách 1, Bước 3)

---

## 📝 TEMPLATE FIRESTORE DOCUMENT

### Cấu trúc dữ liệu:

```json
{
  "userId": "USER_UID_HERE",           // String
  "email": "admin@smarttravel.app",     // String
  "displayName": "Admin User",          // String
  "role": "admin",                      // String
  "permissions": [                      // Array of Strings
    "manage_users",
    "manage_destinations",
    "manage_tours",
    "manage_bookings"
  ],
  "createdAt": "2024-01-01T00:00:00Z",  // Timestamp
  "updatedAt": "2024-01-01T00:00:00Z"   // Timestamp
}
```

### Hướng dẫn thêm trong Firestore Console:

1. **userId** (String):
   - Type: `string`
   - Value: Paste User UID từ Firebase Authentication

2. **email** (String):
   - Type: `string`
   - Value: Email của admin

3. **displayName** (String):
   - Type: `string`
   - Value: Tên hiển thị

4. **role** (String):
   - Type: `string`
   - Value: `admin`

5. **permissions** (Array):
   - Type: `array`
   - Thêm từng item:
     - Item 1: `manage_users` (type: string)
     - Item 2: `manage_destinations` (type: string)
     - Item 3: `manage_tours` (type: string)
     - Item 4: `manage_bookings` (type: string)

6. **createdAt** (Timestamp):
   - Type: `timestamp`
   - Value: Chọn ngày giờ hiện tại (hoặc để trống, sẽ tự động set)

7. **updatedAt** (Timestamp):
   - Type: `timestamp`
   - Value: Chọn ngày giờ hiện tại (hoặc để trống, sẽ tự động set)

---

**Sau khi tạo admin user, bạn có thể đăng nhập vào admin web app!** 🎉

