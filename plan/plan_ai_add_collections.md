# Plan: Tạo Destination từ AI Suggestion với Validation & Moderation

## 🎯 **Mục tiêu**
Cho phép AI suggestions tạo destinations mới trong Firestore collection `destinations` với validation nghiêm ngặt và mechanism review.

## 📋 **Các bước triển khai**

### **Step 1: Tạo AI Destination Service**
```dart
class AIDestinationService {
  // Tạo destination từ AI suggestion với validation
  Future<Destination> createDestinationFromSuggestion(AIActivitySuggestion suggestion)
  
  // Validate thông tin AI suggestion trước khi tạo destination
  ValidationResult validateSuggestionData(AIActivitySuggestion suggestion)
  
  // Lưu destination với status pending review
  Future<String> saveAIDestination(Destination destination)
  
  // Kiểm tra destination đã tồn tại chưa (theo tọa độ + tên)
  Future<Destination?> findExistingDestination(AIActivitySuggestion suggestion)
}
```

### **Step 2: Validation Logic nghiêm ngặt**
```dart
class AIDestinationValidator {
  // Kiểm tra tọa độ hợp lệ (trong phạm vi Việt Nam: 8.5-23.5°N, 102-110°E)
  bool validateCoordinates(double lat, double lng)
  
  // Kiểm tra tên địa điểm (2-100 ký tự, không chứa HTML/script)
  bool validateName(String name)
  
  // Kiểm tra mô tả (10-500 ký tự, không spam, không từ cấm)
  bool validateDescription(String description)
  
  // Kiểm tra category hợp lệ (so với whitelist: restaurant, cafe, attraction, etc.)
  bool validateCategory(String category)
  
  // Kiểm tra địa chỉ có format chuẩn (chứa tỉnh/thành phố Việt Nam)
  bool validateAddress(String address)
  
  // Kiểm tra không trùng lặp (trong bán kính 100m)
  Future<bool> checkDuplicateLocation(double lat, double lng)
}
```

