# Kế hoạch triển khai chức năng: Lập kế hoạch chuyến đi cá nhân

## Mục tiêu
Cho phép người dùng tạo, quản lý và theo dõi các kế hoạch chuyến đi cá nhân với nhiều điểm đến, thời gian, và các tính năng thông minh (AI).

## Tính năng chính

### 1. Quản lý kế hoạch chuyến đi cơ bản
- Tạo kế hoạch mới với tên, ngày, mô tả
- Thêm/xóa/sắp xếp điểm đến
- Chỉnh sửa và xóa kế hoạch
- Xem danh sách tất cả kế hoạch
- Filter và sort kế hoạch

### 2. Tính năng thông minh (AI & Smart Features)

#### 2.1. AI Tính toán chi phí du lịch
- **Input**: 
  - Danh sách điểm đến
  - Số ngày du lịch
  - Số người tham gia
  - Loại du lịch (tiết kiệm/trung bình/sang trọng)
- **Output**:
  - Chi phí ước tính cho từng hạng mục:
    - Vé tham quan
    - Ăn uống
    - Nơi ở
    - Di chuyển
    - Mua sắm
    - Chi phí phát sinh
  - Tổng chi phí
  - Chi phí trung bình/người
  - So sánh với budget (nếu user nhập)
- **Implementation**:
  - Sử dụng OpenAI API hoặc Gemini API
  - Prompt engineering để tính toán dựa trên:
    - Data từ destinations (entranceFee, estimatedCost)
    - Số ngày, số người
    - Loại du lịch
  - Cache kết quả để tránh gọi API nhiều lần
  - Fallback: Tính toán thủ công nếu API fail

#### 2.2. Dự báo thời tiết
- **Input**: 
  - Ngày trong kế hoạch
  - Vị trí (city) của điểm đến
- **Output**:
  - Nhiệt độ (min/max)
  - Điều kiện thời tiết (nắng/mưa/âm u)
  - Độ ẩm
  - Tốc độ gió
  - Khuyến nghị (nên/không nên đi)
- **Implementation**:
  - Sử dụng OpenWeatherMap API (free tier: 1000 calls/day)
  - Hoặc WeatherAPI.com
  - Cache theo ngày và location
  - Hiển thị icon và màu sắc trực quan
  - Cảnh báo nếu thời tiết xấu

#### 2.3. AI Gợi ý hoạt động
- **Input**:
  - Điểm đến đã chọn
  - Thời gian có sẵn
  - Sở thích người dùng (từ lịch sử favorites)
  - Thời tiết dự báo
- **Output**:
  - Danh sách hoạt động gợi ý phù hợp
  - Lý do gợi ý
  - Thời gian ước tính cho mỗi hoạt động
  - Chi phí (nếu có)
- **Implementation**:
  - Sử dụng OpenAI/Gemini API
  - Prompt bao gồm:
    - Thông tin destination (activities, specialties, bestMonths)
    - Thời tiết
    - Sở thích user
  - Gợi ý có thể từ:
    - Activities có sẵn trong destination data
    - Hoạt động mới do AI đề xuất
  - Cho phép user thêm vào kế hoạch

---

## Cấu trúc Data Model

### Trip Model
```dart
class Trip {
  String? id; // Document ID từ Firestore
  String userId; // UID của user
  String name; // Tên kế hoạch
  String? description; // Mô tả
  DateTime startDate; // Ngày bắt đầu
  DateTime endDate; // Ngày kết thúc
  String? location; // Thành phố/khu vực chính
  TripStatus status; // Trạng thái
  int numberOfTravelers; // Số người tham gia
  TripBudgetLevel budgetLevel; // Loại du lịch (tiết kiệm/trung bình/sang trọng)
  double? budgetLimit; // Budget giới hạn (optional)
  DateTime createdAt;
  DateTime updatedAt;
  List<TripItem> items; // Các điểm đến trong trip
  TripCostEstimate? costEstimate; // Ước tính chi phí từ AI
  List<WeatherForecast>? weatherForecasts; // Dự báo thời tiết
  List<AIActivitySuggestion>? aiSuggestions; // Gợi ý từ AI
}
```

