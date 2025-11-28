# 📋 KẾ HOẠCH TRIỂN KHAI: ĐẶT TOUR CÓ SẴN

## 🎯 TỔNG QUAN

Chức năng **"Đặt tour có sẵn"** cho phép người dùng:
- Xem danh sách các tour packages được tạo sẵn bởi admin/đối tác
- Xem chi tiết tour (lịch trình, giá, điều kiện, đánh giá)
- Đặt tour với thông tin người tham gia
- Thanh toán (tùy chọn: tích hợp payment gateway hoặc đặt chỗ trước)
- Quản lý booking của mình (xem, hủy, đánh giá)

---

## 🔄 LUỒNG HOẠT ĐỘNG

### 1. **Luồng người dùng (User Flow)**

```
┌─────────────────────────────────────────────────────────┐
│  Màn hình chính (Home/Tours)                           │
│  - Danh sách tour packages                             │
│  - Filter: địa điểm, giá, thời gian, loại tour        │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  Chi tiết Tour                                          │
│  - Thông tin tour (mô tả, lịch trình, giá)             │
│  - Hình ảnh, đánh giá                                   │
│  - Nút "Đặt tour ngay"                                 │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  Form đặt tour                                          │
│  - Chọn số người tham gia                              │
│  - Chọn ngày khởi hành (nếu có nhiều ngày)             │
│  - Nhập thông tin người tham gia                       │
│  - Chọn phương thức thanh toán                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  Xác nhận & Thanh toán                                  │
│  - Tổng tiền, thông tin booking                        │
│  - Thanh toán (nếu tích hợp payment)                    │
│  - Hoặc "Đặt chỗ trước" (chờ xác nhận)                 │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  Kết quả                                                │
│  - Booking thành công                                   │
│  - Mã booking, thông tin liên hệ                       │
│  - Quản lý booking trong "Tài khoản"                    │
└─────────────────────────────────────────────────────────┘
```

### 2. **Luồng quản trị (Admin Flow)** - Tùy chọn

```
Admin tạo tour package → Lưu vào Firestore → Hiển thị cho user
```

---

## 📊 CẤU TRÚC DỮ LIỆU

### 1. **Tour Package Model**

```dart
class TourPackage {
  final String? id;
  final String title;                    // "Tour Đà Nẵng - Hội An 3N2Đ"
  final String description;               // Mô tả chi tiết
  final String shortDescription;         // Mô tả ngắn
  final List<String> images;             // Hình ảnh tour
  final String thumbnail;                // Ảnh đại diện
  
  // Địa điểm & thời gian
  final String destination;               // "Đà Nẵng - Hội An"
  final List<String> destinations;       // Danh sách điểm đến
  final int durationDays;                // 3 ngày
  final int durationNights;              // 2 đêm
  final List<DateTime> availableDates;   // Các ngày khởi hành có sẵn
  
  // Giá cả
  final double basePrice;                // Giá gốc (1 người)
  final double? childPrice;               // Giá trẻ em (nếu có)
  final double? infantPrice;             // Giá em bé (nếu có)
  final PriceType priceType;              // per_person, per_room, per_group
  final List<PriceTier> priceTiers;      // Giá theo số người (nếu có)
  
  // Lịch trình
  final List<TourItineraryDay> itinerary; // Lịch trình từng ngày
  
  // Điều kiện & chính sách
  final TourInclusions inclusions;        // Bao gồm gì
  final TourExclusions exclusions;        // Không bao gồm
  final CancellationPolicy cancellationPolicy;
  final String? termsAndConditions;
  
  // Thông tin tour
  final TourType type;                    // private, group, self_guided
  final int maxGroupSize;                 // Số người tối đa
  final int minGroupSize;                 // Số người tối thiểu
  final String? language;                 // Ngôn ngữ hướng dẫn
  final String? pickupLocation;          // Điểm đón
  final String? dropoffLocation;          // Điểm trả
  
  // Đánh giá & thống kê
  final double rating;                    // Điểm đánh giá
  final int reviewCount;                  // Số lượt đánh giá
  final int bookingCount;                 // Số lượt đặt
  final int viewCount;                    // Số lượt xem
  
  // Trạng thái
  final TourStatus status;                // active, inactive, sold_out
  final bool featured;                    // Tour nổi bật
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Metadata
  final String? providerId;                // ID đối tác cung cấp tour
  final String? providerName;             // Tên đối tác
}
```

