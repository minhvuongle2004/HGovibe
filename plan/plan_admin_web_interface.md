# 📋 KẾ HOẠCH TRIỂN KHAI: ADMIN WEB INTERFACE (FLUTTER WEB)

## 🎯 TỔNG QUAN

Tạo **Admin Web Interface** bằng Flutter Web để quản lý:
- 👥 **Quản lý người dùng** (Users Management)
- 📍 **Quản lý điểm đến** (Destinations Management)
- 🎫 **Quản lý tour** (Tours Management)
- 📋 **Quản lý Booking** (Bookings Management)

**Công nghệ:** Flutter Web  
**URL:** `https://admin.smarttravel.app` (hoặc subdomain riêng)

---

## 🏗️ KIẾN TRÚC HỆ THỐNG

```
┌─────────────────────┐
│  Flutter Mobile App │  (User app)
│  - Đặt tour         │
│  - Xem bookings     │
└──────────┬──────────┘
           │
           │ Firestore
           │
┌──────────▼──────────┐
│  Flutter Web App     │  (Admin interface)
│  - Quản lý users     │
│  - Quản lý destinations│
│  - Quản lý tours     │
│  - Quản lý bookings  │
└─────────────────────┘
```

---

## 📦 CẤU TRÚC PROJECT

### **Option 1: Monorepo (Khuyến nghị)**

```
smart_travel_app/
├── mobile_app/              # Flutter mobile (hiện tại)
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
├── admin_web/               # Flutter web (mới)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── ...
│   ├── web/
│   │   ├── index.html
│   │   └── assets/
│   └── pubspec.yaml
└── packages/
    └── shared/              # Shared code
        ├── lib/
        │   ├── models/
        │   │   ├── user.dart
        │   │   ├── destination.dart
        │   │   ├── tour_package.dart
        │   │   └── tour_booking.dart
        │   └── services/
        │       ├── user_service.dart
        │       ├── destination_service.dart
        │       ├── tour_package_service.dart
        │       └── tour_booking_service.dart
        └── pubspec.yaml
```

### **Option 2: Separate Repo**

```
admin_web/
├── lib/
├── web/
└── pubspec.yaml
```

**Khuyến nghị: Option 1 (Monorepo)** để dễ share code.

---

## 🔐 AUTHENTICATION & AUTHORIZATION

### **1. Admin Login**

**Flow:**
```
Admin truy cập: https://admin.smarttravel.app
    ↓
Login Screen
    ↓
Nhập email/password
    ↓
Firebase Auth xác thực
    ↓
Check quyền admin (Firestore: admins/{userId})
    ↓
Nếu là admin → Dashboard
Nếu không → Hiển thị lỗi
```

