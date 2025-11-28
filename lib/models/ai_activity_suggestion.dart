/// Model gợi ý hoạt động từ AI
class AIActivitySuggestion {
  final String id;
  final String tripId;
  final String? destinationId; // Nếu gợi ý cho destination cụ thể
  final String activityName; // Tên hoạt động
  final String description; // Mô tả
  final String reason; // Lý do gợi ý
  final int? estimatedDuration; // Thời gian ước tính (phút)
  final double? estimatedCost; // Chi phí ước tính
  final String? category; // Loại hoạt động
  final double? latitude; // Tọa độ lat (nếu có)
  final double? longitude; // Tọa độ lng (nếu có)
  final String? address; // Địa chỉ cụ thể
  final String? sourcePlaceId; // ID địa điểm từ Mapbox/nguồn dữ liệu
  final String? mealType; // breakfast/lunch/dinner/coffee...
  final DateTime suggestedAt; // Thời gian gợi ý
  final bool isAdded; // Đã thêm vào kế hoạch chưa

  AIActivitySuggestion({
    required this.id,
    required this.tripId,
    this.destinationId,
    required this.activityName,
    required this.description,
    required this.reason,
    this.estimatedDuration,
    this.estimatedCost,
    this.category,
    this.latitude,
    this.longitude,
    this.address,
    this.sourcePlaceId,
    this.mealType,
    required this.suggestedAt,
    this.isAdded = false,
  });

  /// Convert từ Map (từ AI response)
  factory AIActivitySuggestion.fromMap(Map<String, dynamic> map) {
    return AIActivitySuggestion(
      id: map['id'] ?? '',
      tripId: map['tripId'] ?? '',
      destinationId: map['destinationId'],
      activityName: map['activityName'] ?? map['name'] ?? '',
      description: map['description'] ?? '',
      reason: map['reason'] ?? '',
      estimatedDuration: map['estimatedDuration'] ?? map['duration'],
      estimatedCost: map['estimatedCost'] != null
          ? (map['estimatedCost'] as num).toDouble()
          : null,
      category: map['category'],
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      address: map['address'],
      sourcePlaceId: map['sourcePlaceId'] ?? map['placeId'],
      mealType: map['mealType'],
      suggestedAt: map['suggestedAt'] is DateTime
          ? map['suggestedAt'] as DateTime
          : DateTime.parse(map['suggestedAt'] as String? ?? DateTime.now().toIso8601String()),
      isAdded: map['isAdded'] ?? false,
    );
  }

  /// Convert sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'destinationId': destinationId,
      'activityName': activityName,
      'description': description,
      'reason': reason,
      'estimatedDuration': estimatedDuration,
      'estimatedCost': estimatedCost,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'sourcePlaceId': sourcePlaceId,
      'mealType': mealType,
      'suggestedAt': suggestedAt.toIso8601String(),
      'isAdded': isAdded,
    };
  }

  /// Copy với các thay đổi
  AIActivitySuggestion copyWith({
    String? id,
    String? tripId,
    String? destinationId,
    String? activityName,
    String? description,
    String? reason,
    int? estimatedDuration,
    double? estimatedCost,
    String? category,
    double? latitude,
    double? longitude,
    String? address,
    String? sourcePlaceId,
    String? mealType,
    DateTime? suggestedAt,
    bool? isAdded,
  }) {
    return AIActivitySuggestion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      destinationId: destinationId ?? this.destinationId,
      activityName: activityName ?? this.activityName,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      sourcePlaceId: sourcePlaceId ?? this.sourcePlaceId,
      mealType: mealType ?? this.mealType,
      suggestedAt: suggestedAt ?? this.suggestedAt,
      isAdded: isAdded ?? this.isAdded,
    );
  }
}

