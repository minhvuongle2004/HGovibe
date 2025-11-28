import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/models/users/app_user.dart';
import 'package:smart_travel_app/providers/auth/user_provider.dart';
import 'package:smart_travel_app/providers/favorites/favorites_provider.dart';
import 'package:smart_travel_app/services/auth/auth_service.dart';
import 'package:smart_travel_app/services/destinations/favorites_service.dart';
import 'package:smart_travel_app/services/users/user_profile_service.dart';
import 'package:smart_travel_app/widgets/destinations/favorite_destination_card.dart';

void main() {
  setUpAll(() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project-id',
        ),
      );
    } catch (_) {
      // Firebase already initialized
    }
  });

  group('FavoriteDestinationCard', () {
    late Destination testDestination;
    late FavoritesProvider favoritesProvider;
    late UserProvider userProvider;
    late AuthService authService;

    setUp(() {
      final favoritesFirestore = FakeFirebaseFirestore();
      final testFavoritesService =
          FavoritesService.testing(favoritesFirestore);
      final profileFirestore = FakeFirebaseFirestore();
      authService = AuthService.testing(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(
            uid: 'test-user',
            email: 'test@example.com',
          ),
        ),
        profileService: UserProfileService.testing(profileFirestore),
      );
      favoritesProvider = FavoritesProvider(favoritesService: testFavoritesService);
      userProvider = UserProvider.test(
        const AppUser(uid: 'test-user', email: 'test@example.com'),
        authService: authService,
      );

      testDestination = Destination(
        id: 'test-dest-1',
        name: 'Test Destination',
        nameLowercase: 'test destination',
        slug: 'test-destination',
        category: 'Thiên nhiên',
        tags: const ['tag1', 'tag2'],
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
        images: const ['https://example.com/image1.jpg'],
        thumbnail: 'https://example.com/thumbnail.jpg',
        rating: 4.5,
        reviewCount: 100,
        popularityScore: 1000,
        bestMonths: const [1, 2, 3],
        seasonalEvents: const [],
        specialties: const [],
        activities: const [],
        tips: const [],
        nearbyPlaces: const [],
        suggestedDuration: '2 giờ',
        suggestedDurationHours: 2,
        weatherDependent: false,
        suitableFor: const [],
        status: 'active',
        verified: true,
        visitCount: 1000,
        trendingScore: 100,
        userPreferenceTags: const [],
      );
    });

    Widget _buildTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider<FavoritesProvider>.value(
            value: favoritesProvider,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('hiển thị tên địa điểm', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(FavoriteDestinationCard(destination: testDestination)),
      );

      expect(find.text('Test Destination'), findsOneWidget);
    });

    testWidgets('hiển thị heart icon overlay', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(FavoriteDestinationCard(destination: testDestination)),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('hiển thị rating và review count', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(FavoriteDestinationCard(destination: testDestination)),
      );

      expect(find.text('4.5(100)'), findsOneWidget);
    });

    testWidgets('có thể tap để navigate', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(FavoriteDestinationCard(destination: testDestination)),
      );

      await tester.tap(find.byType(FavoriteDestinationCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });
  });
}

