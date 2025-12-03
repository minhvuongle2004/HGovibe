# 📋 KẾ HOẠCH CHI TIẾT: PHASE 8 - ADMIN WEB INTERFACE

## 🎯 MỤC TIÊU

Triển khai đầy đủ Admin Web Interface để quản lý:
- 📊 **Dashboard** với thống kê real-time
- 👥 **Users Management** (CRUD, Ban/Unban)
- 📍 **Destinations Management** (CRUD)
- 🎫 **Tours Management** (CRUD, Activate/Deactivate)
- 📋 **Bookings Management** (Xác nhận, Hủy, Export)
- 🚀 **Deploy** lên Firebase Hosting

---

## 📦 CHUẨN BỊ

### **1. Shared Code Strategy**

**Option A: Import từ mobile app (Khuyến nghị)**
- Copy models từ `lib/models/` vào `admin_web/lib/models/`
- Copy services từ `lib/services/` vào `admin_web/lib/services/`
- Hoặc tạo shared package (nếu monorepo)

**Option B: Tạo mới cho admin web**
- Tạo models/services riêng cho admin web
- Không khuyến nghị (duplicate code)

**Khuyến nghị: Option A** - Copy models và services từ mobile app.

### **2. Models cần copy:**

```
lib/models/
├── users/
│   └── app_user.dart
├── destinations/
│   └── destination.dart
├── tours/
│   ├── tour_package.dart
│   ├── tour_booking.dart
│   ├── tour_itinerary_day.dart
│   ├── tour_activity.dart
│   ├── tour_inclusions.dart
│   ├── tour_exclusions.dart
│   ├── cancellation_policy.dart
│   ├── price_tier.dart
│   ├── participant_info.dart
│   └── contact_info.dart
```

### **3. Services cần copy/adapt:**

```
lib/services/
├── users/
│   └── user_profile_service.dart
├── destinations/
│   └── destination_service.dart
├── tours/
│   ├── tour_package_service.dart
│   └── tour_booking_service.dart
```

**Lưu ý:** Cần thêm admin-specific methods:
- `banUser()`, `unbanUser()`, `deleteUser()`
- `confirmBooking()`, `cancelBooking()`
- `activateTour()`, `deactivateTour()`

---

## 🚀 KẾ HOẠCH TRIỂN KHAI CHI TIẾT

### **Phase 8.1: Dashboard với Thống kê** (Tuần 1)

#### **Bước 1: Copy Models & Services**
- [ ] Copy models từ mobile app vào `admin_web/lib/models/`
- [ ] Copy services từ mobile app vào `admin_web/lib/services/`
- [ ] Update imports trong services
- [ ] Test services hoạt động với Firebase

#### **Bước 2: Dashboard Stats Cards**
- [ ] Tạo `StatsCard` widget
- [ ] Implement 4 stats cards:
  - **Total Users**: Query `users` collection count
  - **Total Tours**: Query `tour_packages` collection count
  - **Total Bookings**: Query `tour_bookings` collection count
  - **Pending Bookings**: Query `tour_bookings` where `status = pending` count
- [ ] Real-time updates (StreamBuilder)
- [ ] Loading states
- [ ] Error handling

#### **Bước 3: Quick Actions**
- [ ] Tạo `QuickActionCard` widget
- [ ] Buttons:
  - "Xem bookings mới" → Navigate to `/bookings?tab=pending`
  - "Tạo tour mới" → Navigate to `/tours/new`
  - "Thêm điểm đến" → Navigate to `/destinations/new`
- [ ] Badge hiển thị số bookings pending

#### **Bước 4: Recent Activity (Optional)**
- [ ] Hiển thị 5 bookings mới nhất
- [ ] Hiển thị 5 tours mới nhất
- [ ] Click vào item → Navigate to detail

#### **Bước 5: Testing**
- [ ] Test stats cards hiển thị đúng
- [ ] Test real-time updates
- [ ] Test quick actions navigation

---

### **Phase 8.2: Users Management** (Tuần 2)

#### **Bước 1: Setup Services**
- [ ] Copy `UserProfileService` từ mobile app
- [ ] Tạo `AdminUserService` với methods:
  - `getAllUsers()` - Lấy tất cả users với pagination
  - `searchUsers(String query)` - Search users
  - `banUser(String userId)` - Ban user
  - `unbanUser(String userId)` - Unban user
  - `deleteUser(String userId)` - Soft delete user
  - `getUserById(String userId)` - Lấy user detail

