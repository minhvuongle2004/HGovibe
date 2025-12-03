# 🛠️ ADMIN WEB APP - TECH STACK & SETUP GUIDE

## 🎯 QUYẾT ĐỊNH

**Admin Interface = Web Application** (riêng biệt với Flutter mobile app)

---

## 🔧 CÔNG NGHỆ ĐỀ XUẤT

### **Option 1: Flutter Web** ⭐ **KHUYẾN NGHỊ**

**Ưu điểm:**
- ✅ Share codebase với mobile app (models, services, business logic)
- ✅ Dùng cùng Firebase SDK
- ✅ Dễ maintain, một codebase cho cả mobile và web
- ✅ Material Design sẵn có
- ✅ Hot reload, development nhanh

**Nhược điểm:**
- ⚠️ Bundle size lớn hơn React/Vue
- ⚠️ Performance có thể chậm hơn một chút (nhưng đủ dùng)

**Setup:**
```bash
# Tạo Flutter web project
flutter create admin_web_app
cd admin_web_app

# Enable web
flutter config --enable-web

# Run
flutter run -d chrome

# Build
flutter build web
```

**Cấu trúc:**
```
admin_web_app/
├── lib/
│   ├── models/          # Import từ shared package hoặc copy
│   ├── services/        # Import từ shared package hoặc copy
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── dashboard/
│   │   │   └── admin_dashboard_screen.dart
│   │   ├── bookings/
│   │   │   ├── admin_bookings_screen.dart
│   │   │   └── admin_booking_detail_screen.dart
│   │   └── tours/
│   │       └── admin_tours_screen.dart
│   ├── widgets/
│   │   ├── booking_card.dart
│   │   ├── booking_status_badge.dart
│   │   └── stats_card.dart
│   └── main.dart
├── web/
│   ├── index.html
│   └── assets/
└── pubspec.yaml
```

**Dependencies:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.0.0
  cloud_firestore: ^4.0.0
  firebase_auth: ^4.0.0
  provider: ^6.0.0
  intl: ^0.18.0
  
  # Share code với mobile app
  # Option 1: Tạo shared package
  smart_travel_shared:
    path: ../packages/smart_travel_shared
  
  # Option 2: Copy models/services (không khuyến nghị)
