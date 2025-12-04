# Hướng dẫn sử dụng Backend Server thay thế Cloud Functions

## 🎯 Tại sao cần giải pháp này?

Firebase Cloud Functions yêu cầu **Blaze plan (pay-as-you-go)**, trong khi bạn không có thẻ tín dụng/ghi nợ để upgrade. 

**Giải pháp**: Tạo backend server riêng (Node.js/Express) để thay thế Cloud Functions, có thể deploy **miễn phí** trên các platform như Railway, Render, Vercel.

---

## 📋 Tổng quan

Backend server này sẽ:
- ✅ Tạo payment URL VNPay (thay thế `createVnPayPayment` Cloud Function)
- ✅ Nhận webhook từ VNPay (thay thế `vnpayWebhook` Cloud Function)
- ✅ Kết nối với Firestore để update booking
- ✅ Chạy được trên các platform miễn phí

### 🗂️ Cấu trúc dự án

Backend đã được **tách ra khỏi dự án Flutter** và đặt cùng cấp:
```
KhoaLuanTotNghiep/
  ├── smart_travel_app/          # Flutter app (repo riêng)
  └── smart_travel_backend/      # Backend server (repo riêng)
```

**Lợi ích của việc tách repo**:
- ✅ Quản lý độc lập: Update Flutter app không ảnh hưởng backend và ngược lại
- ✅ Deploy dễ dàng: Railway/Render chỉ cần connect repo backend, không cần cấu hình Root Directory
- ✅ Git history sạch: Mỗi repo có lịch sử commit riêng, dễ theo dõi
- ✅ Bảo mật tốt hơn: Có thể set quyền truy cập khác nhau cho từng repo
- ✅ Team collaboration: Backend dev và Flutter dev có thể làm việc độc lập

---

## 🚀 Bước 1: Cài đặt Backend Server

**Lưu ý**: Thư mục `backend` đã được tách ra khỏi dự án Flutter và đặt cùng cấp với `smart_travel_app` với tên `smart_travel_backend`.

### 1.1. Cài đặt dependencies
```bash
cd ../smart_travel_backend  # hoặc cd D:\voghidaihoc\KhoaLuanTotNghiep\smart_travel_backend
npm install
```

### 1.2. Tạo file `.env`

Tạo file `.env` trong thư mục `smart_travel_backend/`:

```env
# VNPay Configuration
VNPAY_TMNCODE=LWG0SW3Z
VNPAY_HASHSECRET=AXMIOWI7UVM1WQHH59VN6Z5UV6ZFA4TS
VNPAY_PAYURL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURNURL=https://your-domain.com/payment/return
VNPAY_IPNURL=http://localhost:3000/vnpayWebhook

# Server Configuration
PORT=3000
```

**Lưu ý**: 
- Thay `VNPAY_TMNCODE` và `VNPAY_HASHSECRET` bằng credentials từ VNPay của bạn
- `VNPAY_IPNURL` sẽ được cập nhật sau khi deploy (xem bước 3)

**Cấu trúc thư mục sau khi tách**:
```
KhoaLuanTotNghiep/
  ├── smart_travel_app/          # Flutter app (repo riêng)
  │   ├── lib/
  │   ├── assets/
  │   └── ...
  └── smart_travel_backend/      # Backend server (repo riêng)
      ├── server.js
      ├── package.json
      └── ...
```

### 1.3. Cấu hình Firebase

**Cách 1: Dùng Firebase CLI (khuyến nghị cho local)**
```bash
firebase login
```
Server sẽ tự động dùng credentials từ Firebase CLI.

**Cách 2: Dùng Service Account Key (cho local hoặc deploy)**
1. Vào Firebase Console: https://console.firebase.google.com/
2. Chọn project: **smart-travel-app**
3. Click **⚙️ Settings** (góc trên trái) → **Project settings**
4. Scroll xuống tab **Service accounts**
5. Click **Generate new private key** → Xác nhận
6. File JSON sẽ được tải xuống (ví dụ: `smart-travel-app-firebase-adminsdk-xxxxx.json`)
7. Đổi tên file thành `serviceAccountKey.json` (tùy chọn)
8. Di chuyển file vào thư mục `smart_travel_backend/`
9. Thêm vào `.env`:
   ```env
   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
   ```
   
   **Lưu ý**: Nếu không thấy tab "Service accounts" trong Firebase Console, xem hướng dẫn chi tiết ở **Bước 5** (phần deploy).

### 1.4. Test chạy local
```bash
npm start
```

Server sẽ chạy tại: `http://localhost:3000`

Kiểm tra:
- Health check: http://localhost:3000/health
- Nếu thấy `{"status":"ok"}` là thành công!

---

## 🌐 Bước 2: Tạo Git Repo riêng cho Backend