**Collection: `admins`**
```json
{
  "id": "admin-user-id",
  "userId": "user-123",
  "email": "admin@smarttravel.app",
  "role": "admin",
  "permissions": [
    "manage_users",
    "manage_destinations",
    "manage_tours",
    "manage_bookings"
  ],
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### **2. Route Protection**

```dart
// Middleware để check admin
class AdminAuthGuard {
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final doc = await FirebaseFirestore.instance
      .collection('admins')
      .doc(user.uid)
      .get();
    return doc.exists;
  }
}
```

---

## 📱 MÀN HÌNH & CHỨC NĂNG

### **1. Login Screen** (`screens/auth/login_screen.dart`)

**UI:**
```
┌─────────────────────────────────┐
│  🔐 Admin Login                  │
├─────────────────────────────────┤
│                                  │
│  Email: [________________]       │
│  Password: [____________]        │
│                                  │
│  [ ] Remember me                 │
│                                  │
│  [     Đăng nhập     ]          │
│                                  │
│  Quên mật khẩu?                  │
└─────────────────────────────────┘
```

**Chức năng:**
- [ ] Form login (email/password)
- [ ] Firebase Auth authentication
- [ ] Check admin role
- [ ] Redirect to Dashboard nếu thành công
- [ ] Error handling

---

### **2. Dashboard** (`screens/dashboard/admin_dashboard_screen.dart`)

**UI:**
```
┌─────────────────────────────────────────┐
│  Header: Logo | Admin Name | Logout     │
├──────────┬──────────────────────────────┤
│          │  📊 Dashboard                │
│ Sidebar  │                              │
│          │  Thống kê nhanh:             │
│ - Dashboard│  ┌─────┐ ┌─────┐ ┌─────┐   │
│ - Users   │  │ 150 │ │ 45  │ │ 12  │   │
│ - Destinations│ │Users│ │Tours│ │Book│   │
│ - Tours   │  └─────┘ └─────┘ └─────┘   │
│ - Bookings│                              │
│          │  ⚡ Hành động nhanh:          │
│          │  - [Xem bookings mới: 5]     │
│          │  - [Tạo tour mới]            │
│          │  - [Thêm điểm đến]            │
└──────────┴──────────────────────────────┘
```

**Chức năng:**
- [ ] Hiển thị thống kê:
  - Tổng số users
  - Tổng số tours
  - Tổng số bookings
  - Bookings pending (badge)
- [ ] Quick actions buttons
- [ ] Real-time updates
- [ ] Sidebar navigation

---

### **3. Users Management** (`screens/users/admin_users_screen.dart`)

**UI:**
```
┌─────────────────────────────────────────┐
│  👥 Quản lý Người dùng                  │
├─────────────────────────────────────────┤
│  [🔍 Search] [➕ Thêm user] [📊 Export]│
│                                          │
│  Filters: [All] [Active] [Banned]        │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Email          | Name    | Status │ │
│  ├────────────────────────────────────┤ │
│  │ user1@...      | John    | Active │ │
│  │                |         | [Ban]   │ │
│  ├────────────────────────────────────┤ │
│  │ user2@...      | Jane    | Banned │ │
│  │                |         | [Unban]│ │
│  └────────────────────────────────────┘ │
│                                          │
│  Pagination: [<] 1 2 3 [>]              │
└─────────────────────────────────────────┘
```

**Chức năng:**
- [ ] Danh sách users với pagination
- [ ] Search users (email, name)
- [ ] Filter: All, Active, Banned
- [ ] Actions:
  - [ ] Xem chi tiết user
  - [ ] Ban/Unban user
  - [ ] Xóa user (soft delete)
  - [ ] Xem bookings của user
- [ ] Export to CSV/Excel
- [ ] Sort: Name, Email, Created Date

**User Detail Screen:**
- [ ] Thông tin user (email, name, phone, avatar)
- [ ] Danh sách bookings của user
- [ ] Danh sách trips của user
- [ ] Lịch sử hoạt động
- [ ] Actions: Ban, Delete, Edit

---

### **4. Destinations Management** (`screens/destinations/admin_destinations_screen.dart`)

**UI:**
```
┌─────────────────────────────────────────┐
│  📍 Quản lý Điểm đến                    │
├─────────────────────────────────────────┤
│  [🔍 Search] [➕ Thêm điểm đến] [📊 Export]│
│                                          │
│  Filters: [All] [City] [Beach] [Mountain]│
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ [Image] Name      | City  | Rating│ │
│  ├────────────────────────────────────┤ │
│  │ [img] Hội An      | Quảng Nam| 4.8│ │
│  │                [Edit] [Delete]     │ │
│  ├────────────────────────────────────┤ │
│  │ [img] Hạ Long     | Quảng Ninh| 4.9│ │
│  │                [Edit] [Delete]     │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Pagination: [<] 1 2 3 [>]              │
└─────────────────────────────────────────┘
```

**Chức năng:**
- [ ] Danh sách destinations với pagination
- [ ] Search destinations (name, city)
- [ ] Filter: Category, City, Rating
- [ ] Actions:
  - [ ] Xem chi tiết
  - [ ] Thêm destination mới
  - [ ] Sửa destination
  - [ ] Xóa destination (soft delete)
  - [ ] Upload/Edit images
- [ ] Export to CSV/Excel
- [ ] Sort: Name, Rating, Created Date

**Destination Detail/Edit Screen:**
- [ ] Form: Name, Description, City, Coordinates
- [ ] Category selection
- [ ] Images upload (multiple)
- [ ] Opening hours
- [ ] Specialties, Activities
- [ ] Save/Cancel

---

### **5. Tours Management** (`screens/tours/admin_tours_screen.dart`)

**UI:**
```
┌─────────────────────────────────────────┐
│  🎫 Quản lý Tours                       │
├─────────────────────────────────────────┤
│  [🔍 Search] [➕ Tạo tour mới] [📊 Export]│
│                                          │
│  Filters: [All] [Active] [Inactive]     │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ [Image] Title      | Status | Price│ │
│  ├────────────────────────────────────┤ │
│  │ [img] Tour Đà Nẵng| Active | 5M₫  │ │
│  │                [Edit] [Delete]     │ │
│  ├────────────────────────────────────┤ │
│  │ [img] Tour Hạ Long| Active | 8M₫  │ │
│  │                [Edit] [Delete]     │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Pagination: [<] 1 2 3 [>]              │
└─────────────────────────────────────────┘
```

**Chức năng:**
- [ ] Danh sách tours với pagination
- [ ] Search tours (title, destination)
- [ ] Filter: Status, Destination, Price Range
- [ ] Actions:
  - [ ] Xem chi tiết
  - [ ] Tạo tour mới
  - [ ] Sửa tour
  - [ ] Xóa tour (soft delete)
  - [ ] Activate/Deactivate tour
  - [ ] Duplicate tour
- [ ] Export to CSV/Excel
- [ ] Sort: Title, Price, Rating, Created Date

**Tour Create/Edit Screen:**
- [ ] Form đầy đủ:
  - Basic info: Title, Description, Destination
  - Images upload (multiple)
  - Pricing: Base price, Price tiers, Child/Infant price
  - Itinerary: Days, Activities, Meals, Accommodation
  - Inclusions/Exclusions
  - Cancellation policy
  - Availability dates
- [ ] Preview tour
- [ ] Save as Draft / Publish

---

### **6. Bookings Management** (`screens/bookings/admin_bookings_screen.dart`)

**UI:**
```
┌─────────────────────────────────────────┐
│  📋 Quản lý Bookings                    │
├─────────────────────────────────────────┤
│  [🔍 Search] [📊 Export] [🔔 5 mới]     │
│                                          │
│  Tabs: [Chờ xác nhận] [Đã xác nhận]     │
│        [Đã hủy] [Đã hoàn thành]         │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Booking# | Tour      | Date | $  │ │
│  ├────────────────────────────────────┤ │
│  │ BK001    | Tour ĐN   | 15/2 | 10M│ │
│  │          | [Xác nhận] [Hủy] [Chi tiết]│
│  ├────────────────────────────────────┤ │
│  │ BK002    | Tour HL   | 20/2 | 8M │ │
│  │          | [Xác nhận] [Hủy] [Chi tiết]│
│  └────────────────────────────────────┘ │
│                                          │
│  Pagination: [<] 1 2 3 [>]              │
└─────────────────────────────────────────┘
```

**Chức năng:**
- [ ] Danh sách bookings với pagination
- [ ] Tabs: Pending, Confirmed, Cancelled, Completed
- [ ] Real-time listener cho bookings mới
- [ ] Badge số lượng bookings pending
- [ ] Search bookings (booking number, user email, tour name)
- [ ] Filter: Status, Date range, Tour
- [ ] Actions:
  - [ ] Xem chi tiết
  - [ ] Xác nhận booking
  - [ ] Hủy booking
  - [ ] Thêm ghi chú
  - [ ] Export invoice
- [ ] Export to CSV/Excel
- [ ] Sort: Booking Date, Departure Date, Amount

**Booking Detail Screen:**
- [ ] Thông tin booking:
  - Booking number, Status, Payment status
  - Tour package info
  - Departure date
  - Number of participants
- [ ] Thông tin người đặt:
  - Name, Email, Phone
- [ ] Danh sách người tham gia:
  - Name, Age, Gender, Passport (nếu có)
- [ ] Thanh toán:
  - Subtotal, Discount, Total
  - Payment method, Payment status
- [ ] Actions:
  - [ ] Xác nhận booking
  - [ ] Hủy booking (với lý do)
  - [ ] Thêm ghi chú
  - [ ] Export invoice PDF
  - [ ] Gửi email xác nhận

---

## 🎨 UI COMPONENTS

### **Shared Components:**

1. **`AdminLayout`** - Layout chung (Sidebar + Header)
2. **`AdminSidebar`** - Sidebar navigation
3. **`AdminHeader`** - Header với user info và logout
4. **`DataTable`** - Table component với sort, filter, pagination
5. **`SearchBar`** - Search input với debounce
6. **`FilterChips`** - Filter chips
7. **`StatusBadge`** - Badge hiển thị trạng thái
8. **`ActionButtons`** - Buttons cho actions (Edit, Delete, etc.)
9. **`ConfirmDialog`** - Dialog xác nhận trước khi xóa
10. **`LoadingIndicator`** - Loading spinner
11. **`EmptyState`** - Empty state khi không có data
12. **`PaginationWidget`** - Pagination controls

---

## 📊 DATA MODELS & SERVICES

### **Models (Shared Package):**

- ✅ `User` - Đã có trong mobile app
- ✅ `Destination` - Đã có trong mobile app
- ✅ `TourPackage` - Đã có trong mobile app
- ✅ `TourBooking` - Đã có trong mobile app

### **Services (Shared Package):**

- ✅ `UserService` - CRUD users
- ✅ `DestinationService` - CRUD destinations
- ✅ `TourPackageService` - CRUD tours
- ✅ `TourBookingService` - CRUD bookings

**Cần thêm cho Admin:**
- [ ] `AdminUserService` - Admin-specific user operations (ban, unban, delete)
- [ ] `AdminBookingService` - Admin-specific booking operations (confirm, cancel)

---

## 🔐 SECURITY RULES (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function: Check if user is admin
    function isAdmin() {
      return request.auth != null && 
             exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    // Admin collection
    match /admins/{adminId} {
      allow read: if isAdmin();
      allow write: if false; // Chỉ set từ backend
    }
    
    // Users collection - Admin có quyền read/write
    match /users/{userId} {
      allow read: if request.auth != null && (
        request.auth.uid == userId || isAdmin()
      );
      allow write: if isAdmin();
    }
    
    // Destinations - Admin có quyền write
    match /destinations/{destinationId} {
      allow read: if true; // Public
      allow write: if isAdmin();
    }
    
    // Tour packages - Admin có quyền write
    match /tour_packages/{tourId} {
      allow read: if true; // Public
      allow write: if isAdmin();
    }
    
    // Tour bookings - Admin xem tất cả, user chỉ xem của mình
    match /tour_bookings/{bookingId} {
      allow read: if request.auth != null && (
        resource.data.userId == request.auth.uid || isAdmin()
      );
      allow create: if request.auth != null;
      allow update: if request.auth != null && (
        resource.data.userId == request.auth.uid || isAdmin()
      );
      allow delete: if isAdmin();
    }
  }
}
```

