import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/auth_logger.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService;

  AppUser? _user;
  bool _isLoading = true;
  StreamSubscription<AppUser?>? _subscription;
  DateTime? _lastVerificationEmailAt;
  DateTime? _lastPasswordResetAt;

  static const Duration _emailThrottleDuration = Duration(minutes: 5);

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  Duration? get verificationCooldown =>
      _remainingCooldown(_lastVerificationEmailAt);
  Duration? get passwordResetCooldown =>
      _remainingCooldown(_lastPasswordResetAt);

  UserProvider({AuthService? authService})
      : _authService = authService ?? AuthService.instance {
    _subscription = _authService.userChanges.listen((appUser) {
      _user = appUser;
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> refreshUser() async {
    _isLoading = true;
    notifyListeners();
    final refreshed = await _authService.refreshCurrentUser();
    _user = refreshed;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    await _authService.updateDisplayName(name);
    await refreshUser();
    AuthLogger.logEvent('Display name updated');
  }

  Future<void> updateProfileFields(Map<String, dynamic> data) async {
    await _authService.updateProfileFields(data);
    await refreshUser();
    AuthLogger.logEvent('Profile fields updated: ${data.keys.join(', ')}');
  }

  Future<void> sendEmailVerification() async {
    if (_isThrottled(_lastVerificationEmailAt)) {
      throw ThrottleException(verificationCooldown ?? _emailThrottleDuration);
    }
    await _authService.sendEmailVerification();
    _lastVerificationEmailAt = DateTime.now();
    AuthLogger.logEvent('Email verification sent');
  }

  Future<void> sendPasswordReset() async {
    final email = _user?.email;
    if (email == null) return;
    if (_isThrottled(_lastPasswordResetAt)) {
      throw ThrottleException(passwordResetCooldown ?? _emailThrottleDuration);
    }
    await _authService.sendPasswordReset(email);
    _lastPasswordResetAt = DateTime.now();
    AuthLogger.logEvent('Password reset sent for $email');
  }

  Future<void> linkGoogleAccount() async {
    final updated = await _authService.linkGoogleAccount();
    _user = updated;
    notifyListeners();
    AuthLogger.logEvent('Linked Google account');
  }

  Future<void> linkFacebookAccount() async {
    final updated = await _authService.linkFacebookAccount();
    _user = updated;
    notifyListeners();
    AuthLogger.logEvent('Linked Facebook account');
  }

  Future<void> unlinkProvider(String providerId) async {
    final updated = await _authService.unlinkProvider(providerId);
    _user = updated;
    notifyListeners();
    AuthLogger.logEvent('Unlinked provider $providerId');
  }

  bool _isThrottled(DateTime? lastSent) {
    if (lastSent == null) return false;
    return DateTime.now().difference(lastSent) < _emailThrottleDuration;
  }

  Duration? _remainingCooldown(DateTime? lastSent) {
    if (lastSent == null) return null;
    final elapsed = DateTime.now().difference(lastSent);
    if (elapsed >= _emailThrottleDuration) return null;
    return _emailThrottleDuration - elapsed;
  }
}

class ThrottleException implements Exception {
  final Duration remaining;
  const ThrottleException(this.remaining);

  @override
  String toString() =>
      'ThrottleException: try again in ${remaining.inSeconds} seconds';
}


