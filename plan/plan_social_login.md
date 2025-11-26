## Kế hoạch triển khai Social Login (Google/Apple/Facebook)

### Phase S1: Chuẩn bị hạ tầng & cấu hình Firebase
- **S1.1** Tạo OAuth Client trên Google Cloud Console, Apple Developer, Facebook Developer → lấy Client ID/Secret.
- **S1.2** Cấu hình trong Firebase Console (Authentication → Sign-in Method) cho từng provider, thiết lập callback URI, whitelist domain.
- **S1.3** Bổ sung dependencies cần thiết:
  - `google_sign_in`, `sign_in_with_apple`, `flutter_facebook_auth` (hoặc SDK tương đương).
  - Xử lý cấu hình platform-specific (Android SHA-1/ SHA-256, iOS bundle ID + capability Sign in with Apple).

### Phase S2: Kiến trúc code & service layer
- **S2.1** Mở rộng `AuthService`:
  - Thêm method `signInWithGoogle()`, `signInWithApple()`, `signInWithFacebook()`.
  - Hỗ trợ link/unlink provider (nếu người dùng đăng ký email trước).
- **S2.2** Chuẩn hóa `AppUser` để lưu thông tin provider (list providerIds, photoUrl, emailVerified…).
- **S2.3** Đồng bộ UserProfile (nếu social login lần đầu → tạo profile; nếu đã có → cập nhật avatar, tên hiển thị).
- **S2.4** Logging & error mapping cho từng provider (popup closed, account-exists-with-different-credential, network…).

### Phase S3: UI/UX tích hợp Social Buttons
- **S3.1** Cập nhật `AuthSocialButtons`:
  - Icon/brand chuẩn Google/Apple/Facebook.
  - Trạng thái loading riêng cho từng provider.
- **S3.2** Flow đăng ký/đăng nhập kết hợp:
  - Nếu email đã tồn tại với password → hiển thị hướng dẫn liên kết tài khoản.
  - Snackbar/toast thông báo thành công/thất bại rõ ràng.
- **S3.3** Cập nhật màn Account:
  - Hiển thị provider đang liên kết, nút “Liên kết thêm” hoặc “Hủy liên kết”.
  - Cảnh báo khi unlink provider cuối cùng (phải đặt password dự phòng).

### Phase S4: Kiểm thử & bảo mật
- **S4.1** Unit test/mock social auth flows (mô phỏng credential trả về, xử lý lỗi).
- **S4.2** Test widget/UI: đảm bảo nút social login disable khi loading, toast message chính xác.
- **S4.3** Checklist bảo mật:
  - Apple: bắt buộc Sign in with Apple trên iOS nếu hỗ trợ social khác.
  - Facebook: kiểm tra quyền public_profile/email.
  - Google: verify SHA-1/ SHA-256 cho release build.
- **S4.4** QA đa nền tảng: Android/iOS/Web (nếu hỗ trợ), kiểm tra deep-link callback, xử lý khi user hủy giữa chừng.

> Sau khi phê duyệt kế hoạch Social Login, ta sẽ lần lượt thực hiện từ Phase S1 → S4. Trong lúc triển khai có thể song song chuẩn bị UI và service nhưng vẫn nên hoàn thành cấu hình (S1) trước khi test thực tế.