---

## 🚀 KẾ HOẠCH TRIỂN KHAI

### **Phase 1: Setup & Foundation** (Tuần 1)

#### **Bước 1: Project Setup**
- [ ] Tạo Flutter Web project: `admin_web`
- [ ] Setup monorepo structure (hoặc separate repo)
- [ ] Setup shared package (hoặc copy models/services)
- [ ] Configure Firebase for web
- [ ] Setup routing (go_router hoặc Navigator 2.0)

#### **Bước 2: Authentication**
- [ ] Tạo `LoginScreen`
- [ ] Implement Firebase Auth
- [ ] Tạo `AdminService` để check admin role
- [ ] Tạo `AdminAuthGuard` middleware
- [ ] Setup route protection
- [ ] Create admin user trong Firestore

#### **Bước 3: Layout & Navigation**
- [ ] Tạo `AdminLayout` (Sidebar + Header)
- [ ] Tạo `AdminSidebar` với navigation items
- [ ] Tạo `AdminHeader` với user info và logout
- [ ] Setup routing structure

---

### **Phase 2: Dashboard** (Tuần 1-2)

- [ ] Tạo `AdminDashboardScreen`
- [ ] Implement stats cards:
  - Total users
  - Total tours
  - Total bookings
  - Pending bookings (badge)
