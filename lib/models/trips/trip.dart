import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_travel_app/models/ai/ai_activity_suggestion.dart';
import 'package:smart_travel_app/models/trips/trip_cost_estimate.dart';
import 'package:smart_travel_app/models/trips/trip_item.dart';
import 'package:smart_travel_app/models/weather/weather_forecast.dart';

/// Model đại diện cho một kế hoạch chuyến đi
class Trip {
  final String? id; // Document ID từ Firestore
  final String userId; // UID của user
  final String name; // Tên kế hoạch
  final String? description; // Mô tả
  final DateTime startDate; // Ngày bắt đầu
  final DateTime endDate; // Ngày kết thúc
  final String? location; // Thành phố/khu vực chính
  final String? startingLocation; // Điểm xuất phát (thành phố/địa chỉ)
  final int numberOfTravelers; // Số người tham gia
  final TripBudgetLevel budgetLevel; // Loại du lịch
  final double? budgetLimit; // Budget giới hạn (optional)
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TripItem> items; // Các điểm đến trong trip
  final int destinationsCount; // Tổng số điểm đến (preview nhanh)
  final TripCostEstimate? costEstimate; // Ước tính chi phí từ AI
  final List<WeatherForecast>? weatherForecasts; // Dự báo thời tiết
  final List<AIActivitySuggestion>? aiSuggestions; // Gợi ý từ AI

  Trip({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.location,
    this.startingLocation,
    required this.numberOfTravelers,
    required this.budgetLevel,
    this.budgetLimit,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.costEstimate,
    this.weatherForecasts,
    this.aiSuggestions,
    this.destinationsCount = 0,
  });

  /// Convert từ Firestore DocumentSnapshot
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Load costEstimate nếu có
    TripCostEstimate? costEstimate;
    if (data['costEstimate'] != null) {
      try {
        final costEstimateMap = data['costEstimate'] as Map<String, dynamic>;
        costEstimate = TripCostEstimate.fromMap(costEstimateMap);
        debugPrint(
          '✅ Parsed costEstimate from Firestore for trip ${doc.id} (total: ${costEstimate.total} VND)',
        );
      } catch (e, stack) {
        debugPrint('⚠️ Error parsing costEstimate for trip ${doc.id}: $e');
        debugPrint('$stack');
      }
    } else {
      debugPrint(
        'ℹ️ No costEstimate field in Firestore document for trip ${doc.id}',
      );
    }

    return Trip(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      location: data['location'],
      startingLocation: data['startingLocation'],
      numberOfTravelers: data['numberOfTravelers'] ?? 1,
      budgetLevel: TripBudgetLevelExtension.fromString(
        data['budgetLevel'] ?? 'moderate',
      ),
      budgetLimit: data['budgetLimit'] != null
          ? (data['budgetLimit'] as num).toDouble()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      // items, weatherForecasts, aiSuggestions sẽ được load riêng
      items: const [],
      costEstimate: costEstimate, // Load từ Firestore
      destinationsCount: data['destinationsCount'] != null
          ? (data['destinationsCount'] as num).toInt()
          : 0,
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'startingLocation': startingLocation,
      'numberOfTravelers': numberOfTravelers,
      'budgetLevel': budgetLevel.toValue(),
      'budgetLimit': budgetLimit,
      'destinationsCount': destinationsCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Copy với các thay đổi
  Trip copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? startingLocation,
    int? numberOfTravelers,
    TripBudgetLevel? budgetLevel,
    double? budgetLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TripItem>? items,
    TripCostEstimate? costEstimate,
    List<WeatherForecast>? weatherForecasts,
    List<AIActivitySuggestion>? aiSuggestions,
    int? destinationsCount,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      startingLocation: startingLocation ?? this.startingLocation,
      numberOfTravelers: numberOfTravelers ?? this.numberOfTravelers,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      costEstimate: costEstimate ?? this.costEstimate,
      weatherForecasts: weatherForecasts ?? this.weatherForecasts,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      destinationsCount: destinationsCount ?? this.destinationsCount,
    );
  }

  /// Tính số ngày trong trip
  int get daysCount {
    return endDate.difference(startDate).inDays + 1;
  }

  TripStatus get status => TripStatusExtension.fromDates(startDate, endDate);

  int get previewDestinationsCount {
    if (destinationsCount > 0) {
      return destinationsCount;
    }
    return items.length;
  }

  /// Kiểm tra trip có đang diễn ra không
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Kiểm tra trip đã qua chưa
  bool get isPast {
    return DateTime.now().isAfter(endDate);
  }

  /// Kiểm tra trip sắp tới chưa
  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }
}

/// Enum trạng thái của trip
enum TripStatus {
  upcoming, // Sắp tới
  ongoing, // Đang diễn ra
  completed, // Đã hoàn thành
}

/// Enum loại du lịch (budget level)
enum TripBudgetLevel {
  budget, // Tiết kiệm
  moderate, // Trung bình
  luxury, // Sang trọng
}

/// Extension cho TripStatus
extension TripStatusExtension on TripStatus {
  String toValue() {
    switch (this) {
      case TripStatus.upcoming:
        return 'upcoming';
      case TripStatus.ongoing:
        return 'ongoing';
      case TripStatus.completed:
        return 'completed';
    }
  }

  String get displayName {
    switch (this) {
      case TripStatus.upcoming:
        return 'Sắp tới';
      case TripStatus.ongoing:
        return 'Đang diễn ra';
      case TripStatus.completed:
        return 'Đã hoàn thành';
    }
  }

  static TripStatus fromString(String value) {
    switch (value) {
      case 'upcoming':
        return TripStatus.upcoming;
      case 'ongoing':
        return TripStatus.ongoing;
      case 'completed':
        return TripStatus.completed;
      default:
        return TripStatus.upcoming;
    }
  }

  static TripStatus fromDates(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    if (now.isBefore(startDate)) {
      return TripStatus.upcoming;
    }
    if (now.isAfter(endDate)) {
      return TripStatus.completed;
    }
    return TripStatus.ongoing;
  }
}

/// Extension cho TripBudgetLevel
extension TripBudgetLevelExtension on TripBudgetLevel {
  String toValue() {
    switch (this) {
      case TripBudgetLevel.budget:
        return 'budget';
      case TripBudgetLevel.moderate:
        return 'moderate';
      case TripBudgetLevel.luxury:
        return 'luxury';
    }
  }

  String get displayName {
    switch (this) {
      case TripBudgetLevel.budget:
        return 'Tiết kiệm';
      case TripBudgetLevel.moderate:
        return 'Trung bình';
      case TripBudgetLevel.luxury:
        return 'Sang trọng';
    }
  }

  static TripBudgetLevel fromString(String value) {
    switch (value) {
      case 'budget':
        return TripBudgetLevel.budget;
      case 'moderate':
        return TripBudgetLevel.moderate;
      case 'luxury':
        return TripBudgetLevel.luxury;
      default:
        return TripBudgetLevel.moderate;
    }
  }
}
