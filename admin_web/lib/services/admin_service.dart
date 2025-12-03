import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service để kiểm tra quyền admin
class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kiểm tra user hiện tại có phải admin không
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Kiểm tra user cụ thể có phải admin không
  static Future<bool> isAdminUser(String userId) async {
    try {
      final doc = await _firestore.collection('admins').doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Lấy thông tin admin
  static Future<Map<String, dynamic>?> getAdminInfo() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting admin info: $e');
      return null;
    }
  }
}

