# Hướng dẫn cấu hình VNPay cho Smart Travel App

## 📋 Tổng quan

Sau khi code đã được chuyển đổi từ MoMo sang VNPay, bạn cần thực hiện các bước cấu hình sau để hệ thống thanh toán hoạt động.

---

## 🔧 Bước 1: Đăng ký tài khoản VNPay Sandbox

### 1.1. Đăng ký tài khoản
- Truy cập: https://sandbox.vnpayment.vn/
- Đăng ký tài khoản merchant sandbox (miễn phí)
- Xác thực email và hoàn tất đăng ký

### 1.2. Lấy thông tin credentials
Sau khi đăng nhập, bạn sẽ có:
- **Terminal Code (TmnCode)**: Ví dụ: `2QXUI4J4`
- **Hash Secret**: Ví dụ: `RAOCTKRKRJDJIEJSCQJXJXAOILDTLBZ`
- **URL Sandbox**: `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html` (đã có sẵn)

**Lưu ý**: Lưu lại 2 thông tin này (TmnCode và HashSecret) để dùng ở bước tiếp theo.

---

## 🔧 Bước 2: Cấu hình Cloud Functions

### 2.1. Cài đặt Firebase CLI (nếu chưa có)
```bash
npm install -g firebase-tools
```

### 2.2. Đăng nhập Firebase
```bash
firebase login
```

### 2.3. Cấu hình credentials VNPay vào Cloud Functions

**Trên Windows (PowerShell):**
```powershell
cd functions
firebase functions:config:set `
  vnpay.tmncode="LWG0SW3Z" `
  vnpay.hashsecret="AXMIOWI7UVM1WQHH59VN6Z5UV6ZFA4TS" `
  vnpay.payurl="https://sandbox.vnpayment.vn/paymentv2/vpcpay.html" `
  vnpay.returnurl="https://your-domain.com/payment/return" `
  vnpay.ipnurl="https://asia-southeast1-smart-travel-app-a2bfa.cloudfunctions.net/vnpayWebhook"
```

**Trên Mac/Linux:**
```bash
cd functions
firebase functions:config:set \
  vnpay.tmncode="VNP_TMNCODE_CUA_BAN" \
  vnpay.hashsecret="VNP_HASHSECRET_CUA_BAN" \
  vnpay.payurl="https://sandbox.vnpayment.vn/paymentv2/vpcpay.html" \
  vnpay.returnurl="https://your-domain.com/payment/return" \
  vnpay.ipnurl="https://asia-southeast1-smart-travel-app-a2bfa.cloudfunctions.net/vnpayWebhook"
```

**Giải thích:**
- `vnpay.tmncode`: Thay bằng Terminal Code bạn lấy từ VNPay
- `vnpay.hashsecret`: Thay bằng Hash Secret bạn lấy từ VNPay
- `vnpay.payurl`: URL sandbox của VNPay (giữ nguyên)
- `vnpay.returnurl`: URL mà VNPay sẽ redirect về sau khi thanh toán (bạn tự định nghĩa)
- `vnpay.ipnurl`: URL webhook để VNPay gọi lại (đã có sẵn theo project ID của bạn)

### 2.4. Upgrade Firebase Plan (BẮT BUỘC)

**⚠️ QUAN TRỌNG**: Cloud Functions yêu cầu Firebase Blaze plan (pay-as-you-go). Spark plan (free) không hỗ trợ.

**Cách upgrade:**
1. Truy cập: https://console.firebase.google.com/project/smart-travel-app-a2bfa/usage/details
2. Hoặc click vào link trong lỗi: `https://console.firebase.google.com/project/smart-travel-app-a2bfa/usage/details`
3. Click **"Upgrade to Blaze"** hoặc **"Upgrade project"**
4. Thêm phương thức thanh toán (thẻ tín dụng/ghi nợ)
5. Xác nhận upgrade

**Lưu ý về chi phí:**
- Blaze plan có **free tier rộng rãi** cho development:
  - 2 triệu invocations/tháng miễn phí
  - 400,000 GB-seconds compute time/tháng miễn phí
  - 5 GB egress/tháng miễn phí