```

---

### **Option 2: React + TypeScript + Material-UI**

**Ưu điểm:**
- ✅ Ecosystem phong phú
- ✅ Nhiều UI libraries
- ✅ Performance tốt
- ✅ Dễ tìm developers

**Nhược điểm:**
- ⚠️ Cần viết lại models/services
- ⚠️ Không share code với mobile app

**Setup:**
```bash
npx create-react-app admin-web --template typescript
cd admin-web
npm install firebase @mui/material @mui/icons @emotion/react @emotion/styled
npm install react-router-dom
```

**Cấu trúc:**
```
admin-web/
├── src/
│   ├── models/          # TypeScript interfaces
│   ├── services/        # Firebase services
│   ├── components/
│   │   ├── BookingCard.tsx
│   │   └── StatsCard.tsx
│   ├── screens/
│   │   ├── Login.tsx
│   │   ├── Dashboard.tsx
│   │   └── Bookings.tsx
│   ├── App.tsx
│   └── index.tsx
└── package.json
```

**Dependencies:**
```json
{
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "react-router-dom": "^6.0.0",
    "firebase": "^10.0.0",
    "@mui/material": "^5.0.0",
    "@mui/icons-material": "^5.0.0"
  }
}
```

---

### **Option 3: Vue 3 + TypeScript + Vuetify**

**Ưu điểm:**
- ✅ Dễ học, syntax đơn giản
- ✅ Performance tốt
- ✅ Vuetify UI components đẹp

**Nhược điểm:**
- ⚠️ Cần viết lại models/services
- ⚠️ Ecosystem nhỏ hơn React

**Setup:**
```bash
npm create vue@latest admin-web
cd admin-web
npm install firebase vuetify @mdi/font
```

---

## 📦 SHARED CODE STRATEGY

### **Nếu dùng Flutter Web:**

**Option A: Shared Package** (Khuyến nghị)
```
smart_travel_app/
├── packages/
│   └── smart_travel_shared/
│       ├── lib/
│       │   ├── models/
│       │   │   ├── tour_package.dart
│       │   │   └── tour_booking.dart
│       │   └── services/
│       │       ├── tour_package_service.dart
│       │       └── tour_booking_service.dart
│       └── pubspec.yaml
├── mobile_app/          # Flutter mobile
└── admin_web_app/       # Flutter web
```

**Option B: Copy code** (Không khuyến nghị)
- Copy models/services vào admin web app
- Khó maintain, dễ lỗi sync

### **Nếu dùng React/Vue:**

**Cần viết lại:**
- Models → TypeScript interfaces
- Services → TypeScript classes/functions
- Có thể share business logic qua comments/docs

---

## 🔐 AUTHENTICATION SETUP

### **Firebase Auth Configuration:**

**1. Tạo admin users:**
```javascript
// Firebase Console hoặc Admin SDK
admin.auth().createUser({
  email: 'admin@smarttravel.app',
  password: 'secure_password',
  displayName: 'Admin User'
});
```

**2. Check admin role:**
```dart
// Flutter
Future<bool> isAdmin(String userId) async {
  final doc = await FirebaseFirestore.instance
    .collection('admins')
    .doc(userId)
    .get();
  return doc.exists;
}
```

```typescript
// React/TypeScript
async function isAdmin(userId: string): Promise<boolean> {
  const doc = await getDoc(doc(db, 'admins', userId));
  return doc.exists();
}
```

---

## 🎨 UI/UX DESIGN

### **Layout Structure:**

```
┌─────────────────────────────────────────┐
│  Header: Logo | Admin Name | Logout     │
├──────────┬──────────────────────────────┤
│          │                              │
│ Sidebar  │  Main Content Area           │
│          │                              │
│ - Dashboard│  [Content based on route]  │
│ - Bookings│                              │
│ - Tours   │                              │
│ - Partners│                              │
│          │                              │
└──────────┴──────────────────────────────┘
```

### **Color Scheme:**
- Primary: Orange (giống mobile app)
- Success: Green (confirmed bookings)
- Warning: Yellow (pending bookings)
- Error: Red (cancelled bookings)

---

## 🚀 DEPLOYMENT OPTIONS

### **Option 1: Firebase Hosting** ⭐

**Flutter Web:**
```bash
flutter build web
firebase deploy --only hosting
```

**React/Vue:**
```bash
npm run build
firebase deploy --only hosting
```

**Firebase Hosting config:**
```json
{
  "hosting": {
    "public": "build/web",  // Flutter
    // "public": "build",   // React
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### **Option 2: Vercel**

**Setup:**
1. Connect GitHub repo
2. Set build command: `flutter build web` hoặc `npm run build`
3. Set output directory: `build/web` hoặc `build`
4. Auto deploy on push

### **Option 3: Netlify**

Tương tự Vercel

---

## 📝 RECOMMENDATION

**Khuyến nghị: Flutter Web**

**Lý do:**
1. ✅ Share code với mobile app
2. ✅ Dễ maintain
3. ✅ Một team, một codebase
4. ✅ Đủ performance cho admin interface

**Nếu team có kinh nghiệm React/Vue:**
- Có thể chọn React/Vue
- Nhưng cần viết lại models/services

---

## 🎯 NEXT STEPS

1. **Quyết định công nghệ:** Flutter Web hay React/Vue?
2. **Setup project:** Tạo admin web project
3. **Setup Firebase:** Cấu hình authentication và Firestore
4. **Implement:** Bắt đầu với login và dashboard
5. **Deploy:** Deploy lên hosting

---

**Tài liệu này sẽ được cập nhật trong quá trình triển khai.**

