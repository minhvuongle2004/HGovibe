import 'package:cloud_firestore/cloud_firestore.dart';

/// Service để lấy thống kê cho Dashboard
class DashboardStatsService {
  static final DashboardStatsService instance = DashboardStatsService._();
  DashboardStatsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy tổng số users
  Future<int> getTotalUsers() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting total users: $e');
      return 0;
    }
  }

  /// Lấy tổng số tours
  Future<int> getTotalTours() async {
    try {
      final snapshot = await _firestore.collection('tour_packages').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting total tours: $e');
      return 0;
    }
  }

  /// Lấy tổng số bookings
  Future<int> getTotalBookings() async {
    try {
      final snapshot = await _firestore.collection('tour_bookings').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting total bookings: $e');
      return 0;
    }
  }

  /// Lấy số bookings pending
  Future<int> getPendingBookings() async {
    try {
      final snapshot = await _firestore
          .collection('tour_bookings')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting pending bookings: $e');
      return 0;
    }
  }

  /// Stream tổng số users (real-time)
  Stream<int> watchTotalUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) => snapshot.docs.length);
  }

  /// Stream tổng số tours (real-time)
  Stream<int> watchTotalTours() {
    return _firestore.collection('tour_packages').snapshots().map((snapshot) => snapshot.docs.length);
  }

  /// Stream tổng số bookings (real-time)
  Stream<int> watchTotalBookings() {
    return _firestore.collection('tour_bookings').snapshots().map((snapshot) => snapshot.docs.length);
  }

  /// Stream số bookings pending (real-time)
  Stream<int> watchPendingBookings() {
    return _firestore
        .collection('tour_bookings')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

