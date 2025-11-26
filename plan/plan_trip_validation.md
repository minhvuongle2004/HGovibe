# Kế hoạch triển khai: Validation và Gợi ý Điểm Đến

## Mục tiêu
Ngăn chặn người dùng thêm các điểm đến không hợp lý về mặt địa lý và thời gian, đồng thời gợi ý các điểm đến phù hợp hơn trong cùng khu vực.

## Vấn đề cần giải quyết
- Người dùng có thể chọn các điểm đến cách xa nhau (ví dụ: Hà Nội và TP.HCM) trong cùng 1-2 ngày du lịch
- Điều này không hợp lý về mặt thời gian và khoảng cách
- Cần cảnh báo và gợi ý các điểm đến gần hơn

## Ngưỡng khoảng cách

| Số ngày du lịch | Khoảng cách tối đa (cảnh báo) | Mức độ cảnh báo |
|----------------|-------------------------------|-----------------|
| 1 ngày         | >200km                        | Cảnh báo mạnh   |
| 2 ngày         | >500km                        | Cảnh báo        |
| 3-4 ngày       | >800km                        | Cảnh báo nhẹ    |
| 5+ ngày        | >1000km                       | Không cảnh báo  |

## Tính năng

### 1. Validation khoảng cách
- Kiểm tra khoảng cách giữa điểm đến mới và các điểm đã chọn
- Tính thời gian di chuyển ước tính
- So sánh với số ngày du lịch

### 2. Cảnh báo thông minh
- Hiển thị dialog cảnh báo khi phát hiện điểm đến không hợp lý
- Hiển thị khoảng cách và thời gian di chuyển
- Cho phép người dùng quyết định: tiếp tục, chọn điểm đề xuất, hoặc hủy

### 3. Gợi ý điểm đến
- Tìm các điểm đến gần hơn trong cùng khu vực/tỉnh thành
- Sắp xếp theo khoảng cách gần nhất
- Hiển thị trong dialog để người dùng có thể chọn thay thế

## Công nghệ sử dụng

### MapBox API
- **API Key**: `pk.eyJ1IjoidnVvbmdkaDEyYzEiLCJhIjoiY21pOXM2cDV3MHB4NTJpcGo2cTNxNjBxZSJ9.erxF_ABIH1oJYeyAABK-Kg`
- **API sử dụng**:
  1. **MapBox Distance Matrix API**: Tính khoảng cách và thời gian di chuyển thực tế
  2. **MapBox Geocoding API** (tùy chọn): Tìm điểm gần dựa trên tọa độ

### Endpoints MapBox
- **Distance Matrix**: `https://api.mapbox.com/directions-matrix/v1/mapbox/driving/{coordinates}?access_token={token}`
- **Geocoding Reverse**: `https://api.mapbox.com/geocoding/v5/mapbox.places/{lng},{lat}.json?access_token={token}`

## Cấu trúc dữ liệu

### DistanceResult
```dart
class DistanceResult {
  final double distance; // Khoảng cách (km)
  final int duration; // Thời gian di chuyển (giây)
  final String? mode; // Phương tiện (driving, walking, cycling)
}
```

### ValidationResult
```dart
class ValidationResult {
  final bool isValid;
  final String? warningMessage;
  final double? distance;
  final int? estimatedDuration;
  final List<Destination>? suggestedDestinations; // Điểm đến gần hơn
}
```

## Implementation Plan

### Phase 1: Setup MapBox Service (2-3 giờ)

#### 1.1. Tạo MapBox Service
- **File**: `lib/services/mapbox_service.dart`
- **Chức năng**:
  - Tính khoảng cách giữa 2 điểm (lat/lng)
  - Tính thời gian di chuyển
  - Cache kết quả để tránh gọi API nhiều lần
  - Fallback: Haversine formula nếu API fail

#### 1.2. Cấu hình API
- **File**: `lib/config/api_config.dart`
- Thêm MapBox API key và base URL

#### 1.3. Dependencies
- Thêm `http` package (đã có)
- Không cần thêm package mới

#### Tasks:
- [ ] Tạo `MapBoxService` class
- [ ] Implement `calculateDistance()` method
- [ ] Implement `calculateDistanceMatrix()` method (nhiều điểm)
- [ ] Thêm caching logic
- [ ] Thêm fallback Haversine formula
- [ ] Thêm error handling

---

### Phase 2: Trip Validation Service (2-3 giờ)

#### 2.1. Tạo Trip Validation Service
- **File**: `lib/services/trip_validation_service.dart`
- **Chức năng**:
  - Validate điểm đến mới với các điểm đã chọn
  - Tính khoảng cách và thời gian di chuyển
  - So sánh với ngưỡng dựa trên số ngày du lịch
  - Trả về `ValidationResult`