### TripItem Model
```dart
class TripItem {
  String? id; // Document ID
  String tripId; // ID của trip
  String destinationId; // ID của destination
  Destination? destination; // Cache data (optional)
  int order; // Thứ tự trong trip (0, 1, 2...)
  DateTime? plannedDate; // Ngày dự kiến
  TimeOfDay? plannedTime; // Giờ dự kiến (optional)
  int? durationHours; // Thời gian dự kiến tại điểm này
  String? notes; // Ghi chú riêng
  bool isCompleted; // Đã hoàn thành chưa
  DateTime? completedAt; // Thời gian hoàn thành
}
```

### TripStatus Enum
```dart
enum TripStatus {
  planning,    // Đang lên kế hoạch
  upcoming,    // Sắp tới
  ongoing,     // Đang diễn ra
  completed,   // Đã hoàn thành
  cancelled    // Đã hủy
}
```

### TripBudgetLevel Enum
```dart
enum TripBudgetLevel {
  budget,      // Tiết kiệm
  moderate,    // Trung bình
  luxury       // Sang trọng
}
```

### TripCostEstimate Model
```dart
class TripCostEstimate {
  double entranceFees; // Vé tham quan
  double food; // Ăn uống
  double accommodation; // Nơi ở
  double transportation; // Di chuyển
  double shopping; // Mua sắm
  double miscellaneous; // Chi phí phát sinh
  double total; // Tổng
  double perPerson; // Trung bình/người
  DateTime estimatedAt; // Thời gian tính toán
  String? aiModel; // Model AI đã dùng
}
```

### WeatherForecast Model
```dart
class WeatherForecast {
  DateTime date; // Ngày dự báo
  String location; // Vị trí
  double temperatureMin; // Nhiệt độ thấp nhất
  double temperatureMax; // Nhiệt độ cao nhất
  String condition; // Điều kiện (sunny, rainy, cloudy...)
  String description; // Mô tả
  int humidity; // Độ ẩm (%)
  double windSpeed; // Tốc độ gió (km/h)
  String? recommendation; // Khuyến nghị
  String iconCode; // Icon code từ API
}
```

### AIActivitySuggestion Model
```dart
class AIActivitySuggestion {
  String id;
  String tripId;
  String? destinationId; // Nếu gợi ý cho destination cụ thể
  String activityName; // Tên hoạt động
  String description; // Mô tả
  String reason; // Lý do gợi ý
  int? estimatedDuration; // Thời gian ước tính (phút)
  double? estimatedCost; // Chi phí ước tính
  String? category; // Loại hoạt động
  DateTime suggestedAt; // Thời gian gợi ý
  bool isAdded; // Đã thêm vào kế hoạch chưa
}
```

---

## Services

### 1. TripService
**File**: `lib/services/trip_service.dart`

**Methods**:
- `createTrip(Trip trip)`: Tạo trip mới
- `updateTrip(String tripId, Map<String, dynamic> updates)`: Cập nhật trip
- `deleteTrip(String tripId)`: Xóa trip
- `getTrip(String tripId)`: Lấy trip theo ID
- `getTrips(String userId)`: Lấy tất cả trips của user
- `watchTrips(String userId)`: Stream trips real-time
- `addTripItem(String tripId, TripItem item)`: Thêm điểm đến
- `updateTripItem(String tripId, String itemId, Map updates)`: Cập nhật item
- `removeTripItem(String tripId, String itemId)`: Xóa item
- `reorderTripItems(String tripId, List<String> itemIds)`: Sắp xếp lại thứ tự