### **Step 3: Destination Template Builder**
```dart
class AIDestinationBuilder {
  // Category mapping từ AI sang cấu trúc chuẩn
  static const Map<String, String> _categoryMapping = {
    'restaurant': 'restaurant',
    'cafe': 'cafe',
    'street-food': 'restaurant', 
    'local-food': 'restaurant',
    'food': 'restaurant',
    'attraction': 'Danh lam thắng cảnh',
    'shopping': 'shopping',
    'nature': 'nature',
    'culture': 'Danh lam thắng cảnh',
    'entertainment': 'entertainment',
  };

  // Tạo destination đầy đủ từ suggestion + template từ @data
  Destination buildFromSuggestion(AIActivitySuggestion suggestion) {
    final mappedCategory = _mapAICategoryToStandard(suggestion.category);
    
    return Destination(
      id: suggestion.id,
      name: suggestion.activityName,
      nameLowercase: suggestion.activityName.toLowerCase(),
      slug: _generateSlug(suggestion.activityName),
      category: mappedCategory,
      tags: _generateTags(suggestion, mappedCategory),
      location: Location(
        latitude: suggestion.latitude ?? 0.0,
        longitude: suggestion.longitude ?? 0.0,
        address: suggestion.address ?? '',
        city: _extractCityFromAddress(suggestion.address),
        district: _extractDistrictFromAddress(suggestion.address),
        country: 'Vietnam',
      ),
      description: suggestion.description,
      shortDescription: suggestion.reason,
      
      // Images & Media
      images: [], // AI không cung cấp ảnh
      thumbnail: _generatePlaceholderThumbnail(mappedCategory),
      
      // Ratings & Popularity (conservative cho AI destinations)
      rating: 4.0, // Default rating
      reviewCount: 0,
      popularityScore: 25, // Thấp hơn verified destinations (0-100)
      
      // Opening Hours (default cho food places)
      openingHours: _generateDefaultOpeningHours(mappedCategory),
      
      // Seasonal Information
      bestMonths: _getBestMonthsForCategory(mappedCategory),
      bestSeason: 'dry', // Default
      seasonalEvents: [],
      avoidMonths: [], // Không có tháng tránh mặc định
      
      // Specialties (quan trọng cho food suggestions)
      specialties: _generateSpecialtiesFromSuggestion(suggestion),
      
      // Activities
      activities: _generateActivitiesFromCategory(mappedCategory, suggestion),
      
      // Tips & Advice
      tips: [
        suggestion.reason,
        _generateCategorySpecificTip(mappedCategory),
        'Địa điểm được gợi ý bởi AI, nên kiểm tra thông tin trước khi đến'
      ],
      
      // Nearby Places (empty cho AI destinations)
      nearbyPlaces: [],
      
      // Cost Information
      estimatedCost: EstimatedCost(
        entranceFee: 0,
        averageMeal: suggestion.estimatedCost?.toInt() ?? _getDefaultMealCost(mappedCategory),
        shoppingBudget: 0,
        totalSuggested: suggestion.estimatedCost?.toInt() ?? _getDefaultMealCost(mappedCategory),
        currency: 'VND',
      ),
      entranceFee: 0,
      
      // Parking (default)
      parking: Parking(
        available: true,
        fee: 'Miễn phí - 10k',
        note: 'Thông tin parking có thể thay đổi',
      ),
      
      // Duration
      suggestedDuration: _formatDuration(suggestion.estimatedDuration),
      suggestedDurationHours: _convertToHours(suggestion.estimatedDuration),
      
      // Weather & Suitability
      weatherDependent: _isWeatherDependent(mappedCategory),
      idealWeather: 'Khô ráo, mát mẻ',
      suitableFor: _getSuitableForCategory(mappedCategory),
      
      // Accessibility (default values)
      accessibility: Accessibility(
        wheelchairAccessible: false,
        elderlyFriendly: true,
        kidFriendly: _isKidFriendly(mappedCategory),
        notes: 'Thông tin accessibility chưa được xác minh',
      ),
      
      // Status & Verification
      status: 'ai_generated', // Đánh dấu đặc biệt
      verified: false, // AI destinations chưa được verify
      
      // Analytics
      visitCount: 0,
      trendingScore: 20, // Thấp hơn destinations thật
      userPreferenceTags: _generatePreferenceTags(suggestion),
      
      // Timestamps
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods
  String _mapAICategoryToStandard(String? aiCategory) {
    return _categoryMapping[aiCategory?.toLowerCase()] ?? 'restaurant';
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  List<String> _generateTags(AIActivitySuggestion suggestion, String category) {
    List<String> tags = [category];
    
    if (suggestion.mealType != null) {
      tags.add(suggestion.mealType!);
    }
    
    // Category-specific tags
    switch (category) {
      case 'restaurant':
        tags.addAll(['food', 'local-cuisine', 'dining']);
        break;
      case 'cafe':
        tags.addAll(['coffee', 'drinks', 'relaxation']);
        break;
      case 'shopping':
        tags.addAll(['shopping', 'souvenir']);
        break;
    }
    
    // AI-specific tag
    tags.add('ai-recommended');
    
    return tags;
  }

  String _generatePlaceholderThumbnail(String category) {
    const Map<String, String> thumbnails = {
      'restaurant': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
      'cafe': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb',
      'shopping': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8',
      'attraction': 'https://images.unsplash.com/photo-1539650116574-75c0c6d73f6e',
    };
    return thumbnails[category] ?? thumbnails['restaurant']!;
  }

  OpeningHours _generateDefaultOpeningHours(String category) {
    switch (category) {
      case 'restaurant':
        return OpeningHours(
          monday: DayHours(open: '10:00', close: '22:00'),
          tuesday: DayHours(open: '10:00', close: '22:00'),
          wednesday: DayHours(open: '10:00', close: '22:00'),
          thursday: DayHours(open: '10:00', close: '22:00'),
          friday: DayHours(open: '10:00', close: '22:00'),
          saturday: DayHours(open: '10:00', close: '23:00'),
          sunday: DayHours(open: '10:00', close: '23:00'),
          note: 'Giờ mở cửa có thể thay đổi, nên gọi trước khi đến',
        );
      case 'cafe':
        return OpeningHours(
          monday: DayHours(open: '07:00', close: '22:00'),
          tuesday: DayHours(open: '07:00', close: '22:00'),
          wednesday: DayHours(open: '07:00', close: '22:00'),
          thursday: DayHours(open: '07:00', close: '22:00'),
          friday: DayHours(open: '07:00', close: '23:00'),
          saturday: DayHours(open: '07:00', close: '23:00'),
          sunday: DayHours(open: '07:00', close: '23:00'),
          note: 'Giờ mở cửa có thể thay đổi',
        );
      default:
        return OpeningHours(
          monday: DayHours(open: '08:00', close: '20:00'),
          tuesday: DayHours(open: '08:00', close: '20:00'),
          wednesday: DayHours(open: '08:00', close: '20:00'),
          thursday: DayHours(open: '08:00', close: '20:00'),
          friday: DayHours(open: '08:00', close: '20:00'),
          saturday: DayHours(open: '08:00', close: '20:00'),
          sunday: DayHours(open: '08:00', close: '20:00'),
          note: 'Giờ hoạt động có thể thay đổi',
        );
    }
  }

  List<Specialty> _generateSpecialtiesFromSuggestion(AIActivitySuggestion suggestion) {
    if (suggestion.category == 'restaurant' || suggestion.category == 'cafe') {
      return [
        Specialty(
          name: suggestion.activityName,
          type: suggestion.mealType == 'coffee' ? 'drink' : 'food',
          priceRange: _formatPriceRange(suggestion.estimatedCost),
          description: suggestion.description,
          image: _generatePlaceholderThumbnail(suggestion.category ?? 'restaurant'),
          location: suggestion.address ?? 'Địa chỉ chưa xác định',
          rating: 4.0,
        ),
      ];
    }
    return [];
  }

  List<Activity> _generateActivitiesFromCategory(String category, AIActivitySuggestion suggestion) {
    switch (category) {
      case 'restaurant':
        return [
          Activity(
            name: 'Thưởng thức ẩm thực địa phương',
            duration: _formatDuration(suggestion.estimatedDuration),
            bestTime: _getBestTimeForMealType(suggestion.mealType),
            description: 'Trải nghiệm hương vị đặc trưng và không gian ẩm thực tại ${suggestion.activityName}',
          ),
        ];
      case 'cafe':
        return [
          Activity(
            name: 'Thưởng thức cà phê và thư giãn',
            duration: _formatDuration(suggestion.estimatedDuration),
            bestTime: 'Buổi sáng (7:00-10:00) hoặc chiều (15:00-18:00)',
            description: 'Tận hưởng không gian yên tĩnh, thưởng thức đồ uống chất lượng',
          ),
        ];
      default:
        return [
          Activity(
            name: 'Khám phá và trải nghiệm',
            duration: _formatDuration(suggestion.estimatedDuration),
            bestTime: 'Cả ngày',
            description: suggestion.description,
          ),
        ];
    }
  }

  // Additional helper methods...
  String _extractCityFromAddress(String? address) {
    if (address == null) return '';
    // Logic extract city từ address
    final cities = ['Hà Nội', 'TP.HCM', 'Đà Nẵng', 'Hội An', 'Huế', 'Nha Trang'];
    for (final city in cities) {
      if (address.contains(city)) return city;
    }
    return '';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '1-2 giờ';
    if (minutes < 60) return '$minutes phút';
    final hours = (minutes / 60).ceil();
    return '$hours giờ';
  }

  int _convertToHours(int? minutes) {
    return ((minutes ?? 90) / 60).ceil();
  }

  String _getBestTimeForMealType(String? mealType) {
    switch (mealType) {
      case 'breakfast': return 'Buổi sáng (6:00-10:00)';
      case 'lunch': return 'Buổi trưa (11:00-14:00)';
      case 'dinner': return 'Buổi tối (17:00-21:00)';
      case 'coffee': return 'Buổi sáng (7:00-10:00) hoặc chiều (15:00-18:00)';
      default: return 'Cả ngày';
    }
  }

  int _getDefaultMealCost(String category) {
    switch (category) {
      case 'restaurant': return 100000; // 100k VND
      case 'cafe': return 50000; // 50k VND
      default: return 0;
    }
  }
}
```

