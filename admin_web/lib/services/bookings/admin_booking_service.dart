import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/tours/tour_booking.dart';

class AdminBookingService {
  AdminBookingService._();
  static final AdminBookingService instance = AdminBookingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _bookingCollection = 'tour_bookings';
  final String _tourCollection = 'tour_packages';

  Future<BookingQueryResult> getBookings({
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? tourId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_bookingCollection)
          .orderBy('bookingDate', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit * 3).get();
      final bookings = snapshot.docs
          .map((doc) => TourBooking.fromMap(doc.data(), id: doc.id))
          .toList();

      final filtered = bookings.where((booking) {
        if (status != null && booking.status != status) return false;
        if (paymentStatus != null &&
            booking.paymentStatus != paymentStatus) return false;
        if (tourId != null &&
            tourId.isNotEmpty &&
            booking.tourPackageId != tourId) return false;
        if (startDate != null &&
            booking.bookingDate.isBefore(startDate)) return false;
        if (endDate != null &&
            booking.bookingDate.isAfter(endDate)) return false;
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.toLowerCase();
          final matchesBookingNumber =
              booking.bookingNumber.toLowerCase().contains(q);
          final matchesEmail =
              booking.contactInfo.email.toLowerCase().contains(q);
          final matchesName =
              booking.contactInfo.fullName.toLowerCase().contains(q);
          final matchesPhone =
              booking.contactInfo.phoneNumber.toLowerCase().contains(q);
          if (!(matchesBookingNumber ||
              matchesEmail ||
              matchesName ||
              matchesPhone)) {
            return false;
          }
        }
        return true;
      }).toList();

      filtered.sort(
        (a, b) => b.bookingDate.compareTo(a.bookingDate),
      );

      final limited =
          filtered.length > limit ? filtered.sublist(0, limit) : filtered;

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length == limit * 3;

      return BookingQueryResult(
        bookings: limited,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TourBooking>> getBookingsByStatus(
    BookingStatus status, {
    int limit = 20,
  }) async {
    final result = await getBookings(status: status, limit: limit);
    return result.bookings;
  }

  Future<TourBooking?> getBookingById(String bookingId) async {
    final doc =
        await _firestore.collection(_bookingCollection).doc(bookingId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TourBooking.fromMap(doc.data()!, id: doc.id);
  }

  Stream<int> watchPendingCount() {
    return _firestore
        .collection(_bookingCollection)
        .where('status', isEqualTo: _statusToString(BookingStatus.pending))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<TourBooking>> watchBookingsByStatus(
    BookingStatus status, {
    int limit = 10,
  }) {
    return _firestore
        .collection(_bookingCollection)
        .where('status', isEqualTo: _statusToString(status))
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => TourBooking.fromMap(doc.data(), id: doc.id))
              .toList();
          bookings.sort(
            (a, b) => b.bookingDate.compareTo(a.bookingDate),
          );
          return bookings.length > limit ? bookings.sublist(0, limit) : bookings;
        });
  }

  Future<Map<BookingStatus, int>> getStatusCounts() async {
    final counts = <BookingStatus, int>{};
    for (final status in BookingStatus.values) {
      final agg = await _firestore
          .collection(_bookingCollection)
          .where('status', isEqualTo: _statusToString(status))
          .count()
          .get();
      counts[status] = agg.count ?? 0;
    }
    return counts;
  }