### 2. **Tour Itinerary Day**

```dart
class TourItineraryDay {
  final int dayNumber;                   // Ngày 1, 2, 3...
  final String title;                    // "Ngày 1: Khám phá Đà Nẵng"
  final String description;               // Mô tả hoạt động
  final List<TourActivity> activities;    // Các hoạt động trong ngày
  final List<String> meals;               // ["Bữa sáng", "Bữa trưa"]
  final String? accommodation;            // Nơi nghỉ đêm
}
```

### 3. **Tour Booking Model**

```dart
class TourBooking {
  final String? id;
  final String userId;                   // User đặt tour
  final String tourPackageId;            // ID tour package
  final TourPackage? tourPackage;        // Tour package (loaded)
  
  // Thông tin booking
  final String bookingNumber;            // Mã booking (unique)
  final DateTime bookingDate;             // Ngày đặt
  final DateTime departureDate;           // Ngày khởi hành
  final int numberOfAdults;              // Số người lớn
  final int numberOfChildren;            // Số trẻ em
  final int numberOfInfants;             // Số em bé
  
  // Thông tin người tham gia
  final List<ParticipantInfo> participants;
  final ContactInfo contactInfo;         // Thông tin liên hệ
  
  // Giá cả
  final double subtotal;                 // Tổng tiền trước giảm giá
  final double? discountAmount;          // Số tiền giảm
  final double totalAmount;               // Tổng tiền phải trả
  final String currency;                 // "VND"
  
  // Thanh toán
  final PaymentStatus paymentStatus;     // pending, paid, refunded
  final PaymentMethod? paymentMethod;    // cash, bank_transfer, credit_card
  final DateTime? paidAt;                // Ngày thanh toán
  final String? paymentTransactionId;    // ID giao dịch
  
  // Trạng thái
  final BookingStatus status;            // confirmed, cancelled, completed
  final DateTime? confirmedAt;          // Ngày xác nhận
  final DateTime? cancelledAt;           // Ngày hủy
  final String? cancellationReason;      // Lý do hủy
  
  // Ghi chú
  final String? specialRequests;         // Yêu cầu đặc biệt
  final String? notes;                   // Ghi chú từ admin
}
```

### 4. **Participant Info**

```dart
class ParticipantInfo {
  final String fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? nationality;
  final String? passportNumber;          // Nếu cần
  final String? phoneNumber;
  final String? email;
}
```

---

## 🗂️ CẤU TRÚC FIRESTORE

### Collection: `tour_packages`

```json
{
  "id": "tour-dn-hoi-an-001",
  "title": "Tour Đà Nẵng - Hội An 3N2Đ",
  "description": "...",
  "destination": "Đà Nẵng - Hội An",
  "durationDays": 3,
  "basePrice": 5000000,
  "status": "active",
  "createdAt": "2024-01-01T00:00:00Z",
  ...
}
```

### Collection: `tour_bookings`

```json
{
  "id": "booking-001",
  "userId": "user-123",
  "tourPackageId": "tour-dn-hoi-an-001",
  "bookingNumber": "BK20240101001",
  "departureDate": "2024-02-15T00:00:00Z",
  "numberOfAdults": 2,
  "totalAmount": 10000000,
  "status": "confirmed",
  "paymentStatus": "paid",
  ...
}
```

### Subcollection: `tour_packages/{tourId}/reviews`

```json
{
  "userId": "user-123",
  "rating": 5,
  "comment": "Tour rất tuyệt!",
  "createdAt": "2024-01-20T00:00:00Z"
}
```

---

## 🎨 UI/UX MÀN HÌNH

### 1. **Danh sách Tour Packages** (`ToursScreen`)

- **Layout**: Grid hoặc List
- **Filter**: 
  - Địa điểm (dropdown)
  - Khoảng giá (slider)
  - Số ngày (1-3 ngày, 4-7 ngày, 8+ ngày)
  - Loại tour (private, group, self-guided)
  - Sắp xếp (giá, đánh giá, phổ biến)
- **Card Tour**:
  - Ảnh thumbnail
  - Tên tour
  - Địa điểm, số ngày
  - Giá (từ X VND/người)
  - Rating + số review
  - Badge "Nổi bật" nếu `featured = true`

