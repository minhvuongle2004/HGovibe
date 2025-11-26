import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_travel_app/services/favorites_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FavoritesService favoritesService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    favoritesService = FavoritesService.testing(fakeFirestore);
  });

  group('FavoritesService', () {
    test('addFavorite tạo document mới trong subcollection favorites', () async {
      const userId = 'user-1';
      const destinationId = 'dest-1';

      await favoritesService.addFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['destinationId'], destinationId);
      expect(snapshot.docs.first.data()['addedAt'], isNotNull);
    });

    test('addFavorite không thêm duplicate', () async {
      const userId = 'user-1';
      const destinationId = 'dest-1';

      // Thêm lần đầu
      await favoritesService.addFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      // Thêm lần hai (duplicate)
      await favoritesService.addFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      // Chỉ có 1 document
      expect(snapshot.docs.length, 1);
    });

    test('removeFavorite xóa document khỏi subcollection', () async {
      const userId = 'user-1';
      const destinationId = 'dest-1';

      // Thêm favorite
      await favoritesService.addFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      // Xóa favorite
      await favoritesService.removeFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      expect(snapshot.docs.length, 0);
    });

    test('isFavorite trả về true nếu đã yêu thích', () async {
      const userId = 'user-1';
      const destinationId = 'dest-1';

      await favoritesService.addFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      final isFav = await favoritesService.isFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      expect(isFav, isTrue);
    });

    test('isFavorite trả về false nếu chưa yêu thích', () async {
      const userId = 'user-1';
      const destinationId = 'dest-1';

      final isFav = await favoritesService.isFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      expect(isFav, isFalse);
    });

    test('getFavorites trả về danh sách favorites của user', () async {
      const userId = 'user-1';

      // Thêm nhiều favorites
      await favoritesService.addFavorite(
        userId: userId,
        destinationId: 'dest-1',
      );
      await favoritesService.addFavorite(
        userId: userId,
        destinationId: 'dest-2',
      );

      final favorites = await favoritesService.getFavorites(userId);

      expect(favorites.length, 2);
      expect(favorites.map((f) => f.destinationId).toSet(),
          {'dest-1', 'dest-2'});
    });

    test('toggleFavorite thêm nếu chưa có, xóa nếu đã có', () async {
      const userId = 'user-1';
      const destinationId = 'dest-1';

      // Lần 1: thêm
      final wasAdded1 = await favoritesService.toggleFavorite(
        userId: userId,
        destinationId: destinationId,
      );
      expect(wasAdded1, isTrue);

      // Lần 2: xóa
      final wasAdded2 = await favoritesService.toggleFavorite(
        userId: userId,
        destinationId: destinationId,
      );
      expect(wasAdded2, isFalse);

      // Kiểm tra đã xóa
      final isFav = await favoritesService.isFavorite(
        userId: userId,
        destinationId: destinationId,
      );
      expect(isFav, isFalse);
    });

    test('getFavoriteDestinations join với destinations collection', () async {
      const userId = 'user-1';
      const destinationId = 'dest-1';

      // Tạo destination trong Firestore
      await fakeFirestore.collection('destinations').doc(destinationId).set({
        'name': 'Test Destination',
        'name_lowercase': 'test destination',
        'slug': 'test-destination',
        'category': 'Thiên nhiên',
        'tags': [],
        'location': {
          'latitude': 21.0285,
          'longitude': 105.8542,
          'address': 'Test Address',
          'city': 'Hà Nội',
          'district': 'Hoàn Kiếm',
          'country': 'Việt Nam',
        },
        'description': 'Test description',
        'short_description': 'Test short',
        'images': [],
        'thumbnail': 'https://example.com/image.jpg',
        'rating': 4.5,
        'review_count': 100,
        'popularity_score': 1000,
        'best_months': [1, 2, 3],
        'seasonal_events': [],
        'specialties': [],
        'activities': [],
        'tips': [],
        'nearby_places': [],
        'suggested_duration': '2 giờ',
        'suggested_duration_hours': 2,
        'weather_dependent': false,
        'suitable_for': [],
        'status': 'active',
        'verified': true,
        'visit_count': 1000,
        'trending_score': 100,
        'user_preference_tags': [],
      });

      // Thêm favorite
      await favoritesService.addFavorite(
        userId: userId,
        destinationId: destinationId,
      );

      // Lấy favorite destinations
      final destinations = await favoritesService.getFavoriteDestinations(userId);

      expect(destinations.length, 1);
      expect(destinations.first.id, destinationId);
      expect(destinations.first.name, 'Test Destination');
    });
  });
}

