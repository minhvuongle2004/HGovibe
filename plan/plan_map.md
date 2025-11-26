## Kế hoạch Tab Bản đồ & Dẫn đường

### Mục tiêu
- Thay tab `Sale` bằng tab Bản đồ hiển thị toàn bộ điểm đến, vị trí hiện tại và tuyến đường đang hoạt động.
- Cho phép tìm kiếm điểm đến ngay trên bản đồ bằng Mapbox (geocoding, lọc theo loại địa điểm).
- Từ màn chi tiết điểm đến, khi bấm vào địa chỉ sẽ chuyển sang tab Bản đồ, zoom vào điểm đó, hiển thị khoảng cách hiện tại và cho phép bắt đầu dẫn đường theo phương tiện (xe máy/ô tô).

### Giả định
- Được phép dùng Mapbox SDK/REST cho map, geocoding, matrix, directions.
- App đã có xử lý xin quyền vị trí; nếu user từ chối phải hiện hướng dẫn bật lại.
- Dữ liệu điểm đến đều có `location.latitude` và `location.longitude`.
- State chuyến đi/điểm đến dùng chung được Provider quản lý, map chỉ cần subscribe lại.

### Phân phase triển khai
1. **Phase 1 – Tab & khung bản đồ**
   - Đổi tab `Sale` trong bottom nav thành tab `Bản đồ`.
   - Nhúng Mapbox map widget, bật hiển thị vị trí hiện tại và các điều khiển zoom/camera cơ bản.
   - Kết nối Provider để đẩy markers cho các điểm thuộc chuyến đi hoặc danh sách gợi ý.

2. **Phase 2 – Tìm kiếm & thông tin marker**
   - Thêm thanh search nổi (text field debounce) gọi Mapbox Geocoding API.
   - Hiển thị danh sách gợi ý overlay; chọn item thì thêm marker tạm và focus camera.
   - Khi chạm marker, mở bottom sheet chứa tên, địa chỉ, mô tả ngắn, nút “Đi đến”.
   - Lưu cache các truy vấn gần đây để giảm gọi API khi offline.

3. **Phase 3 – Liên kết từ màn chi tiết điểm đến**
   - Quấn phần địa chỉ trong màn chi tiết bằng `InkWell`.
   - Khi bấm, chuyển sang tab Bản đồ thông qua shared navigation state, truyền destination cho map provider để focus và mở sheet.
   - Tính khoảng cách + ETA từ GPS hiện tại bằng Mapbox Matrix (fallback Haversine nếu lỗi) rồi hiển thị trong sheet.
   - Trong sheet có nút “Quay lại chi tiết” để trở về màn trước.

4. **Phase 4 – Tuyến đường & dẫn đường**
   - Thêm nút “Bắt đầu”: gọi Mapbox Directions với profile được chọn (`driving`, `driving-traffic`, `cycling`/`walking` tùy cấu hình cho xe máy).
   - Vẽ polyline lên map, hiển thị tổng quãng đường/thời gian và danh sách bước rẽ (turn-by-turn summary).
   - Cho phép chuyển đổi profile (xe máy/ô tô), ghi nhớ lựa chọn cuối cùng.
   - Cung cấp nút “Mở trong Mapbox/Google Maps” để người dùng tiếp tục dẫn đường đầy đủ nếu muốn.

5. **Phase 5 – Hoàn thiện & tối ưu**
   - Gom cụm marker (clustering) khi zoom xa.
   - Bổ sung thông báo offline, cơ chế retry/backoff khi API lỗi.
   - Ghi log sử dụng tìm kiếm/dẫn đường để giám sát.
   - Viết unit test cho service Map và integration test cho việc chuyển tab + deep link.

### Yêu cầu UI/UX
- Icon và label tab mới phải gợi nhớ đến bản đồ/dẫn đường; tô sáng khi active.
- Thanh tìm kiếm dạng pill nổi, có nút xoá nhanh và trạng thái loading khi gọi API.
- Bottom sheet marker: hình ảnh thu nhỏ, điểm đánh giá, địa chỉ, badge khoảng cách/ETA, nút `Bắt đầu` và `Quay lại chi tiết`.
- Khi mở tab map từ màn chi tiết, hiển thị toast “Đang dẫn tới [Tên điểm]”.
- Polyline hiển thị màu khác nhau theo profile (ví dụ xanh cho ô tô, cam cho xe máy).
- FAB (nút recenter, đổi lớp bản đồ) bố trí tránh che bottom nav và sheet.
- Snackbar/toast hiển thị lỗi mạng, lỗi GPS; dialog hướng dẫn bật quyền khi cần.

### Validation & Edge case
- **Quyền vị trí**: nếu user từ chối thì chặn các thao tác phụ thuộc GPS và mở dialog hướng dẫn bật lại trong cài đặt.
- **Thiếu tọa độ**: nếu điểm đến không có lat/lng thì thông báo và bỏ qua marker.
- **Kiểm tra khoảng cách bất thường**: so sánh distance/duration Mapbox trả về; nếu chênh lệch bất hợp lý thì fallback Haversine và hiển thị cảnh báo.
- **Không có tuyến cho profile**: ví dụ đảo không hỗ trợ ô tô → fallback sang walking/xe máy hoặc báo rõ cho user.
- **Giới hạn API**: debounce 400–600 ms, cache kết quả cùng query, hạn chế spam tìm kiếm.
- **Mất kết nối**: phát hiện offline trước khi gọi API, hiển thị dữ liệu cache và cho phép “thử lại”.
- **Nhiều yêu cầu tuyến đường**: khi user đổi điểm hoặc đổi profile liên tục, hủy request Mapbox Directions trước đó để tránh race condition.