### 2. **Chi tiết Tour** (`TourDetailScreen`)

- **Header**: Carousel hình ảnh
- **Thông tin cơ bản**: Tên, địa điểm, số ngày, giá
- **Tabs**:
  - **Tổng quan**: Mô tả, điểm nổi bật
  - **Lịch trình**: Chi tiết từng ngày
  - **Bao gồm/Không bao gồm**: Inclusions/Exclusions
  - **Đánh giá**: List reviews
  - **Chính sách**: Cancellation, terms
- **Sticky bottom bar**: 
  - Giá hiện tại
  - Nút "Đặt tour ngay"

### 3. **Form đặt tour** (`TourBookingScreen`)

- **Chọn ngày khởi hành**: Date picker (chỉ hiện các ngày có sẵn)
- **Chọn số người**: 
  - Người lớn (stepper)
  - Trẻ em (stepper, nếu có giá)
  - Em bé (stepper, nếu có giá)
- **Tính giá tự động**: 
  - Hiển thị breakdown (người lớn x giá, trẻ em x giá)
  - Tổng tiền
- **Thông tin người tham gia**: 
  - Form cho từng người (tên, ngày sinh, giới tính, SĐT)
  - Có thể thêm/xóa người
- **Thông tin liên hệ**: 
  - Tên, email, SĐT (người đặt)
- **Yêu cầu đặc biệt**: Text field (optional)
- **Nút "Tiếp tục"** → Màn hình xác nhận

### 4. **Xác nhận & Thanh toán** (`TourBookingConfirmScreen`)

- **Tóm tắt booking**:
  - Tour package
  - Ngày khởi hành
  - Số người
  - Tổng tiền
- **Phương thức thanh toán**:
  - Thanh toán ngay (nếu tích hợp payment gateway)
  - Đặt chỗ trước (chờ xác nhận, thanh toán sau)
- **Nút "Xác nhận đặt tour"**
- **Lưu ý**: Hiển thị chính sách hủy, điều kiện

### 5. **Kết quả booking** (`TourBookingSuccessScreen`)

- **Thành công**:
  - Icon checkmark
  - Mã booking
  - Thông tin tour
  - Hướng dẫn tiếp theo
- **Nút**: 
  - "Xem chi tiết booking"
  - "Về trang chủ"

### 6. **Quản lý Booking** (`MyBookingsScreen` - trong Account)

- **Tabs**: 
  - Sắp tới
  - Đã hoàn thành
  - Đã hủy
- **Card booking**:
  - Tour package
  - Ngày khởi hành
  - Số người
  - Trạng thái (confirmed, pending, cancelled)
  - Tổng tiền
- **Actions**: 
  - Xem chi tiết
  - Hủy booking (nếu chưa khởi hành)
  - Đánh giá (nếu đã hoàn thành)

---

## ⚠️ ĐIỂM CẦN LƯU Ý

### 1. **Business Logic**

- **Kiểm tra số chỗ còn lại**: 
  - Mỗi tour có `maxGroupSize`
  - Đếm số booking đã xác nhận cho ngày đó
  - Chỉ cho đặt nếu còn chỗ
  
- **Tính giá động**:
  - Giá có thể thay đổi theo số người (price tiers)
  - Giá trẻ em/em bé khác người lớn
  - Áp dụng giảm giá (nếu có)
  
- **Validation**:
  - Số người không vượt quá `maxGroupSize`
  - Ngày khởi hành phải trong `availableDates`
  - Ngày khởi hành không được trong quá khứ
  - Thông tin người tham gia bắt buộc

### 2. **Thanh toán**

**Option 1: Đặt chỗ trước (Không tích hợp payment)**
- User đặt tour → Booking status = "pending"
- Admin xác nhận → Status = "confirmed"
- User thanh toán offline (chuyển khoản, tiền mặt)
- Admin cập nhật `paymentStatus = "paid"`

**Option 2: Tích hợp Payment Gateway**
- Tích hợp VNPay, MoMo, Stripe, PayPal...
- User thanh toán ngay → `paymentStatus = "paid"`, `status = "confirmed"`
- Webhook xử lý kết quả thanh toán

### 3. **Quản lý Booking**

