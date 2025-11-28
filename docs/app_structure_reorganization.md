# 🔄 TÁI TỔ CHỨC CẤU TRÚC APP: FOCUS VÀO TOURS & CUSTOM PLANNING

## 🎯 QUAN ĐIỂM

Bạn đúng khi nói rằng **đa phần người dùng chỉ quan tâm đến:**
1. **Đặt tour có sẵn** (booking)
2. **Tự lên kế hoạch** (custom planning)

**Destinations** vẫn cần thiết nhưng nên được **tái tổ chức** để:
- Không chiếm quá nhiều không gian UI
- Phục vụ như "catalog" tham khảo cho custom planning
- Có thể tích hợp vào tours (tour packages reference đến destinations)

---

## 📱 CẤU TRÚC MỚI ĐỀ XUẤT

### **Option 1: Tách rõ 2 luồng chính (RECOMMENDED)**

```
┌─────────────────────────────────────────┐
│         HOME SCREEN (Tab 0)             │
│  ┌─────────────────────────────────┐    │
│  │  🎫 ĐẶT TOUR CÓ SẴN             │    │
│  │  - Danh sách tour packages      │    │
│  │  - Filter, search               │    │
│  │  - Featured tours               │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  ✏️ TỰ LÊN KẾ HOẠCH             │    │
│  │  - Tạo kế hoạch mới             │    │
│  │  - Xem kế hoạch của tôi         │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  📍 KHÁM PHÁ ĐỊA ĐIỂM           │    │
│  │  - Danh sách destinations       │    │
│  │  (Phục vụ cho custom planning)  │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

**Bottom Navigation:**
- **Trang chủ** (0): Tours + Custom Planning + Destinations (catalog)
- **Tours** (1): Chỉ tours (có thể merge vào Home)
- **Yêu thích** (2): Tours yêu thích + Destinations yêu thích
- **Bản đồ** (3): Map với tours và destinations
- **Tài khoản** (4): Profile, bookings, trips

### **Option 2: Tách hoàn toàn 2 luồng**

```
Bottom Navigation:
- Trang chủ (0): Tours nổi bật
- Đặt tour (1): Danh sách tours, filter, booking
- Tự lên kế hoạch (2): Tạo trip, quản lý trips
- Yêu thích (3): Tours + Destinations yêu thích
- Tài khoản (4): Profile, bookings, trips
```

**Destinations** chỉ xuất hiện trong:
- Màn hình "Tự lên kế hoạch" → Khi thêm điểm đến vào trip
- Màn hình "Yêu thích" → Destinations yêu thích
- Màn hình "Bản đồ" → Hiển thị trên map

---

## 🔄 CÁCH TỔ CHỨC LẠI

### **1. Home Screen - Tái cấu trúc**

**Trước:**
- Destinations là focus chính
- Có search, categories, recommended destinations

**Sau:**
- **Section 1**: Tours nổi bật (featured tours)
- **Section 2**: Quick actions:
  - Button "Đặt tour ngay" → ToursScreen
  - Button "Tạo kế hoạch mới" → CreateTripScreen
- **Section 3**: Destinations (thu gọn, chỉ hiển thị một số nổi bật)
  - Có thể collapse/expand
  - Hoặc chuyển thành "Khám phá thêm" → DestinationsScreen

### **2. Destinations - Vai trò mới**

**Destinations không còn là focus chính, mà là:**
- **Catalog** để user tham khảo khi tự lên kế hoạch
- **Reference** trong tour packages (tour có thể link đến destinations)
- **Discovery tool** cho user muốn khám phá

**Các màn hình destinations:**
- `DestinationsScreen`: Danh sách đầy đủ (ít dùng, có thể bỏ hoặc để trong menu)
- `DestinationDetailScreen`: Chi tiết điểm đến (vẫn cần khi user xem từ trip hoặc tour)
- `AddDestinationsToTripScreen`: Thêm điểm đến vào trip (vẫn cần)

### **3. Tours - Focus chính**

**Màn hình mới:**
- `ToursScreen`: Danh sách tours (filter, search, categories)
- `TourDetailScreen`: Chi tiết tour
- `TourBookingScreen`: Form đặt tour
- `MyBookingsScreen`: Quản lý bookings

---

## 📊 SO SÁNH: TRƯỚC vs SAU

### **TRƯỚC:**
```
Home → Destinations (focus)
  ├─ Search destinations
  ├─ Categories
  ├─ Recommended destinations
  └─ Favorites destinations