  Future<void> confirmBooking(
    String bookingId, {
    bool markAsPaid = false,
    BookingAdminNote? note,
  }) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw Exception('Không tìm thấy booking');
    }

    final updates = <String, dynamic>{
      'status': _statusToString(BookingStatus.confirmed),
      'confirmedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (markAsPaid) {
      updates['paymentStatus'] = _paymentStatusToString(PaymentStatus.paid);
      updates['paidAt'] = Timestamp.fromDate(DateTime.now());
    }

    if (note != null) {
      updates['adminNotes'] = FieldValue.arrayUnion([note.toMap()]);
    }

    await _firestore
        .collection(_bookingCollection)
        .doc(bookingId)
        .update(updates);

    if (booking.tourPackageId.isNotEmpty) {
      await _firestore.collection(_tourCollection).doc(booking.tourPackageId).update({
        'bookingCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> cancelBooking(
    String bookingId, {
    required String reason,
    bool markRefunded = false,
    BookingAdminNote? note,
  }) async {
    final updates = <String, dynamic>{
      'status': _statusToString(BookingStatus.cancelled),
      'cancelledAt': Timestamp.fromDate(DateTime.now()),
      'cancellationReason': reason,
    };

    if (markRefunded) {
      updates['paymentStatus'] = _paymentStatusToString(PaymentStatus.refunded);
    }

    if (note != null) {
      updates['adminNotes'] = FieldValue.arrayUnion([note.toMap()]);
    }

    await _firestore
        .collection(_bookingCollection)
        .doc(bookingId)
        .update(updates);
  }

  Future<void> completeBooking(String bookingId) async {
    await _firestore.collection(_bookingCollection).doc(bookingId).update({
      'status': _statusToString(BookingStatus.completed),
    });
  }

  Future<void> updatePaymentStatus(
    String bookingId,
    PaymentStatus paymentStatus, {
    PaymentMethod? paymentMethod,
    DateTime? paidAt,
    String? transactionId,
  }) async {
    final data = <String, dynamic>{
      'paymentStatus': _paymentStatusToString(paymentStatus),
    };

    if (paymentMethod != null) {
      data['paymentMethod'] = _paymentMethodToString(paymentMethod);
    }
    if (paidAt != null) {
      data['paidAt'] = Timestamp.fromDate(paidAt);
    }
    if (transactionId != null && transactionId.isNotEmpty) {
      data['paymentTransactionId'] = transactionId;
    }

    await _firestore.collection(_bookingCollection).doc(bookingId).update(data);
  }

  Future<void> addAdminNote(
    String bookingId, {
    required BookingAdminNote note,
  }) async {
    await _firestore.collection(_bookingCollection).doc(bookingId).update({
      'adminNotes': FieldValue.arrayUnion([note.toMap()]),
    });
  }

  Future<List<TourBooking>> searchBookings(
    String query, {
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      final result = await getBookings(limit: limit);
      return result.bookings;
    }

    final lower = query.toLowerCase();
    final snapshot = await _firestore
        .collection(_bookingCollection)
        .orderBy('bookingDate', descending: true)
        .limit(limit * 3)
        .get();

    final bookings = snapshot.docs
        .map((doc) => TourBooking.fromMap(doc.data(), id: doc.id))
        .where((booking) {
      return booking.bookingNumber.toLowerCase().contains(lower) ||
          booking.contactInfo.email.toLowerCase().contains(lower) ||
          booking.contactInfo.fullName.toLowerCase().contains(lower) ||
          booking.contactInfo.phoneNumber.toLowerCase().contains(lower);
    }).toList();

    return bookings.length > limit ? bookings.sublist(0, limit) : bookings;
  }

  Future<List<Map<String, dynamic>>> exportBookingsData({
    DateTime? startDate,
    DateTime? endDate,
    BookingStatus? status,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_bookingCollection);

    if (status != null) {
      query = query.where('status', isEqualTo: _statusToString(status));
    }
    if (startDate != null) {
      query = query.where(
        'bookingDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'bookingDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final booking = TourBooking.fromMap(doc.data(), id: doc.id);
      return {
        'bookingNumber': booking.bookingNumber,
        'bookingDate': booking.bookingDate.toIso8601String(),
        'departureDate': booking.departureDate.toIso8601String(),
        'status': _statusToString(booking.status),
        'paymentStatus': _paymentStatusToString(booking.paymentStatus),
        'totalAmount': booking.totalAmount,
        'currency': booking.currency,
        'contactName': booking.contactInfo.fullName,
        'contactEmail': booking.contactInfo.email,
        'contactPhone': booking.contactInfo.phoneNumber,
        'tourPackageId': booking.tourPackageId,
        'numberOfAdults': booking.numberOfAdults,
        'numberOfChildren': booking.numberOfChildren,
        'numberOfInfants': booking.numberOfInfants,
      };
    }).toList();
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

class BookingQueryResult {
  final List<TourBooking> bookings;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  BookingQueryResult({
    required this.bookings,
    required this.lastDocument,
    required this.hasMore,
  });
}

