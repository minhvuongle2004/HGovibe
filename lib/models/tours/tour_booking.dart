import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_travel_app/models/tours/tour_package.dart';
import 'package:smart_travel_app/models/tours/participant_info.dart';
import 'package:smart_travel_app/models/tours/contact_info.dart';

/// Trạng thái thanh toán
enum PaymentStatus {
  unpaid, // Chưa tạo giao dịch
  pending, // Đang xử lý giao dịch
  paid, // Đã thanh toán
  refunded, // Đã hoàn tiền
  failed, // Thanh toán thất bại
}

/// Phương thức thanh toán
enum PaymentMethod {
  cash, // Tiền mặt
  bankTransfer, // Chuyển khoản
  creditCard, // Thẻ tín dụng
}

/// Trạng thái booking
enum BookingStatus {
  pending, // Chờ xác nhận
  confirmed, // Đã xác nhận
  cancelled, // Đã hủy
  completed, // Đã hoàn thành
}

/// Model đại diện cho một booking tour
class TourBooking {
  final String? id; // Document ID từ Firestore
  final String userId; // User đặt tour
  final String tourPackageId; // ID tour package
  final TourPackage? tourPackage; // Tour package (loaded, optional)

  // Thông tin booking
  final String bookingNumber; // Mã booking (unique)
  final DateTime bookingDate; // Ngày đặt
  final DateTime departureDate; // Ngày khởi hành
  final int numberOfAdults; // Số người lớn
  final int numberOfChildren; // Số trẻ em
  final int numberOfInfants; // Số em bé

  // Thông tin người tham gia
  final List<ParticipantInfo> participants; // Danh sách người tham gia
  final ContactInfo contactInfo; // Thông tin liên hệ

  // Giá cả
  final double subtotal; // Tổng tiền trước giảm giá
  final double? discountAmount; // Số tiền giảm
  final double totalAmount; // Tổng tiền phải trả
  final String currency; // Đơn vị tiền tệ

  // Thanh toán
  final PaymentStatus paymentStatus; // Trạng thái thanh toán
  final PaymentMethod? paymentMethod; // Phương thức thanh toán
  final DateTime? paymentAt; // Thời điểm gateway xác nhận thanh toán
  final String? paymentTransactionId; // ID giao dịch
  final String? paymentRequestId; // ID yêu cầu gửi lên gateway
  final Map<String, dynamic>? paymentGatewayRawData; // Payload gateway trả về

  // Trạng thái
  final BookingStatus status; // Trạng thái booking
  final DateTime? confirmedAt; // Ngày xác nhận
  final DateTime? cancelledAt; // Ngày hủy
  final String? cancellationReason; // Lý do hủy

  // Ghi chú
  final String? specialRequests; // Yêu cầu đặc biệt
  final String? notes; // Ghi chú từ admin

  TourBooking({
    this.id,
    required this.userId,
    required this.tourPackageId,
    this.tourPackage,
    required this.bookingNumber,
    required this.bookingDate,
    required this.departureDate,
    required this.numberOfAdults,
    this.numberOfChildren = 0,
    this.numberOfInfants = 0,
    required this.participants,
    required this.contactInfo,
    required this.subtotal,
    this.discountAmount,
    required this.totalAmount,
    this.currency = 'VND',
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentAt,
    this.paymentTransactionId,
    this.paymentRequestId,
    this.paymentGatewayRawData,
    required this.status,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.specialRequests,
    this.notes,
  });

