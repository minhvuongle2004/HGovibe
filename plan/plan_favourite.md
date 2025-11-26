# Kế hoạch triển khai chức năng: Lưu địa điểm yêu thích

## Mục tiêu
Cho phép người dùng lưu các địa điểm du lịch vào danh sách yêu thích, xem và quản lý danh sách này.

## Yêu cầu UI/UX
1. **Màn hình chi tiết địa điểm**: Có nút trái tim ở AppBar để thêm/bỏ yêu thích
2. **Màn hình yêu thích (chưa đăng nhập)**: Hiển thị graphic trái tim + ticket, thông báo "Hãy đăng nhập để xem danh sách yêu thích của mình", nút "Đăng nhập"
3. **Màn hình yêu thích (đã đăng nhập)**: 
   - Filter chips (Hà Nội, Hoa Lư, Vé tham quan...)
   - Banner gợi ý "Thêm ý tưởng khám phá..."
   - Danh sách địa điểm yêu thích với heart icon
   - Nút edit và add ở AppBar
4. **Màn hình chi tiết địa điểm (cải thiện)**:
   - Nút trái tim ở AppBar
   - Thư viện ảnh (carousel với chỉ báo trang)
   - Thông tin chi tiết: rating, đánh giá, vị trí, mô tả, ưu đãi, giá
   - Nút "Chọn" để đặt vé

---

## Phase 1: Tạo Service và Model cho Favorites

### 1.1. Tạo Model `FavoriteDestination`
**File**: `lib/models/favorite_destination.dart`
- `userId`: String (UID của user)
- `destinationId`: String (ID của destination)
- `addedAt`: DateTime (thời gian thêm vào yêu thích)
- `destination`: Destination? (optional, để cache data khi cần)

**Methods**:
- `fromMap(Map<String, dynamic> map)`
- `toMap()`
- `fromFirestore(DocumentSnapshot doc)`

### 1.2. Tạo Service `FavoritesService`
**File**: `lib/services/favorites_service.dart`

**Dependencies**:
- `FirebaseFirestore` để lưu trữ favorites
- Collection: `favorites` với structure:
  ```
  favorites/{favoriteId}
    - userId: string
    - destinationId: string
    - addedAt: timestamp
  ```

**Methods**:
- `addFavorite(String userId, String destinationId)`: Thêm địa điểm vào yêu thích
- `removeFavorite(String userId, String destinationId)`: Xóa địa điểm khỏi yêu thích
- `isFavorite(String userId, String destinationId)`: Kiểm tra địa điểm có trong yêu thích không
- `getFavorites(String userId)`: Lấy danh sách tất cả favorites của user
- `getFavoriteDestinations(String userId)`: Lấy danh sách Destination từ favorites (join với destinations collection)
- `watchFavorites(String userId)`: Stream để lắng nghe thay đổi real-time
- `watchFavoriteDestinations(String userId)`: Stream danh sách Destination từ favorites

**Error Handling**:
- Xử lý trường hợp user chưa đăng nhập
- Xử lý duplicate favorites (không thêm trùng)
- Xử lý lỗi network/Firestore

### 1.3. Tạo Provider `FavoritesProvider`
**File**: `lib/providers/favorites_provider.dart`

**State**:
- `List<Destination> favorites`: Danh sách địa điểm yêu thích
- `Set<String> favoriteIds`: Set các ID đã yêu thích (để check nhanh)
- `bool isLoading`: Trạng thái loading
- `String? error`: Lỗi nếu có

**Methods**:
- `loadFavorites(String userId)`: Load danh sách favorites
- `toggleFavorite(String userId, String destinationId)`: Thêm/xóa yêu thích
- `isFavorite(String destinationId)`: Kiểm tra nhanh
- `refreshFavorites(String userId)`: Refresh danh sách

**Listeners**:
- Lắng nghe `FavoritesService.watchFavoriteDestinations()` để cập nhật real-time

---

## Phase 2: Cập nhật DestinationDetailScreen

### 2.1. Thêm nút trái tim vào AppBar
**File**: `lib/screens/destination_detail_screen.dart`

