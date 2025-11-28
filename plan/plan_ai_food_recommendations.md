## Kế hoạch tính năng AI gợi ý ăn uống lân cận

### 1. Mục tiêu & Phạm vi
- Gợi ý nhà hàng/quán cà phê/hoạt động ẩm thực quanh từng điểm trong lịch trình dựa trên AI.
- Cho phép xem gợi ý trên bản đồ, dẫn đường, thêm thẳng vào lịch trình và lưu yêu thích.
- Tận dụng Mapbox POI làm nguồn dữ liệu địa điểm thô, Gemini làm bộ máy phân tích/cá nhân hóa.

### 2. Yêu cầu chức năng chính
1. **Thu thập POI**: với mỗi `TripItem` có tọa độ, gọi Mapbox Search (keyword theo ngữ cảnh bữa ăn) để lấy danh sách địa điểm ăn uống trong bán kính tùy chỉnh.
2. **Gọi AI**: truyền thông tin chuyến đi, lịch trình, cấu hình ngân sách và danh sách POI vào Gemini → nhận JSON shortlist + mô tả lý do.
3. **Hiển thị UI**:
   - Tab `Gợi ý AI` hiển thị danh sách card (ảnh placeholder nếu thiếu), tên địa điểm, tag category, khoảng cách, chi phí ước tính, lý do gợi ý.
   - Action: “Xem bản đồ”, “Dẫn đường”, “Thêm vào lịch trình”, “Lưu yêu thích”.
4. **Thêm vào timeline**: tạo `TripItem` mới (destination custom hoặc reference POI) với ngày/giờ gợi ý; cập nhật `AIActivitySuggestion.isAdded`.
5. **Lưu & đồng bộ**: cache kết quả gợi ý trong Firestore để hạn chế gọi AI lặp lại và hỗ trợ offline view.

### 3. Kiến trúc & thành phần
- **Service mới**: `AIPlaceRecommendationService`
  - Nhận `Trip`, danh sách `TripItem` (đã có tọa độ), danh sách POI Mapbox.
  - Build prompt theo format chuẩn (JSON + mô tả).
  - Gọi Gemini (tái sử dụng cấu trúc của `AICostEstimationService`).
  - Parse response thành danh sách `AIActivitySuggestion`.
- **TripProvider**:
  - Cập nhật `loadAISuggestions()` để thực thi pipeline: thu POI → call AI → lưu state + Firestore.
  - Thêm `addAISuggestionToTrip()` để convert suggestion thành `TripItem`.
  - State mới: `_isLoadingSuggestions`, `_suggestionError`, `_aiSuggestions`.
- **Model**:
  - Mở rộng `AIActivitySuggestion` để chứa thông tin tọa độ, nguồn POI, link map thumbnail.
  - Nếu cần custom destination, tạo `CustomDestination` hoặc tái sử dụng `MapboxPlace`.
- **UI**:
  - `TripDetailScreen` tab AI: loading, error, last updated, list suggestions.
  - Nút refresh / lấy lại gợi ý.
  - Dialog xác nhận khi thêm vào lịch trình (chọn ngày/giờ nếu AI không gán sẵn).
  - Action chuyển sang `MapScreen` với deep-link data (lat/lng + tên).

### 4. Phân phase triển khai
1. **Phase 1 – Chuẩn bị dữ liệu**
   - Thêm phương thức lấy POI theo tọa độ + keyword trong `MapBoxService` (vd `searchNearbyPlaces`).
   - Chuẩn hóa model `AIActivitySuggestion` (bổ sung lat/lng, address, sourcePlaceId, mealType).
   - Cập nhật `TripProvider.loadAISuggestions()` skeleton để gọi service mới (chưa gắn AI).
2. **Phase 2 – Tích hợp Gemini**
   - Tạo `AIPlaceRecommendationService`.
   - Viết prompt builder (trip summary + danh sách POI + sở thích người dùng).
   - Gọi Gemini: parse JSON + description, xử lý fallbacks, log lỗi.
   - Lưu suggestion xuống Firestore (`trips/{tripId}/suggestions`).
3. **Phase 3 – UI Tab Gợi Ý**
   - Update `TripDetailScreen` tab: loading states, list card, retry button.
   - Card actions: xem map, dẫn đường (mở Map tab / Mapbox Directions), thêm vào lịch trình, lưu yêu thích.
   - Hỗ trợ hiển thị gợi ý đã thêm (badge “Đã trong lịch trình”).
4. **Phase 4 – Liên kết Map & Timeline**
   - `Xem bản đồ`: navigate sang `MapScreen` với param highlight POI, hiển thị bottom sheet + nút dẫn đường.
   - `Thêm vào lịch trình`: mở bottom sheet chọn ngày/giờ + duration, dùng `TripProvider.addDestinationToTripWithDetails`.
   - Ghi log sử dụng, cập nhật `isAdded`.
5. **Phase 5 – Tối ưu & nâng cao**
   - Bộ lọc sở thích (ăn chay, budget, món địa phương).
   - Caching suggestion theo ngày/chuyến đi, TTL 12h.
   - Cho phép user đánh giá suggestion để cải thiện prompt.

### 5. Validation & Edge Cases
- **Thiếu tọa độ**: bỏ qua TripItem không có lat/lng, cảnh báo user nếu toàn bộ lịch trình thiếu vị trí.
- **Không tìm thấy POI**: fallback sang radius lớn hơn hoặc hiển thị thông báo “Không có quán ăn phù hợp”.
- **Giới hạn API Mapbox/Gemini**: debounce yêu cầu, cache POI + suggestion; hiển thị toast khi vượt quota.
- **Lỗi AI**: hiển thị lỗi, cho phép thử lại; fallback hiển thị danh sách POI chưa qua AI để người dùng tự chọn.
- **Thêm vào lịch trình**: kiểm tra trùng giờ bằng `TripProvider.findScheduleConflict`, yêu cầu xác nhận nếu chồng chéo.
- **Offline**: nếu đang offline, hiển thị cache suggestions cuối cùng; chặn gọi AI và Mapbox, cung cấp nút “Thử lại”.
- **Quyền vị trí**: khi xem bản đồ hoặc dẫn đường, đảm bảo quyền đã được cấp; nếu không, hiển thị dialog hướng dẫn.

### 6. Lưu ý triển khai
- Tái sử dụng hạ tầng logging, caching, error handling hiện có (`UsageLogService`, toast/snackbar utilities).
- Giữ prompt, parsing logic tách biệt để dễ đổi model AI.
- Thử nghiệm với nhiều độ dài lịch trình để đảm bảo prompt không quá lớn (có thể tóm tắt POI theo ngày).
- Khi thêm TripItem mới cho hoạt động ăn uống, cần quyết định `destinationId` (có thể tạo destination tạm hoặc lưu thông tin POI trực tiếp trong TripItem, ví dụ field `customLocation`).
- Đảm bảo UI hỗ trợ cả desktop/tablet: card responsive, bottom sheet không che FAB.
- Viết test/service-level (mock Gemini response, Mapbox response) để đảm bảo parser hoạt động.

