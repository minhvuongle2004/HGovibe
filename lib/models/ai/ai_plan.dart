import 'package:cloud_firestore/cloud_firestore.dart';

/// Model lưu kế hoạch chi tiết từ AI
class AIPlan {
  final String? id; // Document ID từ Firestore
  final String tripId; // ID của trip
  final String userId; // UID của user
  final String description; // Nội dung kế hoạch markdown từ AI
  final String aiModel; // Model AI đã dùng
  final double multiplier; // Hệ số điều chỉnh nhu cầu (1.0 = bình thường)
  final DateTime createdAt; // Thời gian tạo
  final DateTime updatedAt; // Thời gian cập nhật

  AIPlan({
    this.id,
    required this.tripId,
    required this.userId,
    required this.description,
    required this.aiModel,
    required this.multiplier,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert từ Firestore DocumentSnapshot
  factory AIPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIPlan(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      description: data['description'] ?? '',
      aiModel: data['aiModel'] ?? 'unknown',
      multiplier: (data['multiplier'] ?? 1.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'description': description,
      'aiModel': aiModel,
      'multiplier': multiplier,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Copy với các thay đổi
  AIPlan copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? description,
    String? aiModel,
    double? multiplier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIPlan(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      aiModel: aiModel ?? this.aiModel,
      multiplier: multiplier ?? this.multiplier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