**Quan trọng**: Vì backend đã tách ra, bạn cần tạo repo GitHub riêng cho nó.

1. **Khởi tạo Git trong thư mục backend** (nếu chưa có):
   ```bash
   cd ../smart_travel_backend
   git init
   git add .
   git commit -m "Initial commit: Backend server for VNPay payment"
   ```

2. **Tạo repo mới trên GitHub**:
   - Vào https://github.com/new
   - Tên repo: `smart_travel_backend` (hoặc tên khác bạn muốn)
   - Chọn **Private** hoặc **Public** tùy ý
   - **KHÔNG** tích "Initialize with README" (vì đã có code rồi)

3. **Push code lên GitHub**:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/smart_travel_backend.git
   git branch -M main
   git push -u origin main
   ```

---

## 🌐 Bước 3: Deploy lên Platform miễn phí

### Option 1: Railway (Khuyến nghị - dễ nhất) ⭐

1. **Đăng ký Railway**
   - Truy cập: https://railway.app/
   - Đăng ký bằng GitHub (miễn phí)

2. **Tạo Project mới**
   - Click "New Project"
   - Chọn "Deploy from GitHub repo"
   - **Chọn repo `smart_travel_backend`** (repo riêng cho backend)

3. **Cấu hình Deploy**
   - Railway sẽ tự detect Node.js
   - **Root Directory**: Để trống (vì repo đã là backend rồi)
   - **Start Command**: `npm start`
   - **Lưu ý**: Vì backend đã tách ra repo riêng, bạn không cần set Root Directory nữa!

4. **Thêm Environment Variables**
   - Vào tab "Variables"
   - Thêm các biến sau:
     ```
     VNPAY_TMNCODE=LWG0SW3Z
     VNPAY_HASHSECRET=AXMIOWI7UVM1WQHH59VN6Z5UV6ZFA4TS
     VNPAY_PAYURL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
     VNPAY_RETURNURL=https://your-domain.com/payment/return
     PORT=3000
     ```
   - **Lưu ý**: `VNPAY_IPNURL` sẽ được set sau khi có URL deploy

5. **Cấu hình Firebase Service Account**
   
   **Cách 1: Từ Firebase Console (Khuyến nghị)**
   1. Vào Firebase Console: https://console.firebase.google.com/
   2. Chọn project của bạn: **smart-travel-app**
   3. Click vào **⚙️ Settings** (biểu tượng bánh răng) ở góc trên bên trái
   4. Chọn **Project settings**
   5. Scroll xuống và click vào tab **Service accounts** (ở dưới cùng)
   6. Bạn sẽ thấy phần "Firebase Admin SDK"
   7. Click nút **Generate new private key** (màu xanh)
   8. Xác nhận "Generate key" trong popup
   9. File JSON sẽ được tải xuống tự động
   10. Mở file JSON vừa tải, copy **toàn bộ nội dung**
   
   **Cách 2: Từ Google Cloud Console (Nếu không thấy trong Firebase)**
   1. Vào Google Cloud Console: https://console.cloud.google.com/
   2. Chọn project: **smart-travel-app** (hoặc project ID của bạn)
   3. Vào menu **☰** → **IAM & Admin** → **Service accounts**
   4. Click **+ CREATE SERVICE ACCOUNT**
   5. Điền tên: `railway-backend` (hoặc tên khác)
   6. Click **CREATE AND CONTINUE**
   7. Chọn role: **Firebase Admin SDK Administrator Service Agent** (hoặc **Editor**)
   8. Click **CONTINUE** → **DONE**
   9. Click vào service account vừa tạo
   10. Vào tab **KEYS** → **ADD KEY** → **Create new key**
   11. Chọn **JSON** → **CREATE**
   12. File JSON sẽ được tải xuống, copy toàn bộ nội dung
   
   **Thêm vào Railway:**
   - Vào Railway → Tab **Variables**
   - Click **+ New Variable**
   - **Key**: `GOOGLE_APPLICATION_CREDENTIALS`
   - **Value**: Paste **toàn bộ nội dung JSON** (bao gồm cả dấu `{` và `}`)
     - Ví dụ: `{"type":"service_account","project_id":"smart-travel-app-a2bfa",...}`
     - **Lưu ý quan trọng**: 
       - Paste JSON trên **1 dòng** hoặc Railway sẽ tự xử lý multi-line
       - Đảm bảo JSON hợp lệ (có thể test tại jsonlint.com)
       - Không cần escape quotes, Railway sẽ tự xử lý
   - Click **Add**
   - **Code đã được cập nhật** để tự động detect JSON string vs file path

6. **Deploy và lấy URL**
   - Railway sẽ tự động deploy khi bạn push code hoặc thay đổi variables
   - Đợi vài phút để deploy xong (xem progress ở tab **Deployments**)
   - Sau khi deploy thành công, lấy URL bằng cách:
     
     **⚠️ QUAN TRỌNG**: Bạn cần vào **Service Settings**, KHÔNG phải **Project Settings**!
     
     **Cách 1: Từ Service Settings (Khuyến nghị)**
     1. **Thoát khỏi Project Settings** (click X hoặc click vào tên project ở sidebar trái)
     2. Vào **service** của bạn (ví dụ: `smart-travel-backend`) - click vào tên service trong danh sách services
     3. Vào tab **Settings** của **service** (KHÔNG phải project settings)
     4. Scroll xuống phần **Networking** hoặc **Domains**
     5. Bạn sẽ thấy:
        - **Public Domain**: Nếu đã có domain
        - Hoặc nút **Generate Domain**: Nếu chưa có
     6. Click **Generate Domain** (nếu chưa có)
     7. Railway sẽ tạo URL dạng: `https://smart-travel-backend-production-xxxx.up.railway.app`
     8. Copy URL này
     
     **Cách 2: Từ trang chính của Service**
     1. Vào service của bạn (click vào tên service)
     2. Ở trang chính, bạn sẽ thấy URL hiển thị ở:
        - **Header** của service (bên cạnh tên service)
        - Hoặc trong **card** của service với label "Public URL" hoặc "Domain"
     3. Click vào URL để copy
     
     **Cách 3: Từ tab Deployments**
     1. Vào service của bạn
     2. Vào tab **Deployments**
     3. Click vào deployment mới nhất (status = "Active" hoặc "Success")
     4. Xem phần **Public URL** hoặc **Domains**
     
     **Cách 4: Từ tab Metrics**
     1. Vào service của bạn
     2. Vào tab **Metrics**
     3. URL thường hiển thị ở phần trên cùng
     
   - **Lưu ý**: 
     - URL mặc định có dạng: `https://[service-name]-[hash].up.railway.app`
     - Nếu không thấy URL, có thể service chưa deploy xong hoặc chưa generate domain
     - Bạn có thể đổi tên domain trong Service Settings → Networking → **Custom Domain** (nếu muốn)

