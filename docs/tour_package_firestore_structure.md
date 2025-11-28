# 📊 CẤU TRÚC DỮ LIỆU TOUR PACKAGE CHO FIRESTORE

## 🗂️ COLLECTION: `tour_packages`

### Document Structure

```json
{
  // ========== THÔNG TIN CƠ BẢN ==========
  "id": "tour-dn-hoi-an-001",                    // Document ID (tự động hoặc set thủ công)
  "title": "Tour Đà Nẵng - Hội An 3N2Đ",        // Tên tour (required)
  "description": "...",                           // Mô tả chi tiết (required)
  "shortDescription": "...",                      // Mô tả ngắn (required)
  "images": ["url1", "url2", "url3"],            // Array of image URLs (required, min 1)
  "thumbnail": "url",                            // Ảnh đại diện (required)
  
  // ========== ĐỊA ĐIỂM & THỜI GIAN ==========
  "destination": "Đà Nẵng - Hội An",            // Địa điểm chính (required)
  "destinations": ["Đà Nẵng", "Hội An"],        // Array of destinations (required)
  "durationDays": 3,                             // Số ngày (required, int)
  "durationNights": 2,                           // Số đêm (required, int)
  "availableDates": [                            // Các ngày khởi hành có sẵn (required, array of Timestamp)
    Timestamp(2024, 2, 15),
    Timestamp(2024, 2, 20)
  ],
  
  // ========== GIÁ CẢ ==========
  "basePrice": 5000000,                          // Giá gốc 1 người (required, double, VND)
  "childPrice": 3500000,                          // Giá trẻ em (optional, double, VND)
  "infantPrice": 0,                              // Giá em bé (optional, double, VND)
  "priceType": "per_person",                     // Loại giá: "per_person", "per_room", "per_group" (required)
  "priceTiers": [                                // Giá theo số người (optional, array)
    {
      "minPeople": 1,
      "maxPeople": 2,
      "pricePerPerson": 5000000
    },
    {
      "minPeople": 3,
      "maxPeople": 4,
      "pricePerPerson": 4500000
    },
    {
      "minPeople": 5,
      "maxPeople": null,                         // null = không giới hạn
      "pricePerPerson": 4000000
    }
  ],
  "currency": "VND",                             // Đơn vị tiền tệ (default: "VND")
  
  // ========== LỊCH TRÌNH ==========
  "itinerary": [                                 // Lịch trình từng ngày (required, array)
    {
      "dayNumber": 1,                            // Số ngày (required, int)
      "title": "Ngày 1: Khám phá Đà Nẵng",      // Tiêu đề ngày (required)
      "description": "...",                       // Mô tả ngày (required)
      "activities": [                            // Các hoạt động (required, array)
        {
          "time": "08:00",                       // Giờ (required, string HH:mm)
          "name": "Đón khách",                   // Tên hoạt động (required)
          "description": "..."                   // Mô tả (optional)
        }
      ],
      "meals": ["Bữa sáng", "Bữa trưa"],        // Các bữa ăn (optional, array)
      "accommodation": "Khách sạn 3-4 sao"      // Nơi nghỉ (optional, string)
    }
  ],
  
  // ========== BAO GỒM / KHÔNG BAO GỒM ==========
  "inclusions": {                                // Bao gồm (required, object)
    "transportation": ["Xe đưa đón", "..."],     // Phương tiện (optional, array)
    "accommodation": ["2 đêm khách sạn", "..."], // Chỗ ở (optional, array)
    "meals": ["2 bữa sáng", "..."],             // Bữa ăn (optional, array)
    "activities": ["Vé tham quan", "..."],      // Hoạt động (optional, array)
    "other": ["Nước uống", "..."]               // Khác (optional, array)
  },
  "exclusions": {                                // Không bao gồm (required, object)
    "meals": ["Đồ uống có cồn"],                // Bữa ăn (optional, array)
    "activities": ["Chi phí cá nhân"],           // Hoạt động (optional, array)
    "other": ["Vé máy bay"]                     // Khác (optional, array)
  },
  
  // ========== CHÍNH SÁCH HỦY ==========
  "cancellationPolicy": {                        // Chính sách hủy (required, object)
    "type": "flexible",                          // Loại: "flexible", "moderate", "strict" (required)
    "rules": [                                   // Các quy tắc (required, array)
      {
        "daysBeforeDeparture": 15,               // Số ngày trước khi khởi hành (required, int)
        "refundPercentage": 100,                  // % hoàn tiền (required, int, 0-100)
        "description": "Hủy trước 15 ngày: Hoàn 100% tiền" // Mô tả (required)
      }
    ],
    "notes": "Thời gian tính từ ngày khởi hành..." // Ghi chú (optional)
  },
  "termsAndConditions": "...",                  // Điều khoản (optional, string)
  
  // ========== THÔNG TIN TOUR ==========
  "type": "group",                               // Loại: "private", "group", "self_guided" (required)
  "maxGroupSize": 30,                            // Số người tối đa (required, int)
  "minGroupSize": 2,                             // Số người tối thiểu (required, int)
  "language": "Tiếng Việt",                     // Ngôn ngữ hướng dẫn (optional, string)
  "pickupLocation": "Sân bay Đà Nẵng",         // Điểm đón (optional, string)
  "dropoffLocation": "Sân bay Đà Nẵng",        // Điểm trả (optional, string)
  
  // ========== ĐÁNH GIÁ & THỐNG KÊ ==========
  "rating": 4.8,                                 // Điểm đánh giá (required, double, 0-5)
  "reviewCount": 125,                            // Số lượt đánh giá (required, int)
  "bookingCount": 342,                           // Số lượt đặt (required, int)
  "viewCount": 1250,                             // Số lượt xem (required, int)
  
  // ========== TRẠNG THÁI ==========
  "status": "active",                            // Trạng thái: "active", "inactive", "sold_out" (required)
  "featured": true,                              // Tour nổi bật (required, boolean)
  
  // ========== METADATA ==========
  "createdAt": Timestamp(2024, 1, 1),          // Ngày tạo (required, Timestamp)
  "updatedAt": Timestamp(2024, 1, 15),          // Ngày cập nhật (required, Timestamp)
  
  // ========== ĐỐI TÁC ==========
  "providerId": "provider-app",                  // ID đối tác (required, string)
  "providerName": "Smart Travel App",           // Tên đối tác (required, string)
  "providerType": "app",                         // Loại: "app", "partner" (required)
  
  // ========== INDEXING FIELDS ==========
  "destination_lowercase": "đà nẵng - hội an",  // Địa điểm lowercase (for search)
  "title_lowercase": "tour đà nẵng - hội an 3n2đ", // Tên tour lowercase (for search)
  "tags": ["đà nẵng", "hội an", "miền trung"],  // Tags để search (optional, array)
  "priceRange": {                                // Khoảng giá (for filtering)
    "min": 4000000,
    "max": 5000000
  }
}
```