**Firestore Structure**:
```
users/{userId}/trips/{tripId}
  - name: string
  - description: string
  - startDate: timestamp
  - endDate: timestamp
  - location: string
  - status: string
  - numberOfTravelers: number
  - budgetLevel: string
  - budgetLimit: number
  - createdAt: timestamp
  - updatedAt: timestamp

users/{userId}/trips/{tripId}/items/{itemId}
  - destinationId: string
  - order: number
  - plannedDate: timestamp
  - plannedTime: string (HH:mm)
  - durationHours: number
  - notes: string
  - isCompleted: boolean
  - completedAt: timestamp
```

### 2. AICostEstimationService
**File**: `lib/services/ai_cost_estimation_service.dart`

**Dependencies**:
- OpenAI API hoặc Google Gemini API
- Package: `http` hoặc `dio`

**Methods**:
- `estimateTripCost(Trip trip)`: Tính toán chi phí bằng AI
- `_buildPrompt(Trip trip)`: Tạo prompt cho AI
- `_parseAIResponse(String response)`: Parse response từ AI
- `_fallbackEstimate(Trip trip)`: Tính toán thủ công nếu AI fail

**Prompt Template**:
```
Bạn là chuyên gia du lịch. Hãy ước tính chi phí cho chuyến đi:
- Số ngày: {days}
- Số người: {travelers}
- Loại du lịch: {budgetLevel}
- Điểm đến: {destinations}
- Thông tin chi phí từ data: {costData}

Hãy tính toán và trả về JSON với format:
{
  "entranceFees": number,
  "food": number,
  "accommodation": number,
  "transportation": number,
  "shopping": number,
  "miscellaneous": number,
  "total": number,
  "perPerson": number,
  "breakdown": {
    "day1": {...},
    "day2": {...}
  }
}
```

**Error Handling**:
- Retry logic (3 lần)
- Fallback to manual calculation
- Cache results để tránh gọi API nhiều lần

### 3. WeatherService
**File**: `lib/services/weather_service.dart`

**Dependencies**:
- OpenWeatherMap API hoặc WeatherAPI.com
- Package: `http` hoặc `dio`

**Methods**:
- `getWeatherForecast(String city, DateTime date)`: Lấy dự báo thời tiết
- `getWeatherForecastsForTrip(Trip trip)`: Lấy dự báo cho cả trip
- `_cacheKey(String city, DateTime date)`: Tạo cache key

**API Integration**:
- OpenWeatherMap: Free tier 1000 calls/day
- WeatherAPI.com: Free tier 1M calls/month
- Cache 24h để tránh gọi API nhiều lần

**Response Parsing**:
```dart
class WeatherResponse {
  final double tempMin;
  final double tempMax;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;
  final String iconCode;
}
```

### 4. AIActivitySuggestionService
**File**: `lib/services/ai_activity_suggestion_service.dart`

**Dependencies**:
- OpenAI API hoặc Google Gemini API

**Methods**:
- `suggestActivities(Trip trip, String? destinationId)`: Gợi ý hoạt động
- `_buildPrompt(Trip trip, Destination? destination, WeatherForecast? weather)`: Tạo prompt
- `_parseSuggestions(String response)`: Parse response

**Prompt Template**:
```
Bạn là chuyên gia du lịch. Dựa trên thông tin sau, hãy gợi ý các hoạt động phù hợp:
- Điểm đến: {destinationName}
- Thời gian có sẵn: {availableTime}
- Thời tiết: {weather}
- Sở thích: {userPreferences}
- Hoạt động có sẵn: {existingActivities}

Hãy gợi ý 3-5 hoạt động và trả về JSON:
[
  {
    "name": string,
    "description": string,
    "reason": string,
    "estimatedDuration": number (phút),
    "estimatedCost": number,
    "category": string
  }
]
```

---

## Providers

### TripProvider
**File**: `lib/providers/trip_provider.dart`

