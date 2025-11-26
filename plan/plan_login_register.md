## Kế hoạch triển khai Đăng ký/Đăng nhập kèm hồ sơ người dùng

### Phase 1: Thiết lập Firebase Auth + Users collection
- **1.1 Bật Email/Password Auth** trong Firebase console, kiểm tra SHA1/IOS bundle nếu cần.
- **1.2 Rà soát dependencies** (`firebase_core`, `firebase_auth`, `cloud_firestore`, `provider`, v.v.).
- **1.3 Định nghĩa mô hình `AppUser`** (uid, email, displayName, photoUrl, phone, createdAt, lastLogin, role...).
- **1.4 Chuẩn bị `UserProfile` schema** cho collection `users` (bio, favoritesCount, savedTrips, preferences...).
- **1.5 Khởi tạo `AuthService` + `UserProfileService`:**
  - AuthService: `signIn`, `signUp`, `signOut`, `sendPasswordReset`, `updateDisplayName`.
  - UserProfileService: CRUD với Firestore (`users/<uid>`), đồng bộ metadata.

### Phase 2: UI/UX cho luồng Auth & Profile cơ bản
- **2.1 AuthGate/Splash**: Lắng nghe `authStateChanges()` để điều hướng Home ↔ AuthStack.
- **2.2 Màn Đăng nhập**: Email, password, “Quên mật khẩu”, chuyển sang SignUp.
- **2.3 Màn Đăng ký**: Email, password, confirm, tên hiển thị, chọn avatar mặc định.
- **2.4 Validation realtime** + hiển thị lỗi thân thiện (email không hợp lệ, mật khẩu yếu...).
- **2.5 Loading states/disable button** + toast/snackbar phản hồi.

### Phase 3: Tích hợp logic Auth & User Profile
- **3.1 Kết nối form với AuthService**, xử lý exception cụ thể (email tồn tại, wrong-password...).
- **3.2 Sau `signUp`:** tạo document `users/<uid>` với profile mặc định, timestamps.
- **3.3 Sau `signIn`:** lấy profile Firestore, cache vào `UserProvider` (ChangeNotifier).
- **3.4 Cho phép cập nhật profile cơ bản** (displayName, phone, avatar) và sync cả Auth + Firestore.
- **3.5 Forgot password / Email verification:** gọi API và hiển thị thông báo gửi mail.

### Phase 4: Bảo mật, trải nghiệm & route protection
- **4.1 Route guard:** Home, Favorites... yêu cầu user đăng nhập, nếu không → Auth screen.
- **4.2 Persist session:** lắng nghe `idTokenChanges` để refresh dữ liệu user tự động.
- **4.3 Error logging & analytics** (tùy chọn): log login/logout, thất bại, thiết bị.
- **4.4 Security rules Firestore:** chỉ cho phép user đọc/ghi document `users/<uid>` của chính họ.
- **4.5 UI polish:** animation nhẹ, state empty khi chưa có profile, dark mode nếu cần.

### Phase 5: Kiểm thử & mở rộng
- **5.1 Unit test AuthService & UserProfileService** (mock Firebase/Auth).
- **5.2 Widget test form login/register** (validation, loading).
- **5.3 Chuẩn bị  (Google/Apple/Facebook)**: cập nhật plan & dependencies.
- **5.4 Checklist bảo mật:** password policy, giới hạn retry, optional reCAPTCHA (web), bảo vệ dữ liệu nhạy cảm.

> Sau khi duyệt kế hoạch mới, mình sẽ bắt đầu Phase 1: cấu hình Firebase Auth + Users collection + service nền tảng.