- Chỉ tính phí khi vượt quá free tier
- Với app test/sandbox, thường sẽ **không mất phí** hoặc rất ít
- Có thể set budget alerts để tránh chi phí bất ngờ

**Sau khi upgrade xong**, quay lại bước 2.5 để deploy.

### 2.5. Build và deploy Cloud Functions

**Trên Windows (PowerShell):**
```powershell
cd functions
npm run build
firebase deploy --only "functions"
```

**Trên Mac/Linux:**
```bash
cd functions
npm run build
firebase deploy --only functions
```

**Lưu ý**: 
- Trên PowerShell, phải dùng dấu ngoặc kép `"functions"` thay vì `functions`.
- Nếu vẫn báo lỗi về plan, đợi vài phút sau khi upgrade rồi thử lại.

**Kiểm tra deploy thành công:**
- Truy cập Firebase Console → Functions
- Bạn sẽ thấy 2 functions: `createVnPayPayment` và `vnpayWebhook`
- Copy URL của `vnpayWebhook` để dùng ở bước tiếp theo

---

## 🔧 Bước 3: Cấu hình VNPay Portal

### 3.1. Đăng nhập VNPay Sandbox Portal
- Truy cập: https://sandbox.vnpayment.vn/
- Đăng nhập với tài khoản đã đăng ký

### 3.2. Cấu hình IPN URL (Webhook)
- Vào phần **Cấu hình** hoặc **Settings**
- Tìm mục **IPN URL** hoặc **Callback URL**
- Nhập URL webhook bạn đã deploy:
  ```
  https://asia-southeast1-smart-travel-app-a2bfa.cloudfunctions.net/vnpayWebhook
  ```
- Lưu lại

### 3.3. Cấu hình Return URL (nếu cần)
- Tìm mục **Return URL** hoặc **Redirect URL**
- Nhập URL mà bạn muốn VNPay redirect về sau khi thanh toán
- Ví dụ: `https://your-domain.com/payment/return`
- **Lưu ý**: URL này phải khớp với `vnpay.returnurl` bạn đã cấu hình ở bước 2.3

---

## 🔧 Bước 4: Cập nhật PaymentConfig trong app

### 4.1. Mở file `lib/config/payments/payment_config.dart`

### 4.2. Cập nhật `cloudFunctionBaseUrl`
Thay đổi dòng 10-11:
```dart
static const String cloudFunctionBaseUrl =
    'https://asia-southeast1-smart-travel-app-a2bfa.cloudfunctions.net';
```

**Giải thích**: 
- `asia-southeast1` là region (giữ nguyên)
- `smart-travel-app-a2bfa` là project ID của bạn (đã đúng)

### 4.3. Cập nhật `vnpayReturnUrl`
Thay đổi dòng 16-17:
```dart
static const String vnpayReturnUrl =
    'https://your-domain.com/payment/return';
```

**Lưu ý**: 
- Thay `your-domain.com` bằng domain thật của bạn
- Hoặc nếu chưa có domain, có thể dùng một URL tạm thời (nhưng phải khớp với cấu hình ở bước 2.3 và 3.3)

### 4.4. Lưu file và rebuild app
```bash
flutter pub get
flutter run
```

---

## 🔧 Bước 5: Kiểm thử

### 5.1. Test tạo payment request
1. Mở app, đặt một tour
2. Chọn phương thức thanh toán "VNPay"
3. Nhấn "Thanh toán qua VNPay"
4. Kiểm tra:
   - App có mở trình duyệt/webview với URL VNPay không?
   - URL có chứa các tham số `vnp_*` không?

### 5.2. Test thanh toán sandbox
1. Trên trang VNPay, sử dụng thẻ test:
   - **Ngân hàng**: NCB
   - **Số thẻ**: `9704198526191432198`
   - **Tên chủ thẻ**: `NGUYEN VAN A`
   - **Ngày hết hạn**: `07/15`
   - **OTP**: `123456`