#### **Bước 2: Users List Screen**
- [ ] Tạo `UsersScreen` với:
  - **Search bar**: Search by email, name
  - **Filter chips**: All, Active, Banned
  - **Data table** với columns:
    - Avatar
    - Email
    - Name
    - Status (Active/Banned)
    - Created Date
    - Actions (View, Ban/Unban, Delete)
  - **Pagination**: 20 items per page
  - **Sort**: Email, Name, Created Date

#### **Bước 3: User Detail Screen**
- [ ] Tạo `UserDetailScreen`:
  - **User Info**: Email, Name, Phone, Avatar
  - **Stats**: 
    - Số bookings
    - Số trips
    - Tổng chi tiêu (nếu có)
  - **Tabs**:
    - Bookings: Danh sách bookings của user
    - Trips: Danh sách trips của user
  - **Actions**: Ban, Unban, Delete

#### **Bước 4: Ban/Unban Functionality**
- [ ] Update Firestore: Thêm field `banned: true/false` vào user document
- [ ] Ban user: Set `banned = true`, `bannedAt = timestamp`
- [ ] Unban user: Set `banned = false`, `bannedAt = null`
- [ ] Confirmation dialog trước khi ban/delete
- [ ] Toast notification sau khi action

#### **Bước 5: Export Functionality**
- [ ] Export users to CSV:
  - Email, Name, Status, Created Date
- [ ] Button "Export CSV" trong UsersScreen

#### **Bước 6: Testing**
- [ ] Test search users
- [ ] Test filter (All, Active, Banned)
- [ ] Test ban/unban user
- [ ] Test delete user
- [ ] Test export CSV

---

### **Phase 8.3: Destinations Management** (Tuần 3)

#### **Bước 1: Setup Services**
- [ ] Copy `DestinationService` từ mobile app
- [ ] Tạo `AdminDestinationService` với methods:
  - `getAllDestinations()` - Lấy tất cả destinations với pagination
  - `searchDestinations(String query)` - Search destinations
  - `createDestination(Destination destination)` - Tạo mới
  - `updateDestination(String id, Destination destination)` - Cập nhật
  - `deleteDestination(String id)` - Soft delete
  - `getDestinationById(String id)` - Lấy detail

#### **Bước 2: Destinations List Screen**
- [ ] Tạo `DestinationsScreen` với:
  - **Search bar**: Search by name, city
  - **Filter chips**: All, Category, City
  - **Data table** với columns:
    - Thumbnail image
    - Name
    - City
    - Category
    - Rating
    - Actions (View, Edit, Delete)
  - **Pagination**: 20 items per page
  - **Sort**: Name, Rating, Created Date

#### **Bước 3: Destination Form Screen (Create/Edit)**
- [ ] Tạo `DestinationFormScreen`:
  - **Basic Info**:
    - Name (required)
    - Description (required)
    - City (required)
    - Coordinates (lat, lng) - Map picker
  - **Category**: Dropdown selection
  - **Images**: 
    - Upload multiple images
    - Reorder images
    - Set thumbnail
  - **Details**:
    - Opening hours (per day)
    - Specialties (tags)
    - Activities (tags)
    - Price range
  - **Actions**: Save, Cancel, Preview

#### **Bước 4: Image Upload**
- [ ] Tích hợp Firebase Storage
- [ ] Upload images từ local
- [ ] Show upload progress
- [ ] Preview images
- [ ] Delete images

#### **Bước 5: Export Functionality**
- [ ] Export destinations to CSV

#### **Bước 6: Testing**
- [ ] Test CRUD operations
- [ ] Test image upload
- [ ] Test search và filter
- [ ] Test export CSV

---

### **Phase 8.4: Tours Management** (Tuần 4-5)

#### **Bước 1: Setup Services**
- [ ] Copy `TourPackageService` từ mobile app
- [ ] Tạo `AdminTourService` với methods:
  - `getAllTours()` - Lấy tất cả tours với pagination
  - `searchTours(String query)` - Search tours
  - `createTour(TourPackage tour)` - Tạo mới
  - `updateTour(String id, TourPackage tour)` - Cập nhật
  - `deleteTour(String id)` - Soft delete
  - `activateTour(String id)` - Activate tour
  - `deactivateTour(String id)` - Deactivate tour
  - `duplicateTour(String id)` - Duplicate tour
  - `getTourById(String id)` - Lấy detail