7. **Cập nhật IPN URL**
   - Vào tab "Variables" trên Railway
   - Thêm/update:
     ```
     VNPAY_IPNURL=https://smarttravelbackend-production.up.railway.app/vnpayWebhook
     ```
   - Redeploy (Railway sẽ tự redeploy khi có thay đổi variables)

### Option 2: Render

1. Truy cập: https://render.com/
2. Đăng ký tài khoản
3. Click "New" → "Web Service"
4. Connect GitHub repo `smart_travel_backend`
5. Cấu hình:
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Environment**: `Node`
6. Thêm environment variables (giống Railway)
7. Deploy

### Option 3: Vercel

1. Truy cập: https://vercel.com/
2. Đăng ký và connect GitHub
3. Import project `smart_travel_backend`
4. Cấu hình:
   - **Root Directory**: Để trống (vì repo đã là backend rồi)
   - **Framework Preset**: `Other`
   - **Build Command**: `npm install`
5. Thêm environment variables
6. Deploy

### Option 4: Chạy local với ngrok (cho test nhanh)

1. Chạy server local:
   ```bash
   npm start
   ```

2. Cài ngrok:
   ```bash
   npm install -g ngrok
   # hoặc download từ https://ngrok.com/
   ```

3. Expose port:
   ```bash
   ngrok http 3000
   ```

4. Copy URL (ví dụ: `https://abc123.ngrok.io`)
5. Cập nhật `VNPAY_IPNURL` = `https://abc123.ngrok.io/vnpayWebhook`
6. **Lưu ý**: URL ngrok sẽ thay đổi mỗi lần restart (trừ khi dùng paid plan)

---

## 🔧 Bước 4: Cập nhật App Flutter

Sau khi deploy backend, cập nhật `lib/config/payments/payment_config.dart`:

```dart
static const String cloudFunctionBaseUrl =
    'https://smarttravelbackend-production.up.railway.app'; // URL backend của bạn
```

**Lưu ý**: 
- Bỏ `/createVnPayPayment` vì `createVnPayPaymentPath` đã có sẵn.
- URL đầy đủ sẽ là: `https://smarttravelbackend-production.up.railway.app/createVnPayPayment`

**Test backend trước khi dùng:**
1. Mở trình duyệt hoặc dùng curl:
   ```
   https://smarttravelbackend-production.up.railway.app/health
   ```
2. Nếu thấy `{"status":"ok","timestamp":"..."}` là backend đã hoạt động!

---

## 🔧 Bước 5: Cấu hình VNPay Portal

1. **Đăng nhập VNPay Sandbox Portal**: https://sandbox.vnpayment.vn/