---

## 🔍 FIRESTORE INDEXES CẦN TẠO

### 1. **Query: Lấy tours active, sắp xếp theo featured và rating**

```
Collection: tour_packages
Fields: status (Ascending), featured (Descending), rating (Descending)
```

### 2. **Query: Lọc theo destination và price range**

```
Collection: tour_packages
Fields: status (Ascending), destination_lowercase (Ascending), priceRange.min (Ascending)
```

### 3. **Query: Tìm kiếm theo text**

```
Collection: tour_packages
Fields: status (Ascending), title_lowercase (Ascending)
```

### 4. **Query: Lọc theo provider**

```
Collection: tour_packages
Fields: status (Ascending), providerId (Ascending), createdAt (Descending)
```

---

## 📝 LƯU Ý KHI IMPORT VÀO FIRESTORE

### 1. **Convert JSON sang Firestore format**

- `availableDates`: Array of strings → Array of Timestamps
- `createdAt`, `updatedAt`: String → Timestamp
- `priceTiers`: Giữ nguyên object structure
- `inclusions`, `exclusions`: Giữ nguyên object structure
- `cancellationPolicy`: Giữ nguyên object structure
- `itinerary`: Giữ nguyên array of objects

### 2. **Tạo computed fields**

- `destination_lowercase`: Lowercase của `destination`
- `title_lowercase`: Lowercase của `title`
- `priceRange.min`: Giá thấp nhất (từ `basePrice` hoặc `priceTiers`)
- `priceRange.max`: Giá cao nhất
- `tags`: Extract từ `destinations` và `title`