**Thay đổi**:
- Thêm `FavoritesProvider` vào widget
- Thêm `IconButton` với icon trái tim ở `AppBar.actions`
- Icon trái tim:
  - Màu cam khi đã yêu thích (`Icons.favorite`)
  - Màu xám khi chưa yêu thích (`Icons.favorite_border`)
- Khi click: gọi `toggleFavorite()`
- Nếu chưa đăng nhập: hiển thị dialog/snackbar yêu cầu đăng nhập

### 2.2. Cải thiện UI theo hình ảnh 3

**Cấu trúc mới**:
```
Scaffold
  AppBar (có nút back, trái tim, share, cart)
  body:
    Stack/Column:
      - Image carousel (full width, height ~300)
        - PageView với images
        - Page indicator (dots)
        - Nút "Thư viện ảnh" ở góc dưới phải
      - Card thông tin (màu trắng, rounded top):
        - Badge "PARTNER AWARDS 2024" (nếu có)
        - Tên địa điểm (bold, lớn)
        - Rating + số đánh giá + số lượt đặt
        - Vị trí (với icon map pin, có thể click để mở map)
        - Mô tả (có "Xem thêm" để expand)
        - Section "Ưu đãi cho bạn" (nếu có)
        - Giá (từ ₫ X, có giá gốc gạch ngang nếu có sale)
        - Nút "Chọn" (màu cam, có mũi tên xuống)
```

**Components cần tạo**:
- `ImageCarouselWidget`: Carousel ảnh với page indicator
- `PriceSectionWidget`: Hiển thị giá và ưu đãi
- `LocationSectionWidget`: Hiển thị vị trí với khả năng mở map

**Dependencies mới**:
- `page_indicator` hoặc tự tạo page indicator
- Có thể cần `url_launcher` để mở map

### 2.3. Xử lý trạng thái loading khi toggle favorite
- Hiển thị loading indicator khi đang thêm/xóa
- Disable nút khi đang xử lý

---

## Phase 3: Cập nhật FavoritesScreen

### 3.1. Xử lý trạng thái chưa đăng nhập
**File**: `lib/screens/favorites_screen.dart`

**UI khi chưa đăng nhập** (theo hình 1):
```
Center:
  Column:
    - Graphic: Trái tim màu cam lớn với ticket màu teal chèn vào
    - Text: "Hãy đăng nhập để xem danh sách yêu thích của mình"
    - Button: "Đăng nhập" (màu cam, rounded)
```

**Logic**:
- Kiểm tra `UserProvider.isLoggedIn`
- Nếu chưa đăng nhập: hiển thị empty state với nút đăng nhập
- Khi click "Đăng nhập": Navigate đến `/` (AuthGate)

### 3.2. UI khi đã đăng nhập (theo hình 2)

**Cấu trúc**:
```
Scaffold
  AppBar:
    - Title: "Yêu thích" (center)
    - Actions:
      - IconButton (edit icon)
      - IconButton (add/folder icon)
  body:
    Column:
      - Filter chips (horizontal scrollable):
        - Chips: "Hà Nội", "Hoa Lư", "Vé tham quan"...
        - Filter icon ở cuối
      - Banner gợi ý (nếu có):
        - Background màu cam nhạt
        - Icon khinh khí cầu
        - Text: "Thêm ý tưởng khám phá [city]"
        - Nút X để dismiss
      - ListView favorites:
        - FavoriteDestinationCard (mỗi item)
      - Empty state: "Không còn mục yêu thích nào"
```

**Components cần tạo**:
- `FavoriteDestinationCard`: Card hiển thị địa điểm yêu thích
  - Ảnh thumbnail (có heart icon overlay ở góc trên phải)
  - Tên địa điểm
  - Tags: "Đặt ngay hôm nay", "Xác nhận tức thời"
  - Rating: ⭐ 4.4(421)
  - Số lượt đặt: "50K+ Đã đặt"
  - Giá: "Từ ₫ 238,000"
  - Badge sale: "Sale Giảm 20%" (nếu có)

- `FilterChipsWidget`: Horizontal scrollable chips
- `RecommendationBannerWidget`: Banner gợi ý

