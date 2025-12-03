# 📋 KẾ HOẠCH: ADMIN INTERFACE & NOTIFICATION SYSTEM

## 🎯 TỔNG QUAN

Khi người dùng đặt tour, **Admin cần có giao diện web riêng** để:
- ✅ Xem danh sách bookings mới (real-time)
- ✅ Xác nhận/hủy bookings
- ✅ Xem thông tin chi tiết booking
- ✅ Quản lý tour packages
- ✅ Nhận thông báo khi có booking mới

## 🌐 ADMIN WEB INTERFACE

**Quyết định:** Admin interface sẽ là **Web Application** riêng biệt, không nằm trong Flutter mobile app.

**Lý do:**
- ✅ Admin thường làm việc trên desktop/laptop
- ✅ Web interface dễ sử dụng hơn cho quản lý dữ liệu
- ✅ Có thể mở nhiều tab, xử lý nhiều bookings cùng lúc
- ✅ Dễ tích hợp các công cụ quản lý (export Excel, print, etc.)

---

## 🔔 NOTIFICATION SYSTEM

### **Cách 1: Real-time Firestore Listener (Khuyến nghị)**

**Ưu điểm:**
- ✅ Real-time, không cần push notification
- ✅ Đơn giản, không cần setup FCM
- ✅ Hoạt động ngay khi admin mở app

**Cách triển khai:**
```dart
// Admin screen lắng nghe bookings mới
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
    .collection('tour_bookings')
    .where('status', isEqualTo: 'pending')
    .orderBy('bookingDate', descending: true)
    .snapshots(),
  builder: (context, snapshot) {
    // Hiển thị danh sách bookings pending
    // Badge số lượng bookings mới
  },
)
```

### **Cách 2: Firebase Cloud Messaging (FCM)**

**Ưu điểm:**
- ✅ Nhận thông báo ngay cả khi app đóng
- ✅ Push notification trên thiết bị

**Nhược điểm:**
- ⚠️ Cần setup FCM
- ⚠️ Phức tạp hơn

**Cách triển khai:**
- Khi user tạo booking → Cloud Function gửi FCM notification cho admin
- Admin nhận push notification

### **Khuyến nghị: Dùng Cách 1 (Real-time Listener)**
- Đơn giản hơn
- Đủ cho nhu cầu hiện tại
- Có thể thêm FCM sau nếu cần

---

## 🏗️ CẤU TRÚC ADMIN INTERFACE

### **1. Admin Authentication**

**Cách xác định Admin:**
```dart
// Option 1: Field trong User model
class User {
  final bool isAdmin;
  final List<String> roles; // ['admin', 'partner']
}

// Option 2: Collection riêng
// Collection: admins/{userId}
{
  "userId": "user-123",
  "email": "admin@example.com",
  "role": "admin",
  "permissions": ["manage_bookings", "manage_tours"]
}
```

**Cách kiểm tra quyền Admin:**
```dart
Future<bool> isAdmin(String userId) async {
  final doc = await FirebaseFirestore.instance
    .collection('admins')
    .doc(userId)
    .get();
  return doc.exists;
}
```

### **2. Admin Web Application**

**Kiến trúc:**
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
│  Admin Web App      │  (Admin interface)
│  - Quản lý bookings │
│  - Quản lý tours    │
└─────────────────────┘
```

**URL:** `https://admin.smarttravel.app` (hoặc subdomain riêng)

**Công nghệ đề xuất:**
- **Option 1: Flutter Web** (Khuyến nghị)
  - ✅ Dùng chung codebase với mobile app (models, services)
  - ✅ Dễ maintain, share business logic
  - ✅ Responsive design
  
- **Option 2: React/Vue + TypeScript**
  - ✅ Ecosystem phong phú
  - ✅ Nhiều UI libraries (Material-UI, Ant Design)
  - ⚠️ Cần viết lại models/services

**Khuyến nghị: Flutter Web** để tận dụng codebase hiện có.

### **3. Admin Screens**

