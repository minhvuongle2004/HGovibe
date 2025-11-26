import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'trip_item.dart';
import 'trip_cost_estimate.dart';
import 'weather_forecast.dart';
import 'ai_activity_suggestion.dart';

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
  final TripStatus status; // Trạng thái
  final int numberOfTravelers; // Số người tham gia
  final TripBudgetLevel budgetLevel; // Loại du lịch
  final double? budgetLimit; // Budget giới hạn (optional)
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TripItem> items; // Các điểm đến trong trip
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
    required this.status,
    required this.numberOfTravelers,
    required this.budgetLevel,
    this.budgetLimit,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.costEstimate,
    this.weatherForecasts,
    this.aiSuggestions,
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
        debugPrint('✅ Parsed costEstimate from Firestore for trip ${doc.id} (total: ${costEstimate.total} VND)');
      } catch (e, stack) {
        debugPrint('⚠️ Error parsing costEstimate for trip ${doc.id}: $e');
        debugPrint('$stack');
      }
    } else {
      debugPrint('ℹ️ No costEstimate field in Firestore document for trip ${doc.id}');
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
      status: TripStatusExtension.fromString(data['status'] ?? 'planning'),
      numberOfTravelers: data['numberOfTravelers'] ?? 1,
      budgetLevel: TripBudgetLevelExtension.fromString(data['budgetLevel'] ?? 'moderate'),
      budgetLimit: data['budgetLimit'] != null
          ? (data['budgetLimit'] as num).toDouble()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      // items, weatherForecasts, aiSuggestions sẽ được load riêng
      items: const [],
      costEstimate: costEstimate, // Load từ Firestore
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
      'status': status.toValue(),
      'numberOfTravelers': numberOfTravelers,
      'budgetLevel': budgetLevel.toValue(),
      'budgetLimit': budgetLimit,
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
    TripStatus? status,
    int? numberOfTravelers,
    TripBudgetLevel? budgetLevel,
    double? budgetLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TripItem>? items,
    TripCostEstimate? costEstimate,
    List<WeatherForecast>? weatherForecasts,
    List<AIActivitySuggestion>? aiSuggestions,
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
      status: status ?? this.status,
      numberOfTravelers: numberOfTravelers ?? this.numberOfTravelers,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      costEstimate: costEstimate ?? this.costEstimate,
      weatherForecasts: weatherForecasts ?? this.weatherForecasts,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
    );
  }

  /// Tính số ngày trong trip
  int get daysCount {
    return endDate.difference(startDate).inDays + 1;
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
  planning, // Đang lên kế hoạch
  upcoming, // Sắp tới
  ongoing, // Đang diễn ra
  completed, // Đã hoàn thành
  cancelled, // Đã hủy
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
      case TripStatus.planning:
        return 'planning';
      case TripStatus.upcoming:
        return 'upcoming';
      case TripStatus.ongoing:
        return 'ongoing';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case TripStatus.planning:
        return 'Đang lên kế hoạch';
      case TripStatus.upcoming:
        return 'Sắp tới';
      case TripStatus.ongoing:
        return 'Đang diễn ra';
      case TripStatus.completed:
        return 'Đã hoàn thành';
      case TripStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static TripStatus fromString(String value) {
    switch (value) {
      case 'planning':
        return TripStatus.planning;
      case 'upcoming':
        return TripStatus.upcoming;
      case 'ongoing':
        return TripStatus.ongoing;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.planning;
    }
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

