# 🔗 MỐI QUAN HỆ GIỮA TOUR PACKAGES VÀ DESTINATIONS

## ✅ XÁC NHẬN: ĐỘC LẬP HOÀN TOÀN

**Tour Packages** và **Destinations** là **2 collections riêng biệt** trong Firestore:

```
Firestore
├─ tour_packages/          ← Collection riêng
│  └─ {tourId}             ← Document tour
│
└─ destinations/           ← Collection riêng
   └─ {destinationId}      ← Document destination
```

**Chúng KHÔNG phụ thuộc vào nhau:**
- ✅ Bạn có thể tạo tour packages mà KHÔNG cần có destinations trong Firestore
- ✅ Bạn có thể tạo destinations mà KHÔNG cần có tour packages
- ✅ Tour packages có thể hoạt động độc lập

---

## 📊 FIELD `destinations` TRONG TOUR PACKAGE

Trong tour package, có field `destinations`:

```json
{
  "destination": "Đà Nẵng - Hội An",        // String: tên địa điểm chính
  "destinations": ["Đà Nẵng", "Hội An"]     // Array of strings: danh sách tên địa điểm
}
```

**Đây chỉ là TÊN ĐỊA ĐIỂM (strings), KHÔNG phải reference đến collection `destinations`.**

### **Mục đích:**
- Hiển thị địa điểm tour đi qua
- Filter/search tours theo địa điểm
- Tagging và categorization

### **KHÔNG cần:**
- ❌ Destination IDs từ collection `destinations`
- ❌ Link/reference đến documents trong `destinations`
- ❌ Validation xem destination có tồn tại không

---

## 🔗 MỐI QUAN HỆ TÙY CHỌN (Nếu muốn link)

Nếu bạn **MUỐN** link tours với destinations (để user có thể xem chi tiết destination từ tour), có thể thêm field:

```json
{
  "destination": "Đà Nẵng - Hội An",
  "destinations": ["Đà Nẵng", "Hội An"],        // Tên địa điểm (bắt buộc)
  "destinationIds": [                            // IDs từ collection destinations (tùy chọn)
    "destination-da-nang-id",
    "destination-hoi-an-id"
  ]
}
```

**Lưu ý:**
- Field `destinationIds` là **TÙY CHỌN**
- Nếu không có, tour vẫn hoạt động bình thường
- Chỉ cần khi muốn link đến chi tiết destination

---

## 📝 CÁCH TẠO DATA TOUR PACKAGES

### **Bước 1: Tạo tour packages độc lập**

Bạn có thể tạo tour packages với:
- ✅ Tên địa điểm tự do (không cần có trong collection `destinations`)
- ✅ Mô tả, hình ảnh, lịch trình tự do
- ✅ Giá cả, chính sách tự do

**Ví dụ:**
```json
{
  "title": "Tour Phú Quốc 4N3Đ",
  "destination": "Phú Quốc",
  "destinations": ["Phú Quốc"],
  "description": "Khám phá đảo ngọc Phú Quốc...",
  // ... các field khác
}
```

**KHÔNG cần:**
- ❌ Kiểm tra xem "Phú Quốc" có trong collection `destinations` không
- ❌ Tạo destination trước
- ❌ Link đến destination ID

### **Bước 2: Tạo data mẫu**

Bạn có thể:
1. **Copy format** từ `assets/data/tour_packages_sample.json`
2. **Tạo 10 tour packages** với các địa điểm khác nhau:
   - Đà Nẵng - Hội An
   - Hạ Long
   - Sapa
   - Phú Quốc
   - Đà Lạt
   - Nha Trang
   - Huế
   - Hà Nội
   - TP.HCM
   - Mũi Né

3. **Tự do tạo** lịch trình, giá cả, chính sách

---

## 🎯 KẾT LUẬN

### **Để tạo data tour packages:**

1. ✅ **KHÔNG cần** data destinations trước
2. ✅ **KHÔNG cần** link đến destinations
3. ✅ **CHỈ CẦN** tên địa điểm (strings) trong field `destinations`
4. ✅ **TỰ DO** tạo tour packages với bất kỳ địa điểm nào

### **Nếu muốn link (tùy chọn):**

1. Tạo tour packages trước (với tên địa điểm)
2. Sau đó có thể thêm field `destinationIds` nếu muốn link
3. Hoặc không link cũng được, tour vẫn hoạt động bình thường

---

## 📋 CHECKLIST TẠO DATA TOUR PACKAGES

- [ ] Copy format từ `assets/data/tour_packages_sample.json`
- [ ] Tạo 10 tour packages với các địa điểm khác nhau
- [ ] Điền đầy đủ thông tin: title, description, images, itinerary, price, policy
- [ ] **KHÔNG cần** kiểm tra destinations collection
- [ ] **KHÔNG cần** destination IDs
- [ ] Chỉ cần tên địa điểm (strings) trong field `destinations`

