import 'package:smart_travel_app/models/ai/ai_activity_suggestion.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';

/// Builder để tạo Destination từ AI suggestion với template đầy đủ
class AIDestinationBuilder {
  // Category mapping từ AI sang cấu trúc chuẩn
  static const Map<String, String> _categoryMapping = {
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

  // Placeholder thumbnails cho từng category
  static const Map<String, String> _thumbnails = {
    'restaurant': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
    'cafe': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb',
    'shopping': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8',
    'Danh lam thắng cảnh':
        'https://images.unsplash.com/photo-1539650116574-75c0c6d73f6e',
    'nature': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4',
    'entertainment':
        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30',
  };

  /// Tạo destination đầy đủ từ suggestion + template từ @data
  static Destination buildFromSuggestion(AIActivitySuggestion suggestion) {
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
        address: suggestion.address ?? 'Địa chỉ chưa xác định',
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
        'Địa điểm được gợi ý bởi AI, nên kiểm tra thông tin trước khi đến',
      ],

      // Nearby Places (empty cho AI destinations)
      nearbyPlaces: [],

      // Cost Information
      estimatedCost: EstimatedCost(
        entranceFee: 0,
        averageMeal:
            suggestion.estimatedCost?.toInt() ??
            _getDefaultMealCost(mappedCategory),
        shoppingBudget: 0,
        totalSuggested:
            suggestion.estimatedCost?.toInt() ??
            _getDefaultMealCost(mappedCategory),
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
  static String _mapAICategoryToStandard(String? aiCategory) {
    return _categoryMapping[aiCategory?.toLowerCase()] ?? 'restaurant';
  }

  static String _generateSlug(String name) {
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

  static List<String> _generateTags(
    AIActivitySuggestion suggestion,
    String category,
  ) {
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
      case 'Danh lam thắng cảnh':
        tags.addAll(['attraction', 'sightseeing', 'culture']);
        break;
    }

    // AI-specific tag
    tags.add('ai-recommended');

    return tags;
  }

  static String _generatePlaceholderThumbnail(String category) {
    return _thumbnails[category] ?? _thumbnails['restaurant']!;
  }

  static OpeningHours _generateDefaultOpeningHours(String category) {
    switch (category) {
      case 'restaurant':
        return OpeningHours(
          days: {
            'monday': DayHours(open: '10:00', close: '22:00'),
            'tuesday': DayHours(open: '10:00', close: '22:00'),
            'wednesday': DayHours(open: '10:00', close: '22:00'),
            'thursday': DayHours(open: '10:00', close: '22:00'),
            'friday': DayHours(open: '10:00', close: '22:00'),
            'saturday': DayHours(open: '10:00', close: '23:00'),
            'sunday': DayHours(open: '10:00', close: '23:00'),
          },
          note: 'Giờ mở cửa có thể thay đổi, nên gọi trước khi đến',
        );
      case 'cafe':
        return OpeningHours(
          days: {
            'monday': DayHours(open: '07:00', close: '22:00'),
            'tuesday': DayHours(open: '07:00', close: '22:00'),
            'wednesday': DayHours(open: '07:00', close: '22:00'),
            'thursday': DayHours(open: '07:00', close: '22:00'),
            'friday': DayHours(open: '07:00', close: '23:00'),
            'saturday': DayHours(open: '07:00', close: '23:00'),
            'sunday': DayHours(open: '07:00', close: '23:00'),
          },
          note: 'Giờ mở cửa có thể thay đổi',
        );
      default:
        return OpeningHours(
          days: {
            'monday': DayHours(open: '08:00', close: '20:00'),
            'tuesday': DayHours(open: '08:00', close: '20:00'),
            'wednesday': DayHours(open: '08:00', close: '20:00'),
            'thursday': DayHours(open: '08:00', close: '20:00'),
            'friday': DayHours(open: '08:00', close: '20:00'),
            'saturday': DayHours(open: '08:00', close: '20:00'),
            'sunday': DayHours(open: '08:00', close: '20:00'),
          },
          note: 'Giờ hoạt động có thể thay đổi',
        );
    }
  }

  static List<int> _getBestMonthsForCategory(String category) {
    // Mặc định cả năm cho food places, seasonal cho attractions
    switch (category) {
      case 'restaurant':
      case 'cafe':
        return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      case 'nature':
        return [3, 4, 9, 10, 11]; // Tránh mùa mưa
      default:
        return [1, 2, 3, 4, 5, 9, 10, 11, 12]; // Tránh mùa nóng
    }
  }

  static List<Specialty> _generateSpecialtiesFromSuggestion(
    AIActivitySuggestion suggestion,
  ) {
    if (suggestion.category == 'restaurant' || suggestion.category == 'cafe') {
      return [
        Specialty(
          name: suggestion.activityName,
          type: suggestion.mealType == 'coffee' ? 'drink' : 'food',
          priceRange: _formatPriceRange(suggestion.estimatedCost),
          description: suggestion.description,
          image: _generatePlaceholderThumbnail(
            suggestion.category ?? 'restaurant',
          ),
          location: suggestion.address ?? 'Địa chỉ chưa xác định',
          rating: 4.0,
        ),
      ];
    }
    return [];
  }

  static List<Activity> _generateActivitiesFromCategory(
    String category,
    AIActivitySuggestion suggestion,
  ) {
    switch (category) {
      case 'restaurant':
        return [
          Activity(
            name: 'Thưởng thức ẩm thực địa phương',
            duration: _formatDuration(suggestion.estimatedDuration),
            bestTime: _getBestTimeForMealType(suggestion.mealType),
            description:
                'Trải nghiệm hương vị đặc trưng và không gian ẩm thực tại ${suggestion.activityName}',
          ),
        ];
      case 'cafe':
        return [
          Activity(
            name: 'Thưởng thức cà phê và thư giãn',
            duration: _formatDuration(suggestion.estimatedDuration),
            bestTime: 'Buổi sáng (7:00-10:00) hoặc chiều (15:00-18:00)',
            description:
                'Tận hưởng không gian yên tĩnh, thưởng thức đồ uống chất lượng',
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

  static String _generateCategorySpecificTip(String category) {
    switch (category) {
      case 'restaurant':
        return 'Nên đặt bàn trước, đặc biệt vào cuối tuần và giờ cao điểm';
      case 'cafe':
        return 'Thời gian tốt nhất là buổi sáng hoặc chiều để tránh đông';
      case 'shopping':
        return 'Có thể thương lượng giá, nhớ mang theo tiền mặt';
      default:
        return 'Kiểm tra giờ mở cửa trước khi đến';
    }
  }

  // Additional helper methods
  static String _extractCityFromAddress(String? address) {
    if (address == null) return '';
    // Logic extract city từ address
    final cities = [
      'Hà Nội',
      'TP.HCM',
      'Đà Nẵng',
      'Hội An',
      'Huế',
      'Nha Trang',
      'Cần Thơ',
      'Vũng Tàu',
    ];
    for (final city in cities) {
      if (address.contains(city)) return city;
    }
    return '';
  }

  static String _extractDistrictFromAddress(String? address) {
    if (address == null) return '';
    // Extract district từ address pattern
    final districtPattern = RegExp(r'(Quận|Huyện|Thành phố|TP\.)\s+([^,]+)');
    final match = districtPattern.firstMatch(address);
    return match?.group(2)?.trim() ?? '';
  }

  static String _formatDuration(int? minutes) {
    if (minutes == null) return '1-2 giờ';
    if (minutes < 60) return '$minutes phút';
    final hours = (minutes / 60).ceil();
    return '$hours giờ';
  }

  static int _convertToHours(int? minutes) {
    return ((minutes ?? 90) / 60).ceil();
  }

  static String _getBestTimeForMealType(String? mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Buổi sáng (6:00-10:00)';
      case 'lunch':
        return 'Buổi trưa (11:00-14:00)';
      case 'dinner':
        return 'Buổi tối (17:00-21:00)';
      case 'coffee':
        return 'Buổi sáng (7:00-10:00) hoặc chiều (15:00-18:00)';
      default:
        return 'Cả ngày';
    }
  }

  static int _getDefaultMealCost(String category) {
    switch (category) {
      case 'restaurant':
        return 100000; // 100k VND
      case 'cafe':
        return 50000; // 50k VND
      default:
        return 0;
    }
  }

  static String _formatPriceRange(double? cost) {
    if (cost == null) return '50k - 100k';
    final costInt = cost.toInt();
    final lower = (costInt * 0.8).toInt();
    final upper = (costInt * 1.2).toInt();
    return '${_formatCurrency(lower)} - ${_formatCurrency(upper)}';
  }

  static String _formatCurrency(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toInt()}k';
    }
    return '${amount}đ';
  }

  static bool _isWeatherDependent(String category) {
    return category == 'nature' || category == 'Danh lam thắng cảnh';
  }

  static List<String> _getSuitableForCategory(String category) {
    switch (category) {
      case 'restaurant':
      case 'cafe':
        return ['all', 'family', 'couple', 'friends'];
      case 'nature':
        return ['adventure', 'family', 'photography'];
      default:
        return ['all'];
    }
  }

  static bool _isKidFriendly(String category) {
    return category == 'restaurant' ||
        category == 'cafe' ||
        category == 'shopping';
  }

  static List<String> _generatePreferenceTags(AIActivitySuggestion suggestion) {
    List<String> tags = ['ai-generated'];

    if (suggestion.mealType != null) {
      tags.add(suggestion.mealType!);
    }

    if (suggestion.category != null) {
      tags.add(suggestion.category!);
    }

    return tags;
  }
}
