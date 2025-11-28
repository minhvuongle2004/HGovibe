import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:smart_travel_app/models/destinations/favorite_destination.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/utils/constants.dart';

/// Service để quản lý favorites của user
class FavoritesService {
  FavoritesService._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FavoritesService instance = FavoritesService._();

  final FirebaseFirestore _firestore;

  @visibleForTesting
  factory FavoritesService.testing(FirebaseFirestore firestore) {
    return FavoritesService._(firestore: firestore);
  }

  /// Collection reference cho favorites của một user cụ thể
  /// Sử dụng subcollection: users/{userId}/favorites/{favoriteId}
  CollectionReference<Map<String, dynamic>> _favoritesRefForUser(
    String userId,
  ) => _firestore.collection('users').doc(userId).collection('favorites');

  /// Collection reference cho destinations
  CollectionReference<Map<String, dynamic>> get _destinationsRef =>
      _firestore.collection(AppConstants.destinationsCollection);

  /// Thêm địa điểm vào yêu thích
  ///
  /// Throws [FirebaseException] nếu có lỗi
  Future<void> addFavorite({
    required String userId,
    required String destinationId,
  }) async {
    try {
      final favoritesRef = _favoritesRefForUser(userId);

      // Kiểm tra xem đã tồn tại chưa (query theo destinationId trong subcollection)
      final existing = await favoritesRef
          .where('destinationId', isEqualTo: destinationId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint(
          '⚠️ Favorite already exists for user $userId, destination $destinationId',
        );
        return; // Không throw error, chỉ return
      }

      // Thêm mới vào subcollection của user
      await favoritesRef.add({
        'destinationId': destinationId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Favorite added: user=$userId, destination=$destinationId');
    } catch (e, stack) {
      debugPrint('❌ Error adding favorite: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Xóa địa điểm khỏi yêu thích
  ///
  /// Throws [FirebaseException] nếu có lỗi
  Future<void> removeFavorite({
    required String userId,
    required String destinationId,
  }) async {
    try {
      final favoritesRef = _favoritesRefForUser(userId);
      final query = await favoritesRef
          .where('destinationId', isEqualTo: destinationId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        debugPrint(
          '⚠️ Favorite not found for user $userId, destination $destinationId',
        );
        return; // Không throw error nếu không tìm thấy
      }

      // Xóa document đầu tiên tìm thấy
      await favoritesRef.doc(query.docs.first.id).delete();

      debugPrint(
        '✅ Favorite removed: user=$userId, destination=$destinationId',
      );
    } catch (e, stack) {
      debugPrint('❌ Error removing favorite: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Kiểm tra địa điểm có trong yêu thích không
  ///
  /// Returns `true` nếu đã yêu thích, `false` nếu chưa
  Future<bool> isFavorite({
    required String userId,
    required String destinationId,
  }) async {
    try {
      final favoritesRef = _favoritesRefForUser(userId);
      final query = await favoritesRef
          .where('destinationId', isEqualTo: destinationId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e, stack) {
      debugPrint('❌ Error checking favorite: $e');
      debugPrint('$stack');
      return false; // Trả về false nếu có lỗi
    }
  }

  /// Lấy danh sách tất cả favorites của user (chỉ FavoriteDestination, không có Destination data)
  ///
  /// Returns danh sách FavoriteDestination
  Future<List<FavoriteDestination>> getFavorites(String userId) async {
    try {
      final favoritesRef = _favoritesRefForUser(userId);
      final snapshot = await favoritesRef
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        // Thêm userId vào FavoriteDestination vì subcollection không có field này
        final data = doc.data();
        return FavoriteDestination(
          id: doc.id,
          userId: userId,
          destinationId: data['destinationId'] ?? '',
          addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e, stack) {
      debugPrint('❌ Error getting favorites: $e');
      debugPrint('$stack');
      return [];
    }
  }

  /// Lấy danh sách Destination từ favorites (join với destinations collection)
  ///
  /// Returns danh sách Destination đã được yêu thích
  Future<List<Destination>> getFavoriteDestinations(String userId) async {
    try {
      // Lấy danh sách favorite IDs từ subcollection
      final favoritesRef = _favoritesRefForUser(userId);
      final favoritesSnapshot = await favoritesRef
          .orderBy('addedAt', descending: true)
          .get();

      if (favoritesSnapshot.docs.isEmpty) {
        return [];
      }

      final destinationIds = favoritesSnapshot.docs
          .map((doc) => doc.data()['destinationId'] as String)
          .toList();

      // Lấy destinations từ collection destinations
      final destinations = <Destination>[];
      for (final destinationId in destinationIds) {
        try {
          final doc = await _destinationsRef.doc(destinationId).get();
          if (doc.exists) {
            destinations.add(Destination.fromFirestore(doc));
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching destination $destinationId: $e');
          // Tiếp tục với destination tiếp theo
        }
      }

      debugPrint(
        '✅ Loaded ${destinations.length} favorite destinations for user $userId',
      );
      return destinations;
    } catch (e, stack) {
      debugPrint('❌ Error getting favorite destinations: $e');
      debugPrint('$stack');
      return [];
    }
  }

  /// Stream để lắng nghe thay đổi favorites real-time (chỉ FavoriteDestination)
  ///
  /// Returns Stream<List<FavoriteDestination>>
  Stream<List<FavoriteDestination>> watchFavorites(String userId) {
    final favoritesRef = _favoritesRefForUser(userId);
    return favoritesRef
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            // Thêm userId vào FavoriteDestination vì subcollection không có field này
            final data = doc.data();
            return FavoriteDestination(
              id: doc.id,
              userId: userId,
              destinationId: data['destinationId'] ?? '',
              addedAt:
                  (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList(),
        );
  }

  /// Stream danh sách Destination từ favorites (join với destinations collection)
  ///
  /// Returns Stream<List<Destination>>
  Stream<List<Destination>> watchFavoriteDestinations(String userId) {
    return watchFavorites(userId).asyncMap((favorites) async {
      if (favorites.isEmpty) {
        return <Destination>[];
      }

      final destinationIds = favorites.map((f) => f.destinationId).toList();
      final destinations = <Destination>[];

      // Fetch destinations từ Firestore
      for (final destinationId in destinationIds) {
        try {
          final doc = await _destinationsRef.doc(destinationId).get();
          if (doc.exists) {
            destinations.add(Destination.fromFirestore(doc));
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching destination $destinationId: $e');
        }
      }

      return destinations;
    });
  }

  /// Toggle favorite (thêm nếu chưa có, xóa nếu đã có)
  ///
  /// Returns `true` nếu đã thêm, `false` nếu đã xóa
  Future<bool> toggleFavorite({
    required String userId,
    required String destinationId,
  }) async {
    final isFav = await isFavorite(
      userId: userId,
      destinationId: destinationId,
    );

    if (isFav) {
      await removeFavorite(userId: userId, destinationId: destinationId);
      return false;
    } else {
      await addFavorite(userId: userId, destinationId: destinationId);
      return true;
    }
  }
}