- [ ] Real-time listener cho bookings pending
- [ ] Quick actions buttons
- [ ] Responsive design

---

### **Phase 3: Users Management** (Tuần 2-3)

- [ ] Tạo `AdminUsersScreen`
- [ ] Implement data table với pagination
- [ ] Search functionality
- [ ] Filter: All, Active, Banned
- [ ] Actions: View, Ban, Unban, Delete
- [ ] Tạo `AdminUserDetailScreen`
- [ ] Export to CSV/Excel
- [ ] Testing

---

### **Phase 4: Destinations Management** (Tuần 3-4)

- [ ] Tạo `AdminDestinationsScreen`
- [ ] Implement data table với pagination
- [ ] Search functionality
- [ ] Filter: Category, City
- [ ] Actions: View, Add, Edit, Delete
- [ ] Tạo `AdminDestinationFormScreen` (Create/Edit)
- [ ] Image upload functionality
- [ ] Export to CSV/Excel
- [ ] Testing

---

### **Phase 5: Tours Management** (Tuần 4-5)

- [ ] Tạo `AdminToursScreen`
- [ ] Implement data table với pagination
- [ ] Search functionality
- [ ] Filter: Status, Destination, Price
- [ ] Actions: View, Add, Edit, Delete, Activate/Deactivate
- [ ] Tạo `AdminTourFormScreen` (Create/Edit)
- [ ] Form đầy đủ:
  - Basic info
  - Images upload
  - Pricing
  - Itinerary (dynamic days)
  - Inclusions/Exclusions
  - Cancellation policy
- [ ] Preview tour
- [ ] Export to CSV/Excel
- [ ] Testing