#### 2.2. Logic validation
```dart
ValidationResult validateDestination(
  Destination newDestination,
  List<TripItem> existingItems,
  int tripDays,
  DateTime? plannedDate,
) {
  // 1. Lấy các điểm đến trong cùng ngày hoặc ngày gần nhất
  // 2. Tính khoảng cách đến điểm mới
  // 3. Kiểm tra ngưỡng dựa trên số ngày
  // 4. Trả về kết quả validation
}
```

#### Tasks:
- [ ] Tạo `TripValidationService` class
- [ ] Implement `validateDestination()` method
- [ ] Implement logic kiểm tra ngưỡng
- [ ] Tính toán thời gian di chuyển ước tính
- [ ] Xử lý trường hợp điểm đến trong cùng ngày
- [ ] Xử lý trường hợp điểm đến ở ngày khác

---

### Phase 3: Destination Suggestion Service (3-4 giờ)

#### 3.1. Tạo Destination Suggestion Service
- **File**: `lib/services/destination_suggestion_service.dart`
- **Chức năng**:
  - Tìm các điểm đến gần hơn trong cùng khu vực
  - Filter theo category/tags (tùy chọn)
  - Sắp xếp theo khoảng cách
  - Trả về danh sách gợi ý (tối đa 5-10 điểm)

#### 3.2. Logic gợi ý
```dart
Future<List<Destination>> suggestNearbyDestinations(
  Destination targetDestination,
  List<Destination> allDestinations,
  double maxDistance, // km
  int limit,
) async {
  // 1. Filter destinations trong cùng tỉnh/thành phố
  // 2. Tính khoảng cách đến target
  // 3. Sắp xếp theo khoảng cách
  // 4. Trả về top N điểm gần nhất
}
```

#### Tasks:
- [ ] Tạo `DestinationSuggestionService` class
- [ ] Implement `suggestNearbyDestinations()` method
- [ ] Filter theo location.city hoặc location.province
- [ ] Tính khoảng cách đến target
- [ ] Sắp xếp và limit kết quả
- [ ] Cache kết quả gợi ý

---

### Phase 4: UI Components (3-4 giờ)

#### 4.1. Distance Warning Dialog
- **File**: `lib/widgets/distance_warning_dialog.dart`
- **Chức năng**:
  - Hiển thị cảnh báo khoảng cách
  - Hiển thị thông tin: khoảng cách, thời gian di chuyển
  - Hiển thị danh sách điểm đến gợi ý
  - Buttons: "Hủy", "Vẫn tiếp tục", "Chọn điểm đề xuất"

#### 4.2. Suggested Destination Card
- **File**: `lib/widgets/suggested_destination_card.dart`
- **Chức năng**:
  - Hiển thị thông tin điểm đến gợi ý
  - Hiển thị khoảng cách đến điểm hiện tại
  - Button "Chọn điểm này"

#### 4.3. UI Flow
```
User chọn điểm đến
    ↓
Kiểm tra validation
    ↓
Nếu không hợp lý → Hiển thị Dialog
    ↓
User chọn:
  - Hủy → Quay lại
  - Vẫn tiếp tục → Thêm điểm vào trip
  - Chọn điểm đề xuất → Thay thế điểm hiện tại
```

#### Tasks:
- [ ] Tạo `DistanceWarningDialog` widget
- [ ] Tạo `SuggestedDestinationCard` widget
- [ ] Design UI cho dialog
- [ ] Implement logic chọn điểm đề xuất
- [ ] Thêm animations/transitions
- [ ] Test các trường hợp edge cases

---

### Phase 5: Integration (2-3 giờ)

#### 5.1. Tích hợp vào AddDestinationsToTripScreen
- **File**: `lib/screens/add_destinations_to_trip_screen.dart`
- **Chức năng**:
  - Khi user chọn điểm đến và click "Thêm", validate trước
  - Nếu không hợp lý, hiển thị dialog
  - Xử lý các action từ dialog

#### 5.2. Tích hợp vào TripProvider (tùy chọn)
- Có thể thêm validation vào `addDestinationToTrip()` method
- Hoặc để validation ở UI layer

#### Tasks:
- [ ] Import validation service vào `AddDestinationsToTripScreen`
- [ ] Gọi validation trước khi thêm điểm đến
- [ ] Hiển thị dialog nếu cần
- [ ] Xử lý action từ dialog
- [ ] Update UI sau khi thêm điểm đến

---

### Phase 6: Testing & Refinement (2-3 giờ)

