import 'package:flutter/foundation.dart';
import 'package:smart_travel_app/models/tours/tour_booking.dart';
import 'package:smart_travel_app/services/tours/tour_booking_service.dart';

/// Provider quản lý state của tour bookings
class TourBookingProvider with ChangeNotifier {
  final TourBookingService _service = TourBookingService.instance;

  List<TourBooking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<TourBooking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load bookings của user
  Future<void> loadUserBookings(
    String userId, {
    BookingStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookings = await _service.getUserBookings(userId, status: status);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading user bookings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo booking mới
  Future<String?> createBooking(TourBooking booking) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bookingId = await _service.createBooking(booking);
      // Reload bookings
      if (booking.userId.isNotEmpty) {
        await loadUserBookings(booking.userId);
      }
      _error = null;
      return bookingId;
    } catch (e) {
      _error = e.toString();
      print('Error creating booking: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy booking theo ID
  Future<TourBooking?> getBookingById(String bookingId) async {
    try {
      return await _service.getBookingById(bookingId);
    } catch (e) {
      print('Error getting booking by ID: $e');
      return null;
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateBookingStatus(
        bookingId,
        status,
        confirmedAt: confirmedAt,
        cancelledAt: cancelledAt,
        cancellationReason: cancellationReason,
      );
      
      // Reload bookings
      final booking = await _service.getBookingById(bookingId);
      if (booking != null) {
        await loadUserBookings(booking.userId);
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error updating booking status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updatePaymentStatus(
        bookingId,
        paymentStatus,
        paymentMethod: paymentMethod,
        paidAt: paidAt,
        paymentTransactionId: paymentTransactionId,
      );
      
      // Reload bookings
      final booking = await _service.getBookingById(bookingId);
      if (booking != null) {
        await loadUserBookings(booking.userId);
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error updating payment status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh bookings
  Future<void> refresh(String userId) async {
    await loadUserBookings(userId);
  }
}

