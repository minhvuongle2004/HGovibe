import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/screens/destinations/destination_detail_screen.dart';

void main() {
  Destination _buildDestination() {
    return Destination(
      id: 'dest_1',
      name: 'Phố đi bộ Nguyễn Huệ',
      nameLowercase: 'phố đi bộ nguyễn huệ',
      slug: 'pho-di-bo-nguyen-hue',
      category: 'attraction',
      tags: const ['city'],
      location: Location(
        latitude: 10.775749,
        longitude: 106.700987,
        address: 'Phường Bến Nghé, Quận 1, TP.HCM',
        city: 'Hồ Chí Minh',
        district: 'Quận 1',
        country: 'Vietnam',
      ),
      description: 'Điểm đến sôi động bậc nhất tại trung tâm Sài Gòn.',
      shortDescription: 'Trung tâm vui chơi, giải trí về đêm.',
      images: const ['https://example.com/image.jpg'],
      thumbnail: 'https://example.com/thumb.jpg',
      rating: 4.7,
      reviewCount: 1280,
      popularityScore: 98,
      bestMonths: const [1, 2, 12],
      seasonalEvents: const [],
      specialties: const [],
      activities: const [],
      tips: const ['Đến vào buổi tối để tận hưởng không khí sôi động.'],
      nearbyPlaces: const [],
      suggestedDuration: '3 giờ',
      suggestedDurationHours: 3,
      weatherDependent: false,
      suitableFor: const ['family'],
      status: 'active',
      verified: true,
      visitCount: 50000,
      trendingScore: 90,
      userPreferenceTags: const ['night-life'],
    );
  }

  testWidgets('Tapping address navigates to map screen', (tester) async {
    final destination = _buildDestination();

    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailScreen(
          destination: destination,
          mapScreenBuilder: (_) => const Scaffold(
            body: Center(child: Text('Fake Map Screen')),
          ),
        ),
      ),
    );

    await tester.tap(find.text(destination.location.address));
    await tester.pumpAndSettle();

    expect(find.text('Fake Map Screen'), findsOneWidget);
  });
}

