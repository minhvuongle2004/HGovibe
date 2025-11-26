# Kế Hoạch Phát Triển Chức Năng Hiển Thị & Tìm Kiếm Điểm Du Lịch

## Mục Tiêu
- Hiển thị các điểm du lịch từ Firestore
- Tìm kiếm điểm đến theo tên
- Gợi ý các điểm du lịch thông minh
- Giao diện theo thiết kế mẫu

---

## PHASE 1: Tầng Dữ Liệu (Data Layer)
**Mục tiêu:** Xây dựng nền tảng để truy vấn dữ liệu từ Firestore

### 1.1. Tạo Model Destination
- **File:** `lib/models/destination.dart`
- **Chức năng:**
  - Định nghĩa class `Destination` với tất cả các fields từ Firestore
  - Method `fromFirestore()` - Convert Firestore Document → Dart Object
  - Method `toMap()` - Convert Dart Object → Map (nếu cần)
  - Các fields chính: name, location, images, thumbnail, rating, review_count, tags, price, etc.

### 1.2. Tạo Destination Service/Repository
- **File:** `lib/services/destination_service.dart`
- **Chức năng:**
  - `getAllDestinations({int limit, DocumentSnapshot? startAfter})` - Lấy tất cả (có phân trang)
  - `searchDestinations(String query)` - Tìm kiếm theo tên (name, name_lowercase)
  - `getDestinationsByRegion(String region)` - Lọc theo vùng (Bắc/Trung/Nam)
  - `getRecommendedDestinations({int limit})` - Gợi ý theo `popularity_score`, `trending_score`
  - `getDestinationsByTags(List<String> tags)` - Lọc theo tags
  - `getDestinationsByCity(String city)` - Lọc theo thành phố (Hà Nội, Phú Quốc, etc.)

### 1.3. Tạo Provider/State Management (Optional)
- **File:** `lib/providers/destination_provider.dart`
- **Chức năng:**
  - Quản lý state: loading, error, destinations list
  - Caching data để tránh fetch lại nhiều lần
  - Sử dụng `provider` hoặc `riverpod` package

---

## PHASE 2: UI Components Cơ Bản
**Mục tiêu:** Xây dựng các widget tái sử dụng

### 2.1. Destination Card Widget
- **File:** `lib/widgets/destination_card.dart`
- **Hiển thị:**
  - Hình ảnh thumbnail (sử dụng `cached_network_image`)
  - Location tag với pin icon + city/district
  - Title (name)
  - Rating với star icon + số reviews (ví dụ: 4.8(110))
  - Price (nếu có trong data) - format: "Từ ₫ 250,000"
- **Style:** Giống card trong thiết kế mẫu
- **Tương tác:** Tap để navigate đến detail screen

### 2.2. Category Chip Widget
- **File:** `lib/widgets/category_chip.dart`
- **Hiển thị:**
  - Circular button với hình ảnh background
  - Text label bên dưới (Hà Nội, Phú Quốc, Hạ Long, etc.)
- **Tương tác:** Tap để filter destinations theo vùng/thành phố

### 2.3. Search Bar Widget
- **File:** `lib/widgets/search_bar_widget.dart`
- **Hiển thị:**
  - Search field với magnifying glass icon
  - Placeholder text: "tràng an" (hoặc dynamic)
  - Icons bên phải: shopping cart, notification bell
- **Tương tác:** Real-time search khi gõ

---

## PHASE 3: Màn Hình Chính (Home Screen)
**Mục tiêu:** Xây dựng màn hình chính theo thiết kế

### 3.1. Home Screen Layout
- **File:** `lib/screens/home_screen.dart`
- **Cấu trúc:**
  - **AppBar:** Search bar widget
  - **Section 1:** "Bạn muốn đi đâu chơi?" + "Xem thêm" link
  - **Section 2:** Horizontal scrollable categories (Category chips)
  - **Section 3:** Tabs - "Đề xuất" | "Gần đây"
  - **Section 4:** List destinations (vertical scrollable)
  - **Bottom Navigation Bar:** 5 tabs (Trang chủ, Yêu thích, SALE, Chuyến đi, Tài khoản)

### 3.2. Tích Hợp Search
- Real-time search khi gõ (với debounce để tối ưu performance)
- Hiển thị kết quả trong cùng màn hình
- Clear search khi xóa text

### 3.3. Tab "Đề xuất" (Recommended)
- Hiển thị destinations theo:
  - `trending_score` (ưu tiên)
  - `popularity_score`
  - `rating` + `review_count`
- Sắp xếp: Trending → Popular → Rating

### 3.4. Tab "Gần đây" (Recent)
- **Tạm thời:** Lưu trong `SharedPreferences` hoặc local storage
- Lưu danh sách ID của destinations đã xem
- **Sau này:** Lưu vào Firestore collection `user_recent_views` (khi có authentication)

---

## PHASE 4: Tính Năng Gợi Ý Thông Minh
**Mục tiêu:** Gợi ý destinations dựa trên dữ liệu

### 4.1. Gợi Ý Theo Vùng Miền
- Filter theo `location.region` hoặc `location.city`
- Category chips: Hà Nội, Phú Quốc, Hạ Long, Ninh Bình, etc.
- Tap vào category → hiển thị destinations của vùng đó

### 4.2. Gợi Ý Theo Mùa/Thời Tiết
- Dựa vào `best_season`, `best_months` trong data
- Hiển thị destinations phù hợp với tháng hiện tại
- Ví dụ: Tháng 12 → gợi ý destinations có `best_months` chứa 12

### 4.3. Gợi Ý Theo Tags/Categories
- Filter theo `tags` array
- Ví dụ: "lịch sử", "văn hóa", "thiên nhiên", "check-in", etc.
- Có thể tạo filter chips cho các tags phổ biến