#### **Bước 2: Tours List Screen**
- [ ] Tạo `ToursScreen` với:
  - **Search bar**: Search by title, destination
  - **Filter chips**: All, Active, Inactive, Featured
  - **Data table** với columns:
    - Thumbnail image
    - Title
    - Destination
    - Status (Active/Inactive)
    - Price
    - Rating
    - Actions (View, Edit, Delete, Activate/Deactivate, Duplicate)
  - **Pagination**: 20 items per page
  - **Sort**: Title, Price, Rating, Created Date

#### **Bước 3: Tour Form Screen (Create/Edit)**
- [ ] Tạo `TourFormScreen` với tabs:
  
  **Tab 1: Basic Info**
  - Title (required)
  - Short description
  - Full description
  - Destination (required)
  - Duration (days, nights)
  - Language
  - Pickup/Dropoff location
  
  **Tab 2: Images**
  - Upload multiple images
  - Set thumbnail
  - Reorder images
  
  **Tab 3: Pricing**
  - Base price (required)
  - Child price (optional)
  - Infant price (optional)
  - Price type (per_person, per_room, per_group)
  - Price tiers (nếu có)
  
  **Tab 4: Itinerary**
  - Dynamic days:
    - Add/Remove day
    - Day number, Title, Description
    - Activities (time, name, description)
    - Meals (breakfast, lunch, dinner)
    - Accommodation
  - Drag & drop để reorder days
  
  **Tab 5: Inclusions/Exclusions**
  - Inclusions: Transportation, Meals, Accommodation, etc.
  - Exclusions: Personal expenses, Insurance, etc.
  
  **Tab 6: Policy & Availability**
  - Cancellation policy (type, rules)
  - Available dates (date picker, multiple dates)
  - Min/Max group size
  - Terms & conditions
  
  **Tab 7: Preview**
  - Preview tour như user sẽ thấy
  - Test layout

#### **Bước 4: Form Validation**
- [ ] Validate required fields
- [ ] Validate dates (availableDates phải trong tương lai)
- [ ] Validate pricing (basePrice > 0)
- [ ] Validate itinerary (ít nhất 1 ngày)
- [ ] Show validation errors

#### **Bước 5: Activate/Deactivate**
- [ ] Toggle `status` field (active/inactive)
- [ ] Confirmation dialog
- [ ] Update Firestore

#### **Bước 6: Duplicate Tour**
- [ ] Copy tour data
- [ ] Generate new ID
- [ ] Set `status = inactive`
- [ ] Set `createdAt = now`
- [ ] Open in edit mode

#### **Bước 7: Export Functionality**
- [ ] Export tours to CSV

#### **Bước 8: Testing**
- [ ] Test CRUD operations
- [ ] Test form validation
- [ ] Test activate/deactivate
- [ ] Test duplicate tour
- [ ] Test export CSV

---

### **Phase 8.5: Bookings Management** (Tuần 5-6)

#### **Bước 1: Setup Services**
- [ ] Copy `TourBookingService` từ mobile app
- [ ] Tạo `AdminBookingService` với methods:
  - `getAllBookings()` - Lấy tất cả bookings với pagination
  - `getBookingsByStatus(BookingStatus status)` - Filter by status
  - `searchBookings(String query)` - Search bookings
  - `confirmBooking(String bookingId)` - Xác nhận booking
  - `cancelBooking(String bookingId, String reason)` - Hủy booking
  - `addNote(String bookingId, String note)` - Thêm ghi chú
  - `getBookingById(String id)` - Lấy detail
  - `exportBookingsToCSV()` - Export CSV

#### **Bước 2: Bookings List Screen**
- [ ] Tạo `BookingsScreen` với:
  - **Tabs**: Pending, Confirmed, Cancelled, Completed
  - **Search bar**: Search by booking number, user email, tour name
  - **Filter**: Date range, Tour, Payment status
  - **Badge**: Số lượng bookings pending (real-time)
  - **Data table** với columns:
    - Booking Number
    - Tour Name
    - User Email
    - Departure Date
    - Number of Participants
    - Total Amount
    - Status
    - Payment Status
    - Actions (View, Confirm, Cancel, Add Note)
  - **Pagination**: 20 items per page
  - **Sort**: Booking Date, Departure Date, Amount

#### **Bước 3: Real-time Listener**
- [ ] StreamBuilder cho bookings pending
- [ ] Auto update khi có booking mới
- [ ] Badge update real-time
- [ ] Notification sound (optional)

