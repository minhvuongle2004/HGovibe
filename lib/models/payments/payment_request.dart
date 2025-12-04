import 'package:smart_travel_app/models/tours/tour_booking.dart';

enum PaymentGateway {
  vnpay,
}

class PaymentRequest {
  PaymentRequest({
    required this.bookingId,
    required this.requestId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.gateway,
    required this.rawResponse,
    this.payUrl,
    this.deepLinkUrl,
  });

  final String bookingId;
  final String requestId;
  final String orderId;
  final double amount;
  final String currency;
  final PaymentGateway gateway;
  final String? payUrl;
  final String? deepLinkUrl;
  final Map<String, dynamic> rawResponse;

  /// URL được dùng để mở trang thanh toán VNPay (web-based).
  String? get launchUrl {
    if (payUrl != null && payUrl!.isNotEmpty) return payUrl;
    return null;
  }

  PaymentStatus get pendingStatus => PaymentStatus.pending;
}

