# Manual Testing Checklist - Validation và Gợi ý Điểm Đến

## Test Cases

### 1. Validation với khoảng cách < ngưỡng (Không cảnh báo)

**Setup:**
- Tạo trip 3 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: Đà Nẵng (cùng ngày hoặc ngày khác)

**Expected:**
- ✅ Không hiển thị dialog cảnh báo
- ✅ Điểm đến được thêm vào trip thành công

---

### 2. Validation với khoảng cách > ngưỡng (Cảnh báo)

#### 2.1. Trip 1 ngày - Khoảng cách > 200km

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày)

**Expected:**
- ⚠️ Hiển thị dialog cảnh báo với mức độ "mạnh"
- ⚠️ Hiển thị khoảng cách và thời gian di chuyển
- ⚠️ Hiển thị gợi ý điểm đến gần hơn (nếu có)

#### 2.2. Trip 2 ngày - Khoảng cách > 500km

**Setup:**
- Tạo trip 2 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày hoặc ngày khác)

**Expected:**
- ⚠️ Hiển thị dialog cảnh báo với mức độ "trung bình"
- ⚠️ Hiển thị khoảng cách và thời gian di chuyển
- ⚠️ Hiển thị gợi ý điểm đến gần hơn (nếu có)

#### 2.3. Trip 3-4 ngày - Khoảng cách > 800km

**Setup:**
- Tạo trip 3 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày hoặc ngày khác)

**Expected:**
- ⚠️ Hiển thị dialog cảnh báo với mức độ "nhẹ"
- ⚠️ Hiển thị khoảng cách và thời gian di chuyển
- ⚠️ Hiển thị gợi ý điểm đến gần hơn (nếu có)

#### 2.4. Trip 5+ ngày - Khoảng cách > 1000km

**Setup:**
- Tạo trip 5 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày hoặc ngày khác)

**Expected:**
- ✅ Không hiển thị dialog cảnh báo (ngưỡng 1000km)
- ✅ Điểm đến được thêm vào trip thành công

---

### 3. Điểm đến trong cùng thành phố

**Setup:**
- Tạo trip 2 ngày
- Thêm điểm đến: Hà Nội (Phố cổ Hà Nội)
- Thêm điểm đến: Hà Nội (Hồ Hoàn Kiếm) - cùng ngày

**Expected:**
- ✅ Không hiển thị dialog cảnh báo (khoảng cách < ngưỡng)
- ✅ Điểm đến được thêm vào trip thành công

---

### 4. Điểm đến ở ngày khác

**Setup:**
- Tạo trip 3 ngày
- Thêm điểm đến: Hà Nội (ngày 1)
- Thêm điểm đến: Đà Nẵng (ngày 2)

**Expected:**
- ✅ Validation so sánh với điểm gần nhất (Hà Nội)
- ✅ Nếu khoảng cách hợp lý → Không cảnh báo
- ✅ Nếu khoảng cách không hợp lý → Hiển thị cảnh báo

---

### 5. Dialog Actions

#### 5.1. "Vẫn tiếp tục"

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày)
- Click "Vẫn tiếp tục" trong dialog

**Expected:**
- ✅ Dialog đóng
- ✅ Điểm đến được thêm vào trip thành công
- ✅ Hiển thị trong trip detail screen

#### 5.2. "Hủy"

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày)
- Click "Hủy" trong dialog

**Expected:**
- ✅ Dialog đóng
- ✅ Điểm đến KHÔNG được thêm vào trip
- ✅ Quay lại màn hình thêm điểm đến

#### 5.3. "Chọn điểm đề xuất"

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày)
- Click "Chọn điểm này" trên một suggestion card

**Expected:**
- ✅ Dialog đóng
- ✅ Điểm đến hiện tại (TP.HCM) được thay thế bằng suggestion
- ✅ Hiển thị SnackBar thông báo đã thay thế
- ✅ Ngày và giờ được giữ nguyên
- ✅ User có thể click "Thêm điểm đến" lại để thêm suggestion

---

### 6. Gợi ý điểm đến

#### 6.1. Có suggestions

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày)

**Expected:**
- ✅ Hiển thị danh sách suggestions (nếu có)
- ✅ Mỗi suggestion hiển thị:
  - Thumbnail
  - Tên điểm đến
  - Địa điểm
  - Khoảng cách
  - Thời gian di chuyển
- ✅ Click vào suggestion → Thay thế điểm hiện tại

#### 6.2. Không có suggestions

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày)
- Không có điểm nào gần hơn trong cùng khu vực

**Expected:**
- ✅ Hiển thị empty state: "Không tìm thấy điểm đến gần hơn trong khu vực này"
- ✅ Chỉ hiển thị buttons "Hủy" và "Vẫn tiếp tục"

---

### 7. Loading States

#### 7.1. Khi đang validate

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Click "Thêm điểm đến" với điểm xa

**Expected:**
- ✅ Hiển thị loading indicator khi đang tính toán khoảng cách
- ✅ Dialog hiển thị sau khi tính toán xong