### **Step 4: Cập nhật TripProvider Logic**
```dart
// Trong addAISuggestionToTrip()
Future<void> addAISuggestionToTrip(...) async {
  try {
    String destinationId = suggestion.destinationId ?? suggestion.id;
    
    // 1. Kiểm tra destination đã tồn tại chưa
    var existingDestination = await _destinationService.getDestination(destinationId);
    
    if (existingDestination == null) {
      // 2. Validate AI suggestion
      final validation = AIDestinationValidator.validate(suggestion);
      if (!validation.isValid) {
        throw Exception('AI suggestion không hợp lệ: ${validation.errors.join(', ')}');
      }
      
      // 3. Kiểm tra trùng lặp theo tọa độ
      existingDestination = await AIDestinationService.findExistingDestination(suggestion);
      
      if (existingDestination == null) {
        // 4. Tạo destination mới từ AI suggestion
        final newDestination = AIDestinationBuilder.buildFromSuggestion(suggestion);
        destinationId = await AIDestinationService.saveAIDestination(newDestination);
        
        debugPrint('✅ Tạo destination mới từ AI: $destinationId');
      } else {
        destinationId = existingDestination.id!;
        debugPrint('✅ Sử dụng destination tương tự đã có: $destinationId');
      }
    }
    
    // 5. Thêm vào trip như bình thường
    await addDestinationToTripWithDetails(...);
    
  } catch (e) {
    // Handle validation errors
    rethrow;
  }
}
```

