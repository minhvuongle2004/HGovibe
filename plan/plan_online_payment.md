## Kế hoạch tích hợp thanh toán online

### Mục tiêu tổng quát
- Mở rộng luồng booking hiện tại để hỗ trợ khách thanh toán trực tuyến sau khi đặt tour.
- Đồng bộ trạng thái `paymentStatus` giữa mobile app, Admin Web và Firestore.
- Cho phép theo dõi giao dịch, xử lý thất bại và đảm bảo bảo mật.

---

### Phase 1 – Phân tích & thiết kế nghiệp vụ
1. **Chọn cổng thanh toán**: xác định ưu tiên (MoMo/ZaloPay/VNPay/Stripe), kiểm tra SDK Flutter, chế độ sandbox và webhook.
2. **Chuẩn hóa trạng thái**:
   - `bookingStatus`: `pending → confirmed → completed/cancelled`.
   - `paymentStatus`: `unpaid → pending → paid/failed/refunded`.
3. **Xác định điểm chuyển trạng thái**: thời điểm tạo yêu cầu thanh toán, sau khi nhận callback.
4. **Thiết kế luồng màn hình**:
   - Mobile: thêm lựa chọn “Thanh toán online”, `PaymentScreen`, `PaymentResultScreen`.
   - Admin Web: hiển thị thông tin thanh toán trong danh sách/chi tiết booking.

### Phase 2 – Thiết kế & cập nhật dữ liệu Firestore
1. **Mở rộng model `TourBooking` (mobile + admin)**:
   - Trường mới: `paymentStatus`, `paymentMethod`, `paymentTransactionId`, `paymentAt`, `paymentGatewayRawData`.
2. **Cập nhật services**:
   - `lib/services/tours/tour_booking_service.dart`.
   - `admin_web/lib/services/bookings/admin_booking_service.dart`.
3. **(Tùy chọn)**: tạo collection `payments` để lưu log giao dịch chi tiết, liên kết bằng `paymentId`.

### Phase 3 – Triển khai Payment Service trên mobile
1. **Tích hợp SDK / REST client** tương ứng cổng đã chọn; cấu hình deeplink/app scheme nếu cần.
2. **Tạo `PaymentService`**:
   - `createPaymentRequest`, `redirectToGateway`, `handleReturn`.
   - Ghi nhận `paymentStatus = pending` trước khi chuyển hướng.
3. **Xử lý kết quả ở client**:
   - Nhận deeplink/return URL, xác thực chữ ký (nếu làm client-side).
   - Cập nhật tạm thời `paymentStatus` và log giao dịch vào Firestore.

### Phase 4 – Webhook / xác thực server-side (khuyến nghị)
1. **Cloud Functions**:
   - Endpoint nhận thông báo từ gateway, xác thực chữ ký.
   - Tìm `bookingId/paymentId` và cập nhật `paymentStatus` chuẩn (`paid/failed`).
   - Ghi log vào `payments` hoặc `payments_logs`.
2. **Đồng bộ real-time**:
   - Mobile app listen thay đổi `paymentStatus`.
   - Admin Web cập nhật bảng và chi tiết booking theo thời gian thực.

### Phase 5 – Cập nhật UI/UX Mobile
1. `TourBookingConfirmScreen`: thêm lựa chọn phương thức (offline/online).
2. `PaymentScreen`: hiển thị tour, số tiền, cổng thanh toán, nút “Tiến hành thanh toán”.
3. `PaymentResultScreen` (hoặc mở rộng `BookingSuccessScreen`):
   - Thông báo thành công/thất bại/hủy.
   - Nút điều hướng “Xem tour của tôi” / “Về trang chủ”.

### Phase 6 – Cập nhật UI/UX Admin Web
1. `bookings_screen.dart`: thêm filter theo `paymentStatus`, cột “Thanh toán” với badge trạng thái.
2. `booking_detail_screen.dart`: section “Thông tin thanh toán” (phương thức, mã giao dịch, thời gian, log lỗi). Hạn chế chỉnh sửa thủ công khi giao dịch online đã `paid`.

### Phase 7 – Kiểm thử, logging & bảo mật
1. **Kiểm thử sandbox**: các case thành công, thất bại, người dùng thoát giữa chừng, double submit.
2. **Logging**:
   - Lưu lịch sử thay đổi `paymentStatus` (ai, khi nào).
   - Ghi toàn bộ payload webhook để debug.
3. **Firestore security rules**:
   - Người dùng chỉ xem/sửa booking của mình, không thể can thiệp `paymentStatus`.
   - Admin chỉ được chỉnh sửa các trường cho phép; `paymentStatus` từ webhook là authoritative.

---

### Thông tin đã chốt
1. **Gateway**: ưu tiên tích hợp **MoMo** (App + Server API).
2. **Thời điểm cho phép thanh toán**: cho phép user thanh toán
   - **Ngay sau khi đặt tour** (auto-confirm nếu giao dịch thành công).
   - **Hoặc** đợi đến khi admin chuyển `bookingStatus` → `confirmed`, khi đó user vẫn có thể mở booking để thanh toán bù.
3. **Bảo mật**: **Triển khai Cloud Functions webhook ngay** để nhận callback từ MoMo và xác thực chữ ký server-side.

### Bổ sung chi tiết Phase 3 (MoMo)
1. Thêm dependency `momo_vn` (hoặc SDK chính thức) + cấu hình `appScheme`.
2. `PaymentService`:
   - `createMomoPayment(booking, amount, returnUrl)`: gọi MoMo “App Payment”/“Capture Wallet” API để lấy `payUrl`.
   - Lưu `paymentRequestId` vào Firestore, set `paymentStatus = pending`.
3. UI:
   - Sau khi user đặt tour thành công ⇒ nếu chọn online, chuyển thẳng tới `PaymentScreen` và mở MoMo bằng `launchUrl`.
   - Nếu chọn offline nhưng sau này muốn thanh toán, từ `MyBookings` → `BookingDetail` thêm nút “Thanh toán MoMo” (khi `paymentStatus = unpaid`).
4. Deeplink:
   - Thiết lập URL scheme `momo<APP_ID>` để nhận kết quả tạm thời (success/fail/cancel) và update UI trước khi webhook về.

### Bổ sung chi tiết Phase 4 (Cloud Functions cho MoMo)
1. Endpoint `https://<region>-<project>.cloudfunctions.net/momoWebhook`.
2. Chức năng:
   - Nhận payload `resultCode`, `orderId`, `transId`, `signature`.
   - Xác thực chữ ký HMAC SHA256 bằng `secretKey`.
   - Nếu `resultCode == 0` ⇒ update Firestore:
     - `paymentStatus = paid`, `paymentTransactionId = transId`, `paymentAt = Timestamp.now()`.
     - Nếu booking đang `pending` và chính sách cho phép auto-confirm ⇒ set `bookingStatus = confirmed`.
   - Nếu thất bại ⇒ `paymentStatus = failed`, ghi `paymentGatewayRawData`.
3. Retry cơ chế:
   - Ghi log `payments_logs/<orderId>` để tránh xử lý trùng.
   - Nếu update Firestore lỗi ⇒ Cloud Function trả 500 để MoMo retry.

### Công việc tiếp theo
1. Triển khai Phase 3 chi tiết (Flutter + MoMo SDK).
2. Xây dựng Cloud Function webhook + cấu hình MoMo callback URL.
3. Cập nhật UI Admin & Mobile theo trạng thái mới, đảm bảo refresh real-time.

