# Kế hoạch triển khai chức năng: Xem đặc sản và hoạt động tại điểm du lịch

## Mục tiêu
Cho phép người dùng xem các đặc sản (đồ ăn, đồ uống) và hoạt động có thể thực hiện tại từng điểm du lịch trong màn hình chi tiết địa điểm.

## Phân tích cấu trúc Data

### Specialties (Đặc sản)
Mỗi destination có field `specialties` là array các đối tượng với cấu trúc:
```json
{
  "name": "Kem Tràng Tiền",
  "type": "food",  // hoặc "drink"
  "price_range": "10k - 20k",
  "description": "Kem truyền thống nổi tiếng Hà Nội...",
  "image": "https://...",  // optional
  "location": "Phố Tràng Tiền, gần hồ",  // optional
  "rating": 4.6  // optional
}
```

### Activities (Hoạt động)
Mỗi destination có field `activities` là array các đối tượng với cấu trúc:
```json
{
  "name": "Dạo bộ quanh hồ",
  "duration": "30-45 phút",
  "best_time": "Sáng sớm (5:00 - 7:00) hoặc chiều tối (18:00 - 20:00)",
  "description": "Đi bộ một vòng quanh hồ, ngắm cảnh đẹp..."
}
```

## Yêu cầu UI/UX

### 1. Specialties Section
- **Header**: "Đặc sản & Ẩm thực" với icon 🍽️
- **Filter tabs**: "Tất cả", "Đồ ăn", "Đồ uống" (horizontal scrollable)
- **Layout**: Grid 2 cột hoặc List tùy số lượng
- **Card design**: 
  - Ảnh (nếu có) hoặc placeholder icon
  - Tên món/đồ uống
  - Badge type (food/drink) với màu khác nhau
  - Rating với icon sao (nếu có)
  - Price range với màu nổi bật
  - Description (có thể expand)
  - Location với icon (nếu có)
- **Empty state**: "Chưa có thông tin đặc sản"

### 2. Activities Section
- **Header**: "Hoạt động & Trải nghiệm" với icon 🎯
- **Layout**: List vertical
- **Card design**:
  - Icon phù hợp với loại hoạt động
  - Tên hoạt động (bold)
  - Duration badge (màu xanh)
  - Best time với icon đồng hồ
  - Description
- **Empty state**: "Chưa có thông tin hoạt động"

### 3. Vị trí trong DestinationDetailScreen
- Đặt sau section "Ưu đãi cho bạn"
- Trước section "Giá và nút Chọn"
- Chỉ hiển thị khi có data (specialties.length > 0 hoặc activities.length > 0)

---

## Phase 1: Tạo Widget Components

### 1.1. Tạo `SpecialtyCard` Widget
**File**: `lib/widgets/specialty_card.dart`

**Props**:
- `specialty`: Specialty object
- `onTap`: Callback khi tap vào card (optional)

**UI Design**:
```
┌─────────────────────────────────┐
│ [Image]  Tên món                │
│          ⭐ 4.6  🍽️ Food        │
│          💰 10k - 20k           │
│          📍 Location             │
│          Description...         │
└─────────────────────────────────┘
```

**Features**:
- Hiển thị ảnh từ URL hoặc placeholder icon
- Badge type với màu: Food (orange), Drink (blue)
- Rating với icon sao (nếu có)
- Price range với format đẹp
- Location với icon map pin (nếu có)
- Description có thể expand/collapse
- Tap để xem chi tiết (có thể mở modal)

**Dependencies**:
- `cached_network_image` cho ảnh
- Material icons

### 1.2. Tạo `ActivityCard` Widget
**File**: `lib/widgets/activity_card.dart`

**Props**:
- `activity`: Activity object
- `onTap`: Callback khi tap (optional)

**UI Design**:
```
┌─────────────────────────────────┐
│ 🎯 Tên hoạt động                │
│    ⏱️ 30-45 phút                │
│    🕐 Best time                  │
│    Description...                │
└─────────────────────────────────┘
```

**Features**:
- Icon động theo tên hoạt động (dùng logic mapping)
- Duration badge với màu xanh
- Best time với icon đồng hồ
- Description đầy đủ
- Tap để xem chi tiết

**Icon mapping**:
- "dạo", "đi bộ" → Icons.directions_walk
- "tham quan" → Icons.explore
- "chụp ảnh" → Icons.camera_alt
- "xem", "biểu diễn" → Icons.theater_comedy
- Default → Icons.local_activity