#### **A. Admin Dashboard** (`AdminDashboardScreen`)
```
┌─────────────────────────────────┐
│  📊 Dashboard                   │
├─────────────────────────────────┤
│  📈 Thống kê nhanh:             │
│  - Bookings mới (pending): 5   │
│  - Bookings hôm nay: 12         │
│  - Tổng doanh thu tháng: ...    │
├─────────────────────────────────┤
│  ⚡ Hành động nhanh:             │
│  - [Xem bookings mới]          │
│  - [Quản lý tours]             │
│  - [Quản lý đối tác]           │
└─────────────────────────────────┘
```

#### **B. Bookings Management** (`AdminBookingsScreen`)
```
┌─────────────────────────────────┐
│  📋 Quản lý Bookings            │
├─────────────────────────────────┤
│  Tabs:                           │
│  [Chờ xác nhận] [Đã xác nhận]   │
│  [Đã hủy] [Đã hoàn thành]       │
├─────────────────────────────────┤
│  🔔 Badge: 5 bookings mới       │
│                                  │
│  List bookings với:              │
│  - Mã booking                    │
│  - Tour name                    │
│  - Ngày khởi hành               │
│  - Số người                     │
│  - Tổng tiền                    │
│  - Trạng thái                   │
│  - [Xác nhận] [Hủy] [Chi tiết] │
└─────────────────────────────────┘
```

#### **C. Booking Detail** (`AdminBookingDetailScreen`)
```
┌─────────────────────────────────┐
│  📄 Chi tiết Booking            │
├─────────────────────────────────┤
│  Thông tin booking:              │
│  - Mã booking: BK20240101001    │
│  - Tour: Tour Đà Nẵng...        │
│  - Ngày đặt: 01/01/2024         │
│  - Ngày khởi hành: 15/02/2024   │
│                                  │
│  Thông tin người đặt:            │
│  - Tên, Email, SĐT              │
│                                  │
│  Danh sách người tham gia:       │
│  - Người 1: Tên, Tuổi, ...      │
│  - Người 2: ...                 │
│                                  │
│  Thanh toán:                     │
│  - Tổng tiền: 10,000,000₫       │
│  - Trạng thái: Chưa thanh toán  │
│                                  │
│  Actions:                        │
│  [✅ Xác nhận] [❌ Hủy]         │
│  [📝 Thêm ghi chú]              │
└─────────────────────────────────┘
```

#### **D. Tours Management** (`AdminToursScreen`)
```
┌─────────────────────────────────┐
│  🎫 Quản lý Tours               │
├─────────────────────────────────┤
│  [➕ Tạo tour mới]              │
│                                  │
│  List tours:                     │
│  - Tour 1 [Sửa] [Xóa] [Ẩn]      │
│  - Tour 2 ...                   │
└─────────────────────────────────┘
```

---

## 🔐 SECURITY RULES (Firestore)

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Admin collection - chỉ admin đọc được
    match /admins/{adminId} {
      allow read: if request.auth != null && 
                     exists(/databases/$(database)/documents/admins/$(request.auth.uid));
      allow write: if false; // Chỉ set từ backend
    }
    
    // Tour bookings - admin xem tất cả, user chỉ xem của mình
    match /tour_bookings/{bookingId} {
      allow read: if request.auth != null && (
        resource.data.userId == request.auth.uid ||
        exists(/databases/$(database)/documents/admins/$(request.auth.uid))
      );
      allow create: if request.auth != null;
      allow update: if request.auth != null && (
        resource.data.userId == request.auth.uid ||
        exists(/databases/$(database)/documents/admins/$(request.auth.uid))
      );
    }
    
    // Tour packages - admin có quyền write
    match /tour_packages/{tourId} {
      allow read: if true; // Public
      allow write: if request.auth != null && 
                     exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
  }
}
```

---

## 📱 UI/UX FLOW

### **Flow Admin nhận thông báo:**

```
User đặt tour
    ↓
Booking được tạo (status: pending)
    ↓
Admin Dashboard có real-time listener
    ↓
Badge hiển thị số bookings mới
    ↓
Admin click vào "Bookings mới"
    ↓
Xem danh sách bookings pending
    ↓
Click vào booking → Xem chi tiết
    ↓
