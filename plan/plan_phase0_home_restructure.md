# 📋 PHASE 0: TÁI CẤU TRÚC HOME SCREEN (Option 1)

## 🎯 MỤC TIÊU

Tái cấu trúc Home Screen để:
- **Tours** và **Custom Planning** là focus chính
- **Destinations** vẫn có nhưng thu gọn (catalog/tham khảo)
- Tách rõ 2 luồng: Đặt tour vs Tự lên kế hoạch

---

## 📐 CẤU TRÚC MỚI CỦA HOME SCREEN

```
HomeScreen
├─ AppBar
│  └─ Search bar (search cả tours và destinations)
│
├─ Body (SingleChildScrollView)
│  ├─ Section 1: Featured Tours Carousel
│  │  └─ FeaturedToursCarousel (3-5 tours nổi bật)
│  │
│  ├─ Section 2: Quick Actions
│  │  └─ QuickActionsSection
│  │     ├─ Button "Đặt tour ngay" (primary, lớn)
│  │     └─ Button "Tạo kế hoạch mới" (secondary)
│  │
│  ├─ Section 3: Tours mới nhất
│  │  └─ ToursHorizontalList (horizontal scroll)
│  │
│  └─ Section 4: Destinations (Thu gọn)
│     └─ DestinationsPreviewSection
│        ├─ ExpansionTile hoặc "Khám phá địa điểm"
│        ├─ DestinationsGrid (6-8 destinations)
│        └─ Button "Xem tất cả" → DestinationsScreen
│
└─ BottomNavigationBar (giữ nguyên)
```

---

## 🛠️ CÁC FILE CẦN TẠO/SỬA

### **1. Widgets mới cần tạo:**

#### `lib/widgets/tours/featured_tours_carousel.dart`
```dart
class FeaturedToursCarousel extends StatelessWidget {
  // Carousel hiển thị 3-5 tours nổi bật (featured = true)
  // Sử dụng PageView hoặc CarouselSlider
}
```

#### `lib/widgets/tours/tours_horizontal_list.dart`
```dart
class ToursHorizontalList extends StatelessWidget {
  // Horizontal scroll list tours mới nhất
  // Sử dụng ListView.builder với scrollDirection: Axis.horizontal
}
```

#### `lib/widgets/common/quick_actions_section.dart`
```dart
class QuickActionsSection extends StatelessWidget {
  // 2 buttons: "Đặt tour ngay" và "Tạo kế hoạch mới"
  // Layout: Row với 2 Expanded buttons
}
```

#### `lib/widgets/destinations/destinations_preview_section.dart`
```dart
class DestinationsPreviewSection extends StatelessWidget {
  // Destinations thu gọn
  // Có thể dùng ExpansionTile hoặc Section với "Xem thêm"
  // Hiển thị 6-8 destinations nổi bật
}
```

### **2. Files cần sửa:**

#### `lib/screens/home/home_screen.dart`
- **Xóa hoặc thu gọn** các sections destinations hiện tại
- **Thêm** Section 1: Featured Tours Carousel
- **Thêm** Section 2: Quick Actions
- **Thêm** Section 3: Tours mới nhất
- **Sửa** Section 4: Destinations (thu gọn)
- **Giữ** search bar (có thể search cả tours và destinations)

#### `lib/providers/tours/tour_package_provider.dart` (sẽ tạo trong Phase 1)
- Load featured tours
- Load tours mới nhất
- Search tours

---

## 📝 CHECKLIST CHI TIẾT

### **Bước 1: Tạo Tour Models & Services (tạm thời)**
- [ ] Tạo `TourPackage` model cơ bản (chỉ cần fields để hiển thị)
- [ ] Tạo `TourPackageService` cơ bản (load từ Firestore)
- [ ] Tạo `TourPackageProvider` cơ bản (state management)
- [ ] **Note**: Sẽ hoàn thiện trong Phase 1, bây giờ chỉ cần đủ để hiển thị

### **Bước 2: Tạo Widgets mới**
- [ ] `FeaturedToursCarousel`
  - [ ] Load tours với `featured = true`
  - [ ] Carousel với PageView hoặc CarouselSlider
  - [ ] Tap vào tour → Navigate to TourDetailScreen (sẽ tạo sau)
  - [ ] Hiển thị: thumbnail, title, destination, price, rating
- [ ] `ToursHorizontalList`
  - [ ] Load tours mới nhất (sort by createdAt)
  - [ ] Horizontal scroll ListView
  - [ ] Tap vào tour → Navigate to TourDetailScreen
  - [ ] Hiển thị: thumbnail, title, price
- [ ] `QuickActionsSection`
  - [ ] Button "Đặt tour ngay" (primary, icon: Icons.luggage)
  - [ ] Button "Tạo kế hoạch mới" (secondary, icon: Icons.edit_calendar)
  - [ ] Layout: Row với 2 Expanded buttons
  - [ ] Navigate: ToursScreen và CreateTripScreen
- [ ] `DestinationsPreviewSection`
  - [ ] Load 6-8 destinations nổi bật (có thể dùng existing logic)
  - [ ] Grid layout (2-3 columns)
  - [ ] ExpansionTile hoặc Section với "Xem thêm"
  - [ ] Button "Xem tất cả" → DestinationsScreen (nếu cần)

### **Bước 3: Sửa Home Screen**
- [ ] **Xóa/Thu gọn** sections destinations cũ:
  - [ ] Xóa hoặc thu gọn "Bạn muốn đi đâu chơi?"
  - [ ] Xóa hoặc thu gọn Category Chips
  - [ ] Xóa hoặc thu gọn "Gợi ý theo mùa"
  - [ ] Xóa hoặc thu gọn "Gợi ý theo tags"
  - [ ] Xóa hoặc thu gọn tabs "Đề xuất | Gần đây"