### 1.3. Tạo `SpecialtiesSection` Widget
**File**: `lib/widgets/specialties_section.dart`

**Props**:
- `specialties`: List<Specialty>
- `onSpecialtyTap`: Callback (optional)

**State**:
- `selectedFilter`: "all", "food", "drink"
- `isExpanded`: bool (cho mỗi specialty)

**Features**:
- Header với icon và title
- Filter tabs (horizontal scrollable)
- Grid/List layout tùy số lượng
- Empty state khi không có data
- Animation khi filter

**Layout logic**:
- Nếu specialties.length <= 2: List layout
- Nếu specialties.length > 2: Grid 2 cột

### 1.4. Tạo `ActivitiesSection` Widget
**File**: `lib/widgets/activities_section.dart`

**Props**:
- `activities`: List<Activity>
- `onActivityTap`: Callback (optional)

**Features**:
- Header với icon và title
- List layout vertical
- Empty state khi không có data
- Smooth scroll animation

---

## Phase 2: Tích hợp vào DestinationDetailScreen

### 2.1. Thêm imports
**File**: `lib/screens/destination_detail_screen.dart`

```dart
import '../widgets/specialties_section.dart';
import '../widgets/activities_section.dart';
```

### 2.2. Thêm sections vào UI
**Vị trí**: Sau section "Ưu đãi cho bạn", trước section "Giá và nút Chọn"

**Code structure**:
```dart
// ... existing code ...

// Section "Ưu đãi cho bạn"
if (widget.destination.tags.isNotEmpty || widget.destination.verified) ...[
  // ... existing code ...
],

// [MỚI] Section "Đặc sản & Ẩm thực"
if (widget.destination.specialties.isNotEmpty) ...[
  const SizedBox(height: 24),
  SpecialtiesSection(
    specialties: widget.destination.specialties,
  ),
],

// [MỚI] Section "Hoạt động & Trải nghiệm"
if (widget.destination.activities.isNotEmpty) ...[
  const SizedBox(height: 24),
  ActivitiesSection(
    activities: widget.destination.activities,
  ),
],

// Section "Giá và nút Chọn"
// ... existing code ...
```

### 2.3. Xử lý empty states
- Nếu không có specialties và activities: Không hiển thị sections
- Nếu chỉ có một trong hai: Chỉ hiển thị section có data

---

## Phase 3: UI/UX Enhancements

### 3.1. Animations
- **Fade-in animation**: Khi scroll đến section
- **Filter animation**: Smooth transition khi đổi filter
- **Card animations**: Hover/tap effects

### 3.2. Interactions
- **Tap specialty card**: 
  - Option 1: Expand description inline
  - Option 2: Mở modal/dialog với thông tin chi tiết
  - Option 3: Navigate đến màn hình chi tiết specialty (nếu cần)
  
- **Tap activity card**:
  - Expand description inline
  - Hoặc hiển thị tooltip với thông tin đầy đủ