Xác nhận hoặc Hủy booking
```

---

## 🚀 KẾ HOẠCH TRIỂN KHAI

### **Phase 3.5: Admin Interface - Bookings Management** (Ưu tiên cao)

**Mục tiêu:** Admin có thể xem và quản lý bookings ngay sau khi Phase 3 hoàn thành.

#### **Bước 1: Admin Authentication**
- [ ] Tạo collection `admins` trong Firestore
- [ ] Tạo service `AdminService` để check quyền admin
- [ ] Tạo helper `isAdmin()` function
- [ ] Update Firestore security rules

#### **Bước 2: Admin Dashboard**
- [ ] Tạo `AdminDashboardScreen`
- [ ] Hiển thị thống kê nhanh:
  - Số bookings pending
  - Số bookings hôm nay
  - Tổng doanh thu (nếu có)
- [ ] Quick actions buttons
- [ ] Badge hiển thị số bookings mới

#### **Bước 3: Bookings Management**
- [ ] Tạo `AdminBookingsScreen`
- [ ] Tabs: Chờ xác nhận, Đã xác nhận, Đã hủy, Đã hoàn thành
- [ ] Real-time listener cho bookings pending
- [ ] List bookings với thông tin cơ bản
- [ ] Badge số lượng bookings mới

#### **Bước 4: Booking Detail & Actions**
- [ ] Tạo `AdminBookingDetailScreen`
- [ ] Hiển thị đầy đủ thông tin booking
- [ ] Actions: Xác nhận, Hủy, Thêm ghi chú
- [ ] Update booking status trong Firestore
- [ ] Validation: Không thể hủy booking đã hoàn thành

#### **Bước 5: Navigation & Integration**
- [ ] Thêm menu "Admin" vào Account screen (chỉ hiện với admin)
- [ ] Hoặc thêm tab "Admin" vào bottom navigation
- [ ] Route protection: Chỉ admin mới vào được
- [ ] Testing với admin account

---

## 📊 DATA STRUCTURE

### **Collection: `admins`**
```json
{
  "id": "admin-user-id",
  "userId": "user-123",
  "email": "admin@example.com",
  "role": "admin",
  "permissions": ["manage_bookings", "manage_tours", "manage_partners"],
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### **Update: `tour_bookings`**
```json
{
  "id": "booking-001",
  "status": "pending", // pending → confirmed/cancelled
  "confirmedAt": null, // Sẽ được set khi admin xác nhận
  "cancelledAt": null,
  "notes": "Ghi chú từ admin",
  ...
}
```

---

## 🎨 UI COMPONENTS CẦN TẠO

1. **`AdminDashboardScreen`** - Dashboard chính
2. **`AdminBookingsScreen`** - Danh sách bookings
3. **`AdminBookingDetailScreen`** - Chi tiết booking
4. **`BookingCard`** - Card hiển thị booking trong list
5. **`BookingStatusBadge`** - Badge trạng thái booking
6. **`AdminStatsCard`** - Card thống kê

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **Security:**
   - ✅ Luôn check quyền admin trước khi cho phép truy cập
   - ✅ Firestore security rules phải chặt chẽ
   - ✅ Không lưu thông tin nhạy cảm ở client

2. **Performance:**
   - ✅ Real-time listener chỉ lắng nghe bookings pending (không load tất cả)
   - ✅ Pagination cho danh sách bookings
   - ✅ Cache thống kê nếu cần

3. **UX:**
   - ✅ Badge rõ ràng số bookings mới
   - ✅ Màu sắc phân biệt trạng thái (pending = vàng, confirmed = xanh)
   - ✅ Confirmation dialog trước khi hủy booking

---

## 🔄 TÍCH HỢP VỚI PHASE 3

Khi triển khai Phase 3 (Booking Flow), cần đảm bảo:
- ✅ Khi user tạo booking → `status = "pending"`
- ✅ Booking được lưu vào Firestore với đầy đủ thông tin
- ✅ Admin có thể xem booking ngay lập tức (real-time)

---

## 📝 NEXT STEPS

1. **Quyết định:** Admin interface trong cùng app hay app riêng?
2. **Setup:** Tạo admin account trong Firestore
3. **Triển khai:** Bắt đầu với Phase 3.5 sau khi Phase 3 hoàn thành

---

**Tài liệu này sẽ được cập nhật trong quá trình triển khai.**