- **Hủy booking**:
  - User có thể hủy trước X ngày (theo cancellation policy)
  - Tính phí hủy (nếu có)
  - Hoàn tiền (nếu đã thanh toán)
  
- **Thông báo**:
  - Email/SMS xác nhận booking
  - Nhắc nhở trước ngày khởi hành
  - Thông báo khi booking bị hủy

### 4. **Bảo mật & Quyền**

- User chỉ xem được booking của mình
- Admin có thể xem tất cả booking
- Validation: User phải đăng nhập để đặt tour
- Rate limiting: Giới hạn số booking/ngày/user (tránh spam)

### 5. **Performance**

- Cache danh sách tour packages (ít thay đổi)
- Pagination cho danh sách tour
- Lazy load hình ảnh
- Index Firestore cho queries phức tạp

---

## 📦 CẤU TRÚC THƯ MỤC

```
lib/
├── models/
│   └── tours/
│       ├── tour_package.dart
│       ├── tour_booking.dart
│       ├── tour_itinerary.dart
│       ├── tour_inclusions.dart
│       └── tour_review.dart
├── services/
│   └── tours/
│       ├── tour_package_service.dart      # CRUD tour packages
│       ├── tour_booking_service.dart       # CRUD bookings
│       └── tour_review_service.dart        # Reviews
├── providers/
│   └── tours/
│       ├── tour_package_provider.dart      # State management cho tours
│       └── tour_booking_provider.dart      # State management cho bookings
├── screens/
│   └── tours/
│       ├── tours_screen.dart               # Danh sách tour
│       ├── tour_detail_screen.dart         # Chi tiết tour
│       ├── tour_booking_screen.dart        # Form đặt tour
│       ├── tour_booking_confirm_screen.dart # Xác nhận & thanh toán
│       ├── tour_booking_success_screen.dart # Kết quả
│       └── my_bookings_screen.dart         # Quản lý booking (trong Account)
└── widgets/
    └── tours/
        ├── tour_card.dart                  # Card tour trong list
        ├── tour_itinerary_widget.dart      # Lịch trình tour
        ├── tour_inclusions_widget.dart     # Bao gồm/Không bao gồm
        ├── tour_review_card.dart           # Card đánh giá
        └── booking_summary_widget.dart     # Tóm tắt booking
```

---

## 🚀 KẾ HOẠCH TRIỂN KHAI

### **Phase 0: Tái cấu trúc UI - Home Screen** (Tuần 0-1) ⭐ **BẮT ĐẦU TỪ ĐÂY**
- [ ] **Tái cấu trúc Home Screen**:
  - [ ] Section 1: Featured Tours Carousel (tours nổi bật)
  - [ ] Section 2: Quick Actions (2 buttons: "Đặt tour ngay" + "Tạo kế hoạch mới")
  - [ ] Section 3: Tours mới nhất (horizontal list)
  - [ ] Section 4: Destinations (thu gọn, ExpansionTile hoặc "Xem thêm")
  - [ ] Giữ search bar (có thể search cả tours và destinations)
- [ ] **Tạo widgets mới**:
  - [ ] `FeaturedToursCarousel`: Carousel tours nổi bật
  - [ ] `ToursHorizontalList`: List tours ngang
  - [ ] `QuickActionsSection`: 2 buttons hành động nhanh
  - [ ] `DestinationsPreviewSection`: Destinations thu gọn
- [ ] **Update bottom navigation** (nếu cần):
  - [ ] Giữ nguyên 5 tabs hiện tại
  - [ ] Hoặc thêm tab "Tours" riêng (tùy chọn)
- [ ] **Testing**: Test UI mới, đảm bảo không break existing features

### **Phase 1: Foundation** (Tuần 1-2)
- [ ] Tạo models: `TourPackage`, `TourBooking`, `TourItineraryDay`
- [ ] Tạo Firestore collections structure
- [ ] Tạo services: `TourPackageService`, `TourBookingService`
- [ ] Tạo providers: `TourPackageProvider`, `TourBookingProvider`
- [ ] Unit tests cho services
- [ ] **Import data mẫu**: Upload tour packages từ JSON vào Firestore

