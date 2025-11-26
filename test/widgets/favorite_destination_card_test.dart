import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:smart_travel_app/widgets/favorite_destination_card.dart';
import 'package:smart_travel_app/models/destination.dart';
import 'package:smart_travel_app/providers/favorites_provider.dart';

void main() {
  setUpAll(() async {
    // Khởi tạo Firebase với fake app
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project-id',
        ),
      );
    } catch (e) {
      // Firebase đã được khởi tạo, bỏ qua
    }
  });

  group('FavoriteDestinationCard', () {
    late Destination testDestination;

    setUp(() {
      testDestination = Destination(
        id: 'test-dest-1',
        name: 'Test Destination',
        nameLowercase: 'test destination',
        slug: 'test-destination',
        category: 'Thiên nhiên',
        tags: ['tag1', 'tag2'],
        location: Location(
          latitude: 21.0285,
          longitude: 105.8542,
          address: 'Test Address',
          city: 'Hà Nội',
          district: 'Hoàn Kiếm',
          country: 'Việt Nam',
        ),
        description: 'Test description',
        shortDescription: 'Test short',
        images: ['https://example.com/image1.jpg'],
        thumbnail: 'https://example.com/thumbnail.jpg',
        rating: 4.5,
        reviewCount: 100,
        popularityScore: 1000,
        bestMonths: [1, 2, 3],
        seasonalEvents: [],
        specialties: [],
        activities: [],
        tips: [],
        nearbyPlaces: [],
        suggestedDuration: '2 giờ',
        suggestedDurationHours: 2,
        weatherDependent: false,
        suitableFor: [],
        status: 'active',
        verified: true,
        visitCount: 1000,
        trendingScore: 100,
        userPreferenceTags: [],
      );
    });

    testWidgets('hiển thị tên địa điểm', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<FavoritesProvider>.value(
            value: FavoritesProvider(),
            child: Scaffold(
              body: FavoriteDestinationCard(destination: testDestination),
            ),
          ),
        ),
      );

      expect(find.text('Test Destination'), findsOneWidget);
    });

    testWidgets('hiển thị heart icon overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<FavoritesProvider>.value(
            value: FavoritesProvider(),
            child: Scaffold(
              body: FavoriteDestinationCard(destination: testDestination),
            ),
          ),
        ),
      );

      // Tìm heart icon
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('hiển thị rating và review count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<FavoritesProvider>.value(
            value: FavoritesProvider(),
            child: Scaffold(
              body: FavoriteDestinationCard(destination: testDestination),
            ),
          ),
        ),
      );

      expect(find.text('4.5(100)'), findsOneWidget);
    });

    testWidgets('có thể tap để navigate', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<FavoritesProvider>.value(
            value: FavoritesProvider(),
            child: Scaffold(
              body: FavoriteDestinationCard(destination: testDestination),
            ),
          ),
        ),
      );

      // Tap vào card
      await tester.tap(find.byType(FavoriteDestinationCard));
      await tester.pumpAndSettle();

      // Kiểm tra đã navigate (có thể kiểm tra bằng cách tìm DestinationDetailScreen)
      // Tạm thời chỉ kiểm tra không có lỗi
      expect(tester.takeException(), isNull);
    });
  });
}

