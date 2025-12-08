import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_travel_app/config/payments/payment_config.dart';
import 'package:smart_travel_app/models/payments/payment_request.dart';
import 'package:smart_travel_app/models/tours/tour_booking.dart';
import 'package:smart_travel_app/services/tours/tour_booking_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentException implements Exception {
  PaymentException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  final http.Client _httpClient = http.Client();
  final TourBookingService _bookingService = TourBookingService.instance;

  /// Gửi request lên Cloud Function để tạo yêu cầu thanh toán VNPay.
  Future<PaymentRequest> createVnPayPayment({
    required TourBooking booking,
  }) async {
    if (booking.id == null) {
      throw PaymentException('Thiếu bookingId để tạo giao dịch.');
    }

    final endpoint = PaymentConfig.createVnPayPaymentUrl;
    if (endpoint.isEmpty) {
      throw PaymentException(
        'Chưa cấu hình endpoint tạo thanh toán. Cập nhật PaymentConfig trước khi sử dụng.',
      );
    }

    final uri = Uri.parse(endpoint);
    final payload = {
      'bookingId': booking.id,
      'bookingNumber': booking.bookingNumber,
      'orderId': booking.id,
      'amount': booking.totalAmount,
      'currency': booking.currency,
      'returnUrl': PaymentConfig.vnpayReturnUrl,
      'extraData': {
        'bookingId': booking.id,
        'bookingNumber': booking.bookingNumber,
        'userId': booking.userId,
      },
    };

    // Log request để debug
    print('🔵 VNPay Payment Request:');
    print('  URL: $endpoint');
    print('  Payload: ${jsonEncode(payload)}');
    print('  ReturnUrl: ${PaymentConfig.vnpayReturnUrl}');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print('🟢 VNPay Payment Response:');
    print('  Status: ${response.statusCode}');
    print('  Body: ${response.body}');

    if (response.statusCode != 200) {
      throw PaymentException(
        'Không thể tạo giao dịch (HTTP ${response.statusCode}).',
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final requestId = data['requestId'] ?? data['orderId'] ?? booking.id;
    final payUrl = data['payUrl'] ?? data['paymentUrl'];
    if (payUrl == null || payUrl.isEmpty) {
      throw PaymentException('Phản hồi từ server không hợp lệ: thiếu payUrl.');
    }

    final paymentRequest = PaymentRequest(
      bookingId: booking.id!,
      requestId: requestId as String,
      orderId: (data['orderId'] as String?) ?? booking.id!,
      amount: booking.totalAmount,
      currency: booking.currency,
      gateway: PaymentGateway.vnpay,
      payUrl: payUrl as String,
      rawResponse: data,
    );

    await _bookingService.updatePaymentStatus(
      booking.id!,
      paymentRequest.pendingStatus,
      paymentMethod: PaymentMethod.vnpay,
      paymentTransactionId: data['vnp_TransactionNo'] as String?,
      paymentRequestId: paymentRequest.requestId,
      paymentGatewayRawData: data,
    );

    return paymentRequest;
  }

  /// Mở trình duyệt/webview để người dùng hoàn tất thanh toán VNPay.
  Future<void> redirectToGateway(PaymentRequest request) async {
    final url = request.launchUrl;
    if (url == null) {
      throw PaymentException('Không tìm thấy link thanh toán.');
    }

    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw PaymentException('Không thể mở trang thanh toán VNPay.');
    }
  }
}