#### 7.2. Khi đang tính khoảng cách cho suggestions

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày)
- Dialog hiển thị với suggestions

**Expected:**
- ✅ Hiển thị CircularProgressIndicator cho mỗi suggestion card khi đang tính khoảng cách
- ✅ Hiển thị khoảng cách sau khi tính toán xong

---

### 8. Error Handling

#### 8.1. MapBox API fail

**Setup:**
- Tắt internet hoặc MapBox API fail
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày)

**Expected:**
- ✅ Fallback về Haversine formula
- ✅ Vẫn hiển thị dialog cảnh báo (nếu khoảng cách > ngưỡng)
- ✅ Khoảng cách và thời gian là ước tính

#### 8.2. Không tìm thấy destination

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến với ID không tồn tại

**Expected:**
- ✅ Hiển thị error message
- ✅ Không crash app

---

### 9. Performance

#### 9.1. Cache hoạt động

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến: TP.HCM (cùng ngày)
- Click "Hủy"
- Thêm lại điểm đến: TP.HCM (cùng ngày)

**Expected:**
- ✅ Lần 2 nhanh hơn (sử dụng cache)
- ✅ Kết quả validation giống nhau

#### 9.2. Batch validation

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Chọn nhiều điểm đến xa (3-5 điểm)
- Click "Thêm điểm đến"

**Expected:**
- ✅ Validate từng điểm một
- ✅ Hiển thị dialog cho mỗi điểm không hợp lý
- ✅ Không bị lag hoặc freeze

---

### 10. Edge Cases

#### 10.1. Trip không có điểm nào

**Setup:**
- Tạo trip mới
- Chọn điểm đến đầu tiên

**Expected:**
- ✅ Validation pass (không có điểm để so sánh)
- ✅ Điểm đến được thêm thành công

#### 10.2. Trip chỉ có 1 điểm

**Setup:**
- Tạo trip 1 ngày
- Thêm điểm đến: Hà Nội
- Thêm điểm đến thứ 2: TP.HCM

**Expected:**
- ✅ Validation so sánh với điểm đầu tiên
- ✅ Hiển thị dialog nếu khoảng cách > ngưỡng

#### 10.3. Điểm đến trong cùng ngày

**Setup:**
- Tạo trip 2 ngày
- Thêm điểm đến: Hà Nội (ngày 1)
- Thêm điểm đến: TP.HCM (ngày 1)

**Expected:**
- ✅ Validation so sánh với các điểm trong cùng ngày
- ✅ Hiển thị dialog nếu khoảng cách > ngưỡng

---

## Test Results Template

| Test Case | Status | Notes |
|-----------|--------|-------|
| 1. Validation < ngưỡng | ⬜ Pass / ⬜ Fail | |
| 2.1. Trip 1 ngày > 200km | ⬜ Pass / ⬜ Fail | |
| 2.2. Trip 2 ngày > 500km | ⬜ Pass / ⬜ Fail | |
| 2.3. Trip 3-4 ngày > 800km | ⬜ Pass / ⬜ Fail | |
| 2.4. Trip 5+ ngày > 1000km | ⬜ Pass / ⬜ Fail | |
| 3. Cùng thành phố | ⬜ Pass / ⬜ Fail | |
| 4. Ngày khác | ⬜ Pass / ⬜ Fail | |
| 5.1. Action: Vẫn tiếp tục | ⬜ Pass / ⬜ Fail | |
| 5.2. Action: Hủy | ⬜ Pass / ⬜ Fail | |
| 5.3. Action: Chọn suggestion | ⬜ Pass / ⬜ Fail | |
| 6.1. Có suggestions | ⬜ Pass / ⬜ Fail | |
| 6.2. Không có suggestions | ⬜ Pass / ⬜ Fail | |
| 7.1. Loading khi validate | ⬜ Pass / ⬜ Fail | |
| 7.2. Loading khi tính suggestions | ⬜ Pass / ⬜ Fail | |
| 8.1. MapBox API fail | ⬜ Pass / ⬜ Fail | |
| 8.2. Không tìm thấy destination | ⬜ Pass / ⬜ Fail | |
| 9.1. Cache hoạt động | ⬜ Pass / ⬜ Fail | |
| 9.2. Batch validation | ⬜ Pass / ⬜ Fail | |
| 10.1. Trip không có điểm | ⬜ Pass / ⬜ Fail | |
| 10.2. Trip chỉ có 1 điểm | ⬜ Pass / ⬜ Fail | |
| 10.3. Cùng ngày | ⬜ Pass / ⬜ Fail | |

---

## Notes

- Test trên cả Android và iOS (nếu có)
- Test với các kết nối mạng khác nhau (WiFi, 4G, 3G)
- Test với MapBox API quota đầy (nếu có)
- Test với nhiều destinations cùng lúc
- Test với trip dài (10+ ngày)
- Test với trip ngắn (1 ngày)

