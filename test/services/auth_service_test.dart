import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_travel_app/models/app_user.dart';
import 'package:smart_travel_app/services/auth_service.dart';
import 'package:smart_travel_app/services/user_profile_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockUserProfileService extends Mock implements UserProfileService {}

class MockUserMetadata extends Mock implements UserMetadata {}

class MockUserInfo extends Mock implements UserInfo {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUserProfileService mockProfileService;
  late AuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockProfileService = MockUserProfileService();
    authService = AuthService.testing(
      auth: mockAuth,
      profileService: mockProfileService,
    );
  });

  UserInfo _mockUserInfo(String id) {
    final info = MockUserInfo();
    when(() => info.providerId).thenReturn(id);
    return info;
  }

  User _buildUser({
    required String uid,
    String? email,
    String? displayName,
    List<String> providerIds = const ['password'],
  }) {
    final user = MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.email).thenReturn(email);
    when(() => user.displayName).thenReturn(displayName);
    when(() => user.photoURL).thenReturn(null);
    when(() => user.phoneNumber).thenReturn(null);
    when(() => user.emailVerified).thenReturn(true);
    final metadata = MockUserMetadata();
    when(() => metadata.creationTime).thenReturn(DateTime(2024, 1, 1));
    when(() => metadata.lastSignInTime).thenReturn(DateTime(2024, 1, 2));
    when(() => user.metadata).thenReturn(metadata);
    final providerInfos = providerIds.map<UserInfo>((id) {
      final info = _mockUserInfo(id);
      return info;
    }).toList();
    when(() => user.providerData).thenReturn(providerInfos);
    return user;
  }

  group('AuthService.signInWithEmail', () {
    test('trả về AppUser cùng profile khi profile tồn tại', () async {
      final credential = MockUserCredential();
      final mockUser = _buildUser(
        uid: 'user-id',
        email: 'demo@example.com',
        displayName: 'Demo',
      );

      when(() => credential.user).thenReturn(mockUser);
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);

      final profile = UserProfile.empty('user-id', fullName: 'Demo');
      when(() => mockProfileService.fetchProfile('user-id'))
          .thenAnswer((_) async => profile);

      final result = await authService.signInWithEmail(
        email: 'demo@example.com',
        password: 'secret123',
      );

      expect(result.uid, 'user-id');
      expect(result.profile, profile);
      verify(() => mockProfileService.fetchProfile('user-id')).called(1);
      verifyNever(
        () => mockProfileService.createProfile(
          uid: any(named: 'uid'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
        ),
      );
    });

    test('tự tạo profile nếu chưa tồn tại', () async {
      final credential = MockUserCredential();
      final mockUser = _buildUser(
        uid: 'user-id',
        email: 'demo2@example.com',
        displayName: 'Demo 2',
      );

      when(() => credential.user).thenReturn(mockUser);
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);

      when(() => mockProfileService.fetchProfile('user-id'))
          .thenAnswer((_) async => null);
      final createdProfile = UserProfile.empty('user-id', fullName: 'Demo 2');
      when(
        () => mockProfileService.createProfile(
          uid: any(named: 'uid'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => createdProfile);

      final result = await authService.signInWithEmail(
        email: 'demo2@example.com',
        password: 'secret123',
      );

      expect(result.profile, createdProfile);
      verify(() => mockProfileService.createProfile(
            uid: 'user-id',
            fullName: any(named: 'fullName'),
            email: 'demo2@example.com',
          )).called(1);
    });
  });

  group('AuthService.signUpWithEmail', () {
    test('cập nhật displayName và tạo profile', () async {
      final credential = MockUserCredential();
      final mockUser = _buildUser(
        uid: 'new-user',
        email: 'new@example.com',
        displayName: 'New User',
      );

      when(() => credential.user).thenReturn(mockUser);
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);

      when(() => mockUser.updateDisplayName(any()))
          .thenAnswer((_) async => {});

      final createdProfile =
          UserProfile.empty('new-user', fullName: 'New User');
      when(
        () => mockProfileService.createProfile(
          uid: 'new-user',
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => createdProfile);

      final result = await authService.signUpWithEmail(
        email: 'new@example.com',
        password: 'secret123',
        displayName: 'New User',
      );

      expect(result.uid, 'new-user');
      verify(() => mockUser.updateDisplayName('New User')).called(1);
      verify(() => mockProfileService.createProfile(
            uid: 'new-user',
            fullName: 'New User',
            email: 'new@example.com',
          )).called(1);
    });
  });
}


