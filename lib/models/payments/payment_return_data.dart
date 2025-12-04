import 'dart:convert';

import 'package:smart_travel_app/models/tours/tour_booking.dart';

class PaymentReturnData {
  PaymentReturnData({
    required this.bookingId,
    required this.orderId,
    required this.isSuccess,
    required this.message,
    this.gatewayTransactionId,
    this.resultCode,
    this.gatewayRaw = const {},
  });

  final String bookingId;
  final String orderId;
  final bool isSuccess;
  final String message;
  final String? gatewayTransactionId;
  final int? resultCode;
  final Map<String, String> gatewayRaw;

  PaymentStatus get suggestedStatus =>
      isSuccess ? PaymentStatus.pending : PaymentStatus.failed;

  /// Parse dữ liệu trả về từ return URL của VNPay (nếu có query params).
  factory PaymentReturnData.fromVnPayUri(Uri uri) {
    final params = uri.queryParameters;
    return PaymentReturnData.fromVnPayParams(params);
  }

  factory PaymentReturnData.fromVnPayParams(Map<String, String> params) {
    final orderId = params['vnp_TxnRef'] ?? '';
    final responseCode = params['vnp_ResponseCode'];
    final transactionStatus = params['vnp_TransactionStatus'];
    // VNPay: ResponseCode = '00' và TransactionStatus = '00' là thành công
    final isSuccess = responseCode == '00' && transactionStatus == '00';
    final bookingId = orderId.isNotEmpty ? orderId : '';
    final message = params['vnp_OrderInfo'] ??
        (isSuccess
            ? 'Giao dịch đang được xử lý. Vui lòng đợi hệ thống xác nhận.'
            : 'Thanh toán thất bại hoặc bị hủy.');

    return PaymentReturnData(
      bookingId: bookingId,
      orderId: orderId,
      isSuccess: isSuccess,
      message: message,
      gatewayTransactionId: params['vnp_TransactionNo'],
      resultCode: int.tryParse(responseCode ?? ''),
      gatewayRaw: params,
    );
  }

  static String _extractBookingIdFromExtra(String? extraData) {
    if (extraData == null || extraData.isEmpty) return '';
    try {
      final decoded = utf8.decode(base64.decode(extraData));
      final map = jsonDecode(decoded);
      return map['bookingId'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}