- [ ] **Thêm** Section 1: Featured Tours Carousel
  - [ ] Load featured tours từ provider
  - [ ] Hiển thị carousel
  - [ ] Handle empty state (nếu chưa có tours)
- [ ] **Thêm** Section 2: Quick Actions
  - [ ] Thêm QuickActionsSection
  - [ ] Test navigation
- [ ] **Thêm** Section 3: Tours mới nhất
  - [ ] Load tours mới nhất từ provider
  - [ ] Hiển thị horizontal list
  - [ ] Handle empty state
- [ ] **Sửa** Section 4: Destinations
  - [ ] Thu gọn thành DestinationsPreviewSection
  - [ ] Giữ logic load destinations hiện tại (nhưng chỉ hiển thị 6-8)
  - [ ] Có thể collapse/expand hoặc "Xem thêm"
- [ ] **Giữ** search bar
  - [ ] Có thể search cả tours và destinations
  - [ ] Hiển thị kết quả mixed (tours + destinations)

### **Bước 4: Update Navigation**
- [ ] Button "Đặt tour ngay" → Navigate to ToursScreen
  - [ ] Tạo ToursScreen tạm thời (chỉ hiển thị "Coming soon" nếu chưa có)
- [ ] Button "Tạo kế hoạch mới" → Navigate to CreateTripScreen (đã có)
- [ ] Tap vào tour → Navigate to TourDetailScreen
  - [ ] Tạo TourDetailScreen tạm thời (chỉ hiển thị "Coming soon" nếu chưa có)

### **Bước 5: Testing**
- [ ] Test UI mới
  - [ ] Featured tours carousel hoạt động
  - [ ] Quick actions navigate đúng
  - [ ] Tours horizontal list scroll được
  - [ ] Destinations preview hiển thị đúng
- [ ] Test không break existing features
  - [ ] Search vẫn hoạt động
  - [ ] Favorites vẫn hoạt động
  - [ ] Trips vẫn hoạt động
- [ ] Test empty states
  - [ ] Nếu chưa có tours → Hiển thị placeholder
  - [ ] Nếu chưa có destinations → Ẩn section

---

## 🎨 UI MOCKUP

### **Section 1: Featured Tours Carousel**
```
┌─────────────────────────────────────────┐
│  [<]  Tour Đà Nẵng - Hội An  [>]      │
│  ┌─────────────────────────────────┐  │
│  │  [Ảnh tour]                     │  │
│  │  Tour Đà Nẵng - Hội An 3N2Đ    │  │
│  │  Đà Nẵng - Hội An              │  │
│  │  ⭐ 4.8 (125) | 5,000,000₫     │  │
│  └─────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### **Section 2: Quick Actions**
```
┌─────────────────────────────────────────┐
│  ┌──────────────────┐ ┌──────────────┐ │
│  │ 🎫 Đặt tour ngay │ │ ✏️ Tạo kế    │ │
│  │                  │ │    hoạch mới │ │
│  └──────────────────┘ └──────────────┘ │
└─────────────────────────────────────────┘
```

### **Section 3: Tours mới nhất**
```
┌─────────────────────────────────────────┐
│  Tours mới nhất                         │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ →        │
│  │Tour│ │Tour│ │Tour│ │Tour│          │
│  └────┘ └────┘ └────┘ └────┘          │
└─────────────────────────────────────────┘
```

### **Section 4: Destinations (Thu gọn)**
```
┌─────────────────────────────────────────┐
│  ▼ Khám phá địa điểm                    │
│  ┌────┐ ┌────┐ ┌────┐                  │
│  │Dest│ │Dest│ │Dest│                  │
│  └────┘ └────┘ └────┘                  │
│  ┌────┐ ┌────┐ ┌────┐                  │
│  │Dest│ │Dest│ │Dest│                  │
│  └────┘ └────┘ └────┘                  │
│  [Xem tất cả →]                        │
└─────────────────────────────────────────┘
```

---

## ⚠️ LƯU Ý

1. **Tạm thời chưa có Tours data**:
   - Có thể tạo mock data để test UI
   - Hoặc hiển thị placeholder/empty state
   - Sẽ load real data sau khi có Firestore data

2. **Không break existing features**:
   - Destinations vẫn hoạt động (chỉ thu gọn)
   - Search vẫn hoạt động
   - Favorites vẫn hoạt động
   - Trips vẫn hoạt động

3. **Navigation tạm thời**:
   - ToursScreen và TourDetailScreen có thể tạm thời hiển thị "Coming soon"
   - Sẽ implement đầy đủ trong Phase 2

4. **Provider tạm thời**:
   - TourPackageProvider có thể chỉ load mock data hoặc empty list
   - Sẽ hoàn thiện trong Phase 1

---

## ✅ KẾT QUẢ MONG ĐỢI

Sau Phase 0:
- ✅ Home Screen mới với Tours là focus
- ✅ Quick Actions rõ ràng (Đặt tour / Tạo kế hoạch)
- ✅ Destinations thu gọn, không chiếm quá nhiều không gian
- ✅ UI/UX rõ ràng, tách bạch 2 luồng
- ✅ Không break existing features

---

## 🚀 NEXT STEPS

Sau Phase 0:
1. **Phase 1**: Hoàn thiện Tour models, services, providers
2. **Phase 2**: Implement ToursScreen và TourDetailScreen đầy đủ
3. **Phase 3**: Implement booking flow