### 3.3. Logic filter và search
- Filter theo category (Hà Nội, Hoa Lư...)
- Filter theo loại (Vé tham quan...)
- Có thể thêm search bar sau

### 3.4. Xử lý empty state
- Khi không có favorites: Hiển thị "Không còn mục yêu thích nào"
- Khi filter không có kết quả: Hiển thị thông báo tương ứng

---

## Phase 4: Tích hợp Favorites vào các màn hình khác

### 4.1. Thêm nút trái tim vào DestinationCard
**File**: `lib/widgets/destination_card.dart`

**Thay đổi**:
- Thêm `FavoritesProvider` vào widget
- Thêm `IconButton` trái tim nhỏ ở góc trên phải của card
- Khi click: toggle favorite
- Nếu chưa đăng nhập: hiển thị snackbar yêu cầu đăng nhập

### 4.2. Cập nhật HomeScreen
**File**: `lib/screens/home_screen.dart`

**Thay đổi**:
- Wrap với `FavoritesProvider` (hoặc dùng `MultiProvider`)
- Các `DestinationCard` sẽ tự động hiển thị trạng thái yêu thích

### 4.3. Cập nhật các màn hình khác
- Kiểm tra các màn hình nào hiển thị `DestinationCard` và đảm bảo tích hợp favorites

---

## Phase 5: Firestore Security Rules và Testing

### 5.1. Cập nhật Firestore Security Rules
**File**: `firebase/firestore.rules`

**Rules cho collection `favorites`**:
```javascript
match /favorites/{favoriteId} {
  // Chỉ user sở hữu mới được đọc/ghi
  allow read, write: if request.auth != null && 
    request.auth.uid == resource.data.userId;
  
  // Khi tạo mới, userId phải khớp với auth.uid
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.userId;
}
```

### 5.2. Testing

**Unit Tests**:
- `FavoritesService`: Test add, remove, get, watch
- `FavoritesProvider`: Test state management

**Widget Tests**:
- `FavoriteDestinationCard`: Test hiển thị và interactions
- `DestinationDetailScreen`: Test nút trái tim
- `FavoritesScreen`: Test empty state và list

**Integration Tests**:
- Flow: Đăng nhập → Thêm favorite → Xem favorites screen
- Flow: Chưa đăng nhập → Click favorite → Redirect login

### 5.3. Error Handling và Edge Cases
- Xử lý khi destination bị xóa khỏi Firestore (favorite vẫn còn)
- Xử lý khi network offline
- Xử lý khi Firestore permission denied
- Xử lý duplicate favorites (không thêm trùng)

### 5.4. Performance Optimization
- Cache favoriteIds trong memory để check nhanh
- Lazy load destinations khi scroll
- Debounce khi toggle favorite nhiều lần nhanh

---

## Phase 6: Polish và UX Improvements

### 6.1. Animations
- Animation khi toggle favorite (heart bounce)
- Animation khi thêm/xóa favorite trong list
- Smooth transitions khi navigate

### 6.2. Feedback
- Snackbar khi thêm/xóa favorite thành công
- Loading indicator khi đang xử lý
- Error messages rõ ràng

### 6.3. Accessibility
- Semantic labels cho các nút
- Screen reader support
- Keyboard navigation

---

## Thứ tự triển khai

1. **Phase 1**: Tạo Service và Model (Foundation)
2. **Phase 2**: Cập nhật DestinationDetailScreen (Core feature)
3. **Phase 3**: Cập nhật FavoritesScreen (Main UI)
4. **Phase 4**: Tích hợp vào các màn hình khác (Complete integration)
5. **Phase 5**: Security Rules và Testing (Quality assurance)
6. **Phase 6**: Polish và UX (Enhancement)

---

## Dependencies cần thêm

```yaml
dependencies:
  # Có thể cần thêm (nếu chưa có):
  # url_launcher: ^6.2.0  # Để mở map từ location
```

---

## Notes

- Đảm bảo favorites được sync real-time giữa các màn hình
- Xử lý offline mode nếu cần (có thể dùng local cache)
- Cân nhắc thêm analytics để track số lượng favorites
- Có thể mở rộng: Share favorites list, Export favorites

