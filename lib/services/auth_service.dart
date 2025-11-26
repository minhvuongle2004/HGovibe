import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/social_login_config.dart';
import '../models/app_user.dart';
import 'exceptions/auth_exceptions.dart';
import 'user_profile_service.dart';

// Import exception mới
import 'exceptions/auth_exceptions.dart' show
    AuthCancelledException,
    AccountExistsWithDifferentCredentialException;

class AuthService {
  AuthService._({
    FirebaseAuth? auth,
    UserProfileService? profileService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _profileService = profileService ?? UserProfileService.instance;

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth;
  final UserProfileService _profileService;

  @visibleForTesting
  factory AuthService.testing({
    required FirebaseAuth auth,
    required UserProfileService profileService,
  }) {
    return AuthService._(auth: auth, profileService: profileService);
  }

  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser.fromFirebaseUser(user);
  }

  Stream<AppUser?> get userChanges {
    return _auth.idTokenChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      final profile = await _profileService.fetchProfile(fbUser.uid);
      return AppUser.fromFirebaseUser(fbUser, profile: profile);
    });
  }

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
      }
      final firebaseUser = credential.user!;
      final profile = await _profileService.createProfile(
        uid: firebaseUser.uid,
        fullName: displayName ?? email.split('@').first,
        email: email,
      );

      return AppUser.fromFirebaseUser(
        firebaseUser,
        profile: profile,
      );
    } on FirebaseAuthException catch (error, stack) {
      debugPrint('❌ signUpWithEmail error: ${error.code} - ${error.message}');
      debugPrint('$stack');
      rethrow;
    }
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user!;
      final profile = await _getOrCreateProfile(
        firebaseUser,
        fallbackFullName: credential.user!.displayName,
        fallbackEmail: credential.user!.email,
      );

      return AppUser.fromFirebaseUser(
        firebaseUser,
        profile: profile,
      );
    } on FirebaseAuthException catch (error, stack) {
      debugPrint('❌ signInWithEmail error: ${error.code} - ${error.message}');
      debugPrint('$stack');
      rethrow;
    }
  }

  Future<AppUser> signInWithGoogle() async {
    String? email;
    try {
      final payload = await _buildGoogleCredential();
      email = payload.email;
      final userCredential =
          await _auth.signInWithCredential(payload.credential);
      final firebaseUser = userCredential.user!;

      final profile = await _getOrCreateProfile(
        firebaseUser,
        fallbackFullName: payload.displayName,
        fallbackEmail: payload.email,
      );

      return AppUser.fromFirebaseUser(
        firebaseUser,
        profile: profile,
      );
    } on AuthCancelledException {
      rethrow;
    } on FirebaseAuthException catch (error, stack) {
      // Xử lý trường hợp email đã tồn tại với provider khác
      if (error.code == 'account-exists-with-different-credential') {
        final errorEmail = error.email ?? email ?? '';
        final providers = _extractProvidersFromError(error);
        
        throw AccountExistsWithDifferentCredentialException(
          email: errorEmail,
          providers: providers,
          attemptedProvider: 'Google',
        );
      }
      debugPrint('❌ signInWithGoogle error: ${error.code} - ${error.message}');
      debugPrint('$stack');
      rethrow;
    } catch (error, stack) {
      if (error is AccountExistsWithDifferentCredentialException) {
        rethrow;
      }
      debugPrint('❌ signInWithGoogle unexpected error: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  Future<AppUser> signInWithFacebook() async {
    String? email;
    try {
      final payload = await _buildFacebookCredential();
      email = payload.email;
      final userCredential =
          await _auth.signInWithCredential(payload.credential);
      final firebaseUser = userCredential.user!;

      final profile = await _getOrCreateProfile(
        firebaseUser,
        fallbackFullName: payload.displayName,
        fallbackEmail: payload.email,
      );

      return AppUser.fromFirebaseUser(
        firebaseUser,
        profile: profile,
      );
    } on AuthCancelledException {
      rethrow;
    } on FirebaseAuthException catch (error, stack) {
      // Xử lý trường hợp email đã tồn tại với provider khác
      if (error.code == 'account-exists-with-different-credential') {
        final errorEmail = error.email ?? email ?? '';
        final providers = _extractProvidersFromError(error);
        
        throw AccountExistsWithDifferentCredentialException(
          email: errorEmail,
          providers: providers,
          attemptedProvider: 'Facebook',
        );
      }
      debugPrint(
          '❌ signInWithFacebook error: ${error.code} - ${error.message}');
      debugPrint('$stack');
      rethrow;
    } catch (error, stack) {
      if (error is AccountExistsWithDifferentCredentialException) {
        rethrow;
      }
      debugPrint('❌ signInWithFacebook unexpected error: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    await user?.sendEmailVerification();
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName.trim());
    await _profileService.updateProfileFields(user.uid, {
      'fullName': displayName.trim(),
    });
    await user.reload();
  }

  Future<void> updateProfileFields(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _profileService.updateProfileFields(user.uid, data);
  }

  Future<AppUser?> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) return null;
    final profile = await _profileService.fetchProfile(refreshed.uid);
    return AppUser.fromFirebaseUser(refreshed, profile: profile);
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    return _profileService.upsertProfile(profile);
  }

  Future<AppUser> linkGoogleAccount() async {
    try {
      final payload = await _buildGoogleCredential();
      final result = await _linkWithCredential(
        payload.credential,
        fallbackFullName: payload.displayName,
        fallbackEmail: payload.email,
      );
      return result;
    } on AuthCancelledException {
      rethrow;
    }
  }

  Future<AppUser> linkFacebookAccount() async {
    try {
      final payload = await _buildFacebookCredential();
      final result = await _linkWithCredential(
        payload.credential,
        fallbackFullName: payload.displayName,
        fallbackEmail: payload.email,
      );
      return result;
    } on AuthCancelledException {
      rethrow;
    }
  }

  Future<AppUser> unlinkProvider(String providerId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-logged-in',
        message: 'Bạn cần đăng nhập lại để thực hiện thao tác này.',
      );
    }

    if (user.providerData.length <= 1) {
      throw FirebaseAuthException(
        code: 'requires-one-provider',
        message: 'Bạn phải giữ lại ít nhất một phương thức đăng nhập.',
      );
    }

    await user.unlink(providerId);
    await user.reload();
    final refreshed = _auth.currentUser!;

    final profile = await _getOrCreateProfile(
      refreshed,
      fallbackFullName: refreshed.displayName,
      fallbackEmail: refreshed.email,
    );
    return AppUser.fromFirebaseUser(
      refreshed,
      profile: profile,
    );
  }

  Future<AppUser> _linkWithCredential(
    OAuthCredential credential, {
    String? fallbackFullName,
    String? fallbackEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-logged-in',
        message: 'Bạn cần đăng nhập lại để thực hiện thao tác này.',
      );
    }

    final result = await user.linkWithCredential(credential);
    final profile = await _getOrCreateProfile(
      result.user!,
      fallbackFullName: fallbackFullName,
      fallbackEmail: fallbackEmail,
    );
    return AppUser.fromFirebaseUser(
      result.user!,
      profile: profile,
    );
  }

  Future<({OAuthCredential credential, String? displayName, String? email})>
      _buildGoogleCredential() async {
    final googleSignIn = GoogleSignIn(
      clientId: SocialLoginConfig.hasGoogleWebClientId
          ? SocialLoginConfig.googleWebClientId
          : null,
      scopes: const ['email'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthCancelledException('Bạn đã hủy đăng nhập Google');
    }

    final googleAuth = await googleUser.authentication;
    return (
      credential: GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),
      displayName: googleUser.displayName,
      email: googleUser.email
    );
  }

  Future<({OAuthCredential credential, String? displayName, String? email})>
      _buildFacebookCredential() async {
    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.cancelled) {
      throw const AuthCancelledException('Bạn đã hủy đăng nhập Facebook');
    }

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw FirebaseAuthException(
        code: 'facebook-login-failed',
        message: result.message ?? 'Không thể đăng nhập bằng Facebook',
      );
    }

    Map<String, dynamic>? fbData;
    try {
      fbData = await FacebookAuth.instance.getUserData(
        fields: "name,email",
      );
    } catch (_) {
      // ignore
    }

    return (
      credential: FacebookAuthProvider.credential(
        result.accessToken!.token,
      ),
      displayName: fbData?['name'] as String?,
      email: fbData?['email'] as String?
    );
  }

  /// Trích xuất danh sách providers từ FirebaseAuthException
  /// Khi gặp lỗi 'account-exists-with-different-credential'
  List<String> _extractProvidersFromError(FirebaseAuthException error) {
    // Firebase có thể cung cấp thông tin providers trong error.customData
    // hoặc có thể fetch từ email, nhưng cách đơn giản nhất là mặc định là 'password'
    // vì thường thì user đăng ký bằng email/password trước
    
    // Nếu có thông tin trong error.customData hoặc error.credential
    // thì có thể parse, nhưng thường thì không có
    // Nên mặc định là 'password' (email/password provider)
    return ['password'];
  }

  Future<UserProfile> _getOrCreateProfile(
    User firebaseUser, {
    String? fallbackFullName,
    String? fallbackEmail,
  }) async {
    final existing = await _profileService.fetchProfile(firebaseUser.uid);
    if (existing != null) return existing;

    return _profileService.createProfile(
      uid: firebaseUser.uid,
      fullName: fallbackFullName ??
          firebaseUser.displayName ??
          fallbackEmail ??
          firebaseUser.email ??
          'Người dùng',
      email: firebaseUser.email ?? fallbackEmail,
    );
  }
}