### **Step 5: Moderation & Review System**

#### **5.1 Admin Review Interface** (Future enhancement)
```dart
class AIDestinationModerationService {
  // Lấy danh sách destinations cần review
  Future<List<Destination>> getPendingReviewDestinations()
  
  // Approve destination (chuyển status từ ai_generated -> active)
  Future<void> approveDestination(String destinationId)
  
  // Reject destination (xóa hoặc mark as rejected)
  Future<void> rejectDestination(String destinationId, String reason)
  
  // Cập nhật thông tin destination sau review
  Future<void> updateDestinationAfterReview(String destinationId, Map<String, dynamic> updates)
}
```

#### **5.2 Auto-moderation Rules**
```dart
class AutoModerationRules {
  // Tự động approve nếu:
  // - Có đủ thông tin cơ bản
  // - Tọa độ hợp lệ
  // - Không trùng lặp
  // - Category phổ biến (restaurant, cafe)
  
  // Tự động reject nếu:
  // - Thiếu thông tin quan trọng
  // - Tọa độ không hợp lệ
  // - Tên chứa từ cấm
  // - Trùng lặp hoàn toàn
}
```

### **Step 6: Error Handling & Fallback**

```dart
// Xử lý các trường hợp lỗi:
1. Validation failed -> Hiển thị lỗi cụ thể cho user
2. Firestore error -> Retry mechanism
3. Duplicate destination -> Sử dụng destination có sẵn
4. Network error -> Cache suggestion để retry sau
```

### **Step 7: Logging & Analytics**

```dart
class AIDestinationAnalytics {
  // Log các AI destinations được tạo
  void logDestinationCreated(String destinationId, AIActivitySuggestion suggestion)
  
  // Track success rate của AI suggestions
  void trackSuggestionToDestinationConversion()
  
  // Monitor validation failures
  void logValidationFailure(String reason, AIActivitySuggestion suggestion)
}
```

