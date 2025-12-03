# Firestore Indexes cho Tour Packages

## Index cần thiết

Để query tours hiệu quả, cần tạo các composite indexes sau trong Firestore:

### 1. Index cho Featured Tours Query

**Collection:** `tour_packages`

**Fields:**
- `featured` (Ascending)
- `status` (Ascending)  
- `rating` (Descending)
- `__name__` (Descending)

**Link tạo index:**
```
https://console.firebase.google.com/v1/r/project/smart-travel-app-a2bfa/firestore/indexes?create_composite=Clxwcm9qZWN0cy9zbWFydC10cmF2ZWwtYXBwLWEyYmZhL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy90b3VyX3BhY2thZ2VzL2luZGV4ZXMvXxABGgwKCGZlYXR1cmVkEAEaCgoGc3RhdHVzEAEaCgoGcmF0aW5nEAIaDAoIX19uYW1lX18QAg
```

### 2. Index cho Active Tours Query

**Collection:** `tour_packages`

**Fields:**
- `status` (Ascending)
- `featured` (Descending)
- `rating` (Descending)
- `__name__` (Descending)

### 3. Index cho Search Query (title_lowercase)

**Collection:** `tour_packages`

**Fields:**
- `status` (Ascending)
- `title_lowercase` (Ascending)
- `__name__` (Ascending)

### 4. Index cho Search Query (destination_lowercase)

**Collection:** `tour_packages`

**Fields:**
- `status` (Ascending)
- `destination_lowercase` (Ascending)
- `__name__` (Ascending)

## Cách tạo index

1. **Tự động:** Click vào link trong error message khi chạy app
2. **Thủ công:** 
   - Vào Firebase Console → Firestore → Indexes
   - Click "Create Index"
   - Chọn collection `tour_packages`
   - Thêm các fields theo thứ tự trên
   - Click "Create"

## Lưu ý

- Index có thể mất vài phút để build
- App sẽ dùng fallback query nếu chưa có index (chậm hơn nhưng vẫn hoạt động)
- Sau khi index được tạo, app sẽ tự động dùng query tối ưu