**State**:
- `List<Trip> trips`: Danh sách trips
- `Trip? currentTrip`: Trip đang xem/chỉnh sửa
- `bool isLoading`: Loading state
- `String? error`: Error message
- `TripCostEstimate? costEstimate`: Ước tính chi phí
- `List<WeatherForecast>? weatherForecasts`: Dự báo thời tiết
- `List<AIActivitySuggestion>? aiSuggestions`: Gợi ý từ AI

**Methods**:
- `loadTrips(String userId)`: Load danh sách trips
- `createTrip(Trip trip)`: Tạo trip mới
- `updateTrip(String tripId, Map updates)`: Cập nhật trip
- `deleteTrip(String tripId)`: Xóa trip
- `setCurrentTrip(Trip trip)`: Set trip hiện tại
- `addDestinationToTrip(String tripId, String destinationId)`: Thêm destination
- `removeDestinationFromTrip(String tripId, String itemId)`: Xóa destination
- `reorderTripItems(String tripId, List<String> itemIds)`: Sắp xếp lại
- `estimateCost(String tripId)`: Tính toán chi phí bằng AI
- `loadWeatherForecasts(String tripId)`: Load dự báo thời tiết
- `loadAISuggestions(String tripId, String? destinationId)`: Load gợi ý AI
- `addAISuggestionToTrip(String tripId, String suggestionId)`: Thêm gợi ý vào trip

---

## UI Screens

### 1. TripsScreen (Danh sách kế hoạch)
**File**: `lib/screens/trips_screen.dart`

**Features**:
- Empty state với nút "Tạo kế hoạch mới"
- List/Grid view các trips
- Filter chips: "Tất cả", "Sắp tới", "Đang diễn ra", "Đã hoàn thành"
- Sort: Theo ngày, tên
- Pull-to-refresh
- Nút "+" để tạo trip mới

**Trip Card**:
- Ảnh cover (từ destination đầu tiên)
- Tên trip
- Ngày (startDate - endDate)
- Số điểm đến
- Trạng thái badge
- Chi phí ước tính (nếu có)

### 2. CreateTripScreen (Tạo kế hoạch)
**File**: `lib/screens/create_trip_screen.dart`

**Form Fields**:
- Tên kế hoạch (required)
- Mô tả (optional)
- Ngày bắt đầu (DatePicker)
- Ngày kết thúc (DatePicker)
- Số người tham gia (Stepper)
- Loại du lịch (Radio buttons: Tiết kiệm/Trung bình/Sang trọng)
- Budget giới hạn (optional, TextField với format số)

**Flow**:
1. Nhập thông tin cơ bản
2. Nút "Tiếp theo" → Chuyển sang AddDestinationsToTripScreen
3. Sau khi thêm destinations → Tự động tính chi phí và load thời tiết

### 3. TripDetailScreen (Chi tiết kế hoạch)
**File**: `lib/screens/trip_detail_screen.dart`

**Tabs**:
- **Lịch trình**: Timeline view với các điểm theo ngày/giờ
- **Bản đồ**: Map view (nếu có) - Optional
- **Chi phí**: Breakdown chi phí, so sánh với budget
- **Thời tiết**: Dự báo cho từng ngày
- **Gợi ý AI**: Danh sách hoạt động gợi ý

**Timeline View**:
- Group theo ngày
- Mỗi item hiển thị: Destination name, time, duration, notes
- Drag & drop để sắp xếp
- Tap để edit
- Swipe to delete

**Actions**:
- Nút "Thêm điểm đến"
- Nút "Tính lại chi phí" (AI)
- Nút "Làm mới thời tiết"
- Nút "Xem gợi ý AI"
- Nút "Chỉnh sửa"
- Nút "Xóa"

### 4. AddDestinationsToTripScreen
**File**: `lib/screens/add_destinations_to_trip_screen.dart`