### **Phase 2: UI - Danh sách & Chi tiết** (Tuần 3-4)
- [ ] `ToursScreen`: Danh sách tour với filter
  - [ ] Filter: địa điểm, giá, số ngày, loại tour
  - [ ] Search tours
  - [ ] Sort: giá, đánh giá, phổ biến
- [ ] `TourDetailScreen`: Chi tiết tour
  - [ ] Tabs: Tổng quan, Lịch trình, Bao gồm/Không bao gồm, Đánh giá, Chính sách
  - [ ] Sticky bottom bar với giá và nút "Đặt tour ngay"
- [ ] Widgets:
  - [ ] `TourCard`: Card tour trong list
  - [ ] `TourItineraryWidget`: Lịch trình tour
  - [ ] `TourInclusionsWidget`: Bao gồm/Không bao gồm
  - [ ] `TourReviewCard`: Card đánh giá
- [ ] Tích hợp vào navigation:
  - [ ] Button "Đặt tour ngay" từ Home → ToursScreen
  - [ ] Có thể thêm vào bottom navigation (tùy chọn)

### **Phase 3: Booking Flow** (Tuần 5-6)
- [ ] `TourBookingScreen`: Form đặt tour
  - [ ] Chọn ngày khởi hành (date picker với availableDates)
  - [ ] Chọn số người (adults, children, infants)
  - [ ] Tính giá tự động (theo priceTiers nếu có)
  - [ ] Form thông tin người tham gia (dynamic list)
  - [ ] Form thông tin liên hệ
  - [ ] Yêu cầu đặc biệt (optional)
- [ ] `TourBookingConfirmScreen`: Xác nhận & thanh toán
  - [ ] Tóm tắt booking
  - [ ] Chọn phương thức thanh toán (VNPay, MoMo, hoặc đặt chỗ trước)
  - [ ] Hiển thị chính sách hủy
- [ ] `TourBookingSuccessScreen`: Kết quả
  - [ ] Mã booking
  - [ ] Thông tin tour
  - [ ] Hướng dẫn tiếp theo
- [ ] Logic validation, tính giá
- [ ] Tạo booking trong Firestore

### **Phase 4: Quản lý Booking** (Tuần 7)
- [ ] `MyBookingsScreen`: Danh sách booking của user
  - [ ] Tabs: Sắp tới, Đã hoàn thành, Đã hủy
  - [ ] Card booking với thông tin tour, ngày, trạng thái
- [ ] Chi tiết booking
  - [ ] Thông tin tour
  - [ ] Thông tin người tham gia
  - [ ] Trạng thái thanh toán
  - [ ] Actions: Hủy booking (nếu chưa khởi hành)
- [ ] Hủy booking (với validation theo cancellation policy)
- [ ] Tích hợp vào Account screen (menu item "Đặt tour của tôi")

### **Phase 5: Reviews & Polish** (Tuần 8)
- [ ] Chức năng đánh giá tour
  - [ ] Form đánh giá (rating + comment)
  - [ ] Hiển thị reviews trong TourDetailScreen
  - [ ] Tính toán rating trung bình
- [ ] Thông báo (email/SMS) - tùy chọn
- [ ] UI/UX improvements
- [ ] Testing & bug fixes

### **Phase 6: Payment Integration** (Tuần 9-10)
- [ ] Tích hợp VNPay SDK
  - [ ] Setup VNPay SDK
  - [ ] Tạo payment request
  - [ ] Xử lý payment callback
- [ ] Tích hợp MoMo SDK (hoặc chọn một)
  - [ ] Setup MoMo SDK
  - [ ] Tạo payment request
  - [ ] Xử lý payment callback
- [ ] Xử lý payment flow
  - [ ] Redirect đến payment gateway
  - [ ] Xử lý kết quả thanh toán
  - [ ] Cập nhật booking status
- [ ] Webhook xử lý kết quả thanh toán (nếu cần)
- [ ] Cập nhật booking status sau thanh toán

### **Phase 7: Partner System** (Tuần 11-12)
- [ ] Đăng ký đối tác (form, validation)
  - [ ] Form đăng ký với thông tin công ty
  - [ ] Upload giấy phép kinh doanh
  - [ ] Admin duyệt đối tác
- [ ] Partner authentication/login
  - [ ] Partner login screen
  - [ ] Partner profile
- [ ] Partner dashboard: Tạo/sửa tour packages
  - [ ] Form tạo tour package
  - [ ] Upload hình ảnh
  - [ ] Quản lý tours của mình
