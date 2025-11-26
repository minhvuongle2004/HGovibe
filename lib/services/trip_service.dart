import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../models/trip_item.dart';
import '../services/destination_service.dart';

/// Service để quản lý trips của user
class TripService {
  TripService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final TripService instance = TripService._();

  final FirebaseFirestore _firestore;

  @visibleForTesting
  factory TripService.testing(FirebaseFirestore firestore) {
    return TripService._(firestore: firestore);
  }

  /// Collection reference cho trips của một user cụ thể
  CollectionReference<Map<String, dynamic>> _tripsRefForUser(String userId) =>
      _firestore.collection('users').doc(userId).collection('trips');

  /// Collection reference cho items của một trip
  CollectionReference<Map<String, dynamic>> _itemsRefForTrip(
    String userId,
    String tripId,
  ) =>
      _tripsRefForUser(userId).doc(tripId).collection('items');

  /// Tạo trip mới
  Future<String> createTrip(Trip trip) async {
    try {
      final tripsRef = _tripsRefForUser(trip.userId);
      final data = trip.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      
      final docRef = await tripsRef.add(data);
      debugPrint('✅ Trip created: ${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      debugPrint('❌ Error creating trip: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Cập nhật trip
  Future<void> updateTrip(
    String userId,
    String tripId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final tripsRef = _tripsRefForUser(userId);
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await tripsRef.doc(tripId).update(updates);
      debugPrint('✅ Trip updated: $tripId');
    } catch (e, stack) {
      debugPrint('❌ Error updating trip: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Xóa trip
  Future<void> deleteTrip(String userId, String tripId) async {
    try {
      final tripsRef = _tripsRefForUser(userId);
      // Xóa tất cả items trước
      final itemsRef = _itemsRefForTrip(userId, tripId);
      final itemsSnapshot = await itemsRef.get();
      final batch = _firestore.batch();
      for (var doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Xóa trip
      await tripsRef.doc(tripId).delete();
      debugPrint('✅ Trip deleted: $tripId');
    } catch (e, stack) {
      debugPrint('❌ Error deleting trip: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Lấy trip theo ID
  Future<Trip?> getTrip(String userId, String tripId) async {
    try {
      final tripsRef = _tripsRefForUser(userId);
      final doc = await tripsRef.doc(tripId).get();
      
      if (!doc.exists) {
        return null;
      }

      final trip = Trip.fromFirestore(doc);
      
      // Load items
      final items = await getTripItems(userId, tripId);
      // costEstimate đã được load trong fromFirestore
      return trip.copyWith(items: items);
    } catch (e, stack) {
      debugPrint('❌ Error getting trip: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Lấy tất cả trips của user
  Future<List<Trip>> getTrips(String userId) async {
    try {
      final tripsRef = _tripsRefForUser(userId);
      final snapshot = await tripsRef
          .orderBy('startDate', descending: false)
          .get();

      final trips = <Trip>[];
      for (var doc in snapshot.docs) {
        try {
          final trip = Trip.fromFirestore(doc);
          trips.add(trip);
        } catch (e) {
          debugPrint('⚠️ Error parsing trip ${doc.id}: $e');
        }
      }

      debugPrint('✅ Loaded ${trips.length} trips for user $userId');
      return trips;
    } catch (e, stack) {
      debugPrint('❌ Error getting trips: $e');
      debugPrint('$stack');
      return [];
    }
  }

  /// Stream trips real-time
  Stream<List<Trip>> watchTrips(String userId) {
    final tripsRef = _tripsRefForUser(userId);
    return tripsRef
        .orderBy('startDate', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final trips = <Trip>[];
      for (var doc in snapshot.docs) {
        try {
          final trip = Trip.fromFirestore(doc);
          trips.add(trip);
        } catch (e) {
          debugPrint('⚠️ Error parsing trip ${doc.id}: $e');
        }
      }
      return trips;
    });
  }

  /// Thêm item vào trip
  Future<String> addTripItem(String userId, String tripId, TripItem item) async {
    try {
      final itemsRef = _itemsRefForTrip(userId, tripId);
      final data = item.toMap();
      final docRef = await itemsRef.add(data);
      debugPrint('✅ Trip item added: ${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      debugPrint('❌ Error adding trip item: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Cập nhật item
  Future<void> updateTripItem(
    String userId,
    String tripId,
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final itemsRef = _itemsRefForTrip(userId, tripId);
      
      // Convert DateTime và TimeOfDay sang format Firestore
      final firestoreUpdates = <String, dynamic>{};
      for (var entry in updates.entries) {
        if (entry.key == 'plannedDate' && entry.value is DateTime) {
          firestoreUpdates['plannedDate'] = Timestamp.fromDate(entry.value as DateTime);
        } else if (entry.key == 'plannedTime' && entry.value is String) {
          firestoreUpdates['plannedTime'] = entry.value;
        } else if (entry.key == 'durationHours') {
          firestoreUpdates['durationHours'] = entry.value;
        } else if (entry.key == 'notes') {
          firestoreUpdates['notes'] = entry.value;
        }
      }
      
      await itemsRef.doc(itemId).update(firestoreUpdates);
      debugPrint('✅ Trip item updated: $itemId');
    } catch (e, stack) {
      debugPrint('❌ Error updating trip item: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Xóa item
  Future<void> removeTripItem(
    String userId,
    String tripId,
    String itemId,
  ) async {
    try {
      final itemsRef = _itemsRefForTrip(userId, tripId);
      await itemsRef.doc(itemId).delete();
      
      // Cập nhật lại order của các items còn lại
      await _reorderItemsAfterDelete(userId, tripId);
      
      debugPrint('✅ Trip item removed: $itemId');
    } catch (e, stack) {
      debugPrint('❌ Error removing trip item: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Lấy tất cả items của trip
  Future<List<TripItem>> getTripItems(String userId, String tripId) async {
    try {
      final itemsRef = _itemsRefForTrip(userId, tripId);
      final snapshot = await itemsRef.orderBy('order', descending: false).get();

      final items = <TripItem>[];
      for (var doc in snapshot.docs) {
        try {
          final item = TripItem.fromFirestore(doc);
          // Load destination data
          if (item.destinationId.isNotEmpty) {
            final destination = await DestinationService.getDestinationById(
              item.destinationId,
            );
            items.add(item.copyWith(destination: destination));
          } else {
            items.add(item);
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing trip item ${doc.id}: $e');
        }
      }

      return items;
    } catch (e, stack) {
      debugPrint('❌ Error getting trip items: $e');
      debugPrint('$stack');
      return [];
    }
  }

  /// Stream items real-time
  Stream<List<TripItem>> watchTripItems(String userId, String tripId) {
    final itemsRef = _itemsRefForTrip(userId, tripId);
    return itemsRef
        .orderBy('order', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final items = <TripItem>[];
      for (var doc in snapshot.docs) {
        try {
          final item = TripItem.fromFirestore(doc);
          // Load destination data
          if (item.destinationId.isNotEmpty) {
            final destination = await DestinationService.getDestinationById(
              item.destinationId,
            );
            items.add(item.copyWith(destination: destination));
          } else {
            items.add(item);
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing trip item ${doc.id}: $e');
        }
      }
      return items;
    });
  }

  /// Sắp xếp lại thứ tự items
  Future<void> reorderTripItems(
    String userId,
    String tripId,
    List<String> itemIds,
  ) async {
    try {
      final itemsRef = _itemsRefForTrip(userId, tripId);
      final batch = _firestore.batch();
      
      for (var i = 0; i < itemIds.length; i++) {
        final itemId = itemIds[i];
        batch.update(itemsRef.doc(itemId), {'order': i});
      }
      
      await batch.commit();
      debugPrint('✅ Trip items reordered');
    } catch (e, stack) {
      debugPrint('❌ Error reordering trip items: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Cập nhật lại order sau khi xóa item
  Future<void> _reorderItemsAfterDelete(
    String userId,
    String tripId,
  ) async {
    try {
      final items = await getTripItems(userId, tripId);
      final batch = _firestore.batch();
      final itemsRef = _itemsRefForTrip(userId, tripId);
      
      for (var i = 0; i < items.length; i++) {
        if (items[i].id != null) {
          batch.update(itemsRef.doc(items[i].id!), {'order': i});
        }
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('⚠️ Error reordering after delete: $e');
    }
  }
}