### 3. **Validation trước khi import**

- ✅ `title`, `description`, `shortDescription` không rỗng
- ✅ `images` có ít nhất 1 URL
- ✅ `basePrice` > 0
- ✅ `durationDays` > 0
- ✅ `maxGroupSize` >= `minGroupSize`
- ✅ `availableDates` không rỗng
- ✅ `itinerary` có ít nhất 1 ngày
- ✅ `status` là một trong: "active", "inactive", "sold_out"
- ✅ `providerType` là "app" hoặc "partner"

---

## 🛠️ SCRIPT IMPORT (Tùy chọn)

Có thể tạo script Dart/Node.js để:
1. Đọc file JSON
2. Validate dữ liệu
3. Convert sang Firestore format
4. Tạo computed fields
5. Upload vào Firestore

---

## 📋 CHECKLIST CHUẨN BỊ DATA

- [ ] Tạo ít nhất 5-10 tour packages mẫu
- [ ] Đảm bảo mỗi tour có:
  - [ ] Thông tin cơ bản đầy đủ
  - [ ] Lịch trình ít nhất 2 ngày
  - [ ] Hình ảnh (có thể dùng placeholder URLs)
  - [ ] Giá cả hợp lý
  - [ ] Chính sách hủy rõ ràng
- [ ] Mix các loại tour:
  - [ ] Tour do app tạo (`providerType: "app"`)
  - [ ] Tour do đối tác tạo (`providerType: "partner"`)
- [ ] Mix các địa điểm khác nhau
- [ ] Mix các loại tour: group, private (nếu có)
- [ ] Test với các trạng thái: active, inactive, sold_out

---

## 🎯 VÍ DỤ MINIMAL (Tối thiểu)

Nếu muốn test nhanh, có thể tạo tour với cấu trúc tối thiểu:

```json
{
  "title": "Tour Test",
  "description": "Mô tả tour",
  "shortDescription": "Mô tả ngắn",
  "images": ["https://example.com/image.jpg"],
  "thumbnail": "https://example.com/image.jpg",
  "destination": "Đà Nẵng",
  "destinations": ["Đà Nẵng"],
  "durationDays": 2,
  "durationNights": 1,
  "availableDates": [Timestamp(2024, 2, 15)],
  "basePrice": 3000000,
  "priceType": "per_person",
  "itinerary": [
    {
      "dayNumber": 1,
      "title": "Ngày 1",
      "description": "Mô tả ngày 1",
      "activities": [
        {
          "time": "08:00",
          "name": "Hoạt động 1",
          "description": ""
        }
      ],
      "meals": [],
      "accommodation": null
    }
  ],
  "inclusions": {
    "transportation": [],
    "accommodation": [],
    "meals": [],
    "activities": [],
    "other": []
  },
  "exclusions": {
    "meals": [],
    "activities": [],
    "other": []
  },
  "cancellationPolicy": {
    "type": "flexible",
    "rules": [
      {
        "daysBeforeDeparture": 7,
        "refundPercentage": 100,
        "description": "Hủy trước 7 ngày: Hoàn 100%"
      }
    ],
    "notes": ""
  },
  "type": "group",
  "maxGroupSize": 20,
  "minGroupSize": 2,
  "rating": 0,
  "reviewCount": 0,
  "bookingCount": 0,
  "viewCount": 0,
  "status": "active",
  "featured": false,
  "createdAt": Timestamp.now(),
  "updatedAt": Timestamp.now(),
  "providerId": "provider-app",
  "providerName": "Smart Travel App",
  "providerType": "app",
  "destination_lowercase": "đà nẵng",
  "title_lowercase": "tour test",
  "tags": ["đà nẵng"],
  "priceRange": {
    "min": 3000000,
    "max": 3000000
  }
}
```