---

### **Phase 6: Bookings Management** (Tuần 5-6)

- [ ] Tạo `AdminBookingsScreen`
- [ ] Implement tabs: Pending, Confirmed, Cancelled, Completed
- [ ] Real-time listener cho bookings mới
- [ ] Badge số lượng bookings pending
- [ ] Data table với pagination
- [ ] Search functionality
- [ ] Filter: Status, Date range, Tour
- [ ] Actions: View, Confirm, Cancel, Add Note
- [ ] Tạo `AdminBookingDetailScreen`
- [ ] Implement:
  - Xác nhận booking
  - Hủy booking (với lý do)
  - Thêm ghi chú
  - Export invoice PDF
- [ ] Export to CSV/Excel
- [ ] Testing

---

### **Phase 7: Polish & Deployment** (Tuần 6-7)

- [ ] UI/UX improvements
- [ ] Responsive design (Desktop, Tablet)
- [ ] Error handling & validation
- [ ] Loading states
- [ ] Empty states
- [ ] Confirmation dialogs
- [ ] Toast notifications
- [ ] Testing toàn bộ flow
- [ ] Performance optimization
- [ ] Build for production
- [ ] Deploy to Firebase Hosting (hoặc Vercel/Netlify)
- [ ] Setup domain/subdomain
- [ ] SSL certificate
- [ ] Final testing

---

## 📦 DEPENDENCIES

### **pubspec.yaml (admin_web):**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  cloud_firestore: ^4.13.0
  firebase_auth: ^4.15.0
  
  # State Management
  provider: ^6.1.0
  
  # Routing
  go_router: ^12.0.0
  
  # UI
  flutter_svg: ^2.0.0
  cached_network_image: ^3.3.0
  
  # Utils
  intl: ^0.18.0
  uuid: ^4.0.0
  
  # Shared package
  smart_travel_shared:
    path: ../packages/shared

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## 🎨 UI/UX GUIDELINES

### **Color Scheme:**
- Primary: Orange (#FF6B35)
- Success: Green (#4CAF50)
- Warning: Yellow (#FFC107)
- Error: Red (#F44336)
- Background: Light Gray (#F5F5F5)

### **Typography:**
- Headings: Roboto Bold
- Body: Roboto Regular
- Code: Roboto Mono

### **Layout:**
- Sidebar width: 250px (Desktop), Collapsible (Tablet)
- Header height: 64px
- Content padding: 24px
- Card elevation: 2-4

### **Responsive Breakpoints:**
- Desktop: > 1200px
- Tablet: 768px - 1200px
- Mobile: < 768px (optional, admin thường dùng desktop)

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **Security:**
   - ✅ Luôn check admin role trước mọi action
   - ✅ Firestore security rules phải chặt chẽ
   - ✅ Không expose sensitive data ở client
   - ✅ Validate input ở cả client và server

2. **Performance:**
   - ✅ Pagination cho tất cả danh sách
   - ✅ Lazy loading cho images
   - ✅ Debounce cho search
   - ✅ Cache data khi có thể

3. **UX:**
   - ✅ Loading states rõ ràng
   - ✅ Error messages dễ hiểu
   - ✅ Confirmation dialogs cho destructive actions
   - ✅ Toast notifications cho feedback
   - ✅ Keyboard shortcuts (nếu có thể)

4. **Data:**
   - ✅ Soft delete (không xóa vĩnh viễn)
   - ✅ Audit log (track changes)
   - ✅ Backup data định kỳ

---

## 📝 NEXT STEPS

1. **Quyết định:** Monorepo hay separate repo?
2. **Setup:** Tạo Flutter Web project
3. **Setup:** Configure Firebase for web
4. **Setup:** Tạo admin user trong Firestore
5. **Triển khai:** Bắt đầu với Phase 1

---

## 🎯 TIMELINE TỔNG QUAN

| Phase | Thời gian | Mô tả |
|-------|-----------|-------|
| Phase 1 | Tuần 1 | Setup & Foundation |
| Phase 2 | Tuần 1-2 | Dashboard |
| Phase 3 | Tuần 2-3 | Users Management |
| Phase 4 | Tuần 3-4 | Destinations Management |
| Phase 5 | Tuần 4-5 | Tours Management |
| Phase 6 | Tuần 5-6 | Bookings Management |
| Phase 7 | Tuần 6-7 | Polish & Deployment |
| **Tổng** | **6-7 tuần** | **Hoàn thành Admin Web** |

---

**Tài liệu này sẽ được cập nhật trong quá trình triển khai.**

