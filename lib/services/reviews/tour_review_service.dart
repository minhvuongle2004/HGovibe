import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_travel_app/models/reviews/tour_review.dart';

class TourReviewService {
  TourReviewService._();
  static final TourReviewService instance = TourReviewService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('tour_reviews');

  Future<String> createReview(TourReview review) async {
    final docRef = await _collection.add(review.toFirestore());
    return docRef.id;
  }

  Future<void> updateReview(
    String reviewId, {
    double? rating,
    String? comment,
    List<String>? photos,
    ReviewStatus? status,
  }) async {
    final data = <String, dynamic>{
      if (rating != null) 'rating': rating,
      if (comment != null) 'comment': comment,
      if (photos != null) 'photos': photos,
      if (status != null) 'status': reviewStatusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _collection.doc(reviewId).update(data);
  }

  Future<void> deleteReview(String reviewId) async {
    await _collection.doc(reviewId).delete();
  }

  Future<TourReview?> getReviewById(String reviewId) async {
    final doc = await _collection.doc(reviewId).get();
    if (!doc.exists) return null;
    return TourReview.fromDoc(doc);
  }

  Future<TourReview?> getReviewByBooking(String bookingId) async {
    final snap = await _collection
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return TourReview.fromDoc(snap.docs.first);
  }

  Future<List<TourReview>> getReviewsByTour(
    String tourId, {
    int limit = 50,
  }) async {
    final snap = await _collection
        .where('tourId', isEqualTo: tourId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(TourReview.fromDoc).toList();
  }

  Future<List<TourReview>> getReviewsByUser(
    String userId, {
    int limit = 50,
  }) async {
    final snap = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(TourReview.fromDoc).toList();
  }

  Future<bool> hasReviewForBooking(String bookingId) async {
    final snap = await _collection
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}

