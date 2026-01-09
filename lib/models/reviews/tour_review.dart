import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewStatus { active, hidden }

ReviewStatus reviewStatusFromString(String? value) {
  switch (value) {
    case 'hidden':
      return ReviewStatus.hidden;
    case 'active':
    default:
      return ReviewStatus.active;
  }
}

String reviewStatusToString(ReviewStatus status) {
  switch (status) {
    case ReviewStatus.hidden:
      return 'hidden';
    case ReviewStatus.active:
      return 'active';
  }
}

class TourReview {
  final String? id;
  final String tourId;
  final String userId;
  final String bookingId;
  final double rating;
  final String? comment;
  final List<String> photos;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ReviewStatus status;

  const TourReview({
    this.id,
    required this.tourId,
    required this.userId,
    required this.bookingId,
    required this.rating,
    this.comment,
    this.photos = const [],
    this.createdAt,
    this.updatedAt,
    this.status = ReviewStatus.active,
  });

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    return {
      'tourId': tourId,
      'userId': userId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'status': reviewStatusToString(status),
      if (includeTimestamps) 'createdAt': createdAt,
      if (includeTimestamps) 'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tourId': tourId,
      'userId': userId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'status': reviewStatusToString(status),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TourReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TourReview(
      id: doc.id,
      tourId: data['tourId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      bookingId: data['bookingId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      photos: List<String>.from(data['photos'] as List? ?? []),
      status: reviewStatusFromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