  /// Convert từ Firestore DocumentSnapshot
  factory TourBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TourBooking.fromMap(data, id: doc.id);
  }

  /// Convert từ Map (Firestore hoặc JSON)
  factory TourBooking.fromMap(Map<String, dynamic> map, {String? id}) {
    // Parse paymentStatus
    PaymentStatus paymentStatus;
    switch (map['paymentStatus'] as String?) {
      case 'unpaid':
        paymentStatus = PaymentStatus.unpaid;
        break;
      case 'pending':
        paymentStatus = PaymentStatus.pending;
        break;
      case 'paid':
        paymentStatus = PaymentStatus.paid;
        break;
      case 'refunded':
        paymentStatus = PaymentStatus.refunded;
        break;
      case 'failed':
        paymentStatus = PaymentStatus.failed;
        break;
      default:
        paymentStatus = PaymentStatus.unpaid;
    }

    // Parse paymentMethod
    PaymentMethod? paymentMethod;
    switch (map['paymentMethod'] as String?) {
      case 'cash':
        paymentMethod = PaymentMethod.cash;
        break;
      case 'bank_transfer':
        paymentMethod = PaymentMethod.bankTransfer;
        break;
      case 'credit_card':
        paymentMethod = PaymentMethod.creditCard;
        break;
      default:
        paymentMethod = null;
    }

    // Parse status
    BookingStatus status;
    switch (map['status'] as String?) {
      case 'pending':
        status = BookingStatus.pending;
        break;
      case 'confirmed':
        status = BookingStatus.confirmed;
        break;
      case 'cancelled':
        status = BookingStatus.cancelled;
        break;
      case 'completed':
        status = BookingStatus.completed;
        break;
      default:
        status = BookingStatus.pending;
    }

    return TourBooking(
      id: id ?? map['id'],
      userId: map['userId'] ?? '',
      tourPackageId: map['tourPackageId'] ?? '',
      bookingNumber: map['bookingNumber'] ?? '',
      bookingDate: map['bookingDate'] is Timestamp
          ? (map['bookingDate'] as Timestamp).toDate()
          : DateTime.parse(map['bookingDate'] ?? DateTime.now().toIso8601String()),
      departureDate: map['departureDate'] is Timestamp
          ? (map['departureDate'] as Timestamp).toDate()
          : DateTime.parse(map['departureDate'] ?? DateTime.now().toIso8601String()),
      numberOfAdults: map['numberOfAdults'] ?? 0,
      numberOfChildren: map['numberOfChildren'] ?? 0,
      numberOfInfants: map['numberOfInfants'] ?? 0,
      participants: (map['participants'] as List<dynamic>?)
              ?.map((e) => ParticipantInfo.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      contactInfo: ContactInfo.fromMap(map['contactInfo'] ?? {}),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'VND',
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      paymentAt: _parsePaymentAt(map),
      paymentTransactionId: map['paymentTransactionId'],
      paymentRequestId: map['paymentRequestId'],
      paymentGatewayRawData: map['paymentGatewayRawData'] is Map
          ? Map<String, dynamic>.from(
              map['paymentGatewayRawData'] as Map,
            )
          : null,
      status: status,
      confirmedAt: map['confirmedAt'] is Timestamp
          ? (map['confirmedAt'] as Timestamp).toDate()
          : map['confirmedAt'] != null
              ? DateTime.parse(map['confirmedAt'])
              : null,
      cancelledAt: map['cancelledAt'] is Timestamp
          ? (map['cancelledAt'] as Timestamp).toDate()
          : map['cancelledAt'] != null
              ? DateTime.parse(map['cancelledAt'])
              : null,
      cancellationReason: map['cancellationReason'],
      specialRequests: map['specialRequests'],
      notes: map['notes'],
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tourPackageId': tourPackageId,
      'bookingNumber': bookingNumber,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'departureDate': Timestamp.fromDate(departureDate),
      'numberOfAdults': numberOfAdults,
      'numberOfChildren': numberOfChildren,
      'numberOfInfants': numberOfInfants,
      'participants': participants.map((e) => e.toMap()).toList(),
      'contactInfo': contactInfo.toMap(),
      'subtotal': subtotal,
      if (discountAmount != null) 'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'paymentStatus': _paymentStatusToString(paymentStatus),
      if (paymentMethod != null)
        'paymentMethod': _paymentMethodToString(paymentMethod!),
      if (paymentAt != null) 'paymentAt': Timestamp.fromDate(paymentAt!),
      if (paymentTransactionId != null)
        'paymentTransactionId': paymentTransactionId,
      if (paymentRequestId != null) 'paymentRequestId': paymentRequestId,
      if (paymentGatewayRawData != null)
        'paymentGatewayRawData': paymentGatewayRawData,
      'status': _statusToString(status),
      if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (specialRequests != null) 'specialRequests': specialRequests,
      if (notes != null) 'notes': notes,
    };
  }

  String _paymentStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'unpaid';
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

  static DateTime? _parsePaymentAt(Map<String, dynamic> map) {
    final rawPaymentAt = map['paymentAt'] ?? map['paidAt'];
    if (rawPaymentAt is Timestamp) {
      return rawPaymentAt.toDate();
    }
    if (rawPaymentAt is DateTime) {
      return rawPaymentAt;
    }
    if (rawPaymentAt is String && rawPaymentAt.isNotEmpty) {
      return DateTime.tryParse(rawPaymentAt);
    }
    return null;
  }
}