### 4.4. Gợi Ý Theo Rating/Popularity
- Top destinations theo `rating` + `review_count`
- Trending destinations theo `trending_score`
- Popular destinations theo `popularity_score`

---

## PHASE 5: Tối Ưu & Hoàn Thiện
**Mục tiêu:** Cải thiện UX và performance

### 5.1. Loading States
- Skeleton loaders cho destination cards
- Shimmer effect khi đang tải data
- Loading indicator khi search

### 5.2. Empty States
- Hiển thị message khi không có kết quả tìm kiếm
- Empty state cho tab "Gần đây" (chưa xem destination nào)
- Empty state khi không có destinations

### 5.3. Error Handling
- Hiển thị error message khi không load được data
- Retry mechanism (nút "Thử lại")
- Network error handling

### 5.4. Performance Optimization
- Lazy loading cho danh sách dài (pagination)
- Image caching (đã có `cached_network_image`)
- Pagination cho Firestore queries (limit + startAfter)
- Debounce cho search input (tránh query quá nhiều)

### 5.5. Pull-to-Refresh
- Refresh danh sách destinations
- Pull down để reload data từ Firestore

---

## PHASE 6: Bottom Navigation & Navigation Flow
**Mục tiêu:** Hoàn thiện navigation

### 6.1. Bottom Navigation Bar
- **5 tabs:**
  - Trang chủ (Home) - active
  - Yêu thích (Favorites) - placeholder
  - SALE - placeholder
  - Chuyến đi (Trips) - placeholder
  - Tài khoản (Account) - placeholder
- Navigation giữa các màn hình
- Highlight tab đang active

### 6.2. Navigation Đến Detail Screen
- Tap vào destination card → navigate đến detail screen
- **File:** `lib/screens/destination_detail_screen.dart` (sẽ làm sau)
- Pass destination data qua arguments

---

## Thứ Tự Triển Khai Đề Xuất

### Tuần 1: Phase 1 + Phase 2
- ✅ Tạo Model Destination
- ✅ Tạo Destination Service với các methods cơ bản
- ✅ Tạo Destination Card Widget
- ✅ Tạo Category Chip Widget
- ✅ Tạo Search Bar Widget

### Tuần 2: Phase 3
- ✅ Xây dựng Home Screen layout
- ✅ Tích hợp search functionality
- ✅ Implement tab "Đề xuất"
- ✅ Implement tab "Gần đây" (tạm thời dùng local storage)

### Tuần 3: Phase 4
- ✅ Gợi ý theo vùng miền (category chips)
- ✅ Gợi ý theo mùa/thời tiết
- ✅ Gợi ý theo tags
- ✅ Gợi ý theo rating/popularity

### Tuần 4: Phase 5 + Phase 6
- ✅ Loading states & shimmer effects
- ✅ Empty states & error handling
- ✅ Performance optimization (pagination, debounce)
- ✅ Pull-to-refresh
- ✅ Bottom navigation bar
- ✅ Navigation flow

---

## Các Package Cần Bổ Sung

### Bắt Buộc:
- `provider: ^6.1.1` hoặc `flutter_riverpod: ^2.5.1` - State management
- `shared_preferences: ^2.2.2` - Lưu recent views tạm thời

### Tùy Chọn (Nâng Cao):
- `shimmer: ^3.0.0` - Loading shimmer effect
- `flutter_staggered_grid_view: ^0.7.0` - Grid layout (nếu cần)
- `infinite_scroll_pagination: ^4.0.0` - Pagination helper

---

## Lưu Ý Khi Triển Khai

1. **Firestore Queries:**
   - Sử dụng indexes cho các queries phức tạp
   - Limit số lượng documents mỗi lần query (ví dụ: 20-30 items)
   - Sử dụng pagination với `startAfter` để load thêm

2. **Image Loading:**
   - Đã có `cached_network_image` - sử dụng để cache ảnh
   - Placeholder image khi load lỗi
   - Loading indicator khi đang load ảnh

3. **Search Performance:**
   - Debounce search input (300-500ms)
   - Case-insensitive search (dùng `name_lowercase` field)
   - Limit kết quả search (ví dụ: 50 items)

4. **State Management:**
   - Cache destinations list để tránh fetch lại nhiều lần
   - Clear cache khi cần refresh
   - Handle loading/error states properly

5. **UI/UX:**
   - Smooth scrolling
   - Responsive design (hỗ trợ nhiều screen sizes)
   - Material Design 3 guidelines
   - Accessibility (semantic labels)

---

## Checklist Hoàn Thành

### Phase 1: Data Layer
- [ ] Model Destination
- [ ] Destination Service
- [ ] Provider/State Management (optional)

### Phase 2: UI Components
- [ ] Destination Card Widget
- [ ] Category Chip Widget
- [ ] Search Bar Widget

### Phase 3: Home Screen
- [ ] Home Screen Layout
- [ ] Search Integration
- [ ] Tab "Đề xuất"
- [ ] Tab "Gần đây"

### Phase 4: Smart Recommendations
- [ ] Gợi ý theo vùng miền
- [ ] Gợi ý theo mùa/thời tiết
- [ ] Gợi ý theo tags
- [ ] Gợi ý theo rating/popularity

### Phase 5: Optimization
- [ ] Loading States
- [ ] Empty States
- [ ] Error Handling
- [ ] Performance Optimization
- [ ] Pull-to-Refresh

### Phase 6: Navigation
- [ ] Bottom Navigation Bar
- [ ] Navigation Flow

---

**Ghi chú:** Kế hoạch này có thể điều chỉnh tùy theo tiến độ và yêu cầu thực tế trong quá trình phát triển.