**Features**:
- Search destinations
- Filter theo thành phố, category
- List destinations với checkbox
- Có thể chọn nhiều cùng lúc
- Nút "Thêm vào kế hoạch"
- Hiển thị số lượng đã chọn

### 5. EditTripItemScreen
**File**: `lib/screens/edit_trip_item_screen.dart`

**Form Fields**:
- Chọn ngày (DatePicker)
- Chọn giờ (TimePicker, optional)
- Thời gian dự kiến (Stepper, giờ)
- Ghi chú (TextField, multi-line)

**Actions**:
- Nút "Lưu"
- Nút "Xóa khỏi kế hoạch"

### 6. AISuggestionsScreen
**File**: `lib/screens/ai_suggestions_screen.dart`

**Features**:
- Loading state khi đang gọi AI
- List các gợi ý với:
  - Tên hoạt động
  - Mô tả
  - Lý do gợi ý
  - Thời gian ước tính
  - Chi phí ước tính
- Nút "Thêm vào kế hoạch" cho mỗi gợi ý
- Pull-to-refresh để load lại gợi ý

---

## Widgets

### 1. TripCard
**File**: `lib/widgets/trip_card.dart`
- Card hiển thị trip trong list
- Ảnh, tên, ngày, trạng thái, chi phí

### 2. TripTimelineItem
**File**: `lib/widgets/trip_timeline_item.dart`
- Item trong timeline view
- Drag handle, time, destination info

### 3. WeatherForecastCard
**File**: `lib/widgets/weather_forecast_card.dart`
- Card hiển thị dự báo thời tiết
- Icon, nhiệt độ, điều kiện, khuyến nghị

### 4. CostBreakdownWidget
**File**: `lib/widgets/cost_breakdown_widget.dart`
- Hiển thị breakdown chi phí
- Progress bar so với budget
- Chart (optional)

### 5. AIActivitySuggestionCard
**File**: `lib/widgets/ai_activity_suggestion_card.dart`
- Card hiển thị gợi ý từ AI
- Nút "Thêm vào kế hoạch"

---

## Dependencies cần thêm

```yaml
dependencies:
  # HTTP client
  dio: ^5.4.0  # Hoặc http: ^1.1.0
  
  # AI APIs (chọn một)
  # Option 1: OpenAI
  openai_dart: ^0.3.0
  
  # Option 2: Google Gemini
  google_generative_ai: ^0.2.0
  
  # Weather API
  # Sử dụng dio/http trực tiếp với OpenWeatherMap API
  
  # Date/Time
  intl: ^0.19.0  # Đã có sẵn trong Flutter
  
  # Optional: Charts
  fl_chart: ^0.65.0  # Để vẽ biểu đồ chi phí
```

---

## API Keys & Configuration

### Environment Variables
Tạo file `.env` (không commit vào git):
```
OPENAI_API_KEY=your_key_here
# Hoặc
GEMINI_API_KEY=your_key_here

WEATHER_API_KEY=your_openweathermap_key
```

### Config Service
**File**: `lib/config/api_config.dart`
```dart
class ApiConfig {
  static const String openAiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String weatherApiKey = String.fromEnvironment('WEATHER_API_KEY');
}
```

---

## Security & Best Practices

### 1. API Key Security
- Không hardcode API keys trong code
- Sử dụng environment variables
- Có thể dùng Firebase Functions để proxy API calls (nếu cần)

### 2. Rate Limiting
- Cache AI responses để tránh gọi API nhiều lần
- Implement retry logic với exponential backoff
- Show loading states rõ ràng

### 3. Error Handling
- Graceful degradation: Fallback to manual calculation nếu AI fail
- User-friendly error messages
- Log errors để debug

### 4. Cost Management
- Cache AI responses (cùng input → cùng output)
- Debounce user actions
- Limit số lần gọi API trong một session

---

## Thứ tự triển khai