#### **Bước 4: Booking Detail Screen**
- [ ] Tạo `BookingDetailScreen`:
  - **Booking Info**:
    - Booking Number
    - Status (badge)
    - Payment Status (badge)
    - Booking Date
    - Departure Date
  - **Tour Info**:
    - Tour title, destination
    - Link to tour detail
  - **Contact Info**:
    - Name, Email, Phone
  - **Participants**:
    - List với: Name, Age, Gender, Passport
  - **Pricing**:
    - Subtotal
    - Discount (nếu có)
    - Total Amount
    - Payment Method
    - Payment Transaction ID (nếu có)
  - **Timeline**:
    - Booking created
    - Confirmed at (nếu có)
    - Paid at (nếu có)
    - Cancelled at (nếu có)
  - **Notes**:
    - Special requests
    - Admin notes
    - Add note form
  - **Actions**:
    - Confirm Booking
    - Cancel Booking
    - Export Invoice PDF
    - Send Email (optional)

#### **Bước 5: Confirm Booking**
- [ ] Update `status = confirmed`
- [ ] Set `confirmedAt = timestamp`
- [ ] Update `bookingCount` của tour
- [ ] Confirmation dialog
- [ ] Toast notification
- [ ] Optional: Send email confirmation

#### **Bước 6: Cancel Booking**
- [ ] Dialog nhập lý do hủy
- [ ] Update `status = cancelled`
- [ ] Set `cancelledAt = timestamp`
- [ ] Set `cancellationReason`
- [ ] Handle refund (nếu đã thanh toán)
- [ ] Toast notification
- [ ] Optional: Send email cancellation

#### **Bước 7: Export Invoice PDF**
- [ ] Tạo invoice template
- [ ] Fill data: Booking info, Tour info, Participants, Pricing
- [ ] Generate PDF
- [ ] Download PDF

#### **Bước 8: Export CSV**
- [ ] Export bookings to CSV với đầy đủ thông tin

#### **Bước 9: Testing**
- [ ] Test real-time listener
- [ ] Test confirm booking
- [ ] Test cancel booking
- [ ] Test add note
- [ ] Test export invoice
- [ ] Test export CSV

---

### **Phase 8.6: Polish & Deployment** (Tuần 6-7)

#### **Bước 1: Shared Components**
- [ ] Tạo `DataTable` widget (reusable):
  - Sort columns
  - Pagination
  - Row selection
  - Actions column
- [ ] Tạo `SearchBar` widget:
  - Debounce search
  - Clear button
- [ ] Tạo `FilterChips` widget:
  - Multiple selection
  - Clear all
- [ ] Tạo `StatusBadge` widget:
  - Color coding (pending=yellow, confirmed=green, etc.)
- [ ] Tạo `ConfirmDialog` widget:
  - Reusable confirmation dialog
- [ ] Tạo `LoadingIndicator` widget
- [ ] Tạo `EmptyState` widget

#### **Bước 2: Error Handling**
- [ ] Try-catch cho tất cả async operations
- [ ] Error messages user-friendly
- [ ] Error snackbar/toast
- [ ] Retry mechanism (nếu có)

#### **Bước 3: Loading States**
- [ ] Loading indicator khi fetch data
- [ ] Skeleton loaders cho tables
- [ ] Disable buttons khi đang process

#### **Bước 4: Empty States**
- [ ] Empty state khi không có data
- [ ] Empty state khi search không có kết quả
- [ ] Action buttons trong empty state

#### **Bước 5: Responsive Design**
- [ ] Desktop: Full layout
- [ ] Tablet: Adapted layout
- [ ] Mobile: Simplified layout (optional)

#### **Bước 6: Performance Optimization**
- [ ] Lazy load images
- [ ] Pagination cho tất cả lists
- [ ] Debounce search
- [ ] Cache data khi có thể
- [ ] Optimize Firestore queries

#### **Bước 7: Testing**
- [ ] Test toàn bộ flow:
  - Login → Dashboard
  - Users Management (CRUD, Ban/Unban)
  - Destinations Management (CRUD)
  - Tours Management (CRUD, Activate/Deactivate)
  - Bookings Management (Confirm, Cancel)
- [ ] Test error handling
- [ ] Test loading states
- [ ] Test responsive design

#### **Bước 8: Build for Production**
- [ ] Update `web/index.html` với meta tags
- [ ] Update `web/manifest.json`
- [ ] Build: `flutter build web --release`
- [ ] Test build locally

#### **Bước 9: Deploy to Firebase Hosting**
- [ ] Setup Firebase Hosting:
  ```bash
  firebase init hosting
  ```