### 3.3. Visual Enhancements
- **Color coding**:
  - Food badge: Orange (#FF9800)
  - Drink badge: Blue (#2196F3)
  - Duration badge: Green (#4CAF50)
  
- **Icons**:
  - Food: Icons.restaurant
  - Drink: Icons.local_drink
  - Rating: Icons.star (amber)
  - Price: Icons.attach_money
  - Location: Icons.location_on
  - Duration: Icons.timer
  - Best time: Icons.access_time

- **Typography**:
  - Title: FontWeight.bold, fontSize: 18
  - Name: FontWeight.w600, fontSize: 16
  - Description: FontWeight.normal, fontSize: 14
  - Price: FontWeight.bold, fontSize: 14, color: orange

### 3.4. Responsive Design
- Grid layout tự động điều chỉnh theo màn hình
- Padding và spacing phù hợp với các kích thước màn hình

---

## Phase 4: Optional Features (Future)

### 4.1. Search trong Specialties
- Search bar để tìm kiếm món ăn/đồ uống
- Filter theo tên, type, price range

### 4.2. Sort Options
- Sort theo: Rating, Price, Name
- Dropdown hoặc bottom sheet

### 4.3. Map Integration
- Hiển thị location của specialty trên map
- Click location để mở map app

### 4.4. Favorites cho Specialties
- Cho phép lưu specialty yêu thích
- Hiển thị trong profile hoặc favorites screen

### 4.5. Share Specialty/Activity
- Chia sẻ thông tin specialty/activity qua social media

---

## Thứ tự triển khai

1. **Step 1**: Tạo `SpecialtyCard` widget (Foundation)
2. **Step 2**: Tạo `ActivityCard` widget (Foundation)
3. **Step 3**: Tạo `SpecialtiesSection` widget (Container)
4. **Step 4**: Tạo `ActivitiesSection` widget (Container)
5. **Step 5**: Tích hợp vào `DestinationDetailScreen` (Integration)
6. **Step 6**: Polish UI/UX (Animations, Colors, Spacing)
7. **Step 7**: Testing và fix bugs (Quality assurance)

---

## Dependencies cần thêm

```yaml
dependencies:
  # Đã có sẵn:
  # cached_network_image: ^3.3.1
  
  # Có thể cần thêm (nếu chưa có):
  # url_launcher: ^6.2.0  # Để mở map từ location
```

---

## Testing Checklist

### Unit Tests
- [ ] SpecialtyCard: Test hiển thị đúng data
- [ ] ActivityCard: Test hiển thị đúng data
- [ ] SpecialtiesSection: Test filter logic
- [ ] ActivitiesSection: Test empty state

### Widget Tests
- [ ] Test SpecialtyCard với đầy đủ fields
- [ ] Test SpecialtyCard với missing fields (image, rating, location)
- [ ] Test ActivityCard với các loại hoạt động khác nhau
- [ ] Test filter tabs trong SpecialtiesSection
- [ ] Test empty states

### Integration Tests
- [ ] Test hiển thị specialties trong DestinationDetailScreen
- [ ] Test hiển thị activities trong DestinationDetailScreen
- [ ] Test filter specialties
- [ ] Test tap interactions

### Manual Testing
- [ ] Test với destination có nhiều specialties
- [ ] Test với destination có ít specialties
- [ ] Test với destination không có specialties
- [ ] Test với destination có nhiều activities
- [ ] Test với destination không có activities
- [ ] Test responsive trên các kích thước màn hình
- [ ] Test scroll performance với nhiều items

---

## Notes

- Đảm bảo UI nhất quán với design system hiện tại (màu cam chủ đạo)
- Xử lý gracefully khi thiếu data (image, rating, location)
- Tối ưu performance khi render nhiều cards
- Cân nhắc lazy loading cho ảnh
- Có thể cache ảnh specialties để tăng tốc độ load
- Xử lý lỗi khi load ảnh (error widget)
- Accessibility: Thêm semantic labels cho screen readers

---

## UI Mockup Concept

### Specialties Section
```
┌─────────────────────────────────────────┐
│ 🍽️ Đặc sản & Ẩm thực                   │
│ [Tất cả] [Đồ ăn] [Đồ uống]             │
├─────────────────────────────────────────┤
│ ┌─────────┐  ┌─────────┐               │
│ │ [Image] │  │ [Image] │               │
│ │ Name    │  │ Name    │               │
│ │ ⭐ 4.6  │  │ ⭐ 4.7  │               │
│ │ 🍽️ Food│  │ 🥤 Drink│               │
│ │ 💰 Price│  │ 💰 Price│               │
│ └─────────┘  └─────────┘               │
└─────────────────────────────────────────┘
```

### Activities Section
```
┌─────────────────────────────────────────┐
│ 🎯 Hoạt động & Trải nghiệm              │
├─────────────────────────────────────────┤
│ 🚶 Dạo bộ quanh hồ                      │
│    ⏱️ 30-45 phút                         │
│    🕐 Sáng sớm (5:00 - 7:00)            │
│    Description...                       │
├─────────────────────────────────────────┤
│ 📸 Chụp ảnh cầu Thê Húc                 │
│    ⏱️ 15-30 phút                         │
│    🕐 Sáng sớm hoặc hoàng hôn            │
│    Description...                       │
└─────────────────────────────────────────┘
```

---

## Estimated Time

- Phase 1 (Widgets): 2-3 hours
- Phase 2 (Integration): 1 hour
- Phase 3 (Polish): 1-2 hours
- Testing: 1 hour
- **Total**: ~5-7 hours

---

## Success Criteria

✅ Người dùng có thể xem danh sách đặc sản tại điểm du lịch
✅ Người dùng có thể filter đặc sản theo type (food/drink)
✅ Người dùng có thể xem danh sách hoạt động tại điểm du lịch
✅ UI đẹp, nhất quán với design system
✅ Performance tốt, không lag khi scroll
✅ Xử lý gracefully các trường hợp thiếu data
✅ Responsive trên các kích thước màn hình

