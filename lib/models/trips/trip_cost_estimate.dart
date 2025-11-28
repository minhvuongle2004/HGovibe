import 'package:cloud_firestore/cloud_firestore.dart';

/// Model ước tính chi phí từ AI
class TripCostEstimate {
  final double entranceFees; // Vé tham quan
  final double food; // Ăn uống
  final double accommodation; // Nơi ở
  final double transportation; // Di chuyển
  final double shopping; // Mua sắm
  final double miscellaneous; // Chi phí phát sinh
  final double total; // Tổng
  final double perPerson; // Trung bình/người
  final DateTime estimatedAt; // Thời gian tính toán
  final String? aiModel; // Model AI đã dùng
  final String?
  detailedDescription; // Text mô tả chi tiết từ AI (bullet points)

  TripCostEstimate({
    required this.entranceFees,
    required this.food,
    required this.accommodation,
    required this.transportation,
    required this.shopping,
    required this.miscellaneous,
    required this.total,
    required this.perPerson,
    required this.estimatedAt,
    this.aiModel,
    this.detailedDescription,
  });

  /// Convert từ Map (từ AI response hoặc Firestore)
  factory TripCostEstimate.fromMap(Map<String, dynamic> map) {
    return TripCostEstimate(
      entranceFees: (map['entranceFees'] ?? 0).toDouble(),
      food: (map['food'] ?? 0).toDouble(),
      accommodation: (map['accommodation'] ?? 0).toDouble(),
      transportation: (map['transportation'] ?? 0).toDouble(),
      shopping: (map['shopping'] ?? 0).toDouble(),
      miscellaneous: (map['miscellaneous'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      perPerson: (map['perPerson'] ?? 0).toDouble(),
      estimatedAt: map['estimatedAt'] is Timestamp
          ? (map['estimatedAt'] as Timestamp).toDate()
          : map['estimatedAt'] is DateTime
          ? map['estimatedAt'] as DateTime
          : DateTime.now(),
      aiModel: map['aiModel'],
      detailedDescription: map['detailedDescription'],
    );
  }

  /// Convert từ Firestore DocumentSnapshot
  factory TripCostEstimate.fromFirestore(DocumentSnapshot doc) {
    return TripCostEstimate.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'entranceFees': entranceFees,
      'food': food,
      'accommodation': accommodation,
      'transportation': transportation,
      'shopping': shopping,
      'miscellaneous': miscellaneous,
      'total': total,
      'perPerson': perPerson,
      'estimatedAt': Timestamp.fromDate(estimatedAt),
      'aiModel': aiModel,
      'detailedDescription': detailedDescription,
    };
  }

  /// Copy với các thay đổi
  TripCostEstimate copyWith({
    double? entranceFees,
    double? food,
    double? accommodation,
    double? transportation,
    double? shopping,
    double? miscellaneous,
    double? total,
    double? perPerson,
    DateTime? estimatedAt,
    String? aiModel,
    String? detailedDescription,
  }) {
    return TripCostEstimate(
      entranceFees: entranceFees ?? this.entranceFees,
      food: food ?? this.food,
      accommodation: accommodation ?? this.accommodation,
      transportation: transportation ?? this.transportation,
      shopping: shopping ?? this.shopping,
      miscellaneous: miscellaneous ?? this.miscellaneous,
      total: total ?? this.total,
      perPerson: perPerson ?? this.perPerson,
      estimatedAt: estimatedAt ?? this.estimatedAt,
      aiModel: aiModel ?? this.aiModel,
      detailedDescription: detailedDescription ?? this.detailedDescription,
    );
  }
}
