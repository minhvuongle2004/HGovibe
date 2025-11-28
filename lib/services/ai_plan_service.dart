import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_plan.dart';

/// Service để quản lý kế hoạch AI trong Firestore
class AIPlanService {
  AIPlanService._();
  static final AIPlanService instance = AIPlanService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lưu hoặc cập nhật kế hoạch AI cho một trip
  /// Nếu đã có plan, sẽ ghi đè (update)
  /// Nếu chưa có, sẽ tạo mới
  Future<String?> saveAIPlan(String userId, AIPlan plan) async {
    try {
      final planRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(plan.tripId)
          .collection('aiPlans')
          .doc('current'); // Luôn dùng 'current' để ghi đè

      await planRef.set(plan.toMap(), SetOptions(merge: false));
      
      debugPrint('✅ AIPlan saved for trip ${plan.tripId}');
      return planRef.id;
    } catch (e, stack) {
      debugPrint('❌ Error saving AIPlan: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Lấy kế hoạch AI hiện tại của trip
  Future<AIPlan?> getCurrentAIPlan(String userId, String tripId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .collection('aiPlans')
          .doc('current')
          .get();

      if (doc.exists) {
        return AIPlan.fromFirestore(doc);
      }
      return null;
    } catch (e, stack) {
      debugPrint('❌ Error getting AIPlan: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// Stream kế hoạch AI hiện tại của trip (real-time)
  Stream<AIPlan?> watchCurrentAIPlan(String userId, String tripId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('trips')
        .doc(tripId)
        .collection('aiPlans')
        .doc('current')
        .snapshots()
        .map((doc) => doc.exists ? AIPlan.fromFirestore(doc) : null);
  }

  /// Xóa kế hoạch AI
  Future<bool> deleteAIPlan(String userId, String tripId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .collection('aiPlans')
          .doc('current')
          .delete();
      
      debugPrint('✅ AIPlan deleted for trip $tripId');
      return true;
    } catch (e, stack) {
      debugPrint('❌ Error deleting AIPlan: $e');
      debugPrint('$stack');
      return false;
    }
  }
}

