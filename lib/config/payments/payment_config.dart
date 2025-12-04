/// Cấu hình mặc định cho luồng thanh toán VNPay.
///
/// ⚠️ Cần thay đổi các giá trị bên dưới khi triển khai thực tế:
/// - `cloudFunctionBaseUrl` trỏ tới backend server của bạn (Cloud Functions hoặc backend riêng).
/// - `vnpayReturnUrl` là URL web mà VNPay sẽ redirect về sau khi thanh toán (có thể là trang web của bạn hoặc deep link app).
///
/// 📝 Có 2 options:
/// 1. Firebase Cloud Functions (cần Blaze plan):
///    'https://asia-southeast1-smart-travel-app-a2bfa.cloudfunctions.net'
/// 2. Backend server riêng (miễn phí, xem backend/README.md):
///    'https://your-backend.railway.app' hoặc URL khác
class PaymentConfig {
  PaymentConfig._();

  /// Endpoint tạo yêu cầu thanh toán.
  /// 
  /// Option 1: Firebase Cloud Functions (cần Blaze plan)
  /// 'https://asia-southeast1-smart-travel-app-a2bfa.cloudfunctions.net'
  ///
  /// Option 2: Backend server riêng (không cần Blaze plan)
  /// 'https://your-backend.railway.app' hoặc URL khác
  static const String cloudFunctionBaseUrl =
      'https://smarttravelbackend-production.up.railway.app';
  static const String createVnPayPaymentPath = '/createVnPayPayment';

  /// URL VNPay sẽ redirect về sau khi thanh toán.
  /// Dùng backend endpoint để handle redirect và chuyển về app qua deep link.
  static String get vnpayReturnUrl =>
      '$cloudFunctionBaseUrl/payment/return';

  /// URL đầy đủ tới Cloud Function tạo yêu cầu thanh toán.
  static String get createVnPayPaymentUrl =>
      '$cloudFunctionBaseUrl$createVnPayPaymentPath';
}