2. **Tìm phần cấu hình IPN URL** (có thể ở một trong các vị trí sau):
   
   **Cách 1: Từ sidebar "CÔNG CỤ" (TOOLS)**
   - Ở sidebar bên trái, tìm phần **"CÔNG CỤ"** (TOOLS)
   - Click vào **"Cài đặt thông báo"** (Notification settings)
   - Tìm mục **"IPN URL"** hoặc **"Callback URL"** hoặc **"Webhook URL"**
   
   **Cách 2: Từ menu trên cùng**
   - Click vào tên merchant của bạn (ví dụ: "smart travel app") ở góc trên bên phải
   - Tìm menu **"Cài đặt"** (Settings) hoặc **"Thông tin tài khoản"** (Account Info)
   - Tìm mục **"IPN URL"** hoặc **"Callback URL"**
   
   **Cách 3: Từ trang chính**
   - Ở trang chính (Màn hình chính), tìm icon **⚙️ Settings** hoặc **"Cấu hình"**
   - Vào phần **"Thông tin merchant"** hoặc **"Cài đặt thanh toán"**
   - Tìm mục **"IPN URL"** hoặc **"Callback URL"**

3. **Nhập URL webhook**:
   ```
   https://smarttravelbackend-production.up.railway.app/vnpayWebhook
   ```

4. **Lưu lại** (click nút "Lưu" hoặc "Save")

**⚠️ Lưu ý**: 
- Nếu không tìm thấy phần cấu hình IPN URL, có thể VNPay Sandbox tự động dùng URL từ request hoặc không yêu cầu cấu hình trước
- Trong trường hợp đó, bạn có thể bỏ qua bước này và test trực tiếp
- VNPay sẽ gọi webhook đến URL bạn đã set trong biến `VNPAY_IPNURL` trên Railway

---

## ✅ Bước 6: Test

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
1. Vào Railway/Render/Vercel dashboard → Logs
2. Tìm log của webhook request
3. Kiểm tra:
   - Webhook có nhận được callback từ VNPay không?
   - Chữ ký có được verify thành công không?
   - Firestore có được update đúng không?

---

## 🆘 Troubleshooting

### Lỗi: "Firebase initialization error"
- **Giải pháp**: 
  - Đảm bảo đã login Firebase CLI: `firebase login`
  - Hoặc set `GOOGLE_APPLICATION_CREDENTIALS` với service account key

### Lỗi: "VNPay credentials not configured"
- **Giải pháp**: 
  - Kiểm tra file `.env` có đầy đủ `VNPAY_TMNCODE` và `VNPAY_HASHSECRET`
  - Trên platform deploy, kiểm tra environment variables đã được set chưa

### Webhook không nhận được callback
- **Giải pháp**: 
  - Kiểm tra `VNPAY_IPNURL` đã được cấu hình đúng trên VNPay Portal
  - Kiểm tra server có đang chạy và accessible từ internet không
  - Kiểm tra logs của server để xem có request đến không
  - Kiểm tra firewall/security settings của platform

### Server không kết nối được Firestore
- **Giải pháp**: 
  - Kiểm tra Firebase credentials (CLI hoặc service account)
  - Kiểm tra service account có quyền truy cập Firestore không
  - Kiểm tra project ID có đúng không

---

## 📝 Checklist

- [ ] Di chuyển thư mục `backend` ra ngoài thành `smart_travel_backend` ✅ (Đã hoàn thành)
- [ ] Tạo Git repo riêng cho backend trên GitHub
- [ ] Push code backend lên GitHub
- [ ] Cài đặt dependencies (`npm install`)
- [ ] Tạo file `.env` với VNPay credentials
- [ ] Cấu hình Firebase (CLI hoặc service account)
- [ ] Test chạy local (`npm start`)
- [ ] Deploy lên platform (Railway/Render/Vercel)
- [ ] Cập nhật `VNPAY_IPNURL` trên VNPay Portal
- [ ] Cập nhật `PaymentConfig.cloudFunctionBaseUrl` trong app Flutter
- [ ] Test tạo payment request
- [ ] Test webhook

---

## 💡 So sánh: Cloud Functions vs Backend Server

| Tiêu chí | Cloud Functions | Backend Server |
|----------|----------------|----------------|
| **Chi phí** | Cần Blaze plan (có free tier) | Miễn phí (Railway/Render) |
| **Setup** | Phức tạp hơn | Đơn giản hơn |
| **Scalability** | Tự động scale | Cần cấu hình |
| **Maintenance** | Ít hơn | Nhiều hơn |
| **Phù hợp** | Production lớn | Development/Test/Small production |

---

## 📞 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra logs trên platform (Railway/Render/Vercel)
2. Kiểm tra Firestore → Collection `payments_logs` để xem log chi tiết
3. Kiểm tra VNPay Sandbox Portal → Transaction History