Trips → Custom planning
  └─ Add destinations to trip
```

### **SAU:**
```
Home → Tours + Custom Planning (focus)
  ├─ Featured tours
  ├─ Quick actions (Đặt tour / Tạo kế hoạch)
  └─ Destinations (catalog, thu gọn)

Tours → Booking flow
  ├─ List tours
  ├─ Tour detail
  └─ Booking

Trips → Custom planning
  └─ Add destinations (từ catalog)
```

---

## 🎨 UI/UX ĐỀ XUẤT

### **Home Screen mới:**

```dart
Scaffold(
  body: SingleChildScrollView(
    children: [
      // Section 1: Hero - Tours nổi bật
      FeaturedToursCarousel(),
      
      // Section 2: Quick Actions
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.luggage),
              label: Text('Đặt tour ngay'),
              onPressed: () => Navigator.push(ToursScreen()),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.edit_calendar),
              label: Text('Tạo kế hoạch'),
              onPressed: () => Navigator.push(CreateTripScreen()),
            ),
          ),
        ],
      ),
      
      // Section 3: Tours mới nhất
      SectionHeader(title: 'Tours mới nhất'),
      ToursHorizontalList(),
      
      // Section 4: Destinations (Thu gọn)
      ExpansionTile(
        title: Text('Khám phá địa điểm'),
        children: [
          DestinationsGrid(limit: 6),
          TextButton(
            onPressed: () => Navigator.push(DestinationsScreen()),
            child: Text('Xem tất cả'),
          ),
        ],
      ),
    ],
  ),
)
```

### **Bottom Navigation mới:**

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Trang chủ',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.luggage),
      label: 'Tours',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.edit_calendar),
      label: 'Kế hoạch',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.favorite_border),
      label: 'Yêu thích',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'Tài khoản',
    ),
  ],
)
```

---

## ✅ KẾ HOẠCH TÁI TỔ CHỨC

### **Phase 1: Tái cấu trúc Home Screen**
- [ ] Thêm section Tours nổi bật
- [ ] Thêm Quick Actions (Đặt tour / Tạo kế hoạch)
- [ ] Thu gọn Destinations section
- [ ] Update bottom navigation

### **Phase 2: Tạo Tours Screen**
- [ ] Tạo `ToursScreen` với filter, search
- [ ] Tích hợp vào bottom navigation
- [ ] Remove destinations từ home (hoặc thu gọn)

### **Phase 3: Cleanup Destinations**
- [ ] Giữ `DestinationDetailScreen` (vẫn cần)
- [ ] Giữ `AddDestinationsToTripScreen` (vẫn cần)
- [ ] Có thể bỏ hoặc ẩn `DestinationsScreen` (danh sách đầy đủ)
- [ ] Destinations chỉ xuất hiện khi cần (trong custom planning flow)

---

## 🎯 KẾT LUẬN

**Không nên bỏ destinations hoàn toàn** vì:
1. ✅ Cần cho chức năng "Tự lên kế hoạch"
2. ✅ Tour packages có thể reference đến destinations
3. ✅ User vẫn cần xem chi tiết điểm đến

**Nên làm:**
1. ✅ **Tái tổ chức UI** để Tours và Custom Planning là focus
2. ✅ **Thu gọn Destinations** thành catalog/tham khảo
3. ✅ **Tách rõ 2 luồng**: Đặt tour vs Tự lên kế hoạch
4. ✅ **Update bottom navigation** để phản ánh cấu trúc mới

---

## ❓ QUYẾT ĐỊNH CẦN LÀM

1. **Bottom Navigation**: Giữ 5 tabs hay rút xuống 4 tabs?
2. **Home Screen**: Merge Tours + Custom Planning + Destinations hay tách riêng?
3. **Destinations Screen**: Bỏ hoàn toàn hay giữ nhưng ẩn trong menu?

