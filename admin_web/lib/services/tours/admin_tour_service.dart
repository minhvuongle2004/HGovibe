import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/tours/tour_package.dart';

/// Service để quản lý tour packages cho admin panel
class AdminTourService {
  static final AdminTourService instance = AdminTourService._();
  AdminTourService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tour_packages';

  /// Lấy tất cả tours với các bộ lọc cơ bản.
  Future<List<TourPackage>> getAllTours({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    TourStatus? status,
    bool? featured,
    String? destination,
    bool includeDeleted = false,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (status != null) {
        query = query.where('status', isEqualTo: _statusToString(status));
      }

      if (featured != null) {
        query = query.where('featured', isEqualTo: featured);
      }

      if (destination != null && destination.isNotEmpty) {
        // Sử dụng trường destination_lowercase nếu có, nếu không sẽ filter client-side
        try {
          query = query.where(
            'destination_lowercase',
            isGreaterThanOrEqualTo: destination.toLowerCase(),
          ).where(
            'destination_lowercase',
            isLessThanOrEqualTo: '${destination.toLowerCase()}\uf8ff',
          );
        } catch (e) {
          print('⚠️ Cannot filter destination server-side: $e');
        }
      }

      if (startAfter != null) {
        try {
          query = query.startAfterDocument(startAfter);
        } catch (e) {
          print('⚠️ Invalid startAfter document: $e');
        }
      }

      // Lấy nhiều hơn để filter client-side (tránh cần composite index)
      query = query.limit(limit * 5);

      final snapshot = await query.get();
      final tours = <TourPackage>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          // Loại bỏ tours đã bị đánh dấu deleted nếu không yêu cầu
          final deleted = data['deleted'] == true || data['status'] == 'deleted';
          if (deleted && !includeDeleted) {
            continue;
          }

          final tour = TourPackage.fromMap(data, id: doc.id);

          if (searchQuery != null && searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            final matches = tour.title.toLowerCase().contains(q) ||
                tour.destination.toLowerCase().contains(q) ||
                tour.providerName.toLowerCase().contains(q);
            if (!matches) continue;
          }

          if (destination != null && destination.isNotEmpty) {
            if (tour.destination.toLowerCase() != destination.toLowerCase()) {
              continue;
            }
          }

          tours.add(tour);

          if (tours.length >= limit) break;
        } catch (e) {
          print('❌ Error parsing tour ${doc.id}: $e');
        }
      }

      tours.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tours;
    } catch (e, stackTrace) {
      print('❌ Error loading tours: $e');
      print(stackTrace);
      rethrow;
    }
  }

  /// Stream các tours (real-time)
  Stream<List<TourPackage>> watchTours({TourStatus? status}) {
    Query query = _firestore.collection(_collection);
    if (status != null) {
      query = query.where('status', isEqualTo: _statusToString(status));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TourPackage.fromMap(data, id: doc.id);
      }).toList();
    });
  }

  Future<TourPackage?> getTourById(String tourId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(tourId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return TourPackage.fromMap(data, id: doc.id);
    } catch (e) {
      print('❌ Error getting tour by ID: $e');
      rethrow;
    }
  }

  Future<String> createTour(TourPackage tour) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final data = _buildStorableData(tour.toMap(), docRef.id);

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      print('❌ Error creating tour: $e');
      rethrow;
    }
  }

  Future<void> updateTour(TourPackage tour) async {
    try {
      if (tour.id == null) {
        throw Exception('Tour ID is required to update');
      }

      final data = _buildStorableData(tour.toMap(), tour.id!);
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(tour.id).update(data);
    } catch (e) {
      print('❌ Error updating tour: $e');
      rethrow;
    }
  }

  Future<void> deleteTour(String tourId) async {
    try {
      await _firestore.collection(_collection).doc(tourId).update({
        'status': 'inactive',
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error deleting tour: $e');
      rethrow;
    }
  }

  Future<void> activateTour(String tourId) async {
    await _updateStatus(tourId, TourStatus.active);
  }

  Future<void> deactivateTour(String tourId) async {
    await _updateStatus(tourId, TourStatus.inactive);
  }

  Future<void> markSoldOut(String tourId) async {
    await _updateStatus(tourId, TourStatus.soldOut);
  }

  Future<String?> duplicateTour(String tourId) async {
    try {
      final tour = await getTourById(tourId);
      if (tour == null) return null;

      final newDoc = _firestore.collection(_collection).doc();
      final data = tour.toMap();
      data['title'] = '${tour.title} (Copy)';
      data['status'] = 'inactive';

      final storable = _buildStorableData(data, newDoc.id);
      storable['createdAt'] = FieldValue.serverTimestamp();
      storable['updatedAt'] = FieldValue.serverTimestamp();

      await newDoc.set(storable);
      return newDoc.id;
    } catch (e) {
      print('❌ Error duplicating tour: $e');
      rethrow;
    }
  }

  Future<int> getTourCount({TourStatus? status}) async {
    Query query = _firestore.collection(_collection);
    if (status != null) {
      query = query.where('status', isEqualTo: _statusToString(status));
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<List<TourPackage>> searchTours(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      return getAllTours(limit: limit);
    }

    final lower = query.toLowerCase();
    try {
      final results = <String, TourPackage>{};

      final titleQuery = _firestore
          .collection(_collection)
          .where('title_lowercase',
              isGreaterThanOrEqualTo: lower)
          .where('title_lowercase',
              isLessThanOrEqualTo: '$lower\uf8ff')
          .limit(limit);

      final destinationQuery = _firestore
          .collection(_collection)
          .where('destination_lowercase',
              isGreaterThanOrEqualTo: lower)
          .where('destination_lowercase',
              isLessThanOrEqualTo: '$lower\uf8ff')
          .limit(limit);

      final titleSnapshot = await titleQuery.get();
      final destinationSnapshot = await destinationQuery.get();

      for (final doc in titleSnapshot.docs) {
        final data = doc.data();
        results[doc.id] = TourPackage.fromMap(data, id: doc.id);
      }
      for (final doc in destinationSnapshot.docs) {
        final data = doc.data();
        results[doc.id] = TourPackage.fromMap(data, id: doc.id);
      }

      final tours = results.values.toList();
      tours.sort((a, b) => b.rating.compareTo(a.rating));
      if (tours.length > limit) {
        return tours.sublist(0, limit);
      }
      return tours;
    } catch (e) {
      print('❌ Error searching tours: $e');
      return getAllTours(limit: limit, searchQuery: query);
    }
  }

  Future<void> _updateStatus(String tourId, TourStatus status) async {
    try {
      await _firestore.collection(_collection).doc(tourId).update({
        'status': _statusToString(status),
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == TourStatus.active) 'deleted': false,
      });
    } catch (e) {
      print('❌ Error updating tour status: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _buildStorableData(Map<String, dynamic> source, String docId) {
    final data = Map<String, dynamic>.from(source);
    data['id'] = docId;
    data['title_lowercase'] = (data['title'] as String? ?? '').toLowerCase();
    data['destination_lowercase'] =
        (data['destination'] as String? ?? '').toLowerCase();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['createdAt'] = data['createdAt'] ?? FieldValue.serverTimestamp();
    return data;
  }

  String _statusToString(TourStatus status) {
    switch (status) {
      case TourStatus.active:
        return 'active';
      case TourStatus.inactive:
        return 'inactive';
      case TourStatus.soldOut:
        return 'sold_out';
    }
  }
}