- [ ] Partner quản lý bookings của tour mình
  - [ ] Xem danh sách bookings
  - [ ] Xác nhận/hủy bookings
- [ ] Admin duyệt tour từ đối tác (nếu cần)

### **Phase 8: Admin Panel** (Tuần 13-14)
- [ ] Admin screen để tạo/sửa tour packages
- [ ] Admin screen quản lý bookings
- [ ] Admin quản lý đối tác
- [ ] Dashboard thống kê

---

## 🔧 CÔNG CỤ & THƯ VIỆN CẦN THIẾT

### **Hiện có:**
- ✅ Firestore (lưu trữ dữ liệu)
- ✅ Provider (state management)
- ✅ Flutter Material (UI)

### **Cần thêm:**
- 📦 `vnpay_flutter` hoặc `momo_flutter` (tích hợp payment VNPay/MoMo) - **BẮT BUỘC**
- 📦 `url_launcher` (mở email, SMS) - đã có
- 📦 `image_picker` (nếu admin/đối tác upload ảnh tour) - tùy chọn
- 📦 `intl` (format tiền, ngày tháng) - đã có

---

## 📝 GHI CHÚ QUAN TRỌNG

1. **Dữ liệu mẫu**: Cần chuẩn bị ít nhất 5-10 tour packages mẫu để test
2. **Payment**: Quyết định sớm có tích hợp payment gateway hay không
3. **Admin**: Nếu không có admin panel, cần tool import tour packages từ JSON/CSV
4. **Scalability**: Thiết kế Firestore indexes cho queries phức tạp
5. **Legal**: Cần Terms & Conditions, Privacy Policy cho booking

---

## ❓ CÂU HỎI CẦN LÀM RÕ - ĐÃ LÀM RÕ

1. **Payment**: ✅ Tích hợp VNPay hoặc MoMo
2. **Admin**: ✅ App tự tạo tour + đối tác bên thứ 3 đăng ký để đăng tour
3. **Provider**: ✅ Cả hai: app tự tạo (`providerType: "app"`) và đối tác (`providerType: "partner"`)
4. **Cancellation**: ✅ Chính sách hủy tour tự tùy chỉnh (flexible, moderate, strict)
5. **Inventory**: ⚠️ Cần quyết định: Quản lý số chỗ real-time hay chỉ hiển thị "Còn chỗ" / "Hết chỗ"?

---

## 📊 CHUẨN BỊ DATA TEST

### File mẫu đã tạo:
- ✅ `assets/data/tour_packages_sample.json` - 3 tour packages mẫu đầy đủ
- ✅ `docs/tour_package_firestore_structure.md` - Tài liệu cấu trúc dữ liệu chi tiết

### Các bước chuẩn bị:
1. **Xem file mẫu**: `assets/data/tour_packages_sample.json`
2. **Đọc tài liệu**: `docs/tour_package_firestore_structure.md` để hiểu rõ từng field
3. **Tạo thêm data**: Copy format từ file mẫu, tạo thêm 5-7 tour packages nữa
4. **Import vào Firestore**: 
   - Có thể dùng Firebase Console (manual)
   - Hoặc tạo script import (sẽ có trong Phase 1)

### Lưu ý khi tạo data:
- ✅ Mỗi tour cần có `id` unique
- ✅ `availableDates` phải là ngày trong tương lai
- ✅ `images` và `thumbnail` có thể dùng placeholder URLs (Unsplash, Pexels)
- ✅ Mix các `providerType`: một số `"app"`, một số `"partner"`
- ✅ Mix các `status`: chủ yếu `"active"`, một vài `"inactive"` để test filter

---

## 🎯 NEXT STEPS

1. ✅ **Review plan này** - Đã có thông tin đầy đủ
2. ✅ **Xem file data mẫu**: `assets/data/tour_packages_sample.json`
3. ✅ **Đọc tài liệu cấu trúc**: `docs/tour_package_firestore_structure.md`
4. **Tạo thêm data**: Tạo 5-7 tour packages nữa dựa trên mẫu
5. **Bắt đầu Phase 1**: Tạo models và services (sau khi có data)

---

**Tài liệu này sẽ được cập nhật trong quá trình triển khai.**

