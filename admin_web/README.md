# Admin Web Interface – Smart Travel App

Ứng dụng Flutter Web dành riêng cho admin Smart Travel App. Tất cả nghiệp vụ quản trị (dashboard, người dùng, điểm đến, tours, bookings) được gom vào một giao diện nhất quán, tối ưu cho desktop.

## 🎯 Tính năng chính

- Đăng nhập + kiểm tra quyền admin (Firebase Auth + Firestore).
- Dashboard thống kê theo thời gian thực (users, tours, bookings, pending bookings).
- Users Management: tìm kiếm, lọc, xem chi tiết, ban/unban, soft delete.
- Destinations Management: CRUD đầy đủ, upload ảnh (ImgBB), soft delete, filter đa tiêu chí.
- Tours Management: danh sách + filters, form nhiều tab (basic info, images, giá, lịch trình, chính sách), activate/deactivate, đánh dấu sold-out, duplicate.
- Bookings Management: tabs theo trạng thái, search/filter nâng cao, badge realtime pending, chi tiết booking với timeline và các action (confirm, cancel, complete, ghi chú admin).

## 🧱 Kiến trúc & công nghệ

- **Flutter 3.x** + **Material 3** cho UI.
- **GoRouter** để routing (ShellRoute giữ sidebar/header).
- **Firebase**: Auth, Firestore (real-time stats & CRUD).
- **Provider** + service layer (AdminUserService, AdminDestinationService, …).
- **Intl**, **file_picker**, **http/ImgBB**…

## ⚙️ Chuẩn bị môi trường

1. Cài Flutter (stable channel) & Dart SDK.
2. Tạo Firebase project, bật Authentication + Firestore.
3. Tải file cấu hình về `lib/firebase_options.dart` (đã có trong repo mẫu).
4. Tạo admin user theo hướng dẫn trong [`CREATE_ADMIN_USER.md`](CREATE_ADMIN_USER.md).

## 🚀 Chạy development

```bash
cd admin_web
flutter pub get
flutter run -d chrome
```

Hoặc chạy web server độc lập:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5000
```

## 🧪 Build nhanh

```bash
flutter build web --release
```

Output nằm tại `build/web`. Có thể serve bằng `flutter run -d web-server` hoặc bất kỳ static server nào.

## 🌐 Build & Deploy Production

- Chuẩn bị meta tags + manifest (đã cập nhật trong `web/`).
- Thực hiện các bước cấu hình Firebase Hosting, build và deploy.  
- Chi tiết từng bước (Firebase CLI, cấu trúc `firebase.json`, kiểm thử sau deploy) nằm tại [`DEPLOYMENT.md`](DEPLOYMENT.md).

## 📁 Cấu trúc thư mục

```
admin_web/
├── lib/
│   ├── main.dart                # Entry point + GoRouter
│   ├── firebase_options.dart    # Firebase config
│   ├── screens/
│   │   ├── auth/                # Login
│   │   ├── dashboard/           # Dashboard + widgets
│   │   ├── users/               # UsersScreen + detail
│   │   ├── destinations/        # DestinationsScreen + form
│   │   ├── tours/               # ToursScreen + form
│   │   └── bookings/            # Bookings list + detail
│   ├── services/                # Admin services (users, tours…)
│   ├── models/                  # Shared models
│   └── widgets/                 # Layout, common components
├── web/                         # index.html, manifest, icons
└── docs (.md)                   # Hướng dẫn ImgBB, Storage, Deploy…
```

## 🔐 Authentication & phân quyền

1. Đăng ký user trong Firebase Authentication.
2. Tạo document tương ứng trong `admins/{uid}` theo template trong [`CREATE_ADMIN_USER.md`](CREATE_ADMIN_USER.md).
3. Ứng dụng luôn kiểm tra quyền admin trước khi truy cập ShellRoute.

## 🔗 Tài liệu liên quan

- [Kế hoạch triển khai chi tiết](../plan/plan_phase8_admin_web_implementation.md)
- [Tài liệu storage và upload ảnh](IMGBB_SETUP.md)
- [Hướng dẫn tạo admin user](CREATE_ADMIN_USER.md)
- [Build & Deploy](DEPLOYMENT.md)
