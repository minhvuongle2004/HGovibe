import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_travel_app/models/tours/tour_booking.dart';

/// Service để quản lý tour bookings trong Firestore
class TourBookingService {
  static final TourBookingService instance = TourBookingService._();
  TourBookingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tour_bookings';

  /// Tạo booking mới
  Future<String> createBooking(TourBooking booking) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final data = booking.toMap();
      data['id'] = docRef.id;

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  /// Lấy booking theo ID
  Future<TourBooking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(bookingId).get();
      if (!doc.exists) return null;
      return TourBooking.fromFirestore(doc);
    } catch (e) {
      print('Error getting booking by ID: $e');
      rethrow;
    }
  }

  /// Lấy bookings của user
  Future<List<TourBooking>> getUserBookings(
    String userId, {
    BookingStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: _statusToString(status));
      }

      query = query.orderBy('departureDate', descending: false);
      query = query.orderBy('bookingDate', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => TourBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user bookings: $e');
      rethrow;
    }
  }

  /// Lấy booking theo booking number
  Future<TourBooking?> getBookingByNumber(String bookingNumber) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('bookingNumber', isEqualTo: bookingNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return TourBooking.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting booking by number: $e');
      rethrow;
    }
  }

  /// Cập nhật booking
  Future<void> updateBooking(TourBooking booking) async {
    try {
      if (booking.id == null) {
        throw Exception('Booking ID is required for update');
      }

      final data = booking.toMap();
      await _firestore.collection(_collection).doc(booking.id).update(data);
    } catch (e) {
      print('Error updating booking: $e');
      rethrow;
    }
  }

  /// Cập nhật trạng thái booking
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': _statusToString(status),
      };

      if (confirmedAt != null) {
        updateData['confirmedAt'] = Timestamp.fromDate(confirmedAt);
      }
      if (cancelledAt != null) {
        updateData['cancelledAt'] = Timestamp.fromDate(cancelledAt);
      }
      if (cancellationReason != null) {
        updateData['cancellationReason'] = cancellationReason;
      }

      await _firestore.collection(_collection).doc(bookingId).update(updateData);
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  /// Cập nhật trạng thái thanh toán
  Future<void> updatePaymentStatus(
    String bookingId,
    PaymentStatus paymentStatus, {
    PaymentMethod? paymentMethod,
    DateTime? paidAt,
    String? paymentTransactionId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'paymentStatus': _paymentStatusToString(paymentStatus),
      };

      if (paymentMethod != null) {
        updateData['paymentMethod'] = _paymentMethodToString(paymentMethod);
      }
      if (paidAt != null) {
        updateData['paidAt'] = Timestamp.fromDate(paidAt);
      }
      if (paymentTransactionId != null) {
        updateData['paymentTransactionId'] = paymentTransactionId;
      }

      await _firestore.collection(_collection).doc(bookingId).update(updateData);
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  /// Tạo booking number unique
  Future<String> generateBookingNumber() async {
    try {
      final now = DateTime.now();
      final prefix = 'BK${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      
      // Tìm số thứ tự trong ngày
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('bookingDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('bookingDate',
              isLessThan: Timestamp.fromDate(tomorrow))
          .get();

      final sequence = (snapshot.docs.length + 1).toString().padLeft(4, '0');
      return '$prefix$sequence';
    } catch (e) {
      print('Error generating booking number: $e');
      // Fallback: dùng timestamp
      return 'BK${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  String _statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
    }
  }

  String _paymentStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.failed:
        return 'failed';
    }
  }

  String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.vnpay:
        return 'vnpay';
      case PaymentMethod.momo:
        return 'momo';
    }
  }
}