#### 6.1. Test cases
- [ ] Test với khoảng cách < ngưỡng (không cảnh báo)
- [ ] Test với khoảng cách > ngưỡng (cảnh báo)
- [ ] Test với 1 ngày du lịch
- [ ] Test với 2 ngày du lịch
- [ ] Test với 5+ ngày du lịch
- [ ] Test với điểm đến trong cùng thành phố
- [ ] Test với điểm đến khác tỉnh
- [ ] Test với MapBox API fail (fallback)
- [ ] Test với không có điểm đề xuất

#### 6.2. Performance
- [ ] Kiểm tra cache hoạt động đúng
- [ ] Tối ưu số lượng API calls
- [ ] Test với nhiều điểm đến

#### 6.3. UX improvements
- [ ] Loading state khi tính toán khoảng cách
- [ ] Error handling khi API fail
- [ ] Empty state khi không có điểm đề xuất

---

## Chi tiết Implementation

### MapBox Service

#### API Endpoint
```
GET https://api.mapbox.com/directions-matrix/v1/mapbox/driving/{coordinates}?access_token={token}&annotations=distance,duration
```

#### Request Example
```
GET https://api.mapbox.com/directions-matrix/v1/mapbox/driving/105.8342,21.0278;106.6297,10.8231?access_token=pk.eyJ1IjoidnVvbmdkaDEyYzEiLCJhIjoiY21pOXM2cDV3MHB4NTJpcGo2cTNxNjBxZSJ9.erxF_ABIH1oJYeyAABK-Kg&annotations=distance,duration
```

#### Response Format
```json
{
  "code": "Ok",
  "distances": [[0, 1700000], [1700000, 0]],
  "durations": [[0, 72000], [72000, 0]]
}
```

#### Haversine Formula (Fallback)
```dart
double calculateHaversineDistance(
  double lat1, double lng1,
  double lat2, double lng2,
) {
  const double earthRadius = 6371; // km
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLng / 2) * sin(dLng / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}
```

### Validation Logic

#### Pseudocode
```
function validateDestination(newDest, existingItems, tripDays):
  if existingItems.isEmpty:
    return VALID
  
  // Lấy các điểm trong cùng ngày hoặc ngày gần nhất
  sameDayItems = filter items with same plannedDate
  nearestDayItems = filter items with nearest plannedDate
  
  // Tính khoảng cách
  maxDistance = 0
  for each item in (sameDayItems + nearestDayItems):
    distance = calculateDistance(newDest, item.destination)
    if distance > maxDistance:
      maxDistance = distance
  
  // Kiểm tra ngưỡng
  threshold = getThreshold(tripDays)
  if maxDistance > threshold:
    return INVALID with warning
  else:
    return VALID
```

### Suggestion Logic

#### Pseudocode
```
function suggestNearbyDestinations(target, allDestinations, maxDistance):
  // Filter theo cùng tỉnh/thành phố
  sameRegion = filter destinations where 
    location.city == target.location.city OR
    location.province == target.location.province
  
  // Tính khoảng cách
  suggestions = []
  for each dest in sameRegion:
    distance = calculateDistance(target, dest)
    if distance < maxDistance AND distance > 0:
      suggestions.add({dest, distance})
  
  // Sắp xếp theo khoảng cách
  sort suggestions by distance ascending
  
  // Limit kết quả
  return top 5-10 suggestions
```

---

## UI/UX Design

### Distance Warning Dialog

```
┌─────────────────────────────────────────┐
│  ⚠️ Cảnh báo khoảng cách                │
├─────────────────────────────────────────┤
│  Điểm đến bạn chọn có khoảng cách khá  │
│  xa so với các điểm đã chọn:            │
│                                          │
│  📍 Hà Nội → TP.HCM                      │
│  📏 Khoảng cách: ~1,700 km              │
│  ⏱️ Thời gian di chuyển: ~2 giờ         │
│     (máy bay) hoặc ~30 giờ (xe khách)   │
│                                          │
│  ⚠️ Với 2 ngày du lịch, việc di chuyển  │
│     này có thể không hợp lý.            │
│                                          │
│  💡 Gợi ý điểm đến gần hơn:             │
│  ┌─────────────────────────────────┐   │
│  │ 🏛️ Phố cổ Hội An                 │   │
│  │ 📏 Cách ~30 km                   │   │
│  │ [Chọn điểm này]                  │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 🏖️ Bãi biển Mỹ Khê               │   │
│  │ 📏 Cách ~50 km                   │   │
│  │ [Chọn điểm này]                  │   │
│  └─────────────────────────────────┘   │
│                                          │
│  [Hủy]  [Vẫn tiếp tục]                  │
└─────────────────────────────────────────┘
```

