import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:smart_travel_app/models/users/app_user.dart';

class UserProfileService {
  UserProfileService._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final UserProfileService instance = UserProfileService._();

  final FirebaseFirestore _firestore;

  @visibleForTesting
  factory UserProfileService.testing(FirebaseFirestore firestore) {
    return UserProfileService._(firestore: firestore);
  }

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Future<UserProfile> createProfile({
    required String uid,
    String? fullName,
    String? email,
  }) async {
    final profile = UserProfile.empty(uid, fullName: fullName, email: email);
    await _usersRef.doc(uid).set(profile.toMap(), SetOptions(merge: true));
    return profile;
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    try {
      final snapshot = await _usersRef.doc(uid).get();
      if (!snapshot.exists) return null;
      final data = snapshot.data() ?? {};
      data['uid'] = uid;
      return UserProfile.fromMap(data);
    } catch (error, stack) {
      debugPrint('❌ fetchProfile error: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    try {
      await _usersRef
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));
      return profile;
    } catch (error, stack) {
      debugPrint('❌ upsertProfile error: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  Future<void> updateProfileFields(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _usersRef.doc(uid).set(data, SetOptions(merge: true));
    } catch (error, stack) {
      debugPrint('❌ updateProfileFields error: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data() ?? {};
      data['uid'] = uid;
      return UserProfile.fromMap(data);
    });
  }
}
