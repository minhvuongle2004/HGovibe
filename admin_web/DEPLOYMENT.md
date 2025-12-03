# 🚀 Deploy Admin Web – Smart Travel App

Tài liệu này mô tả toàn bộ quy trình build & deploy bản Flutter Web lên Firebase Hosting.

---

## 0. Yêu cầu

- Flutter SDK (≥ 3.24) và Dart SDK.
- Firebase CLI (`npm install -g firebase-tools`).
- Truy cập Firebase project đang dùng cho Smart Travel App.
- Đã cấu hình `lib/firebase_options.dart` thông qua `flutterfire configure`.

---

## 1. Chuẩn bị Firebase Hosting

> Thực hiện **một lần** trong thư mục `admin_web/`.

```bash
cd admin_web
firebase login                # nếu chưa đăng nhập
firebase init hosting
```

Khi được hỏi:

| Câu hỏi                          | Lựa chọn khuyến nghị               |
|----------------------------------|------------------------------------|
| Use existing project?            | ✅ Chọn project đang dùng          |
| What do you want to use?         | Hosting                            |
| Public directory?                | `build/web`                        |
| Configure as SPA (rewrite)?      | ✅ Yes                              |
| Set up automatic builds?         | Tuỳ nhu cầu                        |

Firebase CLI sẽ tạo `firebase.json` và `.firebaserc`. Nếu không, tham khảo cấu hình mẫu:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

---

## 2. Build production

```bash
cd admin_web
flutter clean
flutter pub get
flutter build web --release --base-href "/"
```

Kết quả nằm ở `build/web`.

**Tips**
- Kiểm tra lại `web/index.html` và `web/manifest.json` → meta tags, mô tả, theme color.
- Đảm bảo asset (icons, favicon) đúng đường dẫn.

---

## 3. Test build cục bộ

```bash
cd build/web
python -m http.server 8080
# hoặc
npx serve .
```

Truy cập `http://127.0.0.1:8080` kiểm tra nhanh trước khi deploy.

---

## 4. Deploy Firebase Hosting

```bash
cd admin_web
flutter build web --release    # build lại nếu cần
firebase deploy --only hosting
```

Nếu muốn preview trước khi “production release”:

```bash
firebase hosting:channel:deploy staging
```

Firebase trả về URL tạm dạng `https://staging-project-id.web.app`.

---

## 5. Custom domain (tuỳ chọn)

1. Trong Firebase Console → Hosting → Add custom domain.
2. Nhập domain (ví dụ `admin.smarttravel.app`).
3. Cấu hình DNS record (Firebase cung cấp).
4. Firebase tự bật HTTPS/SSL sau khi xác thực DNS.

---

## 6. Kiểm thử sau deploy

Checklist nhanh:

- [ ] Login + check quyền admin.
- [ ] Dashboard stream đúng số liệu.
- [ ] Users / Destinations / Tours / Bookings → CRUD + action quan trọng.
- [ ] Upload ảnh (ImgBB) / xoá ảnh (UI).
- [ ] Responsive ≥ 1280px (desktop) và ~1024px (tablet).
- [ ] Error state, loading state hoạt động.

Nếu phát hiện lỗi:
1. Fix code.
2. `flutter build web --release`.
3. `firebase deploy --only hosting`.

---

## 7. Tài liệu tham khảo

- [Flutter Web deployment](https://docs.flutter.dev/platform-integration/web)
- [Firebase Hosting docs](https://firebase.google.com/docs/hosting)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli)

---

> **Ghi chú**: Nếu cần CI/CD (VD: Github Actions), có thể script: `flutter build web --release` → upload artifact → `firebase deploy`. Tài liệu này tập trung vào manual workflow để dễ kiểm soát trong giai đoạn đầu.

