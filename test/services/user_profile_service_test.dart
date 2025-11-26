import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_travel_app/services/user_profile_service.dart';

void main() {
  test('createProfile tạo document mới trong Firestore', () async {
    final fake = FakeFirebaseFirestore();
    final service = UserProfileService.testing(fake);

    final profile = await service.createProfile(
      uid: 'user-1',
      fullName: 'Traveler',
      email: 'traveler@example.com',
    );

    final snapshot = await fake.collection('users').doc('user-1').get();

    expect(snapshot.exists, isTrue);
    expect(snapshot.data()?['fullName'], 'Traveler');
    expect(profile.uid, 'user-1');
  });

  test('updateProfileFields merge dữ liệu và cập nhật timestamp', () async {
    final fake = FakeFirebaseFirestore();
    final service = UserProfileService.testing(fake);

    await service.createProfile(
      uid: 'user-2',
      fullName: 'Explorer',
      email: 'explorer@example.com',
    );

    await service.updateProfileFields('user-2', {
      'city': 'Hà Nội',
      'country': 'Việt Nam',
    });

    final snapshot = await fake.collection('users').doc('user-2').get();
    expect(snapshot.data()?['city'], 'Hà Nội');
    expect(snapshot.data()?['country'], 'Việt Nam');
  });
}


