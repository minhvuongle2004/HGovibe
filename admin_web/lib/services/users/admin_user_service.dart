import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/users/app_user.dart';

/// Service để quản lý users trong admin panel
class AdminUserService {
  static final AdminUserService instance = AdminUserService._();
  AdminUserService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  /// Lấy tất cả users với pagination
  Future<List<AppUser>> getAllUsers({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    bool? banned,
  }) async {
    try {
      // Để tránh cần composite index, ta sẽ:
      // 1. Query không có where + orderBy cùng lúc
      // 2. Filter banned ở client-side
      Query query = _firestore.collection(_collection);

      // Nếu không filter banned, chỉ orderBy
      if (banned == null) {
        query = query.orderBy('createdAt', descending: true).limit(limit * 2); // Lấy nhiều hơn để filter
      } else {
        // Nếu có filter banned, chỉ where (không orderBy để tránh cần index)
        query = query.where('banned', isEqualTo: banned).limit(limit * 2);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      var users = <AppUser>[];

      for (var doc in snapshot.docs) {
        try {
          final docData = doc.data();
          if (docData == null) continue;
          
          final data = Map<String, dynamic>.from(docData as Map);
          data['uid'] = doc.id;

          // Load profile
          final profile = UserProfile.fromMap(data);

          // Create AppUser from profile
          final user = AppUser(
            uid: doc.id,
            email: data['email'] as String?,
            displayName: profile.fullName,
            photoUrl: profile.avatarUrl,
            phoneNumber: data['phoneNumber'] as String?,
            emailVerified: (data['emailVerified'] as bool?) ?? false,
            createdAt: profile.createdAt,
            lastLoginAt: profile.updatedAt,
            profile: profile,
          );

          // Filter by banned status (client-side nếu cần)
          if (banned != null && (profile.banned != banned)) {
            continue;
          }

          // Filter by search query (client-side)
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final queryLower = searchQuery.toLowerCase();
            final matches = 
                (user.email?.toLowerCase().contains(queryLower) ?? false) ||
                (user.displayName?.toLowerCase().contains(queryLower) ?? false) ||
                (profile.fullName?.toLowerCase().contains(queryLower) ?? false);
            if (!matches) continue;
          }

          users.add(user);
          
          // Dừng khi đủ limit
          if (users.length >= limit) break;
        } catch (e) {
          print('Error parsing user ${doc.id}: $e');
        }
      }

      return users;
    } catch (e) {
      print('Error getting all users: $e');
      rethrow;
    }
  }

  /// Lấy user theo ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['uid'] = doc.id;

      final profile = UserProfile.fromMap(data);
      return AppUser(
        uid: doc.id,
        email: data['email'],
        displayName: profile.fullName,
        photoUrl: profile.avatarUrl,
        phoneNumber: data['phoneNumber'],
        emailVerified: data['emailVerified'] ?? false,
        createdAt: profile.createdAt,
        lastLoginAt: profile.updatedAt,
        profile: profile,
      );
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  /// Ban user
  Future<void> banUser(String userId, {String? reason}) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'banned': true,
        'bannedAt': FieldValue.serverTimestamp(),
        if (reason != null) 'banReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error banning user: $e');
      rethrow;
    }
  }

  /// Unban user
  Future<void> unbanUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'banned': false,
        'bannedAt': FieldValue.delete(),
        'banReason': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error unbanning user: $e');
      rethrow;
    }
  }

  /// Delete user (soft delete)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Lấy số lượng users theo status
  Future<int> getUserCount({bool? banned}) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (banned != null) {
        query = query.where('banned', isEqualTo: banned);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting user count: $e');
      return 0;
    }
  }

  /// Stream users (real-time)
  /// Note: Simplified để tránh cần composite index
  Stream<List<AppUser>> watchUsers({bool? banned}) {
    Query query = _firestore.collection(_collection);

    // Nếu không filter banned, chỉ orderBy
    if (banned == null) {
      query = query.orderBy('createdAt', descending: true).limit(50);
    } else {
      // Nếu có filter, chỉ where (không orderBy)
      query = query.where('banned', isEqualTo: banned).limit(50);
    }

    return query.snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) {
        try {
          final docData = doc.data();
          if (docData == null) return null;
          
          final data = Map<String, dynamic>.from(docData as Map);
          data['uid'] = doc.id;
          final profile = UserProfile.fromMap(data);
          
          // Filter banned ở client-side nếu cần
          if (banned != null && profile.banned != banned) {
            return null;
          }
          
          return AppUser(
            uid: doc.id,
            email: data['email'] as String?,
            displayName: profile.fullName,
            photoUrl: profile.avatarUrl,
            phoneNumber: data['phoneNumber'] as String?,
            emailVerified: data['emailVerified'] as bool? ?? false,
            createdAt: profile.createdAt,
            lastLoginAt: profile.updatedAt,
            profile: profile,
          );
        } catch (e) {
          print('Error parsing user ${doc.id}: $e');
          return null;
        }
      }).whereType<AppUser>().toList();
      
      // Sort ở client-side nếu có filter banned
      if (banned != null) {
        users.sort((a, b) {
          final aDate = a.profile?.createdAt;
          final bDate = b.profile?.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // Descending
        });
      }
      
      return users;
    });
  }
}