### Phase 1: Foundation (Core Features)
1. Tạo Models (Trip, TripItem, TripStatus, etc.)
2. Tạo TripService
3. Tạo TripProvider
4. TripsScreen: Danh sách kế hoạch
5. CreateTripScreen: Tạo kế hoạch
6. TripDetailScreen: Xem chi tiết (chưa có AI)

### Phase 2: Trip Items Management
7. AddDestinationsToTripScreen
8. EditTripItemScreen
9. Drag & drop reorder
10. Timeline view

### Phase 3: Weather Integration
11. WeatherService
12. WeatherForecastCard widget
13. Tích hợp vào TripDetailScreen

### Phase 4: AI Cost Estimation
14. AICostEstimationService
15. CostBreakdownWidget
16. Tích hợp vào TripDetailScreen
17. Fallback manual calculation

### Phase 5: AI Activity Suggestions
18. AIActivitySuggestionService
19. AISuggestionsScreen
20. AIActivitySuggestionCard widget
21. Tích hợp vào TripDetailScreen

### Phase 6: Polish & Optimization
22. Caching strategies
23. Error handling improvements
24. UI/UX enhancements
25. Performance optimization
26. Testing

---

## Testing Checklist

### Unit Tests
- [ ] TripService: CRUD operations
- [ ] AICostEstimationService: Prompt building, response parsing
- [ ] WeatherService: API calls, caching
- [ ] AIActivitySuggestionService: Prompt building, response parsing

### Widget Tests
- [ ] TripCard
- [ ] TripTimelineItem
- [ ] WeatherForecastCard
- [ ] CostBreakdownWidget

### Integration Tests
- [ ] Create trip flow
- [ ] Add destinations flow
- [ ] AI cost estimation flow
- [ ] Weather forecast loading
- [ ] AI suggestions loading

### Manual Testing
- [ ] Test với nhiều trips
- [ ] Test AI với các loại du lịch khác nhau
- [ ] Test weather với các thành phố khác nhau
- [ ] Test error handling (API fail, network error)
- [ ] Test caching
- [ ] Test performance với nhiều items

---

## Estimated Time

- Phase 1 (Foundation): 4-5 hours
- Phase 2 (Items Management): 3-4 hours
- Phase 3 (Weather): 2-3 hours
- Phase 4 (AI Cost): 4-5 hours
- Phase 5 (AI Suggestions): 4-5 hours
- Phase 6 (Polish): 2-3 hours
- **Total**: ~19-25 hours

---

## Success Criteria

✅ Người dùng có thể tạo và quản lý kế hoạch chuyến đi
✅ AI tính toán chi phí chính xác và hữu ích
✅ Dự báo thời tiết hiển thị đúng và kịp thời
✅ AI gợi ý hoạt động phù hợp và có giá trị
✅ UI/UX mượt mà, dễ sử dụng
✅ Performance tốt, không lag
✅ Error handling tốt, graceful degradation
✅ Caching hiệu quả, giảm chi phí API

---

## Notes

- **API Costs**: Cần monitor chi phí API, đặc biệt là AI APIs
- **Rate Limits**: Chú ý rate limits của các API services
- **Offline Support**: Có thể cache data để xem offline (không cần AI)
- **Privacy**: Đảm bảo user data được bảo mật
- **Accessibility**: Thêm semantic labels, screen reader support
- **Internationalization**: Có thể mở rộng đa ngôn ngữ sau

---

## Future Enhancements (Optional)

1. **Route Optimization**: Tự động sắp xếp thứ tự điểm đến tối ưu
2. **Collaboration**: Chia sẻ kế hoạch với người khác
3. **Export**: Xuất PDF, chia sẻ link
4. **Photo Gallery**: Thêm ảnh cho từng điểm trong trip
5. **Real-time Updates**: Sync real-time khi có nhiều người cùng chỉnh sửa
6. **Smart Notifications**: Nhắc nhở trước chuyến đi
7. **Expense Tracking**: Theo dõi chi phí thực tế vs dự kiến

