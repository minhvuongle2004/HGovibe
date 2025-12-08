# Phase 5: Reviews & Polish (không bao gồm thông báo email/SMS)

## Mục tiêu
- Người dùng có thể tạo, xem, cập nhật/xóa đánh giá tour.
- Hỗ trợ upload ảnh kèm review (tối đa 4–5 ảnh/review).
- Chỉ cho phép người đã đặt tour (và đã tham gia/đã thanh toán) được review; mỗi booking chỉ review một lần.
- Hiển thị danh sách review kèm ảnh trên màn Tour Detail; tính rating trung bình.

## Phạm vi
- Data model & Firestore structure cho reviews.
- Upload ảnh lên Firebase Storage; lưu metadata vào Firestore.
- UI/UX: form viết review, gallery ảnh, list reviews.
- Bỏ hạng mục thông báo email/SMS.

## Kiến trúc dữ liệu
- Collection: `tour_reviews`
  - doc id: auto
  - Fields:
    - `tourId` (string)
    - `userId` (string)
    - `bookingId` (string) — để đảm bảo mỗi booking chỉ một review
    - `rating` (number, 1–5)
    - `comment` (string, optional)
    - `photos` (array<string>) — URLs ảnh trên Storage
    - `createdAt`, `updatedAt` (timestamp)
    - `status` (string: active, hidden) — tùy chọn ẩn review xấu
- Index đề xuất:
  - `tour_reviews` where `tourId` + order by `createdAt`
  - `tour_reviews` where `userId`
  - `tour_reviews` where `bookingId` (unique logic ở app)

## Luồng nghiệp vụ
1) Người dùng hoàn tất tour (hoặc đã thanh toán) → mở Tour Detail → nút “Viết đánh giá”.
2) Form review:
   - Chọn rating (1–5).
   - Nhập nội dung.
   - Upload 0–5 ảnh (chọn từ gallery/camera).
3) Lưu:
   - Upload ảnh lên Storage theo path `reviews/{userId}/{reviewId}/{filename}`.
   - Nhận download URLs → lưu vào `photos`.
   - Tạo doc `tour_reviews`.
4) Hiển thị:
   - Tour Detail → tab/section Reviews: list reviews (mới nhất trước), rating trung bình, số lượng reviews.
   - Hiển thị ảnh dạng grid; tap để xem full-screen (PhotoView/Gallery).
5) Chỉnh sửa/Xóa:
   - User chỉ sửa/xóa review của chính mình.
   - Khi xóa, có thể xóa luôn ảnh trên Storage (tùy chọn).

## Ràng buộc & Validation
- Mỗi `bookingId` chỉ tạo 1 review (kiểm tra tồn tại review với bookingId trước khi cho submit).
- Chỉ cho phép review nếu:
  - `booking.paymentStatus == paid` AND `booking.status` in (confirmed/completed), hoặc
  - Đã qua ngày khởi hành (tùy chính sách).
- Ảnh:
  - Kích thước nén trước khi upload (nếu cần).
  - Giới hạn số ảnh (4–5) và dung lượng tối đa mỗi ảnh.

## Công việc chi tiết
1) Model & Service
   - Tạo model `TourReview`.
   - Service `TourReviewService`: create/update/delete/getByTour/getByUser/checkExistingByBooking`.
2) Upload ảnh
   - Dùng Firebase Storage.
   - Helper upload nhiều ảnh, trả về danh sách URLs.
3) UI/UX
   - Tour Detail: thêm section Reviews (rating avg, count, list).
   - Nút “Viết đánh giá” (ẩn nếu đã có review cho booking đó).
   - Form review: rating, comment, picker ảnh (multi-select), preview & remove.
   - Viewer ảnh (full-screen) cho list reviews.
4) Logic hạn chế
   - Kiểm tra booking đủ điều kiện.
   - Chặn submit nếu đã có review cho booking đó.
5) Tính toán rating
   - Tính trung bình tại client sau khi fetch list (hoặc lưu cache ở tour package nếu muốn tối ưu sau).

## Kiểm thử
- Case user đủ điều kiện review → tạo thành công.
- Case đã review booking → chặn và hiển thị thông báo.
- Upload 0 ảnh / nhiều ảnh / ảnh lớn.
- Hiển thị list reviews có ảnh, mở ảnh full-screen.
- Xóa/sửa review của chính mình.

## Triển khai & Ưu tiên
1) Service + Model + Firestore rules (chặn ghi nếu không cùng user / vượt quota).
2) Form review + upload ảnh + create review.
3) List reviews + rating trung bình trên Tour Detail.
4) Edit/Delete review.
5) (Tùy chọn) Tối ưu: nén ảnh trước upload; cache rating vào tour package.

## Ghi chú bảo mật
- Firestore rules cần kiểm tra `request.auth.uid == userId`, match bookingId, và giới hạn 1 review/booking (thực thi logic ở app + validate server nếu có cloud function).
- Storage rules: chỉ cho phép chủ ảnh upload/xóa trong `reviews/{uid}/...`.