2. Hoàn tất thanh toán
3. Kiểm tra:
   - VNPay có redirect về `returnUrl` không?
   - Firestore có cập nhật `paymentStatus = paid` không?
   - Booking có được auto-confirm không?

### 5.3. Kiểm tra webhook
1. Vào Firebase Console → Functions → Logs
2. Tìm log của `vnpayWebhook`
3. Kiểm tra:
   - Webhook có nhận được callback từ VNPay không?
   - Chữ ký có được verify thành công không?
   - Firestore có được update đúng không?

---

## ⚠️ Lưu ý quan trọng

### 1. Bảo mật
- **KHÔNG** commit credentials vào Git
- `vnpay.hashsecret` chỉ lưu trong Firebase Functions config
- Sử dụng environment variables cho production

### 2. Production
Khi chuyển sang production:
- Đăng ký tài khoản VNPay production (có phí)
- Cập nhật `vnpay.payurl` thành: `https://www.vnpayment.vn/paymentv2/vpcpay.html`
- Cập nhật credentials mới
- Test kỹ trước khi go-live

### 3. Return URL
- Return URL phải là HTTPS
- Nếu chưa có domain, có thể dùng Firebase Hosting tạm thời
- Hoặc tạo một trang web đơn giản để hiển thị kết quả thanh toán

---

## 📝 Checklist

- [ ] Đăng ký tài khoản VNPay Sandbox
- [ ] Lấy TmnCode và HashSecret
- [ ] **Upgrade Firebase project lên Blaze plan** (nếu chưa có)
- [ ] Cấu hình Firebase Functions config
- [ ] Deploy Cloud Functions
- [ ] Cấu hình IPN URL trên VNPay Portal
- [ ] Cấu hình Return URL trên VNPay Portal
- [ ] Cập nhật `PaymentConfig.cloudFunctionBaseUrl`
- [ ] Cập nhật `PaymentConfig.vnpayReturnUrl`
- [ ] Test tạo payment request
- [ ] Test thanh toán sandbox
- [ ] Kiểm tra webhook hoạt động

---

## 🆘 Xử lý lỗi thường gặp

### Lỗi: "Your project must be on the Blaze (pay-as-you-go) plan"
- **Nguyên nhân**: Firebase project đang ở Spark plan (free), Cloud Functions yêu cầu Blaze plan
- **Giải pháp**: 
  1. Truy cập: https://console.firebase.google.com/project/smart-travel-app-a2bfa/usage/details
  2. Click **"Upgrade to Blaze"**
  3. Thêm phương thức thanh toán
  4. Đợi vài phút sau khi upgrade, rồi chạy lại `firebase deploy --only "functions"`
- **Lưu ý**: Blaze plan có free tier rộng rãi, thường không mất phí cho development

### Lỗi: "VNPay credentials are not configured"
- **Nguyên nhân**: Chưa cấu hình `vnpay.tmncode` hoặc `vnpay.hashsecret`
- **Giải pháp**: Chạy lại lệnh `firebase functions:config:set` ở bước 2.3

### Lỗi: "Invalid signature" từ webhook
- **Nguyên nhân**: HashSecret không đúng hoặc format chữ ký sai
- **Giải pháp**: Kiểm tra lại HashSecret và đảm bảo đã deploy lại functions sau khi cấu hình

### Lỗi: Không mở được trang thanh toán VNPay
- **Nguyên nhân**: URL không đúng hoặc thiếu tham số
- **Giải pháp**: Kiểm tra log của `createVnPayPayment` trong Firebase Console

### Lỗi: Webhook không nhận được callback
- **Nguyên nhân**: IPN URL chưa được cấu hình đúng trên VNPay Portal
- **Giải pháp**: Kiểm tra lại IPN URL trong VNPay Portal và đảm bảo đã deploy functions

---

## 📞 Hỗ trợ

Nếu gặp vấn đề, kiểm tra:
1. Firebase Console → Functions → Logs
2. VNPay Sandbox Portal → Transaction History
3. Firestore → Collection `payments_logs` để xem log chi tiết

