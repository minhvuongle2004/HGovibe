import 'package:cloud_firestore/cloud_firestore.dart';
import 'destination.dart';

/// Model đại diện cho một địa điểm yêu thích của user
class FavoriteDestination {
  final String? id; // Document ID từ Firestore
  final String userId; // UID của user
  final String destinationId; // ID của destination
  final DateTime addedAt; // Thời gian thêm vào yêu thích
  final Destination? destination; // Optional: cache destination data

  FavoriteDestination({
    this.id,
    required this.userId,
    required this.destinationId,
    required this.addedAt,
    this.destination,
  });

  /// Convert từ Firestore DocumentSnapshot
  factory FavoriteDestination.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteDestination(
      id: doc.id,
      userId: data['userId'] ?? '',
      destinationId: data['destinationId'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert từ Map (dùng cho testing hoặc local storage)
  factory FavoriteDestination.fromMap(Map<String, dynamic> map) {
    return FavoriteDestination(
      id: map['id'],
      userId: map['userId'] ?? '',
      destinationId: map['destinationId'] ?? '',
      addedAt: map['addedAt'] is DateTime
          ? map['addedAt'] as DateTime
          : (map['addedAt'] is Timestamp
                ? (map['addedAt'] as Timestamp).toDate()
                : DateTime.now()),
      // destination không được parse từ map, cần fetch riêng
    );
  }

  /// Convert sang Map để lưu vào Firestore
  /// Lưu ý: userId không cần lưu trong document vì đã nằm trong path của subcollection
  Map<String, dynamic> toMap() {
    return {
      'destinationId': destinationId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  /// Copy với các thay đổi
  FavoriteDestination copyWith({
    String? id,
    String? userId,
    String? destinationId,
    DateTime? addedAt,
    Destination? destination,
  }) {
    return FavoriteDestination(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destinationId: destinationId ?? this.destinationId,
      addedAt: addedAt ?? this.addedAt,
      destination: destination ?? this.destination,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteDestination &&
        other.id == id &&
        other.userId == userId &&
        other.destinationId == destinationId;
  }

  @override
  int get hashCode => Object.hash(id, userId, destinationId);
}
