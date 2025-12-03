import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script helper để tạo admin user
/// 
/// Cách sử dụng:
/// 1. Tạo user trong Firebase Authentication (qua Firebase Console hoặc code)
/// 2. Chạy script này để thêm user vào collection admins
/// 
/// Hoặc có thể chạy trực tiếp trong Firebase Console:
/// - Tạo user trong Authentication
/// - Thêm document vào collection 'admins' với ID = userId
class CreateAdminUser {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo admin user từ email và password
  /// 
  /// Lưu ý: Chỉ chạy script này một lần hoặc trong môi trường development
  /// Trong production, nên tạo admin user thủ công qua Firebase Console
  static Future<void> createAdminUser({
    required String email,
    required String password,
    String? displayName,
    List<String>? permissions,
  }) async {
    try {
      // 1. Tạo user trong Firebase Authentication
      print('📝 Đang tạo user trong Firebase Authentication...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Không thể tạo user');
      }

      // Update display name nếu có
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      print('✅ User đã được tạo: ${user.uid}');

      // 2. Thêm user vào collection admins
      print('📝 Đang thêm user vào collection admins...');
      await _firestore.collection('admins').doc(user.uid).set({
        'userId': user.uid,
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'role': 'admin',
        'permissions': permissions ?? [
          'manage_users',
          'manage_destinations',
          'manage_tours',
          'manage_bookings',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Admin user đã được tạo thành công!');
      print('📧 Email: $email');
      print('🆔 User ID: ${user.uid}');
      print('🔑 Bạn có thể đăng nhập với email và password này.');
    } on FirebaseAuthException catch (e) {
      print('❌ Lỗi Firebase Auth: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Lỗi: $e');
      rethrow;
    }
  }

  /// Thêm quyền admin cho user đã tồn tại
  /// 
  /// Sử dụng khi user đã được tạo trong Firebase Authentication
  /// và chỉ cần thêm quyền admin
  static Future<void> addAdminRole({
    required String userId,
    String? email,
    List<String>? permissions,
  }) async {
    try {
      print('📝 Đang thêm quyền admin cho user: $userId...');

      final adminData = <String, dynamic>{
        'userId': userId,
        'role': 'admin',
        'permissions': permissions ?? [
          'manage_users',
          'manage_destinations',
          'manage_tours',
          'manage_bookings',
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (email != null) {
        adminData['email'] = email;
      }

      await _firestore.collection('admins').doc(userId).set(
        adminData,
        SetOptions(merge: true),
      );

      print('✅ Quyền admin đã được thêm thành công!');
    } catch (e) {
      print('❌ Lỗi: $e');
      rethrow;
    }
  }
}

