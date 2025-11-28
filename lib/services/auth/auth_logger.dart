import 'package:flutter/foundation.dart';

/// Tầng logging/analytics đơn giản cho luồng Auth.
/// Có thể thay thế/ mở rộng bằng Firebase Analytics, Sentry,...
class AuthLogger {
  AuthLogger._();

  static void logEvent(String message) {
    debugPrint('🔐 [AUTH EVENT] $message');
  }

  static void logError(Object error, [StackTrace? stack]) {
    debugPrint('⚠️ [AUTH ERROR] $error');
    if (stack != null) {
      debugPrint(stack.toString());
    }
  }
}