## 🔍 **Validation Rules chi tiết**

### **Coordinates Validation (Dựa trên data thực tế)**
- **Latitude**: 8.5° - 23.5° (Cà Mau đến Lào Cai)
- **Longitude**: 102° - 110° (Điện Biên đến Cà Mau)
- **Precision**: tối thiểu 6 chữ số thập phân (độ chính xác ~1m)
- **Kiểm tra thành phố**: Tọa độ phải nằm gần các thành phố lớn trong @data

### **Name Validation (Theo pattern @data)**
- **Length**: 5-100 ký tự (theo data thực tế: "Chợ Bến Thành", "Khu bảo tồn thiên nhiên Pù Luông")
- **Format**: Cho phép tiếng Việt có dấu, số, dấu &, dấu phẩy
- **Blacklist**: "Unknown", "N/A", "Test", "Restaurant", "Cafe" (quá generic)
- **Pattern**: Phải có ít nhất 1 từ có nghĩa (không phải random)

### **Description Validation (Theo style @data)**
- **Length**: 50-1000 ký tự (theo data: descriptions khá dài và chi tiết)
- **Style**: Phải mô tả cụ thể về địa điểm, không generic
- **Required elements**: Phải mention địa điểm, đặc điểm, trải nghiệm
- **Language**: Tiếng Việt tự nhiên, không Chinglish

### **Category Mapping (Dựa trên data thực tế)**
```dart
Map<String, String> aiCategoryMapping = {
  // Food & Dining
  'restaurant': 'restaurant',
  'cafe': 'cafe', 
  'street-food': 'restaurant',
  'local-food': 'restaurant',
  'food': 'restaurant',
  
  // Attractions (theo cấu trúc @data)
  'attraction': 'Danh lam thắng cảnh',
  'culture': 'Danh lam thắng cảnh',
  'temple': 'Danh lam thắng cảnh',
  'museum': 'Danh lam thắng cảnh',
  
  // Other categories
  'shopping': 'shopping',
  'nature': 'nature',
  'entertainment': 'entertainment',
  'hotel': 'accommodation',
};
```

## 📊 **Success Metrics**

1. **Validation Success Rate**: >90% AI suggestions pass validation (realistic target)
2. **Duplicate Prevention**: <10% duplicate destinations created (trong bán kính 100m)
3. **Data Quality**: AI destinations có đầy đủ required fields theo @data structure
4. **Performance**: Destination creation <3s average time (bao gồm validation)
5. **User Experience**: Destinations hiển thị chính xác trong trip timeline

## ⚠️ **Risk Mitigation**

1. **Data Quality**: Strict validation + manual review
2. **Spam Prevention**: Rate limiting + content filtering  
3. **Storage Cost**: Monitor Firestore usage, cleanup rejected destinations
4. **User Experience**: Clear error messages, fallback options

## 🚀 **Implementation Order (Updated)**

### **Phase 1: Core Builder & Validation** (1 day)
- `AIDestinationBuilder` với full template theo @data structure
- `AIDestinationValidator` với rules cụ thể cho Việt Nam
- Unit tests cho validation logic

### **Phase 2: Service Integration** (1 day)  
- `AIDestinationService` với Firestore integration
- Cập nhật `TripProvider.addAISuggestionToTrip()`
- Error handling & user feedback

### **Phase 3: Testing & Refinement** (0.5 day)
- Test với real AI suggestions
- Fine-tune validation rules
- Performance optimization

### **Phase 4: Monitoring & Analytics** (0.5 day)
- Logging cho AI destination creation
- Analytics tracking
- Error monitoring

### **Phase 5: Future Enhancements**
- Admin review interface
- Batch processing cho multiple suggestions
- Machine learning để improve validation

---

**Total Estimated Time**: 3 days development + testing
**Priority**: High (blocking core user workflow)
**Dependencies**: 
- Existing Destination model structure
- Firestore collections setup
- AI suggestion data format