### Loading State
- Hiển thị `CircularProgressIndicator` khi đang tính toán khoảng cách
- Disable buttons khi đang xử lý

### Empty State (không có điểm đề xuất)
- Hiển thị: "Không tìm thấy điểm đến gần hơn trong khu vực này"
- Chỉ hiển thị buttons "Hủy" và "Vẫn tiếp tục"

---

## Error Handling

### MapBox API Fail
- Fallback về Haversine formula
- Log error để debug
- Vẫn hiển thị cảnh báo dựa trên khoảng cách đường thẳng

### Network Error
- Hiển thị thông báo lỗi
- Cho phép user tiếp tục hoặc thử lại

### No Suggestions
- Hiển thị empty state
- Vẫn cho phép user tiếp tục hoặc hủy

---

## Performance Optimization

### Caching
- Cache kết quả tính khoảng cách (key: lat1,lng1,lat2,lng2)
- Cache trong memory (Map) với TTL 1 giờ
- Giảm số lượng API calls

### Batch Requests
- Nếu có nhiều điểm, tính toán batch với Distance Matrix API
- Giảm số lượng requests

### Lazy Loading
- Chỉ tính toán khi user click "Thêm"
- Không tính toán khi search/filter

---

## Testing Checklist

### Unit Tests
- [ ] Test Haversine formula với các tọa độ khác nhau
- [ ] Test validation logic với các ngưỡng khác nhau
- [ ] Test suggestion logic với các kịch bản khác nhau

### Integration Tests
- [ ] Test MapBox API integration
- [ ] Test fallback khi API fail
- [ ] Test cache hoạt động đúng

### UI Tests
- [ ] Test dialog hiển thị đúng
- [ ] Test các buttons hoạt động đúng
- [ ] Test loading states
- [ ] Test error states

### Manual Testing
- [ ] Test với trip 1 ngày
- [ ] Test với trip 2 ngày
- [ ] Test với trip 5+ ngày
- [ ] Test với điểm đến trong cùng thành phố
- [ ] Test với điểm đến khác tỉnh
- [ ] Test với MapBox API fail
- [ ] Test với không có điểm đề xuất

---

## Timeline Estimate

| Phase | Thời gian ước tính | Phụ thuộc |
|-------|-------------------|-----------|
| Phase 1: MapBox Service | 2-3 giờ | - |
| Phase 2: Validation Service | 2-3 giờ | Phase 1 |
| Phase 3: Suggestion Service | 3-4 giờ | Phase 1 |
| Phase 4: UI Components | 3-4 giờ | Phase 2, 3 |
| Phase 5: Integration | 2-3 giờ | Phase 4 |
| Phase 6: Testing | 2-3 giờ | Phase 5 |
| **Tổng cộng** | **14-20 giờ** | |

---

## Dependencies

### Packages cần thiết
- `http` (đã có) - Gọi MapBox API
- `math` (built-in) - Haversine formula

### API Keys
- MapBox API Key: `pk.eyJ1IjoidnVvbmdkaDEyYzEiLCJhIjoiY21pOXM2cDV3MHB4NTJpcGo2cTNxNjBxZSJ9.erxF_ABIH1oJYeyAABK-Kg`

---

## Notes

### MapBox API Limits
- Free tier: 100,000 requests/tháng
- Cần implement caching để giảm số lượng requests
- Có thể dùng Haversine cho các tính toán đơn giản

### Future Enhancements
- Tích hợp Google Maps API (nếu cần)
- Gợi ý dựa trên category/tags
- Tự động sắp xếp lại lịch trình hợp lý
- Hiển thị bản đồ với các điểm đến

---

## Files sẽ tạo mới

1. `lib/services/mapbox_service.dart` - MapBox API integration
2. `lib/services/trip_validation_service.dart` - Validation logic
3. `lib/services/destination_suggestion_service.dart` - Suggestion logic
4. `lib/widgets/distance_warning_dialog.dart` - Warning dialog UI
5. `lib/widgets/suggested_destination_card.dart` - Suggested destination card

## Files sẽ chỉnh sửa

1. `lib/config/api_config.dart` - Thêm MapBox API key
2. `lib/screens/add_destinations_to_trip_screen.dart` - Tích hợp validation
3. `lib/models/destination.dart` - (Không cần sửa, đã có location)

---

## Kết luận

Kế hoạch này sẽ giúp ngăn chặn người dùng thêm các điểm đến không hợp lý, đồng thời cung cấp gợi ý hữu ích để cải thiện trải nghiệm người dùng. Việc sử dụng MapBox API sẽ đảm bảo tính chính xác về khoảng cách và thời gian di chuyển.

