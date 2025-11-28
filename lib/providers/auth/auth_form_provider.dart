import 'package:flutter/material.dart';

import 'package:smart_travel_app/services/auth/auth_service.dart';
import 'package:smart_travel_app/services/auth/exceptions/auth_exceptions.dart';
import 'package:smart_travel_app/services/auth/auth_logger.dart';

enum AuthFormMode { signIn, signUp }

class AuthFormProvider extends ChangeNotifier {
  static const Duration _resetThrottle = Duration(minutes: 5);
  static DateTime? _lastResetRequestAt;

  AuthFormProvider(this.mode);

  final AuthFormMode mode;
  final AuthService _authService = AuthService.instance;

  String email = '';
  String password = '';
  String confirmPassword = '';
  String displayName = '';
  bool rememberMe = false;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  void setEmail(String value) {
    email = value.trim();
  }

  void setPassword(String value) {
    password = value;
  }

  void setConfirmPassword(String value) {
    confirmPassword = value;
  }

  void setDisplayName(String value) {
    displayName = value.trim();
  }

  void setRememberMe(bool value) {
    rememberMe = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải ít nhất 6 ký tự';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (mode == AuthFormMode.signUp) {
      if (value != password) {
        return 'Mật khẩu nhập lại không khớp';
      }
    }
    return null;
  }

  Future<void> sendPasswordReset(String emailInput) async {
    try {
      if (_isResetThrottled()) {
        errorMessage =
            'Bạn đã yêu cầu gần đây. Vui lòng thử lại sau ${_formatDuration(_resetThrottle - DateTime.now().difference(_lastResetRequestAt!))}';
        notifyListeners();
        return;
      }
      setLoading(true);
      await _authService.sendPasswordReset(emailInput);
      successMessage = 'Đã gửi email đặt lại mật khẩu';
      _lastResetRequestAt = DateTime.now();
      AuthLogger.logEvent('Password reset email sent to $emailInput');
    } catch (error) {
      errorMessage = _mapError(error);
      AuthLogger.logError(error);
    } finally {
      setLoading(false);
    }
  }

  Future<void> submit() async {
    try {
      setLoading(true);
      if (mode == AuthFormMode.signIn) {
        await _authService.signInWithEmail(email: email, password: password);
        AuthLogger.logEvent('Sign in success for $email');
      } else {
        await _authService.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        );
        AuthLogger.logEvent('Sign up success for $email');
      }
      successMessage = mode == AuthFormMode.signIn
          ? 'Đăng nhập thành công'
          : 'Đăng ký thành công';
    } catch (error) {
      errorMessage = _mapError(error);
      AuthLogger.logError(error);
    } finally {
      setLoading(false);
    }
  }

  String _mapError(Object error) {
    if (error is AuthCancelledException) {
      return error.message;
    }
    if (error is AccountExistsWithDifferentCredentialException) {
      return error.toString();
    }
    final message = error is Exception ? error.toString() : 'Đã có lỗi xảy ra';
    if (message.contains('user-not-found')) {
      return 'Email chưa được đăng ký';
    }
    if (message.contains('wrong-password')) {
      return 'Mật khẩu không chính xác';
    }
    if (message.contains('email-already-in-use')) {
      return 'Email đã được sử dụng';
    }
    if (message.contains('weak-password')) {
      return 'Mật khẩu quá yếu';
    }
    if (message.contains('account-exists-with-different-credential')) {
      return 'Email này đã được đăng ký bằng phương thức khác. '
          'Vui lòng đăng nhập bằng phương thức đó trước, sau đó liên kết tài khoản trong phần Tài khoản.';
    }
    return 'Đã xảy ra lỗi, vui lòng thử lại';
  }

  Future<void> signInWithGoogle() async {
    try {
      setLoading(true);
      await _authService.signInWithGoogle();
      successMessage = 'Đăng nhập bằng Google thành công';
    } catch (error) {
      errorMessage = _mapError(error);
    } finally {
      setLoading(false);
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      setLoading(true);
      await _authService.signInWithFacebook();
      successMessage = 'Đăng nhập bằng Facebook thành công';
    } catch (error) {
      errorMessage = _mapError(error);
    } finally {
      setLoading(false);
    }
  }

  bool _isResetThrottled() {
    if (_lastResetRequestAt == null) return false;
    return DateTime.now().difference(_lastResetRequestAt!) < _resetThrottle;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return seconds > 0 ? '$minutes phút ${seconds}s' : '$minutes phút';
    }
    return '${seconds}s';
  }
}