- [ ] Configure `firebase.json`:
  ```json
  {
    "hosting": {
      "public": "build/web",
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    }
  }
  ```
- [ ] Deploy:
  ```bash
  flutter build web --release
  firebase deploy --only hosting
  ```

#### **Bước 10: Setup Domain (Optional)**
- [ ] Custom domain: `admin.smarttravel.app`
- [ ] SSL certificate (tự động với Firebase)
- [ ] DNS configuration

#### **Bước 11: Final Testing**
- [ ] Test trên production URL
- [ ] Test tất cả features
- [ ] Test performance
- [ ] Fix bugs nếu có

---

## 📊 TIMELINE TỔNG QUAN

| Phase | Thời gian | Nội dung |
|-------|-----------|----------|
| **8.1** | Tuần 1 | Dashboard với thống kê |
| **8.2** | Tuần 2 | Users Management |
| **8.3** | Tuần 3 | Destinations Management |
| **8.4** | Tuần 4-5 | Tours Management |
| **8.5** | Tuần 5-6 | Bookings Management |
| **8.6** | Tuần 6-7 | Polish & Deployment |
| **Tổng** | **6-7 tuần** | **Hoàn thành Phase 8** |

---

## 🎨 UI/UX REQUIREMENTS

### **Color Scheme:**
- Primary: Orange (#FF6B35)
- Success: Green (#4CAF50)
- Warning: Yellow (#FFC107)
- Error: Red (#F44336)
- Info: Blue (#2196F3)

### **Status Colors:**
- Pending: Yellow
- Confirmed: Green
- Cancelled: Red
- Completed: Blue
- Active: Green
- Inactive: Grey

### **Typography:**
- Headings: Roboto Bold
- Body: Roboto Regular
- Code: Roboto Mono

---

## 🔐 SECURITY CONSIDERATIONS

1. **Firestore Security Rules**:
   - Admin chỉ đọc được collection `admins`
   - Admin có quyền write tất cả collections
   - User chỉ đọc được data của mình

2. **Input Validation**:
   - Validate tất cả inputs ở client
   - Sanitize user inputs
   - Prevent XSS attacks

3. **Authentication**:
   - Luôn check admin role trước mọi action
   - Session timeout
   - Secure logout

---

## 📝 DEPENDENCIES CẦN THÊM

```yaml
dependencies:
  # CSV Export
  csv: ^5.0.0
  
  # PDF Generation (cho invoice)
  pdf: ^3.10.0
  printing: ^5.12.0
  
  # Image Picker (cho upload)
  image_picker: ^1.0.0
  
  # File Download
  file_picker: ^6.0.0
  
  # Date Range Picker
  syncfusion_flutter_datepicker: ^24.0.0
```

---

## ✅ CHECKLIST TỔNG QUAN

### **Phase 8.1: Dashboard**
- [ ] Copy models & services
- [ ] Stats cards (4 cards)
- [ ] Real-time updates
- [ ] Quick actions
- [ ] Recent activity (optional)

### **Phase 8.2: Users Management**
- [ ] AdminUserService
- [ ] UsersScreen với search, filter, pagination
- [ ] UserDetailScreen
- [ ] Ban/Unban functionality
- [ ] Export CSV

### **Phase 8.3: Destinations Management**
- [ ] AdminDestinationService
- [ ] DestinationsScreen với search, filter, pagination
- [ ] DestinationFormScreen (Create/Edit)
- [ ] Image upload
- [ ] Export CSV

### **Phase 8.4: Tours Management**
- [ ] AdminTourService
- [ ] ToursScreen với search, filter, pagination
- [ ] TourFormScreen với 7 tabs
- [ ] Activate/Deactivate
- [ ] Duplicate tour
- [ ] Export CSV

### **Phase 8.5: Bookings Management**
- [ ] AdminBookingService
- [ ] BookingsScreen với tabs, search, filter
- [ ] Real-time listener
- [ ] BookingDetailScreen
- [ ] Confirm/Cancel booking
- [ ] Export invoice PDF
- [ ] Export CSV

### **Phase 8.6: Polish & Deployment**
- [ ] Shared components
- [ ] Error handling
- [ ] Loading states
- [ ] Empty states
- [ ] Responsive design
- [ ] Performance optimization
- [ ] Build & Deploy

---

## 🎯 NEXT STEPS

1. **Review kế hoạch này**
2. **Copy models & services từ mobile app**
3. **Bắt đầu Phase 8.1: Dashboard**

---

**Tài liệu này sẽ được cập nhật trong quá trình triển khai.**

